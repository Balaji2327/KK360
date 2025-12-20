import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<UserCredential> signInAdmin({
    required String email,
    required String password,
    required String projectId,
  }) => signInWithRole(
    email: email,
    password: password,
    projectId: projectId,
    requiredRole: 'admin',
    roleDisplayName: 'Admin',
  );

  // Sign out
  Future<void> signOut() async {
    try {
      // Note: We intentionally do NOT clear cached classes on sign out
      // This allows classes to persist when the same user logs back in
      // The cache is keyed by user ID, so different users have separate caches
      final user = _auth.currentUser;
      if (user != null) {
        debugPrint('[Auth] Signing out user ${user.uid} (cache preserved)');
      }

      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Simple model for user profile
  // Contains name, email and role as filled in Firestore `users/{uid}` doc
  // Fields are optional and may be null
  // Example usage: final profile = await authService.getUserProfile(projectId: 'kk360-69504');
  Future<UserProfile?> getUserProfile({required String projectId}) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final idToken = await user.getIdToken();
    if (idToken == null) return null;

    final url = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$projectId/databases/(default)/documents/users/${user.uid}',
    );

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
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        final fields = body['fields'] as Map<String, dynamic>?;
        final name = fields?['name']?['stringValue'] as String?;
        final email = fields?['email']?['stringValue'] as String?;
        final role = fields?['role']?['stringValue'] as String?;
        return UserProfile(name: name, email: email, role: role);
      } else {
        // Fallback: return basic auth user info
        return UserProfile(
          name: user.displayName,
          email: user.email,
          role: null,
        );
      }
    } catch (e) {
      debugPrint('[Auth] Error fetching user profile: $e');
      return UserProfile(name: user.displayName, email: user.email, role: null);
    }
  }

  // Return a best-effort display name for the currently signed-in user.
  // Priority: Firestore `name` field -> Firebase `displayName` -> Derived from email -> 'User'
  Future<String> getUserDisplayName({required String projectId}) async {
    final profile = await getUserProfile(projectId: projectId);
    final authUser = _auth.currentUser;
    final email = profile?.email ?? authUser?.email;
    final derived = _deriveNameFromEmail(email);
    return profile?.name ?? authUser?.displayName ?? derived ?? 'User';
  }

  String? _deriveNameFromEmail(String? email) {
    if (email == null) return null;
    final local = email.split('@').first;
    final cleaned = local.replaceAll(RegExp(r'[^A-Za-z]+'), ' ').trim();
    if (cleaned.isEmpty) return null;
    final parts = cleaned.split(RegExp(r'\s+'));
    final titled = parts
        .map(
          (p) =>
              p.isEmpty ? p : p[0].toUpperCase() + p.substring(1).toLowerCase(),
        )
        .join(' ');
    return titled;
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

  // ---------------- Assignments API ----------------
  // Create an assignment that is visible to students of a course
  Future<void> createAssignment({
    required String projectId,
    required String title,
    required String classId,
    String? course,
    String? description,
    String? points,
    DateTime? dueDate,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'Not authenticated';
    final idToken = await user.getIdToken();
    if (idToken == null) throw 'Not authenticated';

    final url = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$projectId/databases/(default)/documents/assignments',
    );

    final fields = <String, dynamic>{
      'title': {'stringValue': title},
      'classId': {'stringValue': classId},
      'createdBy': {'stringValue': user.uid},
      'createdAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
    };
    if (course != null && course.isNotEmpty)
      fields['course'] = {'stringValue': course};
    if (description != null && description.isNotEmpty)
      fields['description'] = {'stringValue': description};
    if (points != null && points.isNotEmpty)
      fields['points'] = {'stringValue': points};
    if (dueDate != null)
      fields['dueDate'] = {'timestampValue': dueDate.toUtc().toIso8601String()};

    final body = jsonEncode({'fields': fields});

    final resp = await http
        .post(
          url,
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 10));

    if (resp.statusCode != 200) {
      throw 'Failed to create assignment (status ${resp.statusCode}): ${resp.body}';
    }
  }

  // Model for assignment
  List<AssignmentInfo> _parseAssignmentsFromRunQuery(List<dynamic> respJson) {
    final out = <AssignmentInfo>[];
    for (final item in respJson) {
      final doc = item['document'] as Map<String, dynamic>?;
      if (doc == null) continue;
      final name = doc['name'] as String?;
      final fields = doc['fields'] as Map<String, dynamic>?;
      if (fields == null) continue;
      final title = fields['title']?['stringValue'] as String? ?? '';
      final classId = fields['classId']?['stringValue'] as String? ?? '';
      final course = fields['course']?['stringValue'] as String? ?? '';
      final description =
          fields['description']?['stringValue'] as String? ?? '';
      final points = fields['points']?['stringValue'] as String? ?? '';
      final dueDate = fields['dueDate']?['timestampValue'] as String?;
      final createdAt = fields['createdAt']?['timestampValue'] as String?;
      out.add(
        AssignmentInfo(
          id: name ?? '',
          title: title,
          course: course,
          description: description,
          points: points,
          dueDate: dueDate != null ? DateTime.tryParse(dueDate) : null,
          createdAt: createdAt != null ? DateTime.tryParse(createdAt) : null,
          classId: classId,
        ),
      );
    }
    return out;
  }

  // Get assignments for a class (by classId)
  Future<List<AssignmentInfo>> getAssignmentsForClass({
    required String projectId,
    required String classId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return [];
    final idToken = await user.getIdToken();
    if (idToken == null) return [];

    final url = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$projectId/databases/(default)/documents:runQuery',
    );

    final q = {
      'structuredQuery': {
        'from': [
          {'collectionId': 'assignments'},
        ],
        'where': {
          'fieldFilter': {
            'field': {'fieldPath': 'classId'},
            'op': 'EQUAL',
            'value': {'stringValue': classId},
          },
        },
        'orderBy': [
          {
            'field': {'fieldPath': 'createdAt'},
            'direction': 'DESCENDING',
          },
        ],
      },
    };

    final resp = await http
        .post(
          url,
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(q),
        )
        .timeout(const Duration(seconds: 10));

    if (resp.statusCode != 200)
      throw 'Failed to fetch assignments (status ${resp.statusCode})';
    final body = jsonDecode(resp.body) as List<dynamic>;
    return _parseAssignmentsFromRunQuery(body);
  }

  // -------- Classes API --------
  List<ClassInfo> _parseClassesFromRunQuery(List<dynamic> respJson) {
    final out = <ClassInfo>[];
    for (final item in respJson) {
      final doc = item['document'] as Map<String, dynamic>?;
      if (doc == null) continue;
      final name = doc['name'] as String?;
      final fields = doc['fields'] as Map<String, dynamic>?;
      if (fields == null) continue;
      final title = fields['name']?['stringValue'] as String? ?? '';
      final course = fields['course']?['stringValue'] as String? ?? '';
      final tutorId = fields['tutorId']?['stringValue'] as String? ?? '';
      final membersList = <String>[];
      final membersVal =
          fields['members']?['arrayValue']?['values'] as List<dynamic>?;
      if (membersVal != null) {
        for (final v in membersVal) {
          final s = v['stringValue'] as String?;
          if (s != null) membersList.add(s);
        }
      }
      final createdAt = fields['createdAt']?['timestampValue'] as String?;
      out.add(
        ClassInfo(
          id: name ?? '',
          name: title,
          course: course,
          tutorId: tutorId,
          members: membersList,
          createdAt: createdAt != null ? DateTime.tryParse(createdAt) : null,
        ),
      );
    }
    return out;
  }

  Future<List<ClassInfo>> getClassesForTutor({
    required String projectId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('[Auth] getClassesForTutor: No current user');
      return [];
    }

    debugPrint(
      '[Auth] getClassesForTutor: Fetching classes for user ${user.uid}',
    );
    final idToken = await user.getIdToken();
    if (idToken == null) {
      debugPrint('[Auth] getClassesForTutor: No ID token available');
      return [];
    }

    final url = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$projectId/databases/(default)/documents:runQuery',
    );

    final q = {
      'structuredQuery': {
        'from': [
          {'collectionId': 'classes'},
        ],
        'where': {
          'fieldFilter': {
            'field': {'fieldPath': 'tutorId'},
            'op': 'EQUAL',
            'value': {'stringValue': user.uid},
          },
        },
        // Remove the orderBy to avoid needing a composite index
        // We can sort the results in the app instead
      },
    };

    debugPrint('[Auth] getClassesForTutor: Query: ${jsonEncode(q)}');

    final resp = await http
        .post(
          url,
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(q),
        )
        .timeout(const Duration(seconds: 10));

    debugPrint(
      '[Auth] getClassesForTutor: Response status: ${resp.statusCode}',
    );
    debugPrint('[Auth] getClassesForTutor: Response body: ${resp.body}');

    if (resp.statusCode != 200)
      throw 'Failed to fetch classes (status ${resp.statusCode}): ${resp.body}';
    final body = jsonDecode(resp.body) as List<dynamic>;
    final parsed = _parseClassesFromRunQuery(body);

    // Sort by createdAt in descending order (newest first) on the client side
    parsed.sort((a, b) {
      if (a.createdAt == null && b.createdAt == null) return 0;
      if (a.createdAt == null) return 1;
      if (b.createdAt == null) return -1;
      return b.createdAt!.compareTo(a.createdAt!);
    });

    debugPrint('[Auth] getClassesForTutor: Parsed ${parsed.length} classes');
    for (final c in parsed) {
      debugPrint(
        '[Auth] getClassesForTutor: Class: ${c.name} (${c.id}) - tutorId: ${c.tutorId}',
      );
    }

    // Cache the fetched classes for quick access
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        final key = 'cached_tutor_classes_${user.uid}';
        await prefs.setString(
          key,
          jsonEncode(parsed.map((c) => c.toJson()).toList()),
        );
      }
    } catch (e) {
      debugPrint('[Auth] Could not cache classes: $e');
    }

    return parsed;
  }

  Future<List<ClassInfo>> getClassesForUser({required String projectId}) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('[Auth] getClassesForUser: No current user');
      return [];
    }

    debugPrint(
      '[Auth] getClassesForUser: Fetching classes for user ${user.uid}',
    );

    final idToken = await user.getIdToken();
    if (idToken == null) {
      debugPrint('[Auth] getClassesForUser: No ID token');
      return [];
    }

    final url = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$projectId/databases/(default)/documents:runQuery',
    );

    final q = {
      'structuredQuery': {
        'from': [
          {'collectionId': 'classes'},
        ],
        'where': {
          'fieldFilter': {
            'field': {'fieldPath': 'members'},
            'op': 'ARRAY_CONTAINS',
            'value': {'stringValue': user.uid},
          },
        },
        'orderBy': [
          {
            'field': {'fieldPath': 'createdAt'},
            'direction': 'DESCENDING',
          },
        ],
      },
    };

    debugPrint(
      '[Auth] getClassesForUser: Query for user ${user.uid}: ${jsonEncode(q)}',
    );

    final resp = await http
        .post(
          url,
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(q),
        )
        .timeout(const Duration(seconds: 10));

    debugPrint('[Auth] getClassesForUser: Response status: ${resp.statusCode}');
    debugPrint('[Auth] getClassesForUser: Response body: ${resp.body}');

    if (resp.statusCode != 200)
      throw 'Failed to fetch classes (status ${resp.statusCode})';
    final body = jsonDecode(resp.body) as List<dynamic>;
    final parsed = _parseClassesFromRunQuery(body);

    debugPrint(
      '[Auth] getClassesForUser: Found ${parsed.length} classes for user ${user.uid}',
    );
    for (final c in parsed) {
      debugPrint(
        '[Auth] getClassesForUser: Class: ${c.name} (${c.id}) - members: ${c.members}',
      );
    }

    // Cache the fetched classes for quick access
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        final key = 'cached_student_classes_${user.uid}';
        await prefs.setString(
          key,
          jsonEncode(parsed.map((c) => c.toJson()).toList()),
        );
      }
    } catch (e) {
      debugPrint('[Auth] Could not cache classes: $e');
    }

    return parsed;
  }

  // Create a class document in 'classes' collection and return its document id
  Future<String> createClass({
    required String projectId,
    required String name,
    String? course,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'Not authenticated';

    // Get fresh token for each request to avoid token expiry issues
    final idToken = await user.getIdToken(true); // Force refresh
    if (idToken == null) throw 'Not authenticated';

    debugPrint(
      '[Auth] Creating class: $name (course: $course) for user: ${user.uid}',
    );

    final url = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$projectId/databases/(default)/documents/classes',
    );

    final fields = <String, dynamic>{
      'name': {'stringValue': name},
      'tutorId': {'stringValue': user.uid},
      'members': {'arrayValue': {}},
      'createdAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
    };
    if (course != null && course.isNotEmpty)
      fields['course'] = {'stringValue': course};

    final body = jsonEncode({'fields': fields});
    debugPrint('[Auth] Request body: $body');

    final resp = await http
        .post(
          url,
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 15)); // Increased timeout

    debugPrint('[Auth] Create class response status: ${resp.statusCode}');
    debugPrint('[Auth] Create class response body: ${resp.body}');

    if (resp.statusCode != 200) {
      throw 'Failed to create class (status ${resp.statusCode}): ${resp.body}';
    }

    final respBody = jsonDecode(resp.body) as Map<String, dynamic>;
    final nameField = respBody['name'] as String?;
    final docId = nameField != null ? nameField.split('/').last : '';

    if (docId.isEmpty) {
      throw 'Failed to get document ID from response: $respBody';
    }

    debugPrint('[Auth] Successfully created class with ID: $docId');
    return docId;
  }

  // Helper: find users by email and return mapping email->uid for found users
  Future<Map<String, String>> lookupUsersByEmails({
    required String projectId,
    required List<String> emails,
  }) async {
    debugPrint(
      '[Auth] lookupUsersByEmails: Looking up ${emails.length} emails: $emails',
    );

    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('[Auth] lookupUsersByEmails: No current user');
      return {};
    }
    final idToken = await user.getIdToken();
    if (idToken == null) {
      debugPrint('[Auth] lookupUsersByEmails: No ID token');
      return {};
    }

    final found = <String, String>{};

    for (final email in emails) {
      debugPrint('[Auth] lookupUsersByEmails: Looking up email: $email');

      final url = Uri.https(
        'firestore.googleapis.com',
        '/v1/projects/$projectId/databases/(default)/documents:runQuery',
      );

      final q = {
        'structuredQuery': {
          'from': [
            {'collectionId': 'users'},
          ],
          'where': {
            'fieldFilter': {
              'field': {'fieldPath': 'email'},
              'op': 'EQUAL',
              'value': {'stringValue': email},
            },
          },
        },
      };

      try {
        final resp = await http
            .post(
              url,
              headers: {
                'Authorization': 'Bearer $idToken',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(q),
            )
            .timeout(const Duration(seconds: 10));

        debugPrint(
          '[Auth] lookupUsersByEmails: Response status for $email: ${resp.statusCode}',
        );

        if (resp.statusCode != 200) {
          debugPrint(
            '[Auth] lookupUsersByEmails: Failed response body: ${resp.body}',
          );
          continue;
        }

        final body = jsonDecode(resp.body) as List<dynamic>;
        debugPrint(
          '[Auth] lookupUsersByEmails: Response body for $email: $body',
        );

        for (final item in body) {
          final doc = item['document'] as Map<String, dynamic>?;
          if (doc == null) {
            debugPrint(
              '[Auth] lookupUsersByEmails: No document found for $email',
            );
            continue;
          }
          final fullName = doc['name'] as String?;
          if (fullName == null) continue;
          final uid = fullName.split('/').last;
          debugPrint(
            '[Auth] lookupUsersByEmails: Found UID $uid for email $email',
          );
          found[email] = uid;
          break;
        }
      } catch (e) {
        debugPrint('[Auth] lookupUsersByEmails: Error for $email: $e');
        continue;
      }
    }

    debugPrint('[Auth] lookupUsersByEmails: Final result: $found');
    return found;
  }

  // Add members to a class document (classId = document id)
  Future<void> addMembersToClass({
    required String projectId,
    required String classId,
    required List<String> memberUids,
  }) async {
    debugPrint(
      '[Auth] addMembersToClass: Adding members $memberUids to class $classId',
    );

    final user = _auth.currentUser;
    if (user == null) throw 'Not authenticated';
    final idToken = await user.getIdToken();
    if (idToken == null) throw 'Not authenticated';

    final docUrl = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$projectId/databases/(default)/documents/classes/$classId',
    );

    debugPrint(
      '[Auth] addMembersToClass: Fetching current class document from $docUrl',
    );

    // Fetch current members if any
    final getResp = await http
        .get(
          docUrl,
          headers: {
            'Authorization': 'Bearer $idToken',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 10));

    debugPrint(
      '[Auth] addMembersToClass: GET response status: ${getResp.statusCode}',
    );

    List<String> existing = [];
    if (getResp.statusCode == 200) {
      final body = jsonDecode(getResp.body) as Map<String, dynamic>;
      debugPrint('[Auth] addMembersToClass: Current document: $body');

      final fields = body['fields'] as Map<String, dynamic>?;
      final membersVal =
          fields?['members']?['arrayValue']?['values'] as List<dynamic>?;
      if (membersVal != null) {
        for (final v in membersVal) {
          final s = v['stringValue'] as String?;
          if (s != null) existing.add(s);
        }
      }
      debugPrint('[Auth] addMembersToClass: Existing members: $existing');
    } else {
      debugPrint(
        '[Auth] addMembersToClass: Failed to fetch class: ${getResp.body}',
      );
    }

    final finalSet = {...existing, ...memberUids};
    debugPrint('[Auth] addMembersToClass: Final members set: $finalSet');

    final fields = {
      'members': {
        'arrayValue': {
          'values': finalSet.map((s) => {'stringValue': s}).toList(),
        },
      },
    };

    final patchUrl = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$projectId/databases/(default)/documents/classes/$classId',
      {'updateMask.fieldPaths': 'members'},
    );

    debugPrint('[Auth] addMembersToClass: Patching to $patchUrl');
    debugPrint(
      '[Auth] addMembersToClass: Patch body: ${jsonEncode({'fields': fields})}',
    );

    final resp = await http
        .patch(
          patchUrl,
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'fields': fields}),
        )
        .timeout(const Duration(seconds: 10));

    debugPrint(
      '[Auth] addMembersToClass: PATCH response status: ${resp.statusCode}',
    );
    debugPrint('[Auth] addMembersToClass: PATCH response body: ${resp.body}');

    if (resp.statusCode != 200) {
      throw 'Failed to update class members (status ${resp.statusCode}): ${resp.body}';
    }

    debugPrint('[Auth] addMembersToClass: Successfully added members!');
  }

  // Create a pending invite for users
  Future<void> createInvite({
    required String projectId,
    required String classId,
    required String invitedUserEmail,
    required String invitedByUserId,
    required String invitedByUserName,
    required String className,
    required String role, // 'student' or 'tutor'
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'Not authenticated';
    final idToken = await user.getIdToken();
    if (idToken == null) throw 'Not authenticated';

    final url = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$projectId/databases/(default)/documents/invites',
    );

    final fields = {
      'classId': {'stringValue': classId},
      'invitedUserEmail': {'stringValue': invitedUserEmail},
      'invitedByUserId': {'stringValue': invitedByUserId},
      'invitedByUserName': {'stringValue': invitedByUserName},
      'className': {'stringValue': className},
      'role': {'stringValue': role},
      'status': {'stringValue': 'pending'},
      'createdAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
    };

    final resp = await http
        .post(
          url,
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'fields': fields}),
        )
        .timeout(const Duration(seconds: 10));

    if (resp.statusCode != 200) {
      throw 'Failed to create invite (status ${resp.statusCode}): ${resp.body}';
    }

    debugPrint('[Auth] Successfully created invite for $invitedUserEmail');
  }

  // Get pending invites for a user
  Future<List<InviteInfo>> getPendingInvites({
    required String projectId,
    required String userEmail,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return [];
    final idToken = await user.getIdToken();
    if (idToken == null) return [];

    final url = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$projectId/databases/(default)/documents:runQuery',
    );

    final q = {
      'structuredQuery': {
        'from': [
          {'collectionId': 'invites'},
        ],
        'where': {
          'compositeFilter': {
            'op': 'AND',
            'filters': [
              {
                'fieldFilter': {
                  'field': {'fieldPath': 'invitedUserEmail'},
                  'op': 'EQUAL',
                  'value': {'stringValue': userEmail},
                },
              },
              {
                'fieldFilter': {
                  'field': {'fieldPath': 'status'},
                  'op': 'EQUAL',
                  'value': {'stringValue': 'pending'},
                },
              },
            ],
          },
        },
        // Remove orderBy to avoid composite index requirement
      },
    };

    final resp = await http
        .post(
          url,
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(q),
        )
        .timeout(const Duration(seconds: 10));

    if (resp.statusCode != 200) {
      throw 'Failed to fetch invites (status ${resp.statusCode})';
    }

    final body = jsonDecode(resp.body) as List<dynamic>;
    final parsed = _parseInvitesFromRunQuery(body);

    // Sort by createdAt in descending order (newest first) on the client side
    parsed.sort((a, b) {
      if (a.createdAt == null && b.createdAt == null) return 0;
      if (a.createdAt == null) return 1;
      if (b.createdAt == null) return -1;
      return b.createdAt!.compareTo(a.createdAt!);
    });

    return parsed;
  }

  // Accept an invite
  Future<void> acceptInvite({
    required String projectId,
    required String inviteId,
    required String classId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'Not authenticated';
    final idToken = await user.getIdToken();
    if (idToken == null) throw 'Not authenticated';

    // Update invite status to accepted
    final inviteUrl = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$projectId/databases/(default)/documents/invites/$inviteId',
    );

    final updateFields = {
      'status': {'stringValue': 'accepted'},
      'acceptedAt': {
        'timestampValue': DateTime.now().toUtc().toIso8601String(),
      },
    };

    final updateResp = await http
        .patch(
          inviteUrl,
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'fields': updateFields}),
        )
        .timeout(const Duration(seconds: 10));

    if (updateResp.statusCode != 200) {
      throw 'Failed to update invite status (status ${updateResp.statusCode})';
    }

    // Add user to class
    await addMembersToClass(
      projectId: projectId,
      classId: classId,
      memberUids: [user.uid],
    );

    debugPrint('[Auth] Successfully accepted invite and joined class');
  }

  // Decline an invite
  Future<void> declineInvite({
    required String projectId,
    required String inviteId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'Not authenticated';
    final idToken = await user.getIdToken();
    if (idToken == null) throw 'Not authenticated';

    final url = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$projectId/databases/(default)/documents/invites/$inviteId',
    );

    final updateFields = {
      'status': {'stringValue': 'declined'},
      'declinedAt': {
        'timestampValue': DateTime.now().toUtc().toIso8601String(),
      },
    };

    final resp = await http
        .patch(
          url,
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'fields': updateFields}),
        )
        .timeout(const Duration(seconds: 10));

    if (resp.statusCode != 200) {
      throw 'Failed to decline invite (status ${resp.statusCode})';
    }

    debugPrint('[Auth] Successfully declined invite');
  }

  // Helper method to parse invites from Firestore query response
  List<InviteInfo> _parseInvitesFromRunQuery(List<dynamic> docs) {
    final out = <InviteInfo>[];
    for (final doc in docs) {
      final document = doc['document'];
      if (document == null) continue;

      final name = document['name'] as String?;
      final fields = document['fields'] as Map<String, dynamic>?;
      if (fields == null) continue;

      final id = name?.split('/').last ?? '';
      final classId = fields['classId']?['stringValue'] as String? ?? '';
      final invitedUserEmail =
          fields['invitedUserEmail']?['stringValue'] as String? ?? '';
      final invitedByUserName =
          fields['invitedByUserName']?['stringValue'] as String? ?? '';
      final className = fields['className']?['stringValue'] as String? ?? '';
      final role = fields['role']?['stringValue'] as String? ?? '';
      final status = fields['status']?['stringValue'] as String? ?? '';
      final createdAt = fields['createdAt']?['timestampValue'] as String?;

      out.add(
        InviteInfo(
          id: id,
          classId: classId,
          invitedUserEmail: invitedUserEmail,
          invitedByUserName: invitedByUserName,
          className: className,
          role: role,
          status: status,
          createdAt: createdAt != null ? DateTime.tryParse(createdAt) : null,
        ),
      );
    }
    return out;
  }

  // Delete a class document
  Future<void> deleteClass({
    required String projectId,
    required String classId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'Not authenticated';

    // Get fresh token for delete operation
    final idToken = await user.getIdToken(true);
    if (idToken == null) throw 'Not authenticated';

    // Extract simple ID if full path provided
    final simpleId = classId.contains('/') ? classId.split('/').last : classId;

    debugPrint('[Auth] Deleting class with ID: $simpleId (original: $classId)');

    final url = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$projectId/databases/(default)/documents/classes/$simpleId',
    );

    debugPrint('[Auth] Delete URL: $url');

    final resp = await http
        .delete(
          url,
          headers: {
            'Authorization': 'Bearer $idToken',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 15));

    debugPrint('[Auth] Delete response status: ${resp.statusCode}');
    debugPrint('[Auth] Delete response body: ${resp.body}');

    // Both 200 (OK) and 404 (already deleted) are acceptable
    if (resp.statusCode != 200 && resp.statusCode != 404) {
      // Check for permission/precondition errors
      if (resp.body.contains('FAILED_PRECONDITION') ||
          resp.body.contains('PERMISSION_DENIED') ||
          resp.statusCode == 403) {
        throw 'Permission denied. Please update Firestore security rules to allow tutors to delete their own classes.';
      }
      throw 'Failed to delete class (status ${resp.statusCode})';
    }

    debugPrint('[Auth] Class deleted successfully from database');

    // Update cached classes (if present)
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'cached_tutor_classes_${user.uid}';
      final s = prefs.getString(key);
      if (s != null) {
        final arr = jsonDecode(s) as List<dynamic>;
        // Match both simple ID and full path ID
        final preserved =
            arr.where((e) {
              final storedId = e['id'] as String? ?? '';
              final storedSimpleId =
                  storedId.contains('/') ? storedId.split('/').last : storedId;
              return storedSimpleId != simpleId && storedId != classId;
            }).toList();
        await prefs.setString(key, jsonEncode(preserved));
        debugPrint(
          '[Auth] Updated cache after delete: ${preserved.length} classes remaining',
        );
      }
    } catch (e) {
      debugPrint('[Auth] Could not update cache after delete: $e');
    }
  }

  // Return cached classes for the currently signed-in user
  Future<List<ClassInfo>> getCachedClassesForCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'cached_tutor_classes_${user.uid}';
      final s = prefs.getString(key);
      if (s == null) return [];
      final arr = jsonDecode(s) as List<dynamic>;
      return arr
          .map((e) => ClassInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[Auth] Could not read cached classes: $e');
      return [];
    }
  }

  // Save classes to cache for the current user
  Future<void> saveClassesToCacheForCurrentUser(List<ClassInfo> classes) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'cached_tutor_classes_${user.uid}';
      await prefs.setString(
        key,
        jsonEncode(classes.map((c) => c.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('[Auth] Could not save cached classes: $e');
    }
  }
}

class UserProfile {
  final String? name;
  final String? email;
  final String? role;

  UserProfile({this.name, this.email, this.role});
}

class AssignmentInfo {
  final String id;
  final String title;
  final String course;
  final String description;
  final String points;
  final String classId;
  final DateTime? dueDate;
  final DateTime? createdAt;

  AssignmentInfo({
    required this.id,
    required this.title,
    required this.course,
    required this.description,
    required this.points,
    required this.classId,
    this.dueDate,
    this.createdAt,
  });
}

class ClassInfo {
  final String id;
  final String name;
  final String course;
  final String tutorId;
  final List<String> members;
  final DateTime? createdAt;

  ClassInfo({
    required this.id,
    required this.name,
    required this.course,
    required this.tutorId,
    required this.members,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'course': course,
    'tutorId': tutorId,
    'members': members,
    'createdAt': createdAt?.toIso8601String(),
  };

  static ClassInfo fromJson(Map<String, dynamic> j) => ClassInfo(
    id: j['id'] as String? ?? '',
    name: j['name'] as String? ?? '',
    course: j['course'] as String? ?? '',
    tutorId: j['tutorId'] as String? ?? '',
    members: (j['members'] as List<dynamic>?)?.cast<String>() ?? [],
    createdAt:
        j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'] as String)
            : null,
  );
}

class InviteInfo {
  final String id;
  final String classId;
  final String invitedUserEmail;
  final String invitedByUserName;
  final String className;
  final String role;
  final String status;
  final DateTime? createdAt;

  InviteInfo({
    required this.id,
    required this.classId,
    required this.invitedUserEmail,
    required this.invitedByUserName,
    required this.className,
    required this.role,
    required this.status,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'classId': classId,
    'invitedUserEmail': invitedUserEmail,
    'invitedByUserName': invitedByUserName,
    'className': className,
    'role': role,
    'status': status,
    'createdAt': createdAt?.toIso8601String(),
  };

  static InviteInfo fromJson(Map<String, dynamic> j) => InviteInfo(
    id: j['id'] as String? ?? '',
    classId: j['classId'] as String? ?? '',
    invitedUserEmail: j['invitedUserEmail'] as String? ?? '',
    invitedByUserName: j['invitedByUserName'] as String? ?? '',
    className: j['className'] as String? ?? '',
    role: j['role'] as String? ?? '',
    status: j['status'] as String? ?? '',
    createdAt:
        j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'] as String)
            : null,
  );
}
