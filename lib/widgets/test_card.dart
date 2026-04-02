import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import '../Student/take_test.dart';
import '../widgets/nav_helper.dart';

class TestCard extends StatelessWidget {
  final TestInfo test;
  final TestSubmission? submission;
  final String tutorName;
  final VoidCallback? onReload;

  const TestCard({
    super.key,
    required this.test,
    this.submission,
    this.tutorName = 'Tutor',
    this.onReload,
  });

  static const Color _cardBg = Color(0xFFF6F6F8);
  static const Color _borderPurple = Color(0xFF5B5AB8);
  static const Color _textDark = Color(0xFF1C1C1E);
  static const Color _textMuted = Color(0xFF4D4D52);
  static const Color _buttonPurple = Color(0xFF8F91F2);

  String _formatDateTimeShort(DateTime date) {
    final local = date.toLocal();
    final shortYear = (local.year % 100).toString().padLeft(2, '0');
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')} ${local.day.toString().padLeft(2, '0')}-${local.month.toString().padLeft(2, '0')}-$shortYear';
  }

  String _compactDuration(int minutes) {
    if (minutes <= 0) return '0 min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m == 0) return '$h hr';
    if (h > 0) return '$h hr ${m}m';
    return '$m min';
  }

  String _compactCountdown(DateTime? target, bool upcoming) {
    if (target == null) return 'Schedule not set';
    final diff = target.difference(DateTime.now());
    if (diff.isNegative) return upcoming ? 'Starts now' : 'Expired';
    final days = diff.inDays;
    final hours = diff.inHours.remainder(24);
    final mins = diff.inMinutes.remainder(60);
    if (upcoming) return 'Starts in ${days}days,${hours} hrs,${mins} mins';
    return 'Test expires in ${days}days,${hours} hrs,${mins} mins';
  }

  Widget _barItem({
    required IconData icon,
    required String value,
    required bool divider,
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: _textDark),
                const SizedBox(width: 4),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (divider)
            Container(
              width: 1.2,
              height: 22,
              color: _borderPurple.withOpacity(0.45),
            ),
        ],
      ),
    );
  }

  Widget _segmentedBar(List<Widget> children) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _borderPurple, width: 1.8),
      ),
      child: Row(children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final now = DateTime.now();
    final isNarrow = w < 700;

    final hasSubmitted = submission != null;
    final isExpired =
        test.endDate != null && now.isAfter(test.endDate!.toLocal());
    final isUpcoming =
        test.startDate != null && now.isBefore(test.startDate!.toLocal());

    String btnText;
    VoidCallback? onTap;
    if (hasSubmitted) {
      btnText =
          'Submitted (${submission!.score}/${submission!.totalQuestions})';
    } else if (isExpired) {
      btnText = 'Expired';
    } else if (isUpcoming) {
      btnText = 'Not Started';
    } else {
      btnText = 'Ready to Begin';
      onTap = () {
        goPush(context, TakeTestScreen(test: test)).then((_) {
          if (onReload != null) onReload!();
        });
      };
    }

    final startText =
        test.startDate != null
            ? _formatDateTimeShort(test.startDate!)
            : 'Not set';
    final endText =
        test.endDate != null ? _formatDateTimeShort(test.endDate!) : 'Not set';
    final durationText =
        test.durationMinutes != null
            ? _compactDuration(test.durationMinutes!)
            : 'N/A';
    final marksText = test.totalMarks != null ? '${test.totalMarks} M' : 'N/A';
    final questionsText = '${test.questions.length} Q';
    final assignedText = '${test.assignedTo.length}';

    final leftTitle = tutorName;
    final leftSub = test.course.isNotEmpty ? test.course : 'General';
    final rightTitle = test.title;
    final rightSub =
        test.unitName.isNotEmpty
            ? test.unitName
            : (test.course.isNotEmpty ? test.course : 'Unit');

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860, minHeight: 280),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _borderPurple, width: 2.4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(w * 0.045, 12, w * 0.045, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.person, size: 30, color: _textDark),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            leftTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            leftSub,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 250),
                          child: Text(
                            rightTitle,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _textDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rightSub,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _textDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(
                color: _textMuted.withOpacity(0.25),
                thickness: 1.2,
                height: 1.2,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(w * 0.045, 10, w * 0.045, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Start Time :$startText',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: _textDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'End Time :$endText',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: _textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(w * 0.04, 3, w * 0.04, 10),
                child:
                    isNarrow
                        ? Column(
                          children: [
                            _segmentedBar([
                              _barItem(
                                icon: Icons.schedule_rounded,
                                value: durationText,
                                divider: true,
                                flex: 3,
                              ),
                              _barItem(
                                icon: Icons.help_outline_rounded,
                                value: questionsText,
                                divider: true,
                                flex: 3,
                              ),
                              _barItem(
                                icon: Icons.check_circle,
                                value: marksText,
                                divider: false,
                                flex: 3,
                              ),
                            ]),
                            const SizedBox(height: 8),
                            _segmentedBar([
                              _barItem(
                                icon: Icons.groups,
                                value: assignedText,
                                divider: true,
                                flex: 3,
                              ),
                              _barItem(
                                icon: Icons.check_circle_outline,
                                value: hasSubmitted ? '1' : '0',
                                divider: true,
                                flex: 2,
                              ),
                              _barItem(
                                icon: Icons.block,
                                value: isExpired && !hasSubmitted ? '1' : '0',
                                divider: true,
                                flex: 2,
                              ),
                              _barItem(
                                icon: Icons.schedule,
                                value: isUpcoming ? '1' : '0',
                                divider: false,
                                flex: 2,
                              ),
                            ]),
                          ],
                        )
                        : Row(
                          children: [
                            Expanded(
                              child: _segmentedBar([
                                _barItem(
                                  icon: Icons.schedule_rounded,
                                  value: durationText,
                                  divider: true,
                                  flex: 3,
                                ),
                                _barItem(
                                  icon: Icons.help_outline_rounded,
                                  value: questionsText,
                                  divider: true,
                                  flex: 3,
                                ),
                                _barItem(
                                  icon: Icons.check_circle,
                                  value: marksText,
                                  divider: false,
                                  flex: 3,
                                ),
                              ]),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _segmentedBar([
                                _barItem(
                                  icon: Icons.groups,
                                  value: assignedText,
                                  divider: true,
                                  flex: 3,
                                ),
                                _barItem(
                                  icon: Icons.check_circle_outline,
                                  value: hasSubmitted ? '1' : '0',
                                  divider: true,
                                  flex: 2,
                                ),
                                _barItem(
                                  icon: Icons.block,
                                  value: isExpired && !hasSubmitted ? '1' : '0',
                                  divider: true,
                                  flex: 2,
                                ),
                                _barItem(
                                  icon: Icons.schedule,
                                  value: isUpcoming ? '1' : '0',
                                  divider: false,
                                  flex: 2,
                                ),
                              ]),
                            ),
                          ],
                        ),
              ),
              Divider(
                color: _textMuted.withOpacity(0.25),
                thickness: 1.2,
                height: 1.2,
              ),
              const SizedBox(height: 10),
              Text(
                _compactCountdown(test.endDate, isUpcoming),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 230,
                height: 46,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        onTap == null ? Colors.grey.shade500 : _buttonPurple,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: Text(
                    onTap == null ? btnText : 'Begin Challenge',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
