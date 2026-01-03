import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import '../widgets/nav_helper.dart';

class CreateClassScreen extends StatefulWidget {
  const CreateClassScreen({super.key});

  @override
  State<CreateClassScreen> createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends State<CreateClassScreen> {
  final _nameController = TextEditingController();
  final _courseController = TextEditingController();
  final FirebaseAuthService _authService = FirebaseAuthService();
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  Future<void> _createClass() async {
    final name = _nameController.text.trim();
    final course = _courseController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a class name')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      debugPrint('[CreateClass] Creating class: $name');
      final docId = await _authService.createClass(
        projectId: 'kk360-69504',
        name: name,
        course: course.isEmpty ? null : course,
      );

      if (!mounted) return;

      // Verify we got a valid document ID
      if (docId.isEmpty) {
        throw 'No document ID returned from server';
      }

      debugPrint('[CreateClass] Class created successfully with ID: $docId');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Class created successfully (ID: $docId)')),
      );

      // Return created class info so caller can update UI immediately
      goBack(context, {'id': docId, 'name': name, 'course': course});
    } catch (e) {
      debugPrint('[CreateClass] Failed to create class: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create class: $e'),
          backgroundColor: Colors.red,
        ),
      );
      // Don't return any result on failure so home screen knows creation failed
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final h = size.height;
    final w = size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Container(
            width: w,
            height: h * 0.12,
            padding: EdgeInsets.symmetric(horizontal: w * 0.06),
            decoration: const BoxDecoration(
              color: Color(0xFF4B3FA3),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: h * 0.07),
                const Text(
                  'Create Class',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(w * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: h * 0.02),
                  TextField(
                    controller: _nameController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Class name',
                      labelStyle: TextStyle(
                        color: isDark ? Colors.white70 : Colors.grey,
                      ),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isDark ? Colors.white24 : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: h * 0.02),
                  TextField(
                    controller: _courseController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Course (optional)',
                      labelStyle: TextStyle(
                        color: isDark ? Colors.white70 : Colors.grey,
                      ),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isDark ? Colors.white24 : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,

                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4B3FA3),

                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: h * 0.015),
                      ),
                      onPressed: _loading ? null : _createClass,
                      child:
                          _loading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Create'),
                    ),
                  ),
                  SizedBox(height: h * 0.02),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
