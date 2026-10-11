import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../data/repositories/situation_repository.dart';
import 'situation.dart';
import 'situation_experience_page.dart';

class MySituationsPage extends StatefulWidget {
  const MySituationsPage({super.key});

  @override
  State<MySituationsPage> createState() => _MySituationsPageState();
}

class _MySituationsPageState extends State<MySituationsPage> {
  final SituationRepository _situationRepository = SituationRepository();

  List<Situation> _situations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSituations();
  }

  Future<void> _loadSituations() async {
    try {
      final situations = await _situationRepository.getAll(
        userId: 'local-user',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _situations = situations;
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
        SnackBar(content: Text('Kunne ikke hente situasjonene: $e')),
      );
    }
  }

  Future<void> _addSituation() async {
    final result = await showDialog<_SituationFormResult>(
      context: context,
      builder: (context) => const _SituationDialog(),
    );

    if (result == null || !mounted) {
      return;
    }

    final now = DateTime.now();

    final situation = Situation(
      id: const Uuid().v4(),
      userId: 'local-user',
      text: result.text,
      category: result.category,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await _situationRepository.save(situation);

      await _loadSituations();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunne ikke lagre situasjonen: $e')),
      );
    }
  }

  Future<void> _showExperiences(Situation situation) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SituationExperiencePage(situation: situation),
      ),
    );
  }

  Future<void> _editSituation(int index) async {
    final situation = _situations[index];

    final result = await showDialog<_SituationFormResult>(
      context: context,
      builder: (context) => _SituationDialog(initialSituation: situation),
    );

    if (result == null || !mounted) {
      return;
    }

    final updatedSituation = Situation(
      id: situation.id,
      userId: situation.userId,
      text: result.text,
      category: result.category,
      createdAt: situation.createdAt,
      updatedAt: DateTime.now(),
    );

    try {
      await _situationRepository.save(updatedSituation);

      await _loadSituations();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunne ikke oppdatere situasjonen: $e')),
      );
    }
  }

  Future<void> _deleteSituation(int index) async {
    final situation = _situations[index];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;

        return AlertDialog(
          title: const Text('Slett situasjon?'),
          content: Text('Vil du slette «${situation.text}»?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Avbryt'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(
                'Slett',
                style: TextStyle(color: colors.error),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await _situationRepository.delete(situation.id);

      await _loadSituations();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunne ikke slette situasjonen: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final red = _situations
        .where((item) => item.category == SituationCategory.red)
        .toList();

    final yellow = _situations
        .where((item) => item.category == SituationCategory.yellow)
        .toList();

    final green = _situations
        .where((item) => item.category == SituationCategory.green)
        .toList();

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        title: const Text('Mine situasjoner'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isLoading
              ? Center(
            child: CircularProgressIndicator(
              color: colors.primary,
            ),
          )
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mine situasjoner',
                style:
                Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Lag din egen oversikt over situasjoner '
                    'og aktiviteter som kan påvirke alkoholbruken din.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _addSituation,
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Legg til situasjon',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadSituations,
                  child: ListView(
                    children: [
                      _buildSection(
                        context,
                        title: 'Rødt',
                        subtitle: 'Situasjoner jeg bør unngå',
                        items: red,
                        color: colors.error,
                        icon: Icons.block,
                      ),

                      const SizedBox(height: 24),

                      _buildSection(
                        context,
                        title: 'Gult',
                        subtitle:
                        'Situasjoner hvor jeg bør være på vakt / ha en plan',
                        items: yellow,
                        color: colors.tertiary,
                        icon: Icons.warning_amber_rounded,
                      ),

                      const SizedBox(height: 24),

                      _buildSection(
                        context,
                        title: 'Grønt',
                        subtitle:
                        'Forebyggende / positive aktiviteter',
                        items: green,
                        color: colors.primary,
                        icon: Icons.check_circle_outline,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, {
        required String title,
        required String subtitle,
        required List<Situation> items,
        required Color color,
        required IconData icon,
      }) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),

            const SizedBox(width: 8),

            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: colors.onSurfaceVariant,
          ),
        ),

        const SizedBox(height: 12),

        if (items.isEmpty)
          Text(
            'Ingen registrerte ennå.',
            style: TextStyle(
              color: colors.onSurfaceVariant,
            ),
          )
        else
          ...items.map((item) {
            final index = _situations.indexOf(item);

            return Card(
              elevation: 0,
              color: colors.surfaceContainerLow,
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Icon(icon, color: color),
                title: Text(
                  item.text,
                  style: TextStyle(
                    color: colors.onSurface,
                  ),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'experiences') {
                      _showExperiences(item);
                    } else if (value == 'edit') {
                      _editSituation(index);
                    } else if (value == 'delete') {
                      _deleteSituation(index);
                    }
                  },
                  itemBuilder: (context) {
                    final items = <PopupMenuEntry<String>>[];

                    if (item.category == SituationCategory.yellow) {
                      items.add(
                        const PopupMenuItem<String>(
                          value: 'experiences',
                          child: Row(
                            children: [
                              Icon(Icons.history_outlined),
                              SizedBox(width: 10),
                              Text('Erfaringer'),
                            ],
                          ),
                        ),
                      );
                    }

                    items.add(
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined),
                            SizedBox(width: 10),
                            Text('Rediger'),
                          ],
                        ),
                      ),
                    );

                    items.add(
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 10),
                            const Text('Slett'),
                          ],
                        ),
                      ),
                    );

                    return items;
                  },
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _SituationFormResult {
  final String text;
  final SituationCategory category;

  const _SituationFormResult({
    required this.text,
    required this.category,
  });
}

class _SituationDialog extends StatefulWidget {
  final Situation? initialSituation;

  const _SituationDialog({this.initialSituation});

  @override
  State<_SituationDialog> createState() => _SituationDialogState();
}

class _SituationDialogState extends State<_SituationDialog> {
  late final TextEditingController _controller;
  late SituationCategory _category;

  bool get _isEditing => widget.initialSituation != null;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.initialSituation?.text ?? '',
    );

    _category =
        widget.initialSituation?.category ?? SituationCategory.yellow;
  }

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
    ).pop(_SituationFormResult(text: text, category: _category));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(_isEditing ? 'Rediger situasjon' : 'Legg til situasjon'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hva vil du legge til?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: _controller,
              autofocus: !_isEditing,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Skriv inn en situasjon eller aktivitet...',
                filled: true,
                fillColor: colors.surfaceContainerHighest,
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
                    color: colors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Velg kategori',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 12),

            _buildCategoryOption(
              category: SituationCategory.red,
              title: 'Rødt',
              description: 'Situasjoner jeg bør unngå',
              color: colors.error,
              icon: Icons.block,
            ),

            _buildCategoryOption(
              category: SituationCategory.yellow,
              title: 'Gult',
              description: 'Vær på vakt / ha en plan',
              color: colors.tertiary,
              icon: Icons.warning_amber_rounded,
            ),

            _buildCategoryOption(
              category: SituationCategory.green,
              title: 'Grønt',
              description: 'Forebyggende / positiv aktivitet',
              color: colors.primary,
              icon: Icons.check_circle_outline,
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
          child: Text(_isEditing ? 'Lagre endringer' : 'Lagre'),
        ),
      ],
    );
  }

  Widget _buildCategoryOption({
    required SituationCategory category,
    required String title,
    required String description,
    required Color color,
    required IconData icon,
  }) {
    final colors = Theme.of(context).colorScheme;
    final selected = _category == category;

    return InkWell(
      onTap: () {
        setState(() {
          _category = category;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : colors.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? color : colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}