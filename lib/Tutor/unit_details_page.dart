import 'package:flutter/material.dart';
import '../widgets/nav_helper.dart';
import '../services/firebase_auth_service.dart';
import 'create_material.dart';
import '../widgets/material_card.dart';

class UnitDetailsPage extends StatefulWidget {
  final UnitInfo unit;
  const UnitDetailsPage({super.key, required this.unit});

  @override
  State<UnitDetailsPage> createState() => _UnitDetailsPageState();
}

class _UnitDetailsPageState extends State<UnitDetailsPage> {
  final FirebaseAuthService _auth = FirebaseAuthService();
  List<MaterialInfo> _materials = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    setState(() => _loading = true);
    try {
      final items = await _auth.getMaterialsForUnit(
        projectId: 'kk360-69504',
        unitId: widget.unit.id,
      );
      if (mounted) {
        setState(() {
          _materials = items;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load materials: $e')));
      }
    }
  }

  // Helper to capitalize the first letter (matches Student design)
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      // Removed standard AppBar

      // Kept Floating Action Button for Tutors
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: h * 0.02,
          right: w * 0.04,
        ), // Fixed padding
        child: GestureDetector(
          onTap: () async {
            await goPush(context, CreateMaterialScreen(unit: widget.unit));
            _loadMaterials();
          },
          child: Container(
            height: h * 0.065,
            width: h * 0.065,
            decoration: BoxDecoration(
              color: const Color(0xFFDFF7E8), // Always light green
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.add,
              size: 30,
              color: Colors.black, // Always black
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,

      body: Column(
        children: [
          // --- Custom Header (From Student Design) ---
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
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: w * 0.04),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Back Button
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    SizedBox(width: w * 0.02),

                    // Title Only
                    Expanded(
                      child: Text(
                        _capitalize(widget.unit.title),
                        style: TextStyle(
                          fontSize: h * 0.024,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- Body Content ---
          Expanded(
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _materials.isEmpty
                    ? _buildEmptyState(h, w, isDark)
                    : RefreshIndicator(
                      onRefresh: _loadMaterials,
                      child: ListView.builder(
                        padding: EdgeInsets.all(w * 0.04),
                        itemCount: _materials.length + 1, // +1 for header info
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: h * 0.03),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (widget.unit.description.isNotEmpty)
                                    Text(
                                      widget.unit.description,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color:
                                            isDark
                                                ? Colors.white70
                                                : Colors.black87,
                                        height: 1.5,
                                      ),
                                    ),
                                  SizedBox(height: h * 0.02),
                                  Divider(
                                    color:
                                        isDark
                                            ? Colors.white24
                                            : Colors.grey.shade300,
                                  ),
                                  SizedBox(height: h * 0.01),
                                  Text(
                                    "${_materials.length} Materials",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isDark
                                              ? Colors.white54
                                              : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          final material = _materials[index - 1];
                          return MaterialCard(
                            material: material,
                            width: w,
                            height: h,
                            isDark: isDark,
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(double h, double w, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
          SizedBox(height: h * 0.02),
          Text(
            "No materials yet",
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white54 : Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
