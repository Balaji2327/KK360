import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign up with email and password
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in student: authenticate then verify role from Firestore
  // STRICTLY rejects tutor accounts - does not allow login
  Future<UserCredential> signInStudent({
    required String email,
    required String password,
    required String projectId,
  }) async {
    // First authenticate with Firebase
    final credential = await signInWithEmail(email: email, password: password);
    final user = credential.user;
    if (user == null) {
      throw 'Authentication failed.';
    }

    debugPrint(
      '[StudentLogin] Authenticated user: ${user.uid} (${user.email})',
    );

    // Get ID token for Firestore API access
    final idToken = await user.getIdToken();
    debugPrint(
      '[StudentLogin] Got ID token: ${idToken?.substring(0, 20) ?? 'null'}...',
    );

    if (idToken == null) {
      // Can't verify role - reject to be safe
      await _auth.signOut();
      throw 'Could not verify your account. Please try again.';
    }

    // Call Firestore REST API to check role
    final url = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$projectId/databases/(default)/documents/users/${user.uid}',
    );

    debugPrint('[StudentLogin] Calling Firestore API: $url');

    try {
      final resp = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $idToken',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      debugPrint(
        '[StudentLogin] Firestore API response code: ${resp.statusCode}',
      );

      if (resp.statusCode == 200) {
        // User document found - check role field
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        final role = body['fields']?['role']?['stringValue'] as String?;

        debugPrint('[StudentLogin] User role: $role');

        if (role == 'student') {
          // ✅ Correct role - allow login
          debugPrint('[StudentLogin] ✅ Student role verified - login allowed');
          return credential;
        } else if (role == 'tutor') {
          // ❌ Tutor account - REJECT login
          await _auth.signOut();
          debugPrint('[StudentLogin] ❌ Tutor detected - login denied');
          throw 'This account is registered as a Tutor. Please login with a Student account.';
        } else {
          // Unknown role - reject
          await _auth.signOut();
          debugPrint('[StudentLogin] ❌ Unknown role: $role - login denied');
          throw 'Unknown account type: $role. Please contact support.';
        }
      } else if (resp.statusCode == 404) {
        // User document not found - reject
        await _auth.signOut();
        debugPrint('[StudentLogin] ❌ User profile not found (404)');
        throw 'Your account has not been registered. Please contact administrator.';
      } else if (resp.statusCode == 401 || resp.statusCode == 403) {
        // Permission denied - log and reject
        debugPrint('[StudentLogin] ⚠️ Permission denied (${resp.statusCode})');
        debugPrint('[StudentLogin] Response: ${resp.body}');
        await _auth.signOut();
        throw 'Unable to verify your account. Please check Firestore security rules.';
      } else {
        // Other API error - reject
        debugPrint('[StudentLogin] ⚠️ API error: ${resp.statusCode}');
        debugPrint('[StudentLogin] Response: ${resp.body}');
        await _auth.signOut();
        throw 'Failed to verify your account. Please try again later.';
      }
    } catch (e) {
      // If exception during API call or parsing, reject login
      // Don't re-throw if it's our custom error message
      if (e is String) {
        rethrow;
      }
      debugPrint('[StudentLogin] Exception during role verification: $e');
      await _auth.signOut();
      throw 'Unable to verify your account. Please try again.';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Check if user is logged in
  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  // Reset password
  Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Handle Firebase Auth Exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
}
