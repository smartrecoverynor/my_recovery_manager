import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/assessment_header.dart';
import '../recommendation/models/mrm_cra_assessment.dart';
import 'data/audit_questions.dart';
import 'widgets/audit_question_card.dart';

/// Leder brukeren gjennom AUDIT-kartleggingen.
class AssessmentPage extends StatefulWidget {
  final MrmCraAssessment? assessment;

  const AssessmentPage({super.key, this.assessment});

  @override
  State<AssessmentPage> createState() => _AssessmentPageState();
}

class _AssessmentPageState extends State<AssessmentPage> {
  int _currentQuestion = 0;
  late final MrmCraAssessment _assessment;

  @override
  void initState() {
    super.initState();
    _assessment = widget.assessment ??
        MrmCraAssessment(
          auditInterpretationCategory:
              AuditInterpretationCategory.otherOrUnspecified,
        );
  }

  int? _selectedAnswerIndexForCurrentQuestion() {
    final score = _assessment.auditScores[_currentQuestion];
    if (score == null) return null;

    // AUDIT spørsmål 1–8 gir 0–4 poeng; spørsmål 9–10 gir 0, 2 eller 4.
    return _currentQuestion < 8 ? score : score ~/ 2;
  }

  void _continue() {
    if (_assessment.auditScores[_currentQuestion] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Velg et svar før du går videre.')),
      );
      return;
    }

    if (_currentQuestion < auditQuestions.length - 1) {
      setState(() {
        _currentQuestion++;
      });
      return;
    }

    if (!_assessment.auditComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Svar på alle spørsmålene før du fullfører.')),
      );
      return;
    }

    context.go('/motivation', extra: _assessment);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kartlegging')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AssessmentHeader(
                step: 'Steg 1 av 5',
                title: 'AUDIT',
                description:
                    'Svar så ærlig som mulig. Det finnes ingen riktige eller gale svar.',
              ),
              Text(
                'Spørsmål ${_currentQuestion + 1} av ${auditQuestions.length}',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: AuditQuestionCard(
                    question: auditQuestions[_currentQuestion],
                    selectedAnswerIndex:
                        _selectedAnswerIndexForCurrentQuestion(),
                    onAnswerSelected: (answerIndex) {
                      setState(() {
                        _assessment.setAuditAnswer(
                          questionIndex: _currentQuestion,
                          answerIndex: answerIndex,
                        );
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _currentQuestion == 0
                          ? null
                          : () {
                              setState(() {
                                _currentQuestion--;
                              });
                            },
                      child: const Text('Forrige'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _continue,
                      child: Text(
                        _currentQuestion == auditQuestions.length - 1
                            ? 'Fullfør'
                            : 'Neste',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
