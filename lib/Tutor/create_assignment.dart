import 'package:flutter/material.dart';
import '../widgets/tutor_bottom_nav.dart';
import '../services/firebase_auth_service.dart';

class CreateAssignmentScreen extends StatefulWidget {
  const CreateAssignmentScreen({super.key});

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

  final FirebaseAuthService _auth = FirebaseAuthService();
  List<ClassInfo> _myClasses = [];
  String? _selectedClassId;
  bool _classesLoading = false;

  @override
  void initState() {
    super.initState();
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
    setState(() => _classesLoading = true);
    try {
      final items = await _auth.getClassesForTutor(projectId: 'kk360-69504');
      if (!mounted) return;
      setState(() {
        _myClasses = items;
        _selectedClassId = _myClasses.isNotEmpty ? _myClasses.first.id : null;
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

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
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
                Navigator.of(ctx).pop();
              },
              child: const Text("Cancel"),
            ),

            /// ✅ GREEN SAVE BUTTON
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
                Navigator.of(ctx).pop();
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
      setState(() {
        _startDate = picked;
      });
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
      setState(() {
        _endDate = picked;
      });
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

    return Scaffold(
      backgroundColor: Colors.white,
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
                    onTap: () => Navigator.of(context).maybePop(),
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
                      if (_selectedClassId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a class to assign to'),
                          ),
                        );
                        return;
                      }

                      try {
                        await _auth.createAssignment(
                          projectId: 'kk360-69504',
                          title: title,
                          classId: _selectedClassId!,
                          course: _selectedCourse,
                          description: _descriptionController.text.trim(),
                          points: _pointsController.text.trim(),
                          startDate: _startDate,
                          endDate: _endDate,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Assignment assigned'),
                            ),
                          );
                          Navigator.of(context).maybePop();
                        }
                      } catch (e) {
                        if (mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to assign: $e')),
                          );
                      }
                    },
                    child: const Text(
                      "Assign",
                      style: TextStyle(
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
                    const Text(
                      "Assignment title (required)",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: h * 0.02),

                    // Title input
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Assignment - 5',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: h * 0.02),

                    // Class selector (so tutor can choose which class to assign to)
                    Row(
                      children: [
                        Expanded(
                          child:
                              _classesLoading
                                  ? const SizedBox(
                                    height: 48,
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                  : DropdownButtonFormField<String>(
                                    value: _selectedClassId,
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
                                    onChanged:
                                        (v) => setState(
                                          () => _selectedClassId = v,
                                        ),
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      labelText: 'Class',
                                    ),
                                  ),
                        ),
                        SizedBox(width: w * 0.02),
                        _chip("All students"),
                      ],
                    ),
                    SizedBox(height: h * 0.02),
                    SizedBox(height: h * 0.02),

                    // DESCRIPTION BOX
                    Container(
                      width: w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black54),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: w * 0.03,
                        vertical: h * 0.012,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.notes, size: 22),
                          SizedBox(width: w * 0.03),
                          Expanded(
                            child: TextFormField(
                              controller: _descriptionController,
                              maxLines: 3,
                              minLines: 3,
                              decoration: const InputDecoration(
                                hintText: "Description",
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
                    Row(
                      children: [
                        const Icon(Icons.attachment, size: 22),
                        SizedBox(width: w * 0.02),
                        Text(
                          "Add attachment",
                          style: TextStyle(
                            fontSize: 15,
                            color: const Color(0xFF4B3FA3),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.black12),
                              ),
                              child: Text(
                                _savedPoints!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
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
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.black12),
                              ),
                              child: Text(
                                _formatDate(_startDate!),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
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
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.black12),
                              ),
                              child: Text(
                                _formatDate(_endDate!),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
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

      bottomNavigationBar: const TutorBottomNav(currentIndex: 2),
    );
  }
}
