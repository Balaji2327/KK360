import 'package:flutter/material.dart';
import '../widgets/nav_helper.dart';
import '../services/firebase_auth_service.dart';
import 'student_unit_details.dart';

class StudentMaterialPage extends StatefulWidget {
  final String classId;
  final String className;
  const StudentMaterialPage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<StudentMaterialPage> createState() => _StudentMaterialPageState();
}

class _StudentMaterialPageState extends State<StudentMaterialPage> {
  final FirebaseAuthService _authService = FirebaseAuthService();

  // -- Added for Header Data --
  String userName = 'User';
  String userEmail = '';
  bool profileLoading = true;
  // ---------------------------

  List<UnitInfo> _units = [];
  bool _unitsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile(); // Load user data for header
    _loadUnits();
  }

  // -- Copied from Assignment Page --
  Future<void> _loadUserProfile() async {
    final profile = await _authService.getUserProfile(projectId: 'kk360-69504');
    final authUser = _authService.getCurrentUser();
    final displayName = await _authService.getUserDisplayName(
      projectId: 'kk360-69504',
    );
    if (mounted) {
      setState(() {
        userName = displayName;
        userEmail = profile?.email ?? authUser?.email ?? '';
        profileLoading = false;
      });
    }
  }

  Future<void> _loadUnits() async {
    setState(() => _unitsLoading = true);
    try {
      final units = await _authService.getUnitsForClass(
        projectId: 'kk360-69504',
        classId: widget.classId,
      );
      if (mounted) {
        setState(() {
          _units = units;
          _unitsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _unitsLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to load units: $e")));
      }
    }
  }

  Future<void> _refreshUnits() async {
    await _loadUnits();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Using Scaffold background color from theme
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // Removed standard AppBar
      body: Column(
        children: [
          // --- Custom Header (Copied & Modified title) ---
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
                    "Materials - ${widget.className}", // Updated Title
                    style: TextStyle(
                      fontSize: h * 0.025,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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

          SizedBox(height: h * 0.0005),

          // --- Main Content ---
          Expanded(
            child:
                _unitsLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _units.isEmpty
                    ? _buildEmptyState(h, w, isDark)
                    : RefreshIndicator(
                      onRefresh: _refreshUnits,
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: w * 0.04,
                          vertical: h * 0.02,
                        ),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _units.length,
                        itemBuilder: (context, index) {
                          final unit = _units[index];
                          return _buildUnitCard(context, unit, h, w, isDark);
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitCard(
    BuildContext context,
    UnitInfo unit,
    double h,
    double w,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () {
        goPush(context, StudentUnitDetailsPage(unit: unit));
      },
      child: Container(
        margin: EdgeInsets.only(
          bottom: h * 0.015,
        ), // Adjusted margin slightly to match assignment look
        padding: EdgeInsets.all(w * 0.04),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.shade100,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              unit.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            if (unit.description.isNotEmpty) ...[
              SizedBox(height: h * 0.01),
              Text(
                unit.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
            SizedBox(height: h * 0.02),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: isDark ? Colors.white38 : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  "${unit.createdAt.day}/${unit.createdAt.month}/${unit.createdAt.year}",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.grey,
                  ),
                ),
                const Spacer(),
                const Text(
                  "View",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4B3FA3),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Color(0xFF4B3FA3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(double h, double w, bool isDark) {
    // Wrapped in SingleChildScrollView to allow pull-to-refresh even when empty
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: h * 0.6, // constrain height to center visually
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_off,
                size: 64,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
              SizedBox(height: h * 0.02),
              Text(
                "No materials found for this class",
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
