import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PanicButtonSupportCardsConfigPage extends StatefulWidget {
  const PanicButtonSupportCardsConfigPage({super.key});

  @override
  State<PanicButtonSupportCardsConfigPage> createState() =>
      _PanicButtonSupportCardsConfigPageState();
}

class _PanicButtonSupportCardsConfigPageState
    extends State<PanicButtonSupportCardsConfigPage> {
  static const Color _softAqua = Color(0xFFDCEEEF);
  static const Color _aqua = Color(0xFF69B9C2);
  static const Color _deepTeal = Color(0xFF176477);

  static const String _deletedCardsKey = 'support_cards_deleted';
  static const String _customCardsKey = 'support_cards_custom';
  static const String _supportCardsCountKey =
      'panic_button_support_cards_count';
  static const String _selectedSupportCardsKey =
      'panic_button_selected_support_cards';

  static const List<String> _defaultCards = [
    'Dette suget går over. Jeg trenger ikke handle på det akkurat nå.',
    'Jeg kan utsette beslutningen. Det er lov å vente 10 minutter.',
    'En vanskelig følelse trenger ikke føre til en handling.',
    'Jeg trenger ikke gjøre resten av dagen perfekt. Bare ta det neste valget.',
    'Jeg har kommet gjennom vanskelige øyeblikk før.',
    'Jeg kan velge det som hjelper meg i dag.',
    'Jeg trenger ikke løse alt akkurat nå. Jeg kan ta én ting om gangen.',
    'Det er lov å kjenne på sug uten å gjøre noe med det.',
    'Jeg kan gi følelsen litt tid. Den trenger ikke vare.',
    'Jeg kan gå bort fra situasjonen hvis det gjør det lettere.',
    'Det er jeg som bestemmer hva jeg gjør med suget.',
    'Jeg kan velge å vente til suget har blitt svakere.',
    'Et vanskelig øyeblikk trenger ikke bestemme hvordan resten av dagen blir.',
    'Jeg trenger ikke diskutere med suget. Jeg kan bare la det være der.',
    'Jeg kan gjøre noe som hjelper meg gjennom de neste minuttene.',
  ];

  int _supportCardsCount = 1;
  List<String> _activeCards = [];
  Set<String> _selectedCards = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  Future<void> _loadConfiguration() async {
    final prefs = await SharedPreferences.getInstance();

    final deletedCards =
        prefs.getStringList(_deletedCardsKey) ?? <String>[];
    final customCards =
        prefs.getStringList(_customCardsKey) ?? <String>[];
    final savedSelected =
    prefs.getStringList(_selectedSupportCardsKey);
    final savedCount =
        prefs.getInt(_supportCardsCountKey) ?? 1;

    final activeCards = _buildActiveCards(
      deletedCards: deletedCards,
      customCards: customCards,
    );

    Set<String> selectedCards;

    if (savedSelected == null) {
      selectedCards = activeCards.toSet();
    } else {
      selectedCards =
          savedSelected.where(activeCards.contains).toSet();
    }

    if (selectedCards.isEmpty && activeCards.isNotEmpty) {
      selectedCards = activeCards.toSet();
    }

    final validCount =
    savedCount >= 1 && savedCount <= 3
        ? savedCount
        : 1;

    if (!mounted) {
      return;
    }

    setState(() {
      _activeCards = activeCards;
      _selectedCards = selectedCards;
      _supportCardsCount = validCount;
      _isLoading = false;
    });
  }

  List<String> _buildActiveCards({
    required List<String> deletedCards,
    required List<String> customCards,
  }) {
    final defaultCards = _defaultCards
        .where((card) => !deletedCards.contains(card))
        .toList();

    return [...defaultCards, ...customCards];
  }

  void _toggleCard(String card) {
    setState(() {
      if (_selectedCards.contains(card)) {
        _selectedCards.remove(card);
      } else {
        _selectedCards.add(card);
      }
    });
  }

  Future<void> _saveConfiguration() async {
    if (_selectedCards.length < _supportCardsCount) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Velg flere kort'),
            content: Text(
              'Du har valgt ${_selectedCards.length} kort, '
                  'men vil vise $_supportCardsCount kort. '
                  'Velg minst $_supportCardsCount kort.',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      return;
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(
      _supportCardsCountKey,
      _supportCardsCount,
    );

    await prefs.setStringList(
      _selectedSupportCardsKey,
      _selectedCards.toList(),
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Støttende kort'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Støttende kort'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  16,
                  24,
                  24,
                ),
                children: [
                  Text(
                    'Konfigurer støttende kort',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Velg hvor mange kort som skal vises når du '
                        'bruker støttende kort fra panic button.',
                    style: TextStyle(
                      fontSize: 16,
                      color: colors.onSurface.withValues(
                        alpha: 0.65,
                      ),
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    'Antall kort',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),

                  const SizedBox(height: 12),

                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment<int>(
                        value: 1,
                        label: Text('1 kort'),
                      ),
                      ButtonSegment<int>(
                        value: 2,
                        label: Text('2 kort'),
                      ),
                      ButtonSegment<int>(
                        value: 3,
                        label: Text('3 kort'),
                      ),
                    ],
                    selected: {_supportCardsCount},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _supportCardsCount = selection.first;
                      });
                    },
                  ),

                  const SizedBox(height: 32),

                  Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          'Velg kortene',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        '${_selectedCards.length} valgt',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Velg hvilke kort Panic Button kan bruke. '
                        'Du kan velge flere kort enn antallet som vises.',
                    style: TextStyle(
                      fontSize: 15,
                      color: colors.onSurface.withValues(
                        alpha: 0.65,
                      ),
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (_activeCards.isEmpty)
                    _buildEmptyState()
                  else
                    ...List.generate(
                      _activeCards.length,
                          (index) =>
                          _buildCardOption(_activeCards[index]),
                    ),

                  const SizedBox(height: 8),

                  _buildInfoCard(),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                24,
                12,
                24,
                20,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _activeCards.isEmpty
                      ? null
                      : _saveConfiguration,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? _deepTeal.withValues(alpha: 0.22)
        : _softAqua;

    final iconColor = isDark
        ? _aqua
        : _deepTeal;

    final textColor = isDark
        ? const Color(0xFFD8E8E8)
        : _deepTeal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: isDark
            ? Border.all(
          color: _aqua.withValues(alpha: 0.18),
        )
            : null,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: iconColor,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              'Hvis du har valgt flere kort enn det som '
                  'skal vises, velger Panic Button tilfeldig '
                  'blant de valgte kortene.',
              style: TextStyle(
                fontSize: 15,
                color: textColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardOption(String card) {
    final colors = Theme.of(context).colorScheme;
    final isSelected = _selectedCards.contains(card);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        elevation: 0,
        child: InkWell(
          onTap: () => _toggleCard(card),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? _aqua
                    : colors.outline.withValues(
                  alpha: 0.7,
                ),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _deepTeal
                        : colors.surface,
                    borderRadius:
                    BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? _deepTeal
                          : colors.outline,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                    Icons.check_rounded,
                    size: 20,
                    color: Colors.white,
                  )
                      : null,
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Text(
                    card,
                    style: TextStyle(
                      fontSize: 16,
                      color: colors.onSurface,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.outline.withValues(
            alpha: 0.7,
          ),
        ),
      ),
      child: Text(
        'Ingen støttende kort er tilgjengelige. '
            'Lag eller gjenopprett kort i Støttende kort.',
        style: TextStyle(
          fontSize: 15,
          color: colors.onSurface.withValues(
            alpha: 0.6,
          ),
          height: 1.4,
        ),
      ),
    );
  }
}
