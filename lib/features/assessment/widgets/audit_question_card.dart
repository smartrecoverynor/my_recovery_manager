import 'package:flutter/material.dart';

import '../../../core/widgets/info_icon.dart';
import '../models/audit_question.dart';

class AuditQuestionCard extends StatelessWidget {
  final AuditQuestion question;
  final int? selectedAnswerIndex;
  final ValueChanged<int> onAnswerSelected;

  const AuditQuestionCard({
    super.key,
    required this.question,
    required this.selectedAnswerIndex,
    required this.onAnswerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                question.question,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (question.question.contains('Hvor mange alkoholenheter'))
              const InfoIcon(
                title: 'Hva er én alkoholenhet?',
                message:
                    'Én alkoholenhet tilsvarer omtrent:\n\n'
                    '• 0,33 liter øl\n'
                    '• 12–14 cl vin\n'
                    '• 4 cl brennevin',
              ),
            if (question.question.contains('seks alkoholenheter'))
              const InfoIcon(
                title: 'Hva tilsvarer seks alkoholenheter?',
                message:
                    'Omtrent:\n\n'
                    '• 4 halvlitere øl\n'
                    '• 1 flaske vin (75 cl)\n'
                    '• 1/3 flaske brennevin (70 cl)',
              ),
            if (question.question.contains('blitt skadet'))
              const InfoIcon(
                title: 'Hva menes med skade?',
                message:
                    'Skade kan være både fysisk og psykisk. '
                    'Eksempler kan være ulykker, fall, vold eller forverring av psykiske plager som angst eller depresjon.',
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...List<Widget>.generate(question.answers.length, (index) {
          return RadioListTile<int>(
            title: Text(question.answers[index]),
            value: index,
            groupValue: selectedAnswerIndex,
            onChanged: (value) {
              if (value != null) onAnswerSelected(value);
            },
          );
        }),
      ],
    );
  }
}
