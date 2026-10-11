import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'panic_button_call_friend_config_page.dart';
import 'panic_button_image_config_page.dart';
import 'panic_button_consequences_config_page.dart';
import 'panic_button_support_cards_config_page.dart';

class PanicButtonConfigPage extends StatefulWidget {
  const PanicButtonConfigPage({super.key});

  @override
  State<PanicButtonConfigPage> createState() => _PanicButtonConfigPageState();
}

class _PanicButtonConfigPageState extends State<PanicButtonConfigPage> {
  static const String _selectedActionsKey = 'panic_button_selected_actions';

  static const int _maxSelectedActions = 4;

  final List<_PanicAction> _availableActions = const [
    _PanicAction(
      id: 'call_friend',
      title: 'Ring en venn',
      description: 'Kontakt en person du stoler på.',
      icon: Icons.phone_outlined,
    ),
    _PanicAction(
      id: 'start_exercise',
      title: 'Start en øvelse',
      description: 'Start en kort coping- eller mindfulnessøvelse.',
      icon: Icons.self_improvement_outlined,
    ),
    _PanicAction(
      id: 'show_consequences',
      title: 'Vis konsekvensliste',
      description: 'Minn deg på hvorfor du ikke vil drikke.',
      icon: Icons.list_alt_outlined,
    ),
    _PanicAction(
      id: 'show_image',
      title: 'Vis et bilde',
      description: 'Vis et bilde du har valgt som støtte.',
      icon: Icons.image_outlined,
    ),
    _PanicAction(
      id: 'show_support_cards',
      title: 'Vis støttende kort',
      description: 'Se korte påminnelser som kan hjelpe akkurat nå.',
      icon: Icons.chat_bubble_outline_rounded,
    ),
  ];

  final List<String> _selectedActionIds = [
    'call_friend',
    'start_exercise',
    'show_consequences',
    'show_image',
  ];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  Future<void> _loadConfiguration() async {
    final prefs = await SharedPreferences.getInstance();

    final savedActions = prefs.getStringList(_selectedActionsKey);

    final validActions = savedActions == null
        ? _selectedActionIds
        : savedActions
              .where((id) => _availableActions.any((action) => action.id == id))
              .take(_maxSelectedActions)
              .toList();

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedActionIds
        ..clear()
        ..addAll(validActions);

      _isLoading = false;
    });
  }

  void _toggleAction(String actionId) {
    setState(() {
      if (_selectedActionIds.contains(actionId)) {
        _selectedActionIds.remove(actionId);
        return;
      }

      if (_selectedActionIds.length >= _maxSelectedActions) {
        return;
      }

      _selectedActionIds.add(actionId);
    });
  }

  Future<void> _openActionConfiguration(String actionId) async {
    if (actionId == 'show_support_cards') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const PanicButtonSupportCardsConfigPage(),
        ),
      );
      return;
    }
    if (actionId == 'call_friend') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const PanicButtonCallFriendConfigPage(),
        ),
      );
    } else if (actionId == 'show_image') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const PanicButtonImageConfigPage(),
        ),
      );
    } else if (actionId == 'show_consequences') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const PanicButtonConsequencesConfigPage(),
        ),
      );
    } else if (actionId == 'show_support_cards') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const PanicButtonSupportCardsConfigPage(),
        ),
      );
    }
  }

  bool _hasSeparateConfiguration(String actionId) {
    return actionId == 'call_friend' ||
        actionId == 'show_image' ||
        actionId == 'show_consequences' ||
        actionId == 'show_support_cards';
  }

  void _handleActionTap(String actionId) {
    _toggleAction(actionId);
  }

  Future<void> _saveConfiguration() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(_selectedActionsKey, _selectedActionIds);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Konfigurer panic button')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final selectedCount = _selectedActionIds.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Konfigurer panic button')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Panic button',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Velg hvilke handlinger som skal være '
                      'tilgjengelige når du trykker på Hjelp!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.62),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '$selectedCount av $_maxSelectedActions valgt',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF176477),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ..._availableActions.map(
                      (action) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildActionCard(
                          action,
                          selected: _selectedActionIds.contains(action.id),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Du kan velge opptil fire handlinger. '
                      'Flere handlinger kan bli lagt til senere.',
                      style: TextStyle(color: Colors.grey, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saveConfiguration,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: const Text('Lagre'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(_PanicAction action, {required bool selected}) {
    const accentColor = Color(0xFF7A5AF8);
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _handleActionTap(action.id),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? accentColor
                  : colors.outline.withValues(alpha: 0.8),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected
                      ? (Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF302A4F)
                          : const Color(0xFFF0ECFF))
                      : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  action.icon,
                  color: selected ? accentColor : Colors.grey.shade600,
                  size: 23,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      action.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurface.withValues(alpha: 0.62),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => _toggleAction(action.id),
                tooltip: selected ? 'Avvelg' : 'Velg',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                icon: selected
                    ? const Icon(Icons.check_circle_rounded, color: accentColor)
                    : Icon(
                        Icons.circle_outlined,
                        color: colors.onSurface.withValues(alpha: 0.38),
                      ),
              ),
              if (_hasSeparateConfiguration(action.id))
                IconButton(
                  onPressed: () => _openActionConfiguration(action.id),
                  tooltip: 'Konfigurer',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 44,
                  ),
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    color: colors.onSurface.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanicAction {
  final String id;
  final String title;
  final String description;
  final IconData icon;

  const _PanicAction({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}
