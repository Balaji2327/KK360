import 'package:flutter/material.dart';
import '../widgets/nav_helper.dart';
import '../services/firebase_auth_service.dart';
import 'package:file_picker/file_picker.dart';

class CreateMaterialScreen extends StatefulWidget {
  final UnitInfo unit;
  const CreateMaterialScreen({super.key, required this.unit});

  @override
  State<CreateMaterialScreen> createState() => _CreateMaterialScreenState();
}

class _CreateMaterialScreenState extends State<CreateMaterialScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FirebaseAuthService _auth = FirebaseAuthService();

  PlatformFile? _pickedFile;
  bool _uploading = false;

  // Selection State
  List<ClassInfo> _myClasses = [];
  bool _classesLoading = false;
  List<String> _selectedClassIds = [];

  List<String> _selectedStudentIds = [];
  Map<String, UserProfile?> _studentProfiles = {};
  bool _studentsLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedClassIds = [widget.unit.classId];
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
      if (mounted) {
        setState(() {
          _myClasses = items;
          _classesLoading = false;
        });
        _fetchStudentsForSelectedClasses();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _classesLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load classes: $e')));
      }
    }
  }

  Future<void> _fetchStudentsForSelectedClasses() async {
    if (_selectedClassIds.isEmpty) {
      if (mounted) {
        setState(() {
          _studentProfiles = {};
          _selectedStudentIds = [];
        });
      }
      return;
    }

    setState(() => _studentsLoading = true);
    try {
      final allStudents = <String, UserProfile>{};

      for (final classId in _selectedClassIds) {
        final classInfo = _myClasses.firstWhere(
          (c) => c.id == classId,
          orElse:
              () => ClassInfo(
                id: '',
                name: '',
                tutorId: '',
                members: [],
                course: '',
              ),
        );
        if (classInfo.id.isEmpty) continue;

        if (classInfo.members.isNotEmpty) {
          final profiles = await _auth.getUserProfiles(
            projectId: 'kk360-69504',
            userIds: classInfo.members,
          );

          profiles.forEach((uid, profile) {
            if (profile != null && profile.role == 'student') {
              allStudents[uid] = profile;
            }
          });
        }
      }

      if (mounted) {
        setState(() {
          _studentProfiles = allStudents;
          // Remove selected IDs that are no longer valid
          _selectedStudentIds.removeWhere(
            (id) => !_studentProfiles.containsKey(id),
          );
          _studentsLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching students: $e');
      if (mounted) setState(() => _studentsLoading = false);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null) {
      if (mounted) {
        setState(() {
          _pickedFile = result.files.first;
        });
      }
    }
  }

  Future<String> _getOrCreateUnitForClass(
    String targetClassId,
    String targetClassName,
  ) async {
    if (targetClassId == widget.unit.classId) {
      return widget.unit.id;
    }

    try {
      final units = await _auth.getUnitsForClass(
        projectId: 'kk360-69504',
        classId: targetClassId,
      );
      final existing = units.firstWhere(
        (u) => u.title == widget.unit.title,
        orElse:
            () => UnitInfo(
              id: '',
              title: '',
              description: '',
              tutorId: '',
              classId: '',
              className: '',
              createdAt: DateTime.now(),
            ),
      );

      if (existing.id.isNotEmpty) {
        return existing.id;
      }

      // Create new unit
      await _auth.createUnit(
        projectId: 'kk360-69504',
        title: widget.unit.title,
        description: widget.unit.description,
        classId: targetClassId,
        className: targetClassName,
      );

      // Fetch again to get ID
      final updatedUnits = await _auth.getUnitsForClass(
        projectId: 'kk360-69504',
        classId: targetClassId,
      );
      final newUnit = updatedUnits.firstWhere(
        (u) => u.title == widget.unit.title,
      );
      return newUnit.id;
    } catch (e) {
      debugPrint('Error finding/creating unit for class $targetClassId: $e');
      throw e;
    }
  }

  Future<void> _postMaterial() async {
    final title = _titleController.text.trim();
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

    setState(() => _uploading = true);

    String? attachmentUrl;
    try {
      if (_pickedFile != null && _pickedFile!.bytes != null) {
        attachmentUrl = await _auth.uploadFile(
          _pickedFile!.bytes!,
          _pickedFile!.name,
        );
      }

      for (final classId in _selectedClassIds) {
        // Find target class info for name
        final cls = _myClasses.firstWhere(
          (c) => c.id == classId,
          orElse:
              () => ClassInfo(
                id: '',
                name: 'Unknown Class',
                tutorId: '',
                members: [],
                course: '',
              ),
        );
        final unitId = await _getOrCreateUnitForClass(classId, cls.name);

        // Determine assignedTo for this class
        List<String>? classAssignedTo;
        if (_selectedStudentIds.isNotEmpty) {
          final studentsInThisClass =
              _selectedStudentIds.where((sid) {
                // Check if sid is in this class's members
                return cls.members.contains(sid);
              }).toList();

          if (studentsInThisClass.isEmpty) {
            debugPrint(
              'Skipping assignedTo for class $classId (no selected students match)',
            );
            continue;
          }
          classAssignedTo = studentsInThisClass;
        }

        await _auth.createMaterial(
          projectId: 'kk360-69504',
          unitId: unitId,
          title: title,
          description: _descriptionController.text.trim(),
          attachmentUrl: attachmentUrl,
          assignedTo: classAssignedTo,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Material Posted!')));
        goBack(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
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
                            this.setState(() {});
                          },
                        );
                      }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _fetchStudentsForSelectedClasses();
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showStudentSelectionDialog() {
    if (_studentProfiles.isEmpty && !_studentsLoading) {
      // Retry fetch if empty?
      _fetchStudentsForSelectedClasses();
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final sortedStudentIds = _studentProfiles.keys.toList();

            return AlertDialog(
              title: const Text('Select Students'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_studentsLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (sortedStudentIds.isEmpty)
                      const Text("No students found in this class.")
                    else ...[
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            if (_selectedStudentIds.length ==
                                sortedStudentIds.length) {
                              _selectedStudentIds.clear();
                            } else {
                              _selectedStudentIds = List.from(sortedStudentIds);
                            }
                          });
                          this.setState(() {});
                        },
                        child: Text(
                          _selectedStudentIds.length == sortedStudentIds.length
                              ? "Deselect All"
                              : "Select All",
                        ),
                      ),
                      const Divider(),
                      Expanded(
                        child: ListView(
                          shrinkWrap: true,
                          children:
                              sortedStudentIds.map((uid) {
                                final profile = _studentProfiles[uid];
                                final isSelected = _selectedStudentIds.contains(
                                  uid,
                                );
                                final name = profile?.name ?? 'Unknown';
                                return CheckboxListTile(
                                  title: Text(name),
                                  value: isSelected,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedStudentIds.add(uid);
                                      } else {
                                        _selectedStudentIds.remove(uid);
                                      }
                                    });
                                    this.setState(() {});
                                  },
                                );
                              }).toList(),
                        ),
                      ),
                    ],
                  ],
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
                    onTap: _uploading ? null : _postMaterial,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: w * 0.05,
                        vertical: h * 0.008,
                      ),
                      decoration: BoxDecoration(
                        color: _uploading ? Colors.grey : Colors.green,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child:
                          _uploading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text(
                                "Post",
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
                      "Material Details",
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
                        labelText: "Title (Required)",
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

                    // CLASS & STUDENT SELECTION (Consistent Style)
                    Text(
                      "Assign To",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(height: 8),

                    _classesLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Class Button
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _showClassSelectionDialog,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4B3FA3),
                                      foregroundColor: Colors.white,
                                      side: BorderSide(
                                        color: Colors.transparent,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    child: Text(
                                      _selectedClassIds.isEmpty
                                          ? 'Select Classes'
                                          : '${_selectedClassIds.length} Classes',
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                // Student Button
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _showStudentSelectionDialog,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4B3FA3),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    child: Text(
                                      _selectedStudentIds.isEmpty
                                          ? 'All Students'
                                          : '${_selectedStudentIds.length} Students',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_selectedClassIds.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Wrap(
                                  spacing: 8,
                                  children:
                                      _selectedClassIds.map((classId) {
                                        final classInfo = _myClasses.firstWhere(
                                          (c) => c.id == classId,
                                          orElse:
                                              () => ClassInfo(
                                                id: '',
                                                name: '',
                                                tutorId: '',
                                                members: [],
                                                course: '',
                                              ),
                                        );
                                        return Chip(
                                          label: Text(
                                            classInfo.name.isNotEmpty
                                                ? classInfo.name
                                                : classInfo.id,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          onDeleted: () {
                                            setState(() {
                                              _selectedClassIds.remove(classId);
                                              _fetchStudentsForSelectedClasses();
                                            });
                                          },
                                          backgroundColor: Colors.blue.shade100,
                                        );
                                      }).toList(),
                                ),
                              ),
                            if (_selectedStudentIds.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Wrap(
                                  spacing: 8,
                                  children:
                                      _selectedStudentIds.map((uid) {
                                        final name =
                                            _studentProfiles[uid]?.name ?? uid;
                                        return Chip(
                                          label: Text(
                                            name,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          onDeleted: () {
                                            setState(() {
                                              _selectedStudentIds.remove(uid);
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
                              maxLines: 5,
                              minLines: 5,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              decoration: InputDecoration(
                                hintText: "Description (Optional)",
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

                    SizedBox(height: h * 0.03),

                    // ATTACHMENT
                    GestureDetector(
                      onTap: _pickFile,
                      child: Row(
                        children: [
                          Icon(
                            Icons.attachment,
                            size: 22,
                            color: isDark ? Colors.white70 : Colors.black,
                          ),
                          SizedBox(width: w * 0.02),
                          Expanded(
                            child: Text(
                              _pickedFile != null
                                  ? _pickedFile!.name
                                  : "Add attachment",
                              style: TextStyle(
                                fontSize: 15,
                                color:
                                    isDark
                                        ? const Color(0xFF8F85FF)
                                        : const Color(0xFF4B3FA3),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_pickedFile != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed:
                                  () => setState(() => _pickedFile = null),
                            ),
                        ],
                      ),
                    ),

                    SizedBox(height: h * 0.015),
                    Divider(color: isDark ? Colors.white24 : Colors.grey),
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
