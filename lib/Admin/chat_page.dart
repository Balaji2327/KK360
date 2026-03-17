import 'package:flutter/material.dart';

import '../widgets/class_chat_page.dart';

class AdminChatPage extends StatelessWidget {
  final String classId;
  final String className;

  const AdminChatPage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  Widget build(BuildContext context) {
    return ClassChatPage(
      classId: classId,
      className: className,
      role: ClassChatRole.admin,
    );
  }
}
