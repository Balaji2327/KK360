import 'package:flutter/material.dart';

import '../services/firebase_auth_service.dart';
import '../services/notification_service.dart';
import '../widgets/nav_helper.dart';
import 'package:file_picker/file_picker.dart';

class CreateAssignmentScreen extends StatefulWidget {
  final String? classId;
  final AssignmentInfo? assignment; // Added for editing
  final bool isTestCreator;
  const CreateAssignmentScreen({
    super.key,
    this.classId,
    this.assignment,
    this.isTestCreator = false,
  });

  @override
  State<CreateAssignmentScreen> createState() => _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends State<CreateAssignmentScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  String _selectedCourse = 'Mathematics';

  String? _savedPoints;
  DateTime? _startDate;

  DateTime? _endDate;
  PlatformFile? _pickedFile;

  final FirebaseAuthService _auth = FirebaseAuthService();
  List<ClassInfo> _myClasses = [];
  List<String> _selectedClassIds = [];

  @override
  void initState() {
    super.initState();
    if (widget.assignment != null) {
      _titleController.text = widget.assignment!.title;
      _descriptionController.text = widget.assignment!.description;
      _pointsController.text = widget.assignment!.points;
      // If points exists, save it
      if (widget.assignment!.points.isNotEmpty) {
        _savedPoints = widget.assignment!.points;
      }
      _startDate = widget.assignment!.startDate;
      _endDate = widget.assignment!.endDate;
      if (widget.assignment!.course.isNotEmpty) {
        _selectedCourse = widget.assignment!.course;
      }
    }
    _loadMyClasses();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _pointsController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadMyClasses() async {
    try {
      final items =
          widget.isTestCreator
              ? await _auth.getAllClasses(projectId: 'kk360-69504')
              : await _auth.getClassesForTutor(projectId: 'kk360-69504');
      if (!mounted) return;
      setState(() {
        _myClasses = items;
        if (widget.assignment != null) {
          // If editing, pre-select the assignment's class if valid
          if (items.any((c) => c.id == widget.assignment!.classId)) {
            _selectedClassIds = [widget.assignment!.classId];
          }
        } else if (widget.classId != null &&
            items.any((c) => c.id == widget.classId)) {
          _selectedClassIds = [widget.classId!];
        } else {
          _selectedClassIds = [];
        }
      });
      _fetchStudentsForSelectedClasses();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load classes: $e')));
    }
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _showPointsDialog(
    BuildContext context,
    double w,
    double h,
  ) async {
    _pointsController.text = _savedPoints ?? '';

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Set total points"),
          content: SizedBox(
            width: w * 0.8,
            child: TextField(
              controller: _pointsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "Enter points (e.g. 100)",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                goBack(ctx);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                final text = _pointsController.text.trim();
                if (text.isNotEmpty) {
                  setState(() {
                    _savedPoints = text;
                  });
                } else {
                  setState(() {
                    _savedPoints = null;
                  });
                }
                goBack(ctx);
              },
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickStartDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      if (context.mounted) {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(now),
        );
        if (time != null) {
          setState(() {
            _startDate = DateTime(
              picked.year,
              picked.month,
              picked.day,
              time.hour,
              time.minute,
            );
          });
        }
      }
    }
  }

  Future<void> _pickEndDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      if (context.mounted) {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(now),
        );
        if (time != null) {
          setState(() {
            _endDate = DateTime(
              picked.year,
              picked.month,
              picked.day,
              time.hour,
              time.minute,
            );
          });
        }
      }
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null) {
      setState(() {
        _pickedFile = result.files.first;
      });
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

  List<String> _selectedStudentIds = [];
  Map<String, UserProfile?> _studentProfiles = {};
  bool _studentsLoading = false;

  Future<void> _fetchStudentsForSelectedClasses() async {
    setState(() => _studentsLoading = true);
    try {
      final Set<String> memberIds = {};
      final selectedClasses = _myClasses.where(
        (c) => _selectedClassIds.contains(c.id),
      );
      for (final c in selectedClasses) {
        memberIds.addAll(c.members);
      }

      if (memberIds.isNotEmpty) {
        final profiles = await _auth.getUserProfiles(
          projectId: 'kk360-69504',
          userIds: memberIds.toList(),
        );
        // Filter to include only students
        _studentProfiles = Map.fromEntries(
          profiles.entries.where(
            (entry) =>
                entry.value?.role == 'student' ||
                (entry.value?.role == null &&
                    entry.value?.email != null &&
                    !entry.value!.email!.toLowerCase().contains('tutor')),
          ),
        );
      } else {
        _studentProfiles = {};
      }
    } catch (e) {
      debugPrint("Error fetching students: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load students: $e")));
    } finally {
      if (mounted) setState(() => _studentsLoading = false);
    }
  }

  void _showStudentSelectionDialog() async {
    await _fetchStudentsForSelectedClasses();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final allMemberIds = _studentProfiles.keys.toList();
            final allSelected =
                allMemberIds.isNotEmpty &&
                _selectedStudentIds.length == allMemberIds.length;

            return AlertDialog(
              title: const Text('Select Students'),
              content: SizedBox(
                width: double.maxFinite,
                child:
                    _studentsLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _studentProfiles.isEmpty
                        ? const Center(child: Text("No students found."))
                        : ListView(
                          shrinkWrap: true,
                          children: [
                            CheckboxListTile(
                              title: const Text(
                                "Select All",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              value: allSelected,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedStudentIds = List.from(
                                      allMemberIds,
                                    );
                                  } else {
                                    _selectedStudentIds.clear();
                                  }
                                });
                                this.setState(() {});
                              },
                            ),
                            const Divider(),
                            ..._studentProfiles.entries.map((entry) {
                              final uid = entry.key;
                              final profile = entry.value;
                              final name = profile?.name ?? "Unknown";
                              final email = profile?.email ?? "";

                              return CheckboxListTile(
                                title: Text(name),
                                subtitle: Text(
                                  email,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                value: _selectedStudentIds.contains(uid),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedStudentIds.add(uid);
                                    } else {
                                      _selectedStudentIds.remove(uid);
                                    }
                                  });
                                  this.setState(() {});
                                },
                              );
                            }),
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
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () async {
                      final title = _titleController.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter an assignment title'),
                          ),
                        );
                        return;
                      }
                      if (_selectedClassIds.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please select at least one class to assign to',
                            ),
                          ),
                        );
                        return;
                      }

                      String? attachmentUrl;
                      try {
                        if (_pickedFile != null && _pickedFile!.bytes != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Uploading attachment..."),
                            ),
                          );
                          attachmentUrl = await _auth.uploadFile(
                            _pickedFile!.bytes!,
                            _pickedFile!.name,
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Failed to upload attachment: $e"),
                            ),
                          );
                        }
                        return;
                      }

                      try {
                        if (widget.assignment != null) {
                          // UPDATE MODE
                          await _auth.updateAssignmentDetails(
                            projectId: 'kk360-69504',
                            assignmentId: widget.assignment!.id,
                            title: title,
                            description: _descriptionController.text.trim(),
                            points: _pointsController.text.trim(),
                            startDate: _startDate,
                            endDate: _endDate,
                            attachmentUrl:
                                attachmentUrl, // If null, won't update
                            course: _selectedCourse,
                            // We don't update classId or assignedTo for single assignment edit simplicity
                            // unless we want to support re-assigning students.
                            // For now, assume simple metadata update.
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Assignment updated successfully',
                                ),
                              ),
                            );
                            goBack(context);
                          }
                        } else {
                          // CREATE MODE
                          // Create assignment for each selected class
                          final notificationService = NotificationService();
                          final tutorProfile = await _auth.getUserProfile(
                            projectId: 'kk360-69504',
                          );
                          final tutorName = tutorProfile?.name ?? 'Tutor';

                          for (String classId in _selectedClassIds) {
                            // Determine assigned students for THIS class
                            List<String>? assignedToForClass;
                            final classInfo = _myClasses.firstWhere(
                              (c) => c.id == classId,
                            );

                            if (_selectedStudentIds.isNotEmpty) {
                              assignedToForClass =
                                  _selectedStudentIds
                                      .where(
                                        (sid) =>
                                            classInfo.members.contains(sid),
                                      )
                                      .toList();

                              if (assignedToForClass.isEmpty) {
                                continue;
                              }
                            }

                            await _auth.createAssignment(
                              projectId: 'kk360-69504',
                              title: title,
                              classId: classId,
                              course: _selectedCourse,
                              description: _descriptionController.text.trim(),
                              points: _pointsController.text.trim(),
                              startDate: _startDate,
                              endDate: _endDate,
                              attachmentUrl: attachmentUrl,
                              assignedTo: assignedToForClass,
                            );

                            // Send notifications to students
                            final studentsToNotify =
                                assignedToForClass ??
                                classInfo.members.where((memberId) {
                                  // Only notify students (not other tutors)
                                  return memberId != classInfo.tutorId;
                                }).toList();

                            debugPrint(
                              '[Assignment] Sending notifications to ${studentsToNotify.length} students',
                            );
                            debugPrint(
                              '[Assignment] Student IDs: $studentsToNotify',
                            );

                            String? dueDateStr;
                            if (_endDate != null) {
                              dueDateStr =
                                  '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}';
                            }

                            int successCount = 0;
                            for (String studentId in studentsToNotify) {
                              try {
                                debugPrint(
                                  '[Assignment] Creating notification for student: $studentId',
                                );
                                await notificationService
                                    .createAssignmentNotification(
                                      recipientUserId: studentId,
                                      tutorName: tutorName,
                                      assignmentTitle: title,
                                      classId: classId,
                                      className: classInfo.name,
                                      assignmentId:
                                          '${classId}_${DateTime.now().millisecondsSinceEpoch}',
                                      dueDate: dueDateStr,
                                    );
                                successCount++;
                                debugPrint(
                                  '[Assignment] Successfully created notification for student: $studentId',
                                );
                                // Small delay to ensure unique notification IDs
                                await Future.delayed(
                                  const Duration(milliseconds: 10),
                                );
                              } catch (e) {
                                debugPrint(
                                  '[Assignment] Failed to send notification to $studentId: $e',
                                );
                              }
                            }
                            debugPrint(
                              '[Assignment] Created $successCount/${studentsToNotify.length} notifications successfully',
                            );
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Assignment assigned to ${_selectedClassIds.length} class(es)',
                                ),
                              ),
                            );
                            goBack(context);
                          }
                        }
                      } catch (e) {
                        if (mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to save assignment: $e'),
                            ),
                          );
                      }
                    },
                    child: Text(
                      widget.assignment != null ? "Update" : "Assign",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
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
                      "Assignment title (required)",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(height: h * 0.02),

                    // Title input
                    TextFormField(
                      controller: _titleController,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. Assignment - 5',
                        hintStyle: TextStyle(
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

                    // Class selector & Student selector
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Select Classes Button
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _showClassSelectionDialog,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4B3FA3),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    vertical: h * 0.015,
                                  ),
                                ),
                                child: Text(
                                  _selectedClassIds.isEmpty
                                      ? 'Select Classes'
                                      : '${_selectedClassIds.length} class(es)',
                                ),
                              ),
                            ),
                            SizedBox(width: w * 0.02),

                            // Select Students Button (Replaces All Classes)
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_selectedClassIds.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Please select a class first",
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  _showStudentSelectionDialog();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4B3FA3),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    vertical: h * 0.015,
                                  ),
                                ),
                                child: Text(
                                  _selectedStudentIds.isEmpty
                                      ? 'All students'
                                      : '${_selectedStudentIds.length} student(s)',
                                ),
                              ),
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
                              maxLines: 3,
                              minLines: 3,
                              decoration: InputDecoration(
                                hintText: "Description",
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
                                  : (widget.assignment?.attachmentUrl != null &&
                                      widget
                                          .assignment!
                                          .attachmentUrl!
                                          .isNotEmpty)
                                  ? "Change attachment (Current: Has file)"
                                  : "Add attachment",
                              style: TextStyle(
                                fontSize: 15,
                                color: const Color(0xFF4B3FA3),
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
                    const Divider(),
                    SizedBox(height: h * 0.015),

                    // TOTAL POINTS
                    InkWell(
                      onTap: () => _showPointsDialog(context, w, h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Set total points",
                            style: TextStyle(
                              color: const Color(0xFF4B3FA3),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_savedPoints != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isDark
                                        ? const Color(0xFF1E1E1E)
                                        : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color:
                                      isDark ? Colors.white24 : Colors.black12,
                                ),
                              ),
                              child: Text(
                                _savedPoints!,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    SizedBox(height: h * 0.02),

                    // START DATE
                    InkWell(
                      onTap: () => _pickStartDate(context),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Set start date",
                            style: TextStyle(
                              color: const Color(0xFF4B3FA3),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_startDate != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isDark
                                        ? const Color(0xFF1E1E1E)
                                        : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color:
                                      isDark ? Colors.white24 : Colors.black12,
                                ),
                              ),
                              child: Text(
                                _formatDate(_startDate!),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    SizedBox(height: h * 0.02),

                    // END DATE (was due date)
                    InkWell(
                      onTap: () => _pickEndDate(context),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Set end date",
                            style: TextStyle(
                              color: const Color(0xFF4B3FA3),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_endDate != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isDark
                                        ? const Color(0xFF1E1E1E)
                                        : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color:
                                      isDark ? Colors.white24 : Colors.black12,
                                ),
                              ),
                              child: Text(
                                _formatDate(_endDate!),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    SizedBox(height: h * 0.05),
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
