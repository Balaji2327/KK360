import 'package:flutter/material.dart';

import '../services/firebase_auth_service.dart';

class UnitCard extends StatelessWidget {
  final UnitInfo unit;
  final VoidCallback? onTap;

  const UnitCard({super.key, required this.unit, this.onTap});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const appColor = Color(0xFF4B3FA3);
    final titleColor = isDark ? Colors.white : const Color(0xFF171A2C);
    final bodyColor = isDark ? Colors.white70 : const Color(0xFF5E6278);
    final borderColor =
        isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE8E6F3);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: h * 0.015),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF17181F) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.28 : 0.08),
              offset: const Offset(0, 14),
              blurRadius: 28,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: w,
              padding: EdgeInsets.fromLTRB(
                w * 0.045,
                h * 0.022,
                w * 0.045,
                h * 0.018,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? const [Color(0xFF282C43), Color(0xFF1C2030)]
                      : const [Color(0xFFF5F0FF), Color(0xFFE7F1FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
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
                        SizedBox(height: h * 0.008),
                        Text(
                          unit.className.isNotEmpty
                              ? unit.className
                              : 'Unknown Class',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: bodyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 18,
                    color: titleColor,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                w * 0.045,
                h * 0.022,
                w * 0.045,
                h * 0.022,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (unit.description.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(w * 0.035),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF20222D)
                            : const Color(0xFFF7F8FC),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        unit.description,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: bodyColor,
                          height: 1.5,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: h * 0.018),
                  ],
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildMetricTile(
                        icon: Icons.event_available_rounded,
                        label: 'Created',
                        value:
                            '${unit.createdAt.day}/${unit.createdAt.month}/${unit.createdAt.year}',
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
                        icon: Icons.menu_book_outlined,
                        label: 'Content',
                        value: 'Materials',
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
}
