import 'package:flutter/material.dart';
import '../widgets/admin_bottom_nav.dart';
import '../services/firebase_auth_service.dart';

class AdminControlScreen extends StatefulWidget {
  const AdminControlScreen({super.key});

  @override
  State<AdminControlScreen> createState() => _AdminControlScreenState();
}

class _AdminControlScreenState extends State<AdminControlScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  bool profileLoading = true;
  String userName = 'User';
  String userEmail = '';
  List<UserProfile> _admins = [];
  bool _adminsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadAdmins();
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

  Future<void> _loadAdmins() async {
    setState(() => _adminsLoading = true);
    try {
      // This is a placeholder - you'll need to implement getAllUsersByRole in your service
      // For now, we'll show a sample structure
      setState(() {
        _admins = [
          UserProfile(
            name: 'Super Admin',
            email: 'admin@kk360.com',
            role: 'admin',
          ),
          UserProfile(
            name: 'System Admin',
            email: 'system@kk360.com',
            role: 'admin',
          ),
          UserProfile(
            name: 'Content Admin',
            email: 'content@kk360.com',
            role: 'admin',
          ),
        ];
        _adminsLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading admins: $e');
      setState(() => _adminsLoading = false);
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
                        "Admin Control",
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
                    style: TextStyle(fontSize: h * 0.014, color: Colors.white),
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
                  "Admin Management Actions",
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
                        icon: Icons.admin_panel_settings,
                        title: "Add Admin",
                        color: Colors.red,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Add Admin functionality'),
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
                        icon: Icons.security,
                        title: "Permissions",
                        color: Colors.indigo,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Manage Permissions functionality'),
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
                        icon: Icons.analytics,
                        title: "System Stats",
                        color: Colors.teal,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('System Statistics functionality'),
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
                        icon: Icons.settings,
                        title: "System Config",
                        color: Colors.grey,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'System Configuration functionality',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                SizedBox(height: h * 0.03),

                const Text(
                  "All Administrators",
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

          // Admins List
          Expanded(
            child:
                _adminsLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _admins.isEmpty
                    ? const Center(
                      child: Text(
                        'No administrators found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                    : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                      itemCount: _admins.length,
                      itemBuilder: (context, index) {
                        final admin = _admins[index];
                        return _adminTile(w, h, admin);
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

  Widget _adminTile(double w, double h, UserProfile admin) {
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
            backgroundColor: Colors.red,
            child: Text(
              admin.name?.substring(0, 1).toUpperCase() ?? 'A',
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
                      admin.name ?? 'Unknown Admin',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(width: w * 0.02),
                    Icon(
                      Icons.admin_panel_settings,
                      size: 16,
                      color: Colors.red,
                    ),
                  ],
                ),
                SizedBox(height: h * 0.005),
                Text(
                  admin.email ?? 'No email',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                SizedBox(height: h * 0.005),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Super User',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
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
                case 'permissions':
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Manage ${admin.name} permissions')),
                  );
                  break;
                case 'activity':
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('View ${admin.name} activity')),
                  );
                  break;
                case 'suspend':
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Suspend ${admin.name}')),
                  );
                  break;
                case 'remove':
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Remove ${admin.name}')),
                  );
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'permissions',
                    child: Row(
                      children: [
                        Icon(Icons.security, color: Colors.indigo),
                        SizedBox(width: 8),
                        Text('Permissions'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'activity',
                    child: Row(
                      children: [
                        Icon(Icons.analytics, color: Colors.teal),
                        SizedBox(width: 8),
                        Text('Activity Log'),
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
