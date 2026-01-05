import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentUnitDetailsPage extends StatefulWidget {
  final UnitInfo unit;
  const StudentUnitDetailsPage({super.key, required this.unit});

  @override
  State<StudentUnitDetailsPage> createState() => _StudentUnitDetailsPageState();
}

class _StudentUnitDetailsPageState extends State<StudentUnitDetailsPage> {
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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch attachment')),
        );
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
      appBar: AppBar(
        title: Text(
          widget.unit.title,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        backgroundColor: bgColor,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        elevation: 0,
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _materials.isEmpty
              ? _buildEmptyState(h, w, isDark)
              : RefreshIndicator(
                onRefresh: _loadMaterials,
                child: ListView.builder(
                  padding: EdgeInsets.all(w * 0.04),
                  itemCount: _materials.length + 1,
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
                                      isDark ? Colors.white70 : Colors.black87,
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
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    final material = _materials[index - 1];
                    return _buildMaterialCard(material, h, w, isDark);
                  },
                ),
              ),
    );
  }

  Widget _buildMaterialCard(
    MaterialInfo material,
    double h,
    double w,
    bool isDark,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: h * 0.02),
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 5,
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
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4B3FA3).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.insert_drive_file,
                  color: Color(0xFF4B3FA3),
                  size: 24,
                ),
              ),
              SizedBox(width: w * 0.04),
              Expanded(
                child: Text(
                  material.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),
          if (material.description.isNotEmpty) ...[
            SizedBox(height: h * 0.015),
            Text(
              material.description,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
          if (material.attachmentUrl != null &&
              material.attachmentUrl!.isNotEmpty) ...[
            SizedBox(height: h * 0.02),
            GestureDetector(
              onTap: () => _launchUrl(material.attachmentUrl!),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? Colors.blue.withOpacity(0.2)
                          : Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        isDark
                            ? Colors.blue.withOpacity(0.4)
                            : Colors.blueAccent.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.attachment,
                      size: 16,
                      color: isDark ? Colors.blueAccent : Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "Open Attachment",
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.blueAccent : Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
