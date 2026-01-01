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
  List<UserProfile> _students = [];
  bool _studentsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadStudents();
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
      // This is a placeholder - you'll need to implement getAllUsersByRole in your service
      // For now, we'll show a sample structure
      setState(() {
        _students = [
          UserProfile(
            name: 'John Doe',
            email: 'john@student.com',
            role: 'student',
          ),
          UserProfile(
            name: 'Jane Smith',
            email: 'jane@student.com',
            role: 'student',
          ),
          UserProfile(
            name: 'Mike Johnson',
            email: 'mike@student.com',
            role: 'student',
          ),
        ];
        _studentsLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading students: $e');
      setState(() => _studentsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
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

                  Row(
                    children: [
                      Text(
                        "Student Control",
                        style: TextStyle(
                          fontSize: h * 0.03,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
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

          // Control Actions
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.06),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Student Management Actions",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                SizedBox(height: h * 0.02),

                Row(
                  children: [
                    Expanded(
                      child: _actionCard(
                        w: w,
                        h: h,
                        icon: Icons.person_add,
                        title: "Add Student",
                        color: Colors.green,
                        onTap: () {
                          // Navigate to add student screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Add Student functionality'),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: w * 0.04),
                    Expanded(
                      child: _actionCard(
                        w: w,
                        h: h,
                        icon: Icons.edit,
                        title: "Edit Student",
                        color: Colors.blue,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Edit Student functionality'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                SizedBox(height: h * 0.02),

                Row(
                  children: [
                    Expanded(
                      child: _actionCard(
                        w: w,
                        h: h,
                        icon: Icons.block,
                        title: "Suspend Student",
                        color: Colors.orange,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Suspend Student functionality'),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: w * 0.04),
                    Expanded(
                      child: _actionCard(
                        w: w,
                        h: h,
                        icon: Icons.delete,
                        title: "Remove Student",
                        color: Colors.red,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Remove Student functionality'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                SizedBox(height: h * 0.03),

                const Text(
                  "All Students",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                SizedBox(height: h * 0.01),
              ],
            ),
          ),

          // Students List
          Expanded(
            child:
                _studentsLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _students.isEmpty
                    ? const Center(
                      child: Text(
                        'No students found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                    : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        return _studentTile(w, h, student);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard({
    required double w,
    required double h,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: h * 0.12,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: color),
            SizedBox(height: h * 0.01),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _studentTile(double w, double h, UserProfile student) {
    return Container(
      margin: EdgeInsets.only(bottom: h * 0.015),
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: const Color(0xFF4B3FA3),
            child: Text(
              student.name?.substring(0, 1).toUpperCase() ?? 'S',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          SizedBox(width: w * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name ?? 'Unknown Student',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: h * 0.005),
                Text(
                  student.email ?? 'No email',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Edit ${student.name}')),
                  );
                  break;
                case 'suspend':
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Suspend ${student.name}')),
                  );
                  break;
                case 'remove':
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Remove ${student.name}')),
                  );
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'suspend',
                    child: Row(
                      children: [
                        Icon(Icons.block, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Suspend'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Remove'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
    );
  }
}
