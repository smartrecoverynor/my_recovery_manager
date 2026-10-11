import 'package:flutter/material.dart';

import 'mar_a_data.dart';

class MarAResultPage extends StatelessWidget {
  final Map<int, int> answers;

  const MarAResultPage({super.key, required this.answers});

  List<_SubscaleResult> _calculateResults() {
    final grouped = <String, List<int>>{};

    for (final question in marAQuestions) {
      grouped.putIfAbsent(question.subscale, () => []);

      grouped[question.subscale]!.add(answers[question.number] ?? 0);
    }

    final results = grouped.entries.map((entry) {
      final values = entry.value;

      final rawScore = values.fold<int>(0, (sum, value) => sum + value);

      final scaledScore = rawScore / values.length;

      return _SubscaleResult(
        name: entry.key,
        rawScore: rawScore,
        scaledScore: scaledScore,
        questionCount: values.length,
      );
    }).toList();

    results.sort((a, b) => a.scaledScore.compareTo(b.scaledScore));

    return results;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final results = _calculateResults();

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        title: const Text('MAR-A resultat'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Dine resultater',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Resultatene er rangert fra lavest til høyest '
                  'skalert skåre.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Lavere skåre betyr at du er mindre sikker på '
                    'at du kan motstå fristelsen til å drikke i '
                    'disse situasjonene.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: colors.onPrimaryContainer,
                ),
              ),
            ),

            const SizedBox(height: 28),

            ...results.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final result = entry.value;

              return _ResultCard(
                rank: rank,
                result: result,
              );
            }),

            const SizedBox(height: 16),

            Text(
              'Skalert skåre er gjennomsnittet av svarene '
                  'på spørsmålene som inngår i hver subskala.',
              style: TextStyle(
                fontSize: 13,
                color: colors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscaleResult {
  final String name;
  final int rawScore;
  final double scaledScore;
  final int questionCount;

  const _SubscaleResult({
    required this.name,
    required this.rawScore,
    required this.scaledScore,
    required this.questionCount,
  });
}

class _ResultCard extends StatelessWidget {
  final int rank;
  final _SubscaleResult result;

  const _ResultCard({
    required this.rank,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final score = result.scaledScore.round();

    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Text(
                    result.name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                ),

                Text(
                  '$score',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 8,
                backgroundColor: colors.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  colors.primary,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Skalert skåre: $score / 100',
              style: TextStyle(
                fontSize: 13,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}