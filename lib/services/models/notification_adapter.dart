import 'package:hive/hive.dart';
import '../models/notification_model.dart';

class NotificationAdapter extends TypeAdapter<NotificationModel> {
  @override
  final typeId = 3;

  @override
  NotificationModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return NotificationModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      title: fields[2] as String,
      message: fields[3] as String,
      type: fields[4] as String,
      classId: fields[5] as String?,
      className: fields[6] as String?,
      senderId: fields[7] as String?,
      senderName: fields[8] as String?,
      senderRole: fields[9] as String?,
      timestamp: fields[10] as DateTime,
      isRead: fields[11] as bool? ?? false,
      metadata:
          fields[12] != null
              ? Map<String, dynamic>.from(fields[12] as Map)
              : null,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.message)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.classId)
      ..writeByte(6)
      ..write(obj.className)
      ..writeByte(7)
      ..write(obj.senderId)
      ..writeByte(8)
      ..write(obj.senderName)
      ..writeByte(9)
      ..write(obj.senderRole)
      ..writeByte(10)
      ..write(obj.timestamp)
      ..writeByte(11)
      ..write(obj.isRead)
      ..writeByte(12)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
