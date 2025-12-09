import 'package:flutter/material.dart';
import '../widgets/tutor_bottom_nav.dart';

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

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Topic name"),
          content: SizedBox(
            width: w * 0.8,
            child: TextField(
              controller: _pointsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "Enter topic name",
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
                    const Text(
                      "Material title (required)",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
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
                            "Add topic",
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
