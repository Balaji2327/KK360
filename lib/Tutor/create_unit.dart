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
  List<String> _selectedClassIds = [];
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
        _selectedClassIds = _myClasses.isNotEmpty ? [_myClasses.first.id] : [];
        if (_myClasses.isNotEmpty) {
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
    if (_selectedClassIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one class')),
      );
      return;
    }

    setState(() => _creating = true);
    try {
      // Create unit for each selected class
      for (String classId in _selectedClassIds) {
        final classInfo = _myClasses.firstWhere((c) => c.id == classId);
        await _auth.createUnit(
          projectId: 'kk360-69504',
          title: title,
          description: description,
          classId: classId,
          className: classInfo.name,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unit created for ${_selectedClassIds.length} class(es)',
            ),
          ),
        );
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

  void _showClassSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Classes'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children:
                      _myClasses.map((classInfo) {
                        final isSelected = _selectedClassIds.contains(
                          classInfo.id,
                        );
                        return CheckboxListTile(
                          title: Text(
                            classInfo.name.isNotEmpty
                                ? classInfo.name
                                : classInfo.id,
                          ),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedClassIds.add(classInfo.id);
                              } else {
                                _selectedClassIds.remove(classInfo.id);
                              }
                            });
                            // Update parent state
                            this.setState(() {});
                          },
                        );
                      }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _showClassSelectionDialog,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      isDark
                                          ? const Color(0xFF2C2C2C)
                                          : Colors.white,
                                  foregroundColor:
                                      isDark ? Colors.white : Colors.black,
                                  side: BorderSide(
                                    color:
                                        isDark ? Colors.white24 : Colors.grey,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    vertical: h * 0.015,
                                  ),
                                ),
                                child: Text(
                                  _selectedClassIds.isEmpty
                                      ? 'Select Classes'
                                      : '${_selectedClassIds.length} class(es) selected',
                                ),
                              ),
                            ),
                            SizedBox(width: w * 0.02),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedClassIds =
                                      _myClasses.map((c) => c.id).toList();
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: EdgeInsets.symmetric(
                                  horizontal: w * 0.03,
                                  vertical: h * 0.015,
                                ),
                              ),
                              child: const Text('All Classes'),
                            ),
                          ],
                        ),
                        if (_selectedClassIds.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: h * 0.01),
                            child: Wrap(
                              spacing: 8,
                              children:
                                  _selectedClassIds.map((classId) {
                                    final classInfo = _myClasses.firstWhere(
                                      (c) => c.id == classId,
                                    );
                                    return Chip(
                                      label: Text(
                                        classInfo.name.isNotEmpty
                                            ? classInfo.name
                                            : classInfo.id,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      onDeleted: () {
                                        setState(() {
                                          _selectedClassIds.remove(classId);
                                        });
                                      },
                                      backgroundColor: Colors.blue.shade100,
                                    );
                                  }).toList(),
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
