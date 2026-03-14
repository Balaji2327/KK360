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
  String userName = FirebaseAuthService.cachedProfile?.name ?? 'User';
  String userEmail = FirebaseAuthService.cachedProfile?.email ?? '';
  bool profileLoading = FirebaseAuthService.cachedProfile == null;
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
                    style: TextStyle(
                      fontSize: h * 0.014,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: h * 0.0005),

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
    const appColor = Color(0xFF4B3FA3);
    final titleColor = isDark ? Colors.white : const Color(0xFF171A2C);
    final bodyColor = isDark ? Colors.white70 : const Color(0xFF5E6278);
    return GestureDetector(
      onTap: () {
        goPush(context, StudentUnitDetailsPage(unit: unit));
      },
      child: Container(
        margin: EdgeInsets.only(bottom: h * 0.015),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF17181F) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.28 : 0.07),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8E6F3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: w,
              padding: EdgeInsets.fromLTRB(w * 0.04, h * 0.02, w * 0.04, h * 0.018),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? const [Color(0xFF262A40), Color(0xFF1A1E2E)]
                      : const [Color(0xFFF5F0FF), Color(0xFFE9F2FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4B3FA3), Color(0xFF6C7EF8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: w * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderPill(
                          label: 'Unit',
                          icon: Icons.folder_open_rounded,
                          color: appColor,
                          isDark: isDark,
                        ),
                        SizedBox(height: h * 0.012),
                        Text(
                          unit.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                            height: 1.15,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_outward_rounded,
                    size: 18,
                    color: Color(0xFF4B3FA3),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(w * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (unit.description.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(w * 0.034),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF20222D)
                            : const Color(0xFFF7F8FC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        unit.description,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: bodyColor,
                          height: 1.5,
                        ),
                      ),
                    ),
                    SizedBox(height: h * 0.016),
                  ],
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildMetricTile(
                        icon: Icons.event_available_rounded,
                        label: 'Created',
                        value:
                            "${unit.createdAt.day}/${unit.createdAt.month}/${unit.createdAt.year}",
                        color: appColor,
                        isDark: isDark,
                      ),
                      _buildMetricTile(
                        icon: Icons.layers_outlined,
                        label: 'Class',
                        value: unit.className.isNotEmpty
                            ? unit.className
                            : 'Unknown Class',
                        color: Colors.teal.shade600,
                        isDark: isDark,
                      ),
                      _buildMetricTile(
                        icon: Icons.visibility_outlined,
                        label: 'Action',
                        value: 'Open unit',
                        color: Colors.amber.shade700,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderPill({
    required String label,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.18) : Colors.white.withOpacity(0.84),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.8,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 118, maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF20222D) : const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8E6F3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : const Color(0xFF70758A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.2,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF171A2C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(double h, double w, bool isDark) {
    // Wrapped in SingleChildScrollView to allow pull-to-refresh even when empty
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(h * 0.03),
              decoration: BoxDecoration(
                color: const Color(0xFF4B3FA3).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_off_outlined,
                size: h * 0.08,
                color: const Color(0xFF4B3FA3),
              ),
            ),
            SizedBox(height: h * 0.03),
            Text(
              "No materials found",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: h * 0.022,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF2D3142),
              ),
            ),
            SizedBox(height: h * 0.015),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.15),
              child: Text(
                "Course materials uploaded by your tutor will appear here.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: h * 0.016,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: h * 0.1),
          ],
        ),
      ),
    );
  }
}
