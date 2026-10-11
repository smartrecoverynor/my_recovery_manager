import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PanicButtonConsequencesConfigPage extends StatefulWidget {
  const PanicButtonConsequencesConfigPage({super.key});

  @override
  State<PanicButtonConsequencesConfigPage> createState() =>
      _PanicButtonConsequencesConfigPageState();
}

class _PanicButtonConsequencesConfigPageState
    extends State<PanicButtonConsequencesConfigPage> {
  static const String _storageKey = 'panic_button_consequences';

  final List<String> _consequences = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConsequences();
  }

  Future<void> _loadConsequences() async {
    try {
      final preferences = await SharedPreferences.getInstance();

      final saved = preferences.getStringList(_storageKey);

      if (!mounted) {
        return;
      }

      setState(() {
        _consequences
          ..clear()
          ..addAll(saved ?? []);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kunne ikke laste konsekvenslisten: $e',
          ),
        ),
      );
    }
  }

  Future<void> _saveConsequences() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setStringList(
      _storageKey,
      List<String>.from(_consequences),
    );
  }

  Future<void> _addConsequence() async {
    final result = await _showConsequenceDialog();

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _consequences.add(result);
    });

    await _saveConsequences();
  }

  Future<void> _editConsequence(int index) async {
    final result = await _showConsequenceDialog(
      initialText: _consequences[index],
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _consequences[index] = result;
    });

    await _saveConsequences();
  }

  Future<void> _deleteConsequence(int index) async {

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Slett påminnelse?'),
          content: Text(
            'Vil du slette "${_consequences[index]}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Avbryt'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text(
                'Slett',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _consequences.removeAt(index);
    });

    await _saveConsequences();
  }

  Future<String?> _showConsequenceDialog({
    String? initialText,
  }) async {
    final controller = TextEditingController(
      text: initialText ?? '',
    );

    var text = initialText ?? '';

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final colors = Theme.of(context).colorScheme;

            return AlertDialog(
              title: Text(
                initialText == null
                    ? 'Ny påminnelse'
                    : 'Rediger påminnelse',
              ),
              content: TextField(
                controller: controller,
                autofocus: true,
                maxLength: 120,
                maxLines: 3,
                textCapitalization:
                TextCapitalization.sentences,
                style: TextStyle(
                  color: colors.onSurface,
                ),
                decoration: InputDecoration(
                  hintText:
                  'F.eks. Jeg kommer til å angre i kveld.',
                  hintStyle: TextStyle(
                    color: colors.onSurface.withValues(
                      alpha: 0.5,
                    ),
                  ),
                  filled: true,
                  fillColor: colors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: colors.outline,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: colors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
                onChanged: (value) {
                  setDialogState(() {
                    text = value;
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Avbryt'),
                ),
                FilledButton(
                  onPressed: text.trim().isEmpty
                      ? null
                      : () {
                    Navigator.of(dialogContext).pop(
                      text.trim(),
                    );
                  },
                  child: const Text('Lagre'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vis konsekvensliste'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addConsequence,
        icon: const Icon(Icons.add),
        label: const Text('Legg til'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            24,
            20,
            100,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'Dine påminnelser',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Skriv korte ting du ønsker å bli minnet '
                    'på når du får lyst til å drikke akkurat nå.',
                style: TextStyle(
                  fontSize: 16,
                  color: colors.onSurface.withValues(
                    alpha: 0.65,
                  ),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              if (_consequences.isEmpty)
                _buildEmptyState()
              else
                ...List.generate(
                  _consequences.length,
                      (index) {
                    return _buildConsequenceCard(
                      index,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.outline.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.list_alt_outlined,
            size: 42,
            color: colors.onSurface.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 12),
          Text(
            'Ingen påminnelser ennå',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Legg til noen korte og konkrete påminnelser '
                'som kan hjelpe deg når suget kommer.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurface.withValues(alpha: 0.6),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsequenceCard(int index) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colors.outline.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          14,
          8,
          14,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _consequences[index],
                style: TextStyle(
                  fontSize: 16,
                  height: 1.35,
                  color: colors.onSurface,
                ),
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _editConsequence(index);
                } else if (value == 'delete') {
                  _deleteConsequence(index);
                }
              },
              itemBuilder: (context) {
                return const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Rediger'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Slett'),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
}