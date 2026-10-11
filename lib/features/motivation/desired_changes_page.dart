import 'package:flutter/material.dart';

class DesiredChangesPage extends StatefulWidget {
  const DesiredChangesPage({super.key});

  @override
  State<DesiredChangesPage> createState() => _DesiredChangesPageState();
}

class _DesiredChangesPageState extends State<DesiredChangesPage> {
  final List<_DesiredChange> _changes = [];

  void _showInfo() {
    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        return AlertDialog(
          title: const Text('Ønskede endringer'),
          content: Text(
            'Se for deg hva som vil endre seg til det bedre '
                'i livet ditt dersom du gjennomfører den ønskede '
                'endringen i alkoholbruk. Vær så konkret du kan.\n\n'
                '«Bedre helse» og «Bedre forhold til familien» '
                'er eksempler på lite konkrete endringer.\n\n'
                '«Jeg vil ha mindre skyldfølelse» og «Min partner '
                'vil kunne stole på meg» er eksempler på mer '
                'konkrete endringer.',
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: colorScheme.onSurface,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Lukk'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addChange() async {
    final result = await showDialog<_DesiredChange>(
      context: context,
      builder: (context) => const _AddDesiredChangeDialog(),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _changes.add(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ønskede endringer'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'Ønskede endringer',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: _showInfo,
                    icon: Icon(
                      Icons.info_outline,
                      size: 26,
                      color: colorScheme.primary,
                    ),
                    tooltip: 'Informasjon',
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                'Hva ønsker du skal bli annerledes '
                    'i livet ditt?',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _addChange,
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Legg til ønsket endring',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Expanded(
                child: _changes.isEmpty
                    ? Center(
                  child: Text(
                    'Ingen ønskede endringer registrert ennå.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
                    : ListView(
                  children: _changes.map((change) {
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: Icon(
                          Icons.flag_outlined,
                          color: colorScheme.primary,
                        ),
                        title: Text(change.text),
                        subtitle: Text(
                          'Viktighet: '
                              '${change.importance}/10',
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesiredChange {
  final String text;
  final int importance;

  const _DesiredChange({
    required this.text,
    required this.importance,
  });
}

class _AddDesiredChangeDialog extends StatefulWidget {
  const _AddDesiredChangeDialog();

  @override
  State<_AddDesiredChangeDialog> createState() =>
      _AddDesiredChangeDialogState();
}

class _AddDesiredChangeDialogState extends State<_AddDesiredChangeDialog> {
  final TextEditingController _controller = TextEditingController();

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

    Navigator.of(
      context,
    ).pop(
      _DesiredChange(
        text: text,
        importance: _importance.round(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Legg til ønsket endring'),

      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hva ønsker du skal bli annerledes?',
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
                hintText: 'Skriv inn en ønsket endring...',
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