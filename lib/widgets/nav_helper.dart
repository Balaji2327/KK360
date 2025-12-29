import 'package:flutter/material.dart';
import 'custom_route.dart'; // Import the file created in Step 1

// Helper for standard navigation (Pushes new screen)
Future<T?> goPush<T extends Object?>(BuildContext context, Widget page) {
  return Navigator.of(
    context,
  ).push<T>(SlideFadeRoute(page: page, slideRight: true));
}

// Helper for replacement (Like Login -> Home)
void goReplace(BuildContext context, Widget page) {
  Navigator.of(
    context,
  ).pushReplacement(SlideFadeRoute(page: page, slideRight: true));
}

// Helper specifically for Tabs/BottomNav (Handles Left/Right logic)
void goTab(BuildContext context, Widget page, {required bool isForward}) {
  Navigator.of(
    context,
  ).pushReplacement(SlideFadeRoute(page: page, slideRight: isForward));
}

// Helper for goBack with optional result
void goBack<T>(BuildContext context, [T? result]) {
  Navigator.of(context).pop(result);
}
