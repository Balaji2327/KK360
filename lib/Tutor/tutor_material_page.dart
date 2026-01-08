import 'package:flutter/material.dart';

import '../widgets/nav_helper.dart';
import '../services/firebase_auth_service.dart';
import 'unit_details_page.dart';
import 'create_unit.dart';

class TutorMaterialPage extends StatefulWidget {
  final String? classId;
  final String? className;

  const TutorMaterialPage({super.key, this.classId, this.className});

  @override
  State<TutorMaterialPage> createState() => _TutorMaterialPageState();
}

class _TutorMaterialPageState extends State<TutorMaterialPage> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  String userName = FirebaseAuthService.cachedProfile?.name ?? 'User';
  String userEmail = FirebaseAuthService.cachedProfile?.email ?? '';
  bool profileLoading = FirebaseAuthService.cachedProfile == null;
  List<UnitInfo> _units = [];
  bool _unitsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadUnits();
  }

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
      final units =
          widget.classId != null
              ? await _authService.getUnitsForClass(
                projectId: 'kk360-69504',
                classId: widget.classId!,
              )
              : await _authService.getUnitsForTutor(projectId: 'kk360-69504');
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

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,

      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: h * 0.02, right: w * 0.04),
        child: GestureDetector(
          onTap: () async {
            // Navigate to Create Unit Screen and reload on return
            await goPush(context, const CreateUnitScreen());
            _loadUnits();
          },
          child: Container(
            height: h * 0.065,
            width: h * 0.065,
            decoration: BoxDecoration(
              color: const Color(0xFFDFF7E8),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add, size: 30, color: Colors.black),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
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
                  Flexible(
                    child: Text(
                      widget.className != null
                          ? "${widget.className} - Materials"
                          : "Materials",
                      style: TextStyle(
                        fontSize: w * 0.045, // Made responsive
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: h * 0.006),
                  Flexible(
                    child: Text(
                      profileLoading ? 'Loading...' : '$userName | $userEmail',
                      style: TextStyle(
                        fontSize: w * 0.035, // Made responsive
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: h * 0.01),

          // Content
          Expanded(
            child:
                _unitsLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _units.isEmpty
                    ? _buildEmptyState(h, w, isDark)
                    : RefreshIndicator(
                      onRefresh: _loadUnits,
                      child: ListView.builder(
                        padding: EdgeInsets.fromLTRB(
                          w * 0.04,
                          h * 0.02,
                          w * 0.04,
                          h * 0.12,
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
      onTap: () async {
        await goPush(context, UnitDetailsPage(unit: unit));
        // Reload in case something changed (e.g. unit deleted?)
        _loadUnits();
      },
      child: Container(
        margin: EdgeInsets.only(bottom: h * 0.02),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    unit.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? Colors.purple.withOpacity(0.2)
                            : Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    unit.className.isNotEmpty ? unit.className : 'Class',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.purpleAccent : Colors.purple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
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
                SizedBox(width: 4),
                Text(
                  "${unit.createdAt.day}/${unit.createdAt.month}/${unit.createdAt.year}",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.grey,
                  ),
                ),
                const Spacer(),
                Text(
                  "View Materials",
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF4B3FA3),
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
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          SizedBox(height: h * 0.08),
          SizedBox(
            height: h * 0.28,
            child: Center(
              child: Image.asset("assets/images/work.png", fit: BoxFit.contain),
            ),
          ),
          SizedBox(height: h * 0.02),
          Text(
            "No units yet",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: h * 0.0185,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: h * 0.015),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.12),
            child: Text(
              "Create your first unit to organize materials",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: h * 0.0145,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.5,
              ),
            ),
          ),
          SizedBox(height: h * 0.18),
        ],
      ),
    );
  }
}
