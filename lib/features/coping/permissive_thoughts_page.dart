import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissiveThoughtsPage extends StatefulWidget {
  const PermissiveThoughtsPage({super.key});

  @override
  State<PermissiveThoughtsPage> createState() => _PermissiveThoughtsPageState();
}

class _PermissiveThoughtsPageState extends State<PermissiveThoughtsPage> {
  static const String _customThoughtsKey = 'permissive_thoughts_custom';
  static const String _responsesKey = 'permissive_thoughts_responses';

  static const List<_PermissiveThought> _defaultThoughts = [
    _PermissiveThought(
      id: 'deserve_it',
      text: 'Jeg fortjener det.',
    ),
    _PermissiveThought(
      id: 'just_tonight',
      text: 'Bare i kveld.',
    ),
    _PermissiveThought(
      id: 'in_control',
      text: 'Jeg har kontroll.',
    ),
    _PermissiveThought(
      id: 'probably_fine',
      text: 'Det går sikkert bra.',
    ),
    _PermissiveThought(
      id: 'already_ruined',
      text: 'Jeg har allerede ødelagt dagen.',
    ),
    _PermissiveThought(
      id: 'need_to_unwind',
      text: 'Jeg trenger å koble av.',
    ),
  ];

  List<_PermissiveThought> _customThoughts = [];
  Map<String, List<String>> _responses = {};
  bool _isLoading = true;

  List<_PermissiveThought> get _allThoughts => [
    ..._defaultThoughts,
    ..._customThoughts,
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final customJson = prefs.getString(_customThoughtsKey);
    final responsesJson = prefs.getString(_responsesKey);

    final customThoughts = <_PermissiveThought>[];

    if (customJson != null && customJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(customJson);

        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              final id = item['id'];
              final text = item['text'];

              if (id is String &&
                  text is String &&
                  text.trim().isNotEmpty) {
                customThoughts.add(
                  _PermissiveThought(
                    id: id,
                    text: text.trim(),
                    isCustom: true,
                  ),
                );
              }
            }
          }
        }
      } catch (_) {}
    }

    final responses = <String, List<String>>{};

    if (responsesJson != null && responsesJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(responsesJson);

        if (decoded is Map) {
          decoded.forEach((key, value) {
            if (key is String && value is List) {
              final items = value
                  .whereType<String>()
                  .map((item) => item.trim())
                  .where((item) => item.isNotEmpty)
                  .toList();

              if (items.isNotEmpty) {
                responses[key] = items;
              }
            }
          });
        }
      } catch (_) {}
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _customThoughts = customThoughts;
      _responses = responses;
      _isLoading = false;
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _customThoughtsKey,
      jsonEncode(
        _customThoughts
            .map(
              (thought) => {
            'id': thought.id,
            'text': thought.text,
          },
        )
            .toList(),
      ),
    );

    await prefs.setString(
      _responsesKey,
      jsonEncode(_responses),
    );
  }

  bool _hasResponses(_PermissiveThought thought) {
    return (_responses[thought.id] ?? []).isNotEmpty;
  }

  Future<void> _addCustomThought() async {
    String value = '';

    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          title: const Text('Lag din egen tillatelsestanke'),
          content: TextField(
            autofocus: true,
            maxLength: 180,
            maxLines: 4,
            onChanged: (text) {
              value = text;
            },
            decoration: InputDecoration(
              hintText: 'Skriv tanken slik den kan dukke opp hos deg.',
              filled: true,
              fillColor: colors.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: colors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Avbryt'),
            ),
            FilledButton(
              onPressed: () {
                final trimmedValue = value.trim();

                if (trimmedValue.isNotEmpty) {
                  Navigator.of(dialogContext).pop(trimmedValue);
                }
              },
              child: const Text('Lagre'),
            ),
          ],
        );
      },
    );

    if (text == null || text.trim().isEmpty) {
      return;
    }

    final thoughtText = text.trim();

    final exists = _allThoughts.any(
          (thought) =>
      thought.text.toLowerCase() == thoughtText.toLowerCase(),
    );

    if (exists) {
      if (!mounted) {
        return;
      }

      await _showMessage(
        'Tanken finnes allerede',
        'Denne tillatelsestanken ligger allerede i listen.',
      );
      return;
    }

    setState(() {
      _customThoughts.add(
        _PermissiveThought(
          id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
          text: thoughtText,
          isCustom: true,
        ),
      );
    });

    await _saveData();
  }

  Future<void> _deleteCustomThought(
      _PermissiveThought thought,
      ) async {
    if (!thought.isCustom) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Slett tillatelsestanke?'),
          content: Text('«${thought.text}» blir fjernet fra listen.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Avbryt'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Slett'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _customThoughts.removeWhere(
            (item) => item.id == thought.id,
      );
      _responses.remove(thought.id);
    });

    await _saveData();
  }

  Future<void> _exploreThought(
      _PermissiveThought thought,
      ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ExplorePermissiveThoughtPage(
          thought: thought.text,
          existingResponses: List<String>.from(
            _responses[thought.id] ?? [],
          ),
          onSave: (responses) async {
            if (responses.isEmpty) {
              _responses.remove(thought.id);
            } else {
              _responses[thought.id] = responses;
            }

            await _saveData();

            if (mounted) {
              setState(() {});
            }
          },
        ),
      ),
    );
  }

  Future<void> _showResponses(
      _PermissiveThought thought,
      ) async {
    final responses = List<String>.from(
      _responses[thought.id] ?? [],
    );

    if (responses.isEmpty) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final colors = Theme.of(sheetContext).colorScheme;

        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: colors.outline.withValues(alpha: 0.65),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: colors.outline.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text(
                  'Tillatelsestanken',
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: 0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '«${thought.text}»',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 20,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Dette har du tidligere skrevet:',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                ...responses.map(
                      (response) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.check_rounded,
                              color: colors.onPrimaryContainer,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              response,
                              style: TextStyle(
                                color: colors.onPrimaryContainer,
                                fontSize: 16,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      _exploreThought(thought);
                    },
                    child: const Text('Utforsk på nytt'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showMessage(
      String title,
      String message,
      ) async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        title: Text(
          'Tillatelsestanker',
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Noen tanker kan gjøre det lettere å vike fra målet du har satt deg.',
            style: TextStyle(
              color: colors.onSurface.withValues(alpha: 0.65),
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          ..._allThoughts.map(_buildThoughtCard),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addCustomThought,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Lag din egen tillatelsestanke',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.primary,
              side: BorderSide(
                color: colors.primary,
              ),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThoughtCard(
      _PermissiveThought thought,
      ) {
    final colors = Theme.of(context).colorScheme;
    final hasResponses = _hasResponses(thought);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(18, 18, 14, 14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.outline.withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '«${thought.text}»',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 17,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _exploreThought(thought),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.primary,
                    side: BorderSide(
                      color: colors.primary,
                    ),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text('Utforsk'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: hasResponses
                      ? () => _showResponses(thought)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    disabledBackgroundColor:
                    colors.surfaceContainerHighest,
                    disabledForegroundColor:
                    colors.onSurface.withValues(alpha: 0.45),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text('Vis'),
                ),
              ),
              if (thought.isCustom) ...[
                const SizedBox(width: 2),
                IconButton(
                  onPressed: () => _deleteCustomThought(thought),
                  tooltip: 'Slett',
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                  ),
                  color: colors.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ExplorePermissiveThoughtPage extends StatefulWidget {
  final String thought;
  final List<String> existingResponses;
  final Future<void> Function(List<String> responses) onSave;

  const _ExplorePermissiveThoughtPage({
    required this.thought,
    required this.existingResponses,
    required this.onSave,
  });

  @override
  State<_ExplorePermissiveThoughtPage> createState() =>
      _ExplorePermissiveThoughtPageState();
}

class _ExplorePermissiveThoughtPageState
    extends State<_ExplorePermissiveThoughtPage> {
  late List<String> _responses;
  final TextEditingController _controller =
  TextEditingController();

  @override
  void initState() {
    super.initState();
    _responses = List<String>.from(
      widget.existingResponses,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addResponse() {
    final value = _controller.text.trim();

    if (value.isEmpty) {
      return;
    }

    if (_responses.any(
          (response) =>
      response.toLowerCase() == value.toLowerCase(),
    )) {
      _controller.clear();
      return;
    }

    setState(() {
      _responses.add(value);
      _controller.clear();
    });
  }

  void _removeResponse(int index) {
    setState(() {
      _responses.removeAt(index);
    });
  }

  Future<void> _saveAndClose() async {
    await widget.onSave(_responses);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        title: Text(
          'Utforsk',
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Tillatelsestanken',
            style: TextStyle(
              color: colors.onSurface.withValues(alpha: 0.6),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: colors.outline.withValues(alpha: 0.65),
              ),
            ),
            child: Text(
              '«${widget.thought}»',
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 21,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'For å utforske tanken, kan du stille deg selv noen spørsmål.',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 16,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildQuestion('Er tanken sann?'),
          _buildQuestion('Hva forteller erfaringen min meg?'),
          _buildQuestion('Hva vil jeg tenke om dette i morgen?'),
          const SizedBox(height: 24),
          Text(
            'Hva taler mot denne tanken?',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Skriv ned det du selv ønsker å huske når denne tanken dukker opp.',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            minLines: 3,
            maxLines: 6,
            maxLength: 300,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              filled: true,
              fillColor: colors.surfaceContainerLow,
              hintText: 'Skriv ditt eget svar …',
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: colors.outline.withValues(alpha: 0.65),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: colors.outline.withValues(alpha: 0.65),
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
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addResponse,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Legg til'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primary,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          if (_responses.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text(
              'Dine svar',
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            ...List.generate(
              _responses.length,
                  (index) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.fromLTRB(
                  15,
                  13,
                  8,
                  13,
                ),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.check_rounded,
                        color: colors.onPrimaryContainer,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _responses[index],
                        style: TextStyle(
                          color: colors.onPrimaryContainer,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeResponse(index),
                      tooltip: 'Fjern',
                      icon: const Icon(Icons.close_rounded),
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed:
              _responses.isEmpty ? null : _saveAndClose,
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                disabledBackgroundColor:
                colors.surfaceContainerHighest,
                disabledForegroundColor:
                colors.onSurfaceVariant,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Lagre',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion(String question) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: Text(
              question,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissiveThought {
  final String id;
  final String text;
  final bool isCustom;

  const _PermissiveThought({
    required this.id,
    required this.text,
    this.isCustom = false,
  });
}