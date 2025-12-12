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

  // Generic sign-in verifying role via Firestore REST API
  Future<UserCredential> signInWithRole({
    required String email,
    required String password,
    required String projectId,
    required String requiredRole,
    required String roleDisplayName,
  }) async {
    final credential = await signInWithEmail(email: email, password: password);
    final user = credential.user;
    if (user == null) throw 'Authentication failed.';

    debugPrint('[Auth] Authenticated user: ${user.uid} (${user.email})');

    final idToken = await user.getIdToken();
    if (idToken == null) {
      await _auth.signOut();
      throw 'Could not verify your account.';
    }

    final url = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$projectId/databases/(default)/documents/users/${user.uid}',
    );

    debugPrint('[Auth] Checking role via Firestore: $url');

    final resp = await http
        .get(
          url,
          headers: {
            'Authorization': 'Bearer $idToken',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 10));

    debugPrint('[Auth] Firestore response: ${resp.statusCode}');

    if (resp.statusCode == 200) {
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final role = body['fields']?['role']?['stringValue'] as String?;
      debugPrint('[Auth] Role for user ${user.uid}: $role');
      if (role == requiredRole) return credential;
      await _auth.signOut();
      throw 'This account is registered as a $role. Please login with a $roleDisplayName account.';
    } else if (resp.statusCode == 404) {
      await _auth.signOut();
      throw 'Your account is not registered in profile. Please contact admin.';
    } else if (resp.statusCode == 401 || resp.statusCode == 403) {
      await _auth.signOut();
      throw 'Unable to verify your account. Check Firestore rules or permissions.';
    } else {
      await _auth.signOut();
      throw 'Failed to verify role (error ${resp.statusCode}).';
    }
  }

  // Wrapper methods for explicit student and tutor sign-ins
  Future<UserCredential> signInStudent({
    required String email,
    required String password,
    required String projectId,
  }) => signInWithRole(
    email: email,
    password: password,
    projectId: projectId,
    requiredRole: 'student',
    roleDisplayName: 'Student',
  );

  Future<UserCredential> signInTutor({
    required String email,
    required String password,
    required String projectId,
  }) => signInWithRole(
    email: email,
    password: password,
    projectId: projectId,
    requiredRole: 'tutor',
    roleDisplayName: 'Tutor',
  );

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
