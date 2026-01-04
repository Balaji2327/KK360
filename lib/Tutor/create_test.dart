import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import '../widgets/nav_helper.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';

class CreateTestScreen extends StatefulWidget {
  const CreateTestScreen({super.key});

  @override
  State<CreateTestScreen> createState() => _CreateTestScreenState();
}

class _QuestionEditor {
  TextEditingController text = TextEditingController();
  List<TextEditingController> options = List.generate(
    4,
    (_) => TextEditingController(),
  );
  int correctOption = 0;

  void dispose() {
    text.dispose();
    for (var c in options) c.dispose();
  }
}

class _CreateTestScreenState extends State<CreateTestScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _questionCountController =
      TextEditingController();

  String? _selectedClassId;
  String _selectedCourse = 'General';
  DateTime? _startDate;
  DateTime? _endDate;

  final FirebaseAuthService _auth = FirebaseAuthService();
  List<ClassInfo> _myClasses = [];
  bool _classesLoading = false;

  List<_QuestionEditor> _questions = [];

  @override
  void initState() {
    super.initState();
    _loadMyClasses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _questionCountController.dispose();
    for (var q in _questions) q.dispose();
    super.dispose();
  }

  void _onQuestionCountChanged(String val) {
    final count = int.tryParse(val) ?? 0;
    // Cap at a reasonable number (e.g. 50)
    if (count < 0 || count > 50) return;

    setState(() {
      if (count > _questions.length) {
        for (int i = _questions.length; i < count; i++) {
          _questions.add(_QuestionEditor());
        }
      } else {
        // Find how many to remove
        final diff = _questions.length - count;
        // Dispose removed controllers
        for (int i = 0; i < diff; i++) {
          _questions.last.dispose();
          _questions.removeLast();
        }
      }
    });
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
          _selectedCourse =
              _myClasses.first.course.isNotEmpty
                  ? _myClasses.first.course
                  : 'General';
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

  void _onClassChanged(String? newId) {
    if (newId == null) return;
    setState(() {
      _selectedClassId = newId;
      final cls = _myClasses.firstWhere(
        (c) => c.id == newId,
        orElse: () => _myClasses.first,
      );
      _selectedCourse = cls.course.isNotEmpty ? cls.course : 'General';
    });
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickStartDate(BuildContext context) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (d != null && mounted) {
      final t = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_startDate ?? now),
      );
      if (t != null) {
        setState(() {
          _startDate = DateTime(d.year, d.month, d.day, t.hour, t.minute);
        });
      }
    }
  }

  Future<void> _pickEndDate(BuildContext context) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _endDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (d != null && mounted) {
      final t = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_endDate ?? now),
      );
      if (t != null) {
        setState(() {
          _endDate = DateTime(d.year, d.month, d.day, t.hour, t.minute);
        });
      }
    }
  }

  Future<void> _generateQuestionsWithAI() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final count = int.tryParse(_questionCountController.text) ?? 5;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a Test Title first")),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Using the Google Generative AI SDK (key supplied at runtime)
      const apiKey = String.fromEnvironment('GEMINI_API_KEY');
      if (apiKey.isEmpty) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gemini API key missing. Run with --dart-define=GEMINI_API_KEY=your_key.',
            ),
          ),
        );
        return;
      }

      final model = GenerativeModel(
        model: 'gemini-1.5-flash-latest',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      final prompt =
          "Generate $count multiple choice questions for a test about '$title'. "
          "Description: '$description'. "
          "The output must be a standard JSON array of objects. "
          "Each object must have exactly these keys: 'question' (string), 'options' (array of 4 strings), and 'correctIndex' (int 0-3).";

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (response.text != null) {
        String cleanJson = response.text!;
        // Basic cleanup just in case
        if (cleanJson.startsWith('```json')) {
          cleanJson = cleanJson.replaceAll('```json', '').replaceAll('```', '');
        } else if (cleanJson.startsWith('```')) {
          cleanJson = cleanJson.replaceAll('```', '');
        }

        final List<dynamic> jsonList = jsonDecode(cleanJson);

        setState(() {
          _questions.clear();
          for (var item in jsonList) {
            final q = _QuestionEditor();
            q.text.text = item['question']?.toString() ?? "";
            final opts = item['options'] as List<dynamic>? ?? [];
            for (int i = 0; i < 4; i++) {
              if (i < opts.length) {
                q.options[i].text = opts[i].toString();
              } else {
                q.options[i].text = "";
              }
            }
            q.correctOption = (item['correctIndex'] as int?) ?? 0;
            _questions.add(q);
          }
          // Update count controller
          _questionCountController.text = _questions.length.toString();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Questions generated successfully!")),
        );
      } else {
        throw "Empty response from AI";
      }
    } catch (e) {
      if (mounted) {
        if (Navigator.canPop(context))
          Navigator.pop(context); // Ensure loading is closed

        // Show a detailed error dialog or snackbar
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text("AI Error"),
                content: SingleChildScrollView(
                  child: Text(
                    "Failed to generate questions.\n\nError: $e\n\n"
                    "CRITICAL TROUBLESHOOTING:\n"
                    "The error 'Not Found' means the Google AI API is NOT enabled for your project.\n\n"
                    "1. Go to https://console.cloud.google.com\n"
                    "2. Select project 'kk360-69504' (or whichever project created the API key).\n"
                    "3. Search for 'Generative Language API'.\n"
                    "4. Click 'ENABLE'.\n"
                    "5. Wait 1-2 minutes and try again.",
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK"),
                  ),
                ],
              ),
        );
      }
    }
  }

  Future<void> _createTest() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a test title')),
      );
      return;
    }
    if (_selectedClassId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a class')));
      return;
    }

    // Validate questions
    final validQuestions = <Question>[];
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.text.text.trim().isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Question ${i + 1} is empty')));
        return;
      }
      final opts = q.options.map((c) => c.text.trim()).toList();
      if (opts.any((o) => o.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Question ${i + 1} has empty options')),
        );
        return;
      }
      validQuestions.add(
        Question(
          text: q.text.text.trim(),
          options: opts,
          correctOptionIndex: q.correctOption,
        ),
      );
    }

    try {
      await _auth.createTest(
        projectId: 'kk360-69504',
        title: title,
        classId: _selectedClassId!,
        course: _selectedCourse,
        description: _descriptionController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        questions: validQuestions,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test assigned successfully!')),
        );
        goBack(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating test: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // Removed SafeArea from here and put it inside the header Container
      // to match CreateAssignmentScreen style
      body: Column(
        children: [
          // APP BAR (Header copied from CreateAssignmentScreen)
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

                  // "Assign" Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: _createTest,
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
              padding: EdgeInsets.symmetric(
                horizontal: w * 0.05,
                vertical: h * 0.02,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    "Test Title",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: "e.g. Unit I Test",
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Class Selection
                  Text(
                    "Assign to Class",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  _classesLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedClassId,
                            isExpanded: true,
                            dropdownColor:
                                isDark ? const Color(0xFF2C2C2C) : Colors.white,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            icon: const Icon(Icons.arrow_drop_down),
                            hint: const Text("Select Class"),
                            items:
                                _myClasses.map((c) {
                                  return DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name),
                                  );
                                }).toList(),
                            onChanged: _onClassChanged,
                          ),
                        ),
                      ),
                  SizedBox(height: 20),

                  // Description
                  Text(
                    "Description / Instructions",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: "Enter details about the test...",
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Dates
                  Row(
                    children: [
                      Expanded(
                        child: _datePickerField(
                          "Start Date & Time",
                          _startDate,
                          () => _pickStartDate(context),
                          isDark,
                        ),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: _datePickerField(
                          "End Date & Time",
                          _endDate,
                          () => _pickEndDate(context),
                          isDark,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  Divider(color: Colors.grey),
                  SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Questions",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4B3FA3),
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4B3FA3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: _generateQuestionsWithAI,
                        icon: const Icon(Icons.auto_awesome, size: 16),
                        label: const Text(
                          "Gemini AI",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),

                  Row(
                    children: [
                      Text(
                        "Number of Questions: ",
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _questionCountController,
                          keyboardType: TextInputType.number,
                          onChanged: _onQuestionCountChanged,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: "e.g. 10",
                            filled: true,
                            fillColor:
                                isDark ? Colors.grey[800] : Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Question Forms
                  ListView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: _questions.length,
                    itemBuilder: (context, index) {
                      return _buildQuestionEditor(
                        index,
                        _questions[index],
                        isDark,
                      );
                    },
                  ),

                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _datePickerField(
    String label,
    DateTime? date,
    VoidCallback onTap,
    bool isDark,
  ) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date != null ? _formatDate(date) : "Select",
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionEditor(int index, _QuestionEditor editor, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 25),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withAlpha(50)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Question ${index + 1}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF4B3FA3),
            ),
          ),
          SizedBox(height: 10),
          TextField(
            controller: editor.text,
            maxLines: 2,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              labelText: "Question Text",
              border: OutlineInputBorder(),
              labelStyle: TextStyle(fontSize: 12),
            ),
          ),
          SizedBox(height: 15),
          Text(
            "Options (Select the correct answer)",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          SizedBox(height: 5),
          ...List.generate(4, (optIndex) {
            final isSelected = editor.correctOption == optIndex;
            return Container(
              margin: EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? (isDark
                            ? Colors.green.withAlpha(50)
                            : Colors.green.withAlpha(30))
                        : null,
                border: Border.all(
                  color: isSelected ? Colors.green : Colors.transparent,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 5),
              child: Row(
                children: [
                  Radio<int>(
                    value: optIndex,
                    groupValue: editor.correctOption,
                    onChanged: (val) {
                      setState(() {
                        editor.correctOption = val!;
                      });
                    },
                    activeColor: Colors.green,
                  ),
                  Expanded(
                    child: TextField(
                      controller: editor.options[optIndex],
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            "Option ${String.fromCharCode(65 + optIndex)}",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        isDense: true,
                        fillColor: isSelected ? Colors.transparent : null,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
