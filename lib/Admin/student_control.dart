import 'package:flutter/material.dart';
import '../widgets/admin_bottom_nav.dart';
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
      // Start with empty list - students will be added via popup
      setState(() {
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

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      bottomNavigationBar: const AdminBottomNav(currentIndex: 2),

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
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search for anything',
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey.shade600,
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
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
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
                      color: Colors.black87,
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
                      color: Colors.black87,
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
                      color: Colors.black87,
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
                    ? const Center(
                      child: Text(
                        'No students found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                    : Container(
                      margin: EdgeInsets.symmetric(horizontal: w * 0.06),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: _filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = _filteredStudents[index];
                          return _studentRow(w, h, student, index);
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
  ) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: h * 0.015, horizontal: w * 0.04),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              student['id']!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              student['name']!,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
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
        return AlertDialog(
          title: const Text(
            'Add New Student',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Color(0xFF4B3FA3),
            ),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: studentIdController,
                  decoration: const InputDecoration(
                    labelText: 'Student ID',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
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
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
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
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
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
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
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
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  // Add new student to the list
                  final newStudent = {
                    'id': studentIdController.text,
                    'name': emailController.text.split('@')[0].toUpperCase(),
                    'email': emailController.text,
                    'password': passwordController.text,
                    'dateAdded': DateTime.now().toString().split(' ')[0],
                  };

                  setState(() {
                    _students.add(newStudent);
                    _filteredStudents = List.from(_students);
                  });

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Student ${studentIdController.text} (${emailController.text}) added successfully!',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
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
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Student Details',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4B3FA3),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _deleteStudent(context, student),
                    child: Icon(Icons.delete, color: Colors.red, size: 24),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Student ID:', student['id'] ?? 'N/A'),
                  SizedBox(height: 12),
                  _buildDetailRow('Name:', student['name'] ?? 'N/A'),
                  SizedBox(height: 12),
                  _buildDetailRow('Email:', student['email'] ?? 'N/A'),
                  SizedBox(height: 12),
                  _buildPasswordRow(
                    'Password:',
                    student['password'] ?? 'N/A',
                    isPasswordVisible,
                    () =>
                        setState(() => isPasswordVisible = !isPasswordVisible),
                  ),
                  SizedBox(height: 12),
                  _buildDetailRow('Date Added:', student['dateAdded'] ?? 'N/A'),
                  SizedBox(height: 12),
                  _buildDetailRow('Status:', 'Active'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Close'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Edit functionality coming soon'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4B3FA3),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Edit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(child: Text(value, style: TextStyle(color: Colors.black87))),
      ],
    );
  }

  Widget _buildPasswordRow(
    String label,
    String password,
    bool isVisible,
    VoidCallback onToggle,
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
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  isVisible ? password : '••••••••',
                  style: TextStyle(color: Colors.black87),
                ),
              ),
              GestureDetector(
                onTap: onToggle,
                child: Icon(
                  isVisible ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                  color: Colors.grey[600],
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
        return AlertDialog(
          title: Text(
            'Delete Student',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          content: Text(
            'Are you sure you want to delete student ${student['name']} (${student['id']})?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _students.removeWhere((s) => s['id'] == student['id']);
                  _filteredStudents = List.from(_students);
                });

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Student ${student['name']} deleted successfully',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
