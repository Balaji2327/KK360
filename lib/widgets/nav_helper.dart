import 'package:flutter/material.dart';
import 'custom_route.dart'; // Import the file created in Step 1

// Helper for standard navigation (Pushes new screen)
void goPush(BuildContext context, Widget page) {
  Navigator.of(context).push(SlideFadeRoute(page: page, slideRight: true));
}

// Helper for replacement (Like Login -> Home)
void goReplace(BuildContext context, Widget page) {
  Navigator.of(context).pushReplacement(SlideFadeRoute(page: page, slideRight: true));
}

// Helper specifically for Tabs/BottomNav (Handles Left/Right logic)
void goTab(BuildContext context, Widget page, {required bool isForward}) {
  Navigator.of(context).pushReplacement(
    SlideFadeRoute(page: page, slideRight: isForward),
  );
}

void goBack(BuildContext context) {
  Navigator.of(context).pop();
}