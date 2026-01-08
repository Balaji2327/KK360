import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firebase_auth_service.dart';

class MaterialCard extends StatelessWidget {
  final MaterialInfo material;
  final bool isDark;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const MaterialCard({
    Key? key,
    required this.material,
    required this.width,
    required this.height,
    required this.isDark,
    this.onTap,
  }) : super(key: key);

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch attachment')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: height * 0.02),
      padding: EdgeInsets.all(width * 0.04),
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
              SizedBox(width: width * 0.04),
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
            SizedBox(height: height * 0.015),
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
            SizedBox(height: height * 0.02),
            GestureDetector(
              onTap: () => _launchUrl(context, material.attachmentUrl!),
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
}
