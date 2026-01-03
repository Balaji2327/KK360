import 'package:flutter/material.dart';
import '../widgets/tutor_bottom_nav.dart';
import '../widgets/nav_helper.dart';

class CreateMaterialScreen extends StatefulWidget {
  const CreateMaterialScreen({super.key});

  @override
  State<CreateMaterialScreen> createState() => _CreateMaterialScreenState();
}

class _CreateMaterialScreenState extends State<CreateMaterialScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController();

  String? _savedPoints;
  // DateTime? _dueDate;

  @override
  void dispose() {
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  // String _formatDate(DateTime d) {
  //   return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
  // }

  Future<void> _showPointsDialog(
    BuildContext context,
    double w,
    double h,
  ) async {
    _pointsController.text = _savedPoints ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          title: Text(
            "Topic name",
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
          content: SizedBox(
            width: w * 0.8,
            child: TextField(
              controller: _pointsController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Enter topic name",
                hintStyle: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey,
                ),
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isDark ? Colors.white24 : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                goBack(ctx);
              },
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
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
                goBack(ctx);
              },
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Future<void> _pickDueDate(BuildContext context) async {
  //   final now = DateTime.now();
  //   final picked = await showDatePicker(
  //     context: context,
  //     initialDate: _dueDate ?? now,
  //     firstDate: DateTime(now.year - 5),
  //     lastDate: DateTime(now.year + 5),
  //   );

  //   if (picked != null) {
  //     setState(() {
  //       _dueDate = picked;
  //     });
  //   }
  // }

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
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: w * 0.05,
                      vertical: h * 0.008,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      "Post",
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
                    Text(
                      "Material title (required)",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(height: h * 0.02),

                    Row(
                      children: [
                        _chip("Mathematics"),
                        SizedBox(width: w * 0.02),
                        _chip("All students"),
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
                              maxLines: 3,
                              minLines: 3,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
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
                    Row(
                      children: [
                        Icon(
                          Icons.attachment,
                          size: 22,
                          color: isDark ? Colors.white70 : Colors.black,
                        ),
                        SizedBox(width: w * 0.02),
                        Text(
                          "Add attachment",
                          style: TextStyle(
                            fontSize: 15,
                            color:
                                isDark
                                    ? const Color(0xFF8F85FF)
                                    : const Color(0xFF4B3FA3),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: h * 0.015),
                    Divider(color: isDark ? Colors.white24 : Colors.grey),
                    SizedBox(height: h * 0.015),

                    // TOTAL POINTS
                    InkWell(
                      onTap: () => _showPointsDialog(context, w, h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Add topic",
                            style: TextStyle(
                              color:
                                  isDark
                                      ? const Color(0xFF8F85FF)
                                      : const Color(0xFF4B3FA3),
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
                                        ? Colors.grey.shade800
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

                    // DUE DATE
                    // InkWell(
                    //   onTap: () => _pickDueDate(context),
                    //   child: Row(
                    //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //     children: [
                    //       Text(
                    //         "Set due date",
                    //         style: TextStyle(
                    //           color: const Color(0xFF4B3FA3),
                    //           fontSize: 15,
                    //           fontWeight: FontWeight.w500,
                    //         ),
                    //       ),
                    //       if (_dueDate != null)
                    //         Container(
                    //           padding: const EdgeInsets.symmetric(
                    //             horizontal: 10,
                    //             vertical: 6,
                    //           ),
                    //           decoration: BoxDecoration(
                    //             color: Colors.grey.shade200,
                    //             borderRadius: BorderRadius.circular(6),
                    //             border: Border.all(color: Colors.black12),
                    //           ),
                    //           child: Text(
                    //             _formatDate(_dueDate!),
                    //             style: const TextStyle(
                    //               fontWeight: FontWeight.w600,
                    //             ),
                    //           ),
                    //         ),
                    //     ],
                    //   ),
                    // ),
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
