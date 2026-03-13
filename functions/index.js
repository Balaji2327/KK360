const admin = require('firebase-admin');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const logger = require('firebase-functions/logger');

admin.initializeApp();

function stringifyValue(value) {
  if (value === null || value === undefined) {
    return '';
  }
  if (typeof value === 'string') {
    return value;
  }
  if (typeof value === 'number' || typeof value === 'boolean') {
    return String(value);
  }
  return JSON.stringify(value);
}

exports.sendNotificationPush = onDocumentCreated(
  'users/{userId}/notifications/{notificationId}',
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.warn('Missing notification snapshot');
      return;
    }

    const notification = snapshot.data();
    const userId = event.params.userId;
    if (!userId) {
      logger.warn('Missing userId param');
      return;
    }

    const userRef = admin.firestore().collection('users').doc(userId);
    const userSnap = await userRef.get();
    if (!userSnap.exists) {
      logger.warn(`User ${userId} does not exist`);
      return;
    }

    const userData = userSnap.data() || {};
    if (userData.pushNotificationsEnabled === false) {
      logger.info(`Push disabled for user ${userId}`);
      return;
    }

    const tokenSnaps = await userRef
      .collection('deviceTokens')
      .where('enabled', '==', true)
      .get();

    const tokens = tokenSnaps.docs
      .map((doc) => doc.data().token)
      .filter((token) => typeof token === 'string' && token.length > 0);

    if (tokens.length === 0) {
      logger.info(`No enabled device tokens for user ${userId}`);
      return;
    }

    const payload = {
      notification: {
        title: notification.title || 'KK360 Notification',
        body: notification.message || '',
      },
      data: {
        notificationId: stringifyValue(
          notification.id || event.params.notificationId,
        ),
        type: stringifyValue(notification.type),
        classId: stringifyValue(notification.classId),
        className: stringifyValue(notification.className),
        senderId: stringifyValue(notification.senderId),
        senderName: stringifyValue(notification.senderName),
        senderRole: stringifyValue(notification.senderRole),
        title: stringifyValue(notification.title),
        message: stringifyValue(notification.message),
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'kk360_notifications',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
          },
        },
      },
      tokens,
    };

    const response = await admin.messaging().sendEachForMulticast(payload);
    const invalidTokenDeletes = [];

    response.responses.forEach((result, index) => {
      if (result.success) {
        return;
      }

      const code = result.error && result.error.code;
      const token = tokens[index];
      logger.error(`Push failed for token ${token}: ${code}`);

      if (
        code === 'messaging/registration-token-not-registered' ||
        code === 'messaging/invalid-registration-token'
      ) {
        const docId = Buffer.from(token, 'utf8').toString('base64url');
        invalidTokenDeletes.push(
          userRef.collection('deviceTokens').doc(docId).delete(),
        );
      }
    });

    if (invalidTokenDeletes.length > 0) {
      await Promise.allSettled(invalidTokenDeletes);
    }

    logger.info(
      `Push sent for notification ${event.params.notificationId}: ${response.successCount} success, ${response.failureCount} failure`,
    );
  },
);
