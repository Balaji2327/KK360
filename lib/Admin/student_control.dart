import 'package:flutter/material.dart';

import '../services/firebase_auth_service.dart';

class StudentControlScreen extends StatefulWidget {
  const StudentControlScreen({super.key});

  @override
  State<StudentControlScreen> createState() => _StudentControlScreenState();
}

class _StudentControlScreenState extends State<StudentControlScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  bool profileLoading = true;
  String userName = 'User';
  String userEmail = '';
  List<Map<String, String>> _students = [];
  List<Map<String, String>> _filteredStudents = [];
  bool _studentsLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadStudents();
    _searchController.addListener(_filterStudents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final profile = await _authService.getUserProfile(projectId: 'kk360-69504');
    final authUser = _authService.getCurrentUser();
    final displayName = await _authService.getUserDisplayName(
      projectId: 'kk360-69504',
    );
    setState(() {
      userName = displayName;
      userEmail = profile?.email ?? authUser?.email ?? '';
      profileLoading = false;
    });
  }

  Future<void> _loadStudents() async {
    setState(() => _studentsLoading = true);
    try {
      final students = await _authService.getAllStudents(
        projectId: 'kk360-69504',
      );
      setState(() {
        _students = students;
        _filteredStudents = List.from(_students);
        _studentsLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading students: $e');
      setState(() => _studentsLoading = false);
    }
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStudents =
          _students.where((student) {
            return student['id']!.toLowerCase().contains(query) ||
                student['name']!.toLowerCase().contains(query);
          }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: Column(
        children: [
          // Header
          Container(
            width: w,
            height: h * 0.16,
            decoration: const BoxDecoration(
              color: Color(0xFF4B3FA3),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.06),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: h * 0.05),

                  Text(
                    "Student Control",
                    style: TextStyle(
                      fontSize: h * 0.03,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: h * 0.006),

                  Text(
                    profileLoading ? 'Loading...' : '$userName | $userEmail',
                    style: TextStyle(fontSize: h * 0.012, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: h * 0.02),

          // Search Bar and Add Button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.06),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: h * 0.06,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search for anything',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: w * 0.04),
                Container(
                  height: h * 0.05,
                  width: h * 0.05,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: GestureDetector(
                    onTap: () => _showAddStudentDialog(context),
                    child: const Icon(
                      Icons.person_add,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: h * 0.02),

          // Table Header
          Container(
            margin: EdgeInsets.symmetric(horizontal: w * 0.06),
            padding: EdgeInsets.symmetric(
              vertical: h * 0.015,
              horizontal: w * 0.04,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'STUDENT ID',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'NAME',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'DETAILS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Students List
          Expanded(
            child:
                _studentsLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredStudents.isEmpty
                    ? Center(
                      child: Text(
                        'No students found',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white54 : Colors.grey,
                        ),
                      ),
                    )
                    : Container(
                      margin: EdgeInsets.symmetric(horizontal: w * 0.06),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: _filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = _filteredStudents[index];
                          return _studentRow(w, h, student, index, isDark);
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _studentRow(
    double w,
    double h,
    Map<String, String> student,
    int index,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: h * 0.015, horizontal: w * 0.04),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              student['id']!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              student['name']!,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: GestureDetector(
                onTap: () => _showStudentDetails(context, student),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'View',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditStudentDialog(
    BuildContext context,
    Map<String, String> student,
  ) {
    final TextEditingController nameController = TextEditingController(
      text: student['name'],
    );
    final TextEditingController studentIdController = TextEditingController(
      text: student['id'],
    );
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          title: Text(
            'Edit Student',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : const Color(0xFF4B3FA3),
            ),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: studentIdController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Student ID',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator:
                      (value) => value!.isEmpty ? 'Enter Student ID' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? 'Enter Name' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder:
                        (ctx) =>
                            const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    await _authService.updateUserAccount(
                      uid: student['uid'] ?? student['id']!,
                      projectId: 'kk360-69504',
                      updates: {
                        'name': nameController.text.trim(),
                        'studentId': studentIdController.text.trim(),
                      },
                    );

                    navigator.pop(); // Close loading
                    navigator.pop(); // Close edit dialog
                    await _loadStudents();

                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Student updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    if (navigator.canPop()) navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4B3FA3),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showAddStudentDialog(BuildContext context) {
    final TextEditingController studentIdController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          title: Text(
            'Add New Student',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : const Color(0xFF4B3FA3),
            ),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: studentIdController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Student ID',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark ? Colors.white24 : Colors.grey,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.badge,
                      color: isDark ? Colors.white70 : Colors.grey,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter student ID';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark ? Colors.white24 : Colors.grey,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.email,
                      color: isDark ? Colors.white70 : Colors.grey,
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter email';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark ? Colors.white24 : Colors.grey,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.lock,
                      color: isDark ? Colors.white70 : Colors.grey,
                    ),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark ? Colors.white24 : Colors.grey,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: isDark ? Colors.white70 : Colors.grey,
                    ),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm password';
                    }
                    if (value != passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  // Show loading dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder:
                        (context) =>
                            const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    await _authService.createStudentAccount(
                      email: emailController.text.trim(),
                      password: passwordController.text,
                      name:
                          emailController.text
                              .split('@')[0]
                              .toUpperCase(), // Simple name derivation
                      studentId: studentIdController.text.trim(),
                      projectId: 'kk360-69504',
                    );

                    if (!context.mounted) return;
                    Navigator.of(context).pop(); // Close loading
                    Navigator.of(context).pop(); // Close add dialog

                    // Refresh list
                    await _loadStudents();

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Student ${studentIdController.text} created successfully!',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    Navigator.of(context).pop(); // Close loading

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error creating student: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4B3FA3),
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Student'),
            ),
          ],
        );
      },
    );
  }

  void _showStudentDetails(BuildContext context, Map<String, String> student) {
    bool isPasswordVisible = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Student Details',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : const Color(0xFF4B3FA3),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _deleteStudent(context, student),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.red,
                      size: 24,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    'Student ID:',
                    student['id'] ?? 'N/A',
                    isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Name:', student['name'] ?? 'N/A', isDark),
                  const SizedBox(height: 12),
                  _buildDetailRow('Email:', student['email'] ?? 'N/A', isDark),
                  const SizedBox(height: 12),
                  _buildPasswordRow(
                    'Password:',
                    student['password'] ?? 'N/A',
                    isPasswordVisible,
                    () =>
                        setState(() => isPasswordVisible = !isPasswordVisible),
                    isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Date Added:',
                    student['dateAdded'] ?? 'N/A',
                    isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Status:', 'Active', isDark),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close details
                    _showEditStudentDialog(context, student);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B3FA3),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Edit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordRow(
    String label,
    String password,
    bool isVisible,
    VoidCallback onToggle,
    bool isDark,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  isVisible ? password : '••••••••',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onToggle,
                child: Icon(
                  isVisible ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _deleteStudent(BuildContext context, Map<String, String> student) {
    Navigator.of(context).pop(); // Close details dialog first

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          title: const Text(
            'Delete Student',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          content: Text(
            'Are you sure you want to delete student ${student['name']} (${student['id']})?\n\nThis will permanently delete their account and they will not be able to login again.',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);

                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder:
                      (ctx) => const Center(child: CircularProgressIndicator()),
                );

                try {
                  await _authService.deleteStudentAccount(
                    uid:
                        student['uid'] ??
                        student['id']!, // Use UID if available, fallback to ID (though ID is likely wrong for deletion, UID should be present now)
                    email: student['email']!,
                    password: student['password'] ?? '',
                    projectId: 'kk360-69504',
                  );

                  navigator.pop(); // Close loading
                  navigator.pop(); // Close delete dialog

                  // Refresh list
                  await _loadStudents();

                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Student ${student['name']} deleted successfully',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                } catch (e) {
                  if (navigator.canPop()) navigator.pop(); // Close loading
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Error deleting student: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
