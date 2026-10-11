import 'package:flutter/material.dart';

class ConsequenceListPage extends StatefulWidget {
  const ConsequenceListPage({super.key});

  @override
  State<ConsequenceListPage> createState() => _ConsequenceListPageState();
}

class _ConsequenceListPageState extends State<ConsequenceListPage> {
  final List<_Consequence> _consequences = [];

  Future<void> _addConsequence() async {
    final result = await showDialog<_Consequence>(
      context: context,
      builder: (context) => const _AddConsequenceDialog(),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _consequences.add(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final positive = _consequences
        .where((item) => item.type == ConsequenceType.positive)
        .toList();

    final negative = _consequences
        .where((item) => item.type == ConsequenceType.negative)
        .toList();

    final positiveSum = positive.fold<int>(
      0,
          (sum, item) => sum + item.importance,
    );

    final negativeSum = negative.fold<int>(
      0,
          (sum, item) => sum + item.importance,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Konsekvensliste'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Konsekvensliste',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Hva opplever du at alkoholen gir deg, '
                    'og hva opplever du at den koster deg?',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'Gir meg',
                      value: positiveSum,
                      color: colorScheme.primary,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _buildSummaryCard(
                      title: 'Koster meg',
                      value: negativeSum,
                      color: colorScheme.error,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _addConsequence,
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Legg til konsekvens',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Expanded(
                child: ListView(
                  children: [
                    _buildSection(
                      title: 'Noe alkoholen gir meg',
                      items: positive,
                      icon: Icons.add_circle_outline,
                    ),

                    const SizedBox(height: 28),

                    _buildSection(
                      title: 'Noe alkoholen koster meg',
                      items: negative,
                      icon: Icons.remove_circle_outline,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required int value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            'samlet viktighet',
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<_Consequence> items,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        if (items.isEmpty)
          Text(
            'Ingen registrerte ennå.',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
            ),
          )
        else
          ...items.map(
                (item) => Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Icon(
                  icon,
                  color: colorScheme.primary,
                ),
                title: Text(item.text),
                subtitle: Text(
                  'Viktighet: ${item.importance}/10',
                ),
              ),
            ),
          ),
      ],
    );
  }
}

enum ConsequenceType { positive, negative }

class _Consequence {
  final String text;
  final ConsequenceType type;
  final int importance;

  const _Consequence({
    required this.text,
    required this.type,
    required this.importance,
  });
}

class _AddConsequenceDialog extends StatefulWidget {
  const _AddConsequenceDialog();

  @override
  State<_AddConsequenceDialog> createState() => _AddConsequenceDialogState();
}

class _AddConsequenceDialogState extends State<_AddConsequenceDialog> {
  final TextEditingController _controller = TextEditingController();

  ConsequenceType _type = ConsequenceType.positive;
  double _importance = 5;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final text = _controller.text.trim();

    if (text.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      _Consequence(
        text: text,
        type: _type,
        importance: _importance.round(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: const Text('Legg til konsekvens'),

      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hva er konsekvensen?',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Skriv inn en konsekvens...',
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Dette er noe alkoholen:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            SegmentedButton<ConsequenceType>(
              segments: const [
                ButtonSegment<ConsequenceType>(
                  value: ConsequenceType.positive,
                  label: Text('Gir meg'),
                  icon: Icon(Icons.add),
                ),
                ButtonSegment<ConsequenceType>(
                  value: ConsequenceType.negative,
                  label: Text('Koster meg'),
                  icon: Icon(Icons.remove),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (selection) {
                setState(() {
                  _type = selection.first;
                });
              },
            ),

            const SizedBox(height: 24),

            const Text(
              'Hvor viktig er dette for deg?',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 4),

            Center(
              child: Text(
                _importance.round().toString(),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),

            Slider(
              value: _importance,
              min: 1,
              max: 10,
              divisions: 9,
              label: _importance.round().toString(),
              onChanged: (value) {
                setState(() {
                  _importance = value;
                });
              },
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '1',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '10',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ikke særlig viktig',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Svært viktig',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Avbryt'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Lagre'),
        ),
      ],
    );
  }
}