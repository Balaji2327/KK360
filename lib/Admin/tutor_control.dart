import 'package:flutter/material.dart';
import '../widgets/admin_bottom_nav.dart';
import '../services/firebase_auth_service.dart';

class TutorControlScreen extends StatefulWidget {
  const TutorControlScreen({super.key});

  @override
  State<TutorControlScreen> createState() => _TutorControlScreenState();
}

class _TutorControlScreenState extends State<TutorControlScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  bool profileLoading = true;
  String userName = 'User';
  String userEmail = '';
  List<UserProfile> _tutors = [];
  bool _tutorsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadTutors();
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

  Future<void> _loadTutors() async {
    setState(() => _tutorsLoading = true);
    try {
      // This is a placeholder - you'll need to implement getAllUsersByRole in your service
      // For now, we'll show a sample structure
      setState(() {
        _tutors = [
          UserProfile(
            name: 'Dr. Sarah Wilson',
            email: 'sarah@tutor.com',
            role: 'tutor',
          ),
          UserProfile(
            name: 'Prof. David Brown',
            email: 'david@tutor.com',
            role: 'tutor',
          ),
          UserProfile(
            name: 'Ms. Emily Davis',
            email: 'emily@tutor.com',
            role: 'tutor',
          ),
        ];
        _tutorsLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading tutors: $e');
      setState(() => _tutorsLoading = false);
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
                        "Tutor Control",
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
                  "Tutor Management Actions",
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
                        title: "Add Tutor",
                        color: Colors.green,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Add Tutor functionality'),
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
                        icon: Icons.verified,
                        title: "Verify Tutor",
                        color: Colors.blue,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Verify Tutor functionality'),
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
                        icon: Icons.assignment,
                        title: "View Classes",
                        color: Colors.purple,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('View Tutor Classes functionality'),
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
                        icon: Icons.block,
                        title: "Suspend Tutor",
                        color: Colors.orange,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Suspend Tutor functionality'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                SizedBox(height: h * 0.03),

                const Text(
                  "All Tutors",
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

          // Tutors List
          Expanded(
            child:
                _tutorsLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _tutors.isEmpty
                    ? const Center(
                      child: Text(
                        'No tutors found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                    : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                      itemCount: _tutors.length,
                      itemBuilder: (context, index) {
                        final tutor = _tutors[index];
                        return _tutorTile(w, h, tutor);
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

  Widget _tutorTile(double w, double h, UserProfile tutor) {
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
            backgroundColor: Colors.green,
            child: Text(
              tutor.name?.substring(0, 1).toUpperCase() ?? 'T',
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
                Row(
                  children: [
                    Text(
                      tutor.name ?? 'Unknown Tutor',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(width: w * 0.02),
                    Icon(Icons.verified, size: 16, color: Colors.blue),
                  ],
                ),
                SizedBox(height: h * 0.005),
                Text(
                  tutor.email ?? 'No email',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                SizedBox(height: h * 0.005),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'verify':
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Verify ${tutor.name}')),
                  );
                  break;
                case 'classes':
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('View ${tutor.name} classes')),
                  );
                  break;
                case 'suspend':
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Suspend ${tutor.name}')),
                  );
                  break;
                case 'remove':
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Remove ${tutor.name}')),
                  );
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'verify',
                    child: Row(
                      children: [
                        Icon(Icons.verified, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Verify'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'classes',
                    child: Row(
                      children: [
                        Icon(Icons.assignment, color: Colors.purple),
                        SizedBox(width: 8),
                        Text('View Classes'),
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
