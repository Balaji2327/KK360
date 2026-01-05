import 'package:flutter/material.dart';
import '../widgets/nav_helper.dart';
import '../services/firebase_auth_service.dart';

class CreateUnitScreen extends StatefulWidget {
  const CreateUnitScreen({super.key});

  @override
  State<CreateUnitScreen> createState() => _CreateUnitScreenState();
}

class _CreateUnitScreenState extends State<CreateUnitScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FirebaseAuthService _auth = FirebaseAuthService();

  List<ClassInfo> _myClasses = [];
  String? _selectedClassId;
  String _selectedClassName = '';
  bool _classesLoading = false;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _loadMyClasses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadMyClasses() async {
    setState(() => _classesLoading = true);
    try {
      final items = await _auth.getClassesForTutor(projectId: 'kk360-69504');
      if (!mounted) return;
      setState(() {
        _myClasses = items;
        if (_myClasses.isNotEmpty) {
          _selectedClassId = _myClasses.first.id;
          _selectedClassName = _myClasses.first.name;
        }
        _classesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _classesLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load classes: $e')));
    }
  }

  Future<void> _createUnit() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }
    if (_selectedClassId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a class')));
      return;
    }

    setState(() => _creating = true);
    try {
      await _auth.createUnit(
        projectId: 'kk360-69504',
        title: title,
        description: description,
        classId: _selectedClassId!,
        className: _selectedClassName,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Unit created')));
        goBack(context);
      }
    } catch (e) {
      setState(() => _creating = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create unit: $e')));
    }
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF4B3FA3),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // APP BAR
          Container(
            height: h * 0.12,
            width: w,
            padding: EdgeInsets.symmetric(horizontal: w * 0.04),
            color: const Color(0xFF4B3FA3),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => goBack(context),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  GestureDetector(
                    onTap: _creating ? null : _createUnit,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: w * 0.05,
                        vertical: h * 0.008,
                      ),
                      decoration: BoxDecoration(
                        color: _creating ? Colors.grey : Colors.green,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child:
                          _creating
                              ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text(
                                "Create",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // MAIN CONTENT
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: w * 0.04,
                  vertical: h * 0.02,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Create New Unit",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(height: h * 0.02),

                    TextFormField(
                      controller: _titleController,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: "Unit Title",
                        labelStyle: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey,
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

                    // CLASS SELECTOR
                    Row(
                      children: [
                        Expanded(
                          child:
                              _classesLoading
                                  ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                  : DropdownButtonFormField<String>(
                                    value: _selectedClassId,
                                    dropdownColor:
                                        isDark
                                            ? const Color(0xFF2C2C2C)
                                            : Colors.white,
                                    style: TextStyle(
                                      color:
                                          isDark ? Colors.white : Colors.black,
                                    ),
                                    items:
                                        _myClasses
                                            .map(
                                              (c) => DropdownMenuItem(
                                                value: c.id,
                                                child: Text(
                                                  c.name.isNotEmpty
                                                      ? c.name
                                                      : c.id,
                                                ),
                                              ),
                                            )
                                            .toList(),
                                    onChanged: (v) {
                                      setState(() {
                                        _selectedClassId = v;
                                        final cls = _myClasses.firstWhere(
                                          (c) => c.id == v,
                                        );
                                        _selectedClassName = cls.name;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'Select Class',
                                      labelStyle: TextStyle(
                                        color:
                                            isDark
                                                ? Colors.white70
                                                : Colors.grey,
                                      ),
                                      border: OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color:
                                              isDark
                                                  ? Colors.white24
                                                  : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                        ),
                      ],
                    ),
                    SizedBox(height: h * 0.02),

                    // DESCRIPTION BOX
                    Container(
                      width: w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? Colors.white24 : Colors.black54,
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: w * 0.03,
                        vertical: h * 0.012,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.notes,
                            size: 22,
                            color: isDark ? Colors.white70 : Colors.black,
                          ),
                          SizedBox(width: w * 0.03),
                          Expanded(
                            child: TextFormField(
                              controller: _descriptionController,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              maxLines: 4,
                              minLines: 4,
                              decoration: InputDecoration(
                                hintText: "Unit Description (Optional)",
                                hintStyle: TextStyle(
                                  color: isDark ? Colors.white54 : Colors.grey,
                                ),
                                border: InputBorder.none,
                                isCollapsed: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
