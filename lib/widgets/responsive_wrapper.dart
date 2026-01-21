import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A wrapper widget that ensures the application content remains within
/// mobile-like dimensions on larger screens (Web, Desktop), centering the UI.
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.maxWidth = 500, // Standard responsive mobile width
  });

  @override
  Widget build(BuildContext context) {
    // Apply only on Web or Desktop platforms
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return LayoutBuilder(
        builder: (context, constraints) {
          // If the available width is greater than our max mobile width target
          if (constraints.maxWidth > maxWidth) {
            return Stack(
              children: [
                // Background for the unused space (optional, keeps it neutral)
                Container(color: const Color(0xFFF0F2F5)),
                Center(
                  child: Container(
                    width: maxWidth,
                    height: constraints.maxHeight,
                    decoration: BoxDecoration(
                      color: Colors.white, // Default canvas color
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRect(
                      child: MediaQuery(
                        data: MediaQuery.of(
                          context,
                        ).copyWith(size: Size(maxWidth, constraints.maxHeight)),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          // If it's already narrow (e.g. mobile browser window), just show as is
          return child;
        },
      );
    }
    // On native mobile devices, do nothing
    return child;
  }
}
