import 'package:flutter/material.dart';

import '../widgets/class_chat_page.dart';

class TutorChatPage extends StatelessWidget {
  final String classId;
  final String className;

  const TutorChatPage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  Widget build(BuildContext context) {
    return ClassChatPage(
      classId: classId,
      className: className,
      role: ClassChatRole.tutor,
      showSettingsButton: true,
    );
  }
}
