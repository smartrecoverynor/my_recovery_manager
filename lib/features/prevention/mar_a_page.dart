import 'package:flutter/material.dart';

import 'mar_a_data.dart';
import 'mar_a_result_page.dart';

class MarAPage extends StatefulWidget {
  const MarAPage({super.key});

  @override
  State<MarAPage> createState() => _MarAPageState();
}

class _MarAPageState extends State<MarAPage> {
  final Map<int, int> _answers = {};

  static const List<int> _values = [0, 20, 40, 60, 80, 100];

  void _submit() {
    if (_answers.length != marAQuestions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Svar på alle spørsmål før du går videre.'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            MarAResultPage(answers: Map<int, int>.from(_answers)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final answered = _answers.length;
    final total = marAQuestions.length;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        title: const Text('MAR-A'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Forventninger om mestring av risikofaktorer',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Angi hvor sikker du er på at du kan motstå '
                    'fristelsen til å drikke alkohol i hver situasjon.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    '$answered av $total besvart',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),

                  const SizedBox(height: 6),

                  LinearProgressIndicator(
                    value: answered / total,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(10),
                    backgroundColor: colors.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                itemCount: marAQuestions.length,
                itemBuilder: (context, index) {
                  final question = marAQuestions[index];
                  final selected = _answers[question.number];

                  return _QuestionCard(
                    question: question,
                    selectedValue: selected,
                    values: _values,
                    onChanged: (value) {
                      setState(() {
                        _answers[question.number] = value;
                      });
                    },
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: answered == total ? _submit : null,
                  child: const Text(
                    'Se resultat',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final MarAQuestion question;
  final int? selectedValue;
  final List<int> values;
  final ValueChanged<int> onChanged;

  const _QuestionCard({
    required this.question,
    required this.selectedValue,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${question.number}.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              question.text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: colors.onSurface,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              selectedValue == null
                  ? 'Ikke besvart'
                  : '$selectedValue % sikker',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selectedValue == null
                    ? colors.onSurfaceVariant
                    : colors.primary,
              ),
            ),

            const SizedBox(height: 8),

            Slider(
              value: (selectedValue ?? 50).toDouble(),
              min: 0,
              max: 100,
              divisions: 5,
              label: selectedValue?.toString(),
              onChanged: (value) {
                onChanged(value.round());
              },
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '0 %',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '20 %',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '40 %',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '60 %',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '80 %',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '100 %',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
