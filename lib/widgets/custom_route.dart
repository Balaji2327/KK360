import 'package:flutter/material.dart';

class SlideFadeRoute extends PageRouteBuilder {
  final Widget page;
  final bool slideRight; // To control direction (useful for Tabs)

  SlideFadeRoute({required this.page, this.slideRight = true})
      : super(
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // SLIDE ANIMATION
            final offsetAnim = Tween<Offset>(
              // If slideRight is true, come from right (1.0). If false, come from left (-1.0)
              begin: Offset(slideRight ? 1.0 : -1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation, 
              curve: Curves.easeOut,
            ));

            // FADE ANIMATION
            final fadeAnim = CurvedAnimation(
              parent: animation, 
              curve: Curves.easeIn,
            );

            return SlideTransition(
              position: offsetAnim,
              child: FadeTransition(opacity: fadeAnim, child: child),
            );
          },
        );
}