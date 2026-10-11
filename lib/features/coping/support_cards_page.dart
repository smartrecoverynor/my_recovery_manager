import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SupportCardsPage extends StatefulWidget {
  const SupportCardsPage({super.key});

  @override
  State<SupportCardsPage> createState() => _SupportCardsPageState();
}

class _SupportCardsPageState extends State<SupportCardsPage> {
  static const String _deletedCardsKey = 'support_cards_deleted';
  static const String _customCardsKey = 'support_cards_custom';
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

  List<String> _activeCards = [];
  List<String> _deletedDefaultCards = [];
  List<String> _customCards = [];

  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final preferences = await SharedPreferences.getInstance();

    final deletedCards =
        preferences.getStringList(_deletedCardsKey) ?? <String>[];
    final customCards =
        preferences.getStringList(_customCardsKey) ?? <String>[];

    if (!mounted) {
      return;
    }

    setState(() {
      _deletedDefaultCards = deletedCards;
      _customCards = customCards;
      _rebuildActiveCards();
      _isLoading = false;
    });
  }

  void _rebuildActiveCards() {
    final defaultCards = _defaultCards
        .where((card) => !_deletedDefaultCards.contains(card))
        .toList();

    _activeCards = [...defaultCards, ..._customCards];

    if (_activeCards.isEmpty) {
      _currentIndex = 0;
    } else if (_currentIndex >= _activeCards.length) {
      _currentIndex = _activeCards.length - 1;
    }
  }

  Future<void> _deleteCurrentCard() async {
    if (_activeCards.isEmpty) {
      return;
    }

    final card = _activeCards[_currentIndex];
    final isCustomCard = _customCards.contains(card);

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Slette kortet?'),
          content: Text(
            isCustomCard
                ? 'Dette egne kortet blir slettet. '
                'Du kan lage et nytt kort senere.'
                : 'Kortet fjernes fra Støttende kort. '
                'Du kan gjenopprette standardkort senere.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Avbryt'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Slett'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();

    if (isCustomCard) {
      _customCards.remove(card);

      await preferences.setStringList(
        _customCardsKey,
        _customCards,
      );
    } else {
      if (!_deletedDefaultCards.contains(card)) {
        _deletedDefaultCards.add(card);
      }

      await preferences.setStringList(
        _deletedCardsKey,
        _deletedDefaultCards,
      );
    }

    // Hvis kortet var valgt i Panic Button, fjernes det også
    // fra Panic Button-utvalget.
    final selectedCards =
    preferences.getStringList(_selectedSupportCardsKey);

    if (selectedCards != null && selectedCards.remove(card)) {
      await preferences.setStringList(
        _selectedSupportCardsKey,
        selectedCards,
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _rebuildActiveCards();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kortet er slettet.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showAddCardDialog() async {
    final controller = TextEditingController();

    final newCard = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          title: const Text('Lag et eget kort'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            maxLength: 180,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'Skriv noe du ønsker å minne deg selv på.',
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
                final text = controller.text.trim();

                if (text.isEmpty) {
                  return;
                }

                Navigator.of(dialogContext).pop(text);
              },
              child: const Text('Legg til'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (newCard == null || newCard.trim().isEmpty) {
      return;
    }

    final text = newCard.trim();

    if (_activeCards.contains(text)) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dette kortet finnes allerede.'),
        ),
      );
      return;
    }

    final preferences = await SharedPreferences.getInstance();

    _customCards.add(text);

    await preferences.setStringList(
      _customCardsKey,
      _customCards,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _rebuildActiveCards();

      final newIndex = _activeCards.indexOf(text);
      if (newIndex >= 0) {
        _currentIndex = newIndex;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ditt kort er lagt til.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _editCurrentCard() async {
    if (_activeCards.isEmpty) {
      return;
    }

    final currentCard = _activeCards[_currentIndex];

    // Standardkortene er faste. Egne kort kan redigeres.
    if (!_customCards.contains(currentCard)) {
      await _showMessage(
        'Standardkort',
        'Dette er et standardkort. Du kan slette det hvis '
            'du ikke ønsker å bruke det, og gjenopprette det senere.',
      );
      return;
    }

    final controller = TextEditingController(
      text: currentCard,
    );

    final editedCard = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Rediger kort'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            maxLength: 180,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'Skriv din påminnelse.',
              filled: true,
              fillColor:
              Theme.of(dialogContext)
                  .colorScheme
                  .surfaceContainerHighest,
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
                  color: Theme.of(dialogContext).colorScheme.primary,
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
                final text = controller.text.trim();

                if (text.isEmpty) {
                  return;
                }

                Navigator.of(dialogContext).pop(text);
              },
              child: const Text('Lagre'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (editedCard == null || editedCard.trim().isEmpty) {
      return;
    }

    final newText = editedCard.trim();

    if (newText != currentCard && _activeCards.contains(newText)) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dette kortet finnes allerede.'),
        ),
      );
      return;
    }

    final preferences = await SharedPreferences.getInstance();

    final customIndex = _customCards.indexOf(currentCard);

    if (customIndex < 0) {
      return;
    }

    _customCards[customIndex] = newText;

    await preferences.setStringList(
      _customCardsKey,
      _customCards,
    );

    // Behold koblingen til Panic Button hvis kortet allerede
    // var valgt der.
    final selectedCards =
    preferences.getStringList(_selectedSupportCardsKey);

    if (selectedCards != null) {
      final selectedIndex = selectedCards.indexOf(currentCard);

      if (selectedIndex >= 0) {
        selectedCards[selectedIndex] = newText;

        // Unngå duplikater i Panic Button-utvalget.
        final uniqueSelectedCards = <String>[];

        for (final selectedCard in selectedCards) {
          if (!uniqueSelectedCards.contains(selectedCard)) {
            uniqueSelectedCards.add(selectedCard);
          }
        }

        await preferences.setStringList(
          _selectedSupportCardsKey,
          uniqueSelectedCards,
        );
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _rebuildActiveCards();

      final newIndex = _activeCards.indexOf(newText);
      if (newIndex >= 0) {
        _currentIndex = newIndex;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kortet er oppdatert.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _restoreDefaultCards() async {
    final shouldRestore = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Gjenopprette standardkort?'),
          content: const Text(
            'Dette vil gjøre alle de opprinnelige standardkortene '
                'tilgjengelige igjen. Egne kort blir ikke påvirket.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Avbryt'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Gjenopprett'),
            ),
          ],
        );
      },
    );

    if (shouldRestore != true) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();

    _deletedDefaultCards.clear();

    await preferences.remove(_deletedCardsKey);

    if (!mounted) {
      return;
    }

    setState(() {
      _currentIndex = 0;
      _rebuildActiveCards();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Standardkortene er gjenopprettet.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _nextCard() {
    if (_activeCards.isEmpty) {
      return;
    }

    setState(() {
      _currentIndex =
          (_currentIndex + 1) % _activeCards.length;
    });
  }

  Future<void> _showOptions() async {
    if (_activeCards.isEmpty) {
      return;
    }

    final currentCard = _activeCards[_currentIndex];
    final isCustomCard = _customCards.contains(currentCard);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        final colors = Theme.of(sheetContext).colorScheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outline.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  leading: Icon(
                    Icons.edit_outlined,
                    color: isCustomCard
                        ? colors.primary
                        : colors.onSurfaceVariant,
                  ),
                  title: const Text('Rediger dette kort'),
                  subtitle: Text(
                    isCustomCard
                        ? 'Endre teksten på ditt eget kort.'
                        : 'Standardkort kan ikke redigeres.',
                  ),
                  enabled: isCustomCard,
                  onTap: isCustomCard
                      ? () {
                    Navigator.of(sheetContext).pop();
                    _editCurrentCard();
                  }
                      : null,
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: colors.primary,
                  ),
                  title: const Text('Slett dette kortet'),
                  subtitle: const Text(
                    'Kortet fjernes fra dine støttende kort.',
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _deleteCurrentCard();
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.add_rounded,
                    color: colors.primary,
                  ),
                  title: const Text('Lag et eget kort'),
                  subtitle: const Text(
                    'Skriv en egen påminnelse.',
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _showAddCardDialog();
                  },
                ),
                if (_deletedDefaultCards.isNotEmpty)
                  ListTile(
                    leading: Icon(
                      Icons.refresh_rounded,
                      color: colors.primary,
                    ),
                    title: const Text(
                      'Gjenopprett standardkort',
                    ),
                    subtitle: Text(
                      '${_deletedDefaultCards.length} '
                          'standardkort er slettet.',
                    ),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _restoreDefaultCards();
                    },
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
        elevation: 0,
        foregroundColor: colors.onSurface,
        title: const Text('Støttende kort'),
        actions: [
          if (!_isLoading && _activeCards.isNotEmpty)
            IconButton(
              onPressed: _showOptions,
              icon: const Icon(
                Icons.more_horiz_rounded,
              ),
              tooltip: 'Flere valg',
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
          child: CircularProgressIndicator(
            color: colors.primary,
          ),
        )
            : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final colors = Theme.of(context).colorScheme;

    if (_activeCards.isEmpty) {
      return _buildEmptyState();
    }

    final currentCard = _activeCards[_currentIndex];
    final isCustomCard = _customCards.contains(currentCard);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'En påminnelse når du trenger litt støtte.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, animation) {
                  final offsetAnimation =
                  Tween<Offset>(
                    begin: const Offset(0.08, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    ),
                  );

                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: offsetAnimation,
                      child: child,
                    ),
                  );
                },
                child: _buildCard(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Kort ${_currentIndex + 1} av ${_activeCards.length}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: colors.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value:
              (_currentIndex + 1) / _activeCards.length,
              minHeight: 5,
              backgroundColor:
              colors.primaryContainer.withValues(alpha: 0.55),
              valueColor: AlwaysStoppedAnimation<Color>(
                colors.primary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: _nextCard,
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Neste kort',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (isCustomCard)
            TextButton.icon(
              onPressed: _editCurrentCard,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Rediger eget kort'),
              style: TextButton.styleFrom(
                foregroundColor: colors.primary,
              ),
            ),
          TextButton.icon(
            onPressed: _showAddCardDialog,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Lag et eget kort'),
            style: TextButton.styleFrom(
              foregroundColor: colors.primary,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Tilbake til Coping',
              style: TextStyle(
                color: colors.primary,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    final colors = Theme.of(context).colorScheme;
    final card = _activeCards[_currentIndex];
    final isCustomCard = _customCards.contains(card);

    return Container(
      key: ValueKey(card),
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 300,
        maxWidth: 520,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 30,
        vertical: 36,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.outline.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.18
                  : 0.06,
            ),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              color: colors.onPrimaryContainer,
              size: 28,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            card,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 23,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: colors.onSurface,
            ),
          ),
          if (isCustomCard) ...[
            const SizedBox(height: 24),
            Text(
              'Eget kort',
              style: TextStyle(
                fontSize: 13,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                color: colors.onPrimaryContainer,
                size: 34,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Ingen støttende kort',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Du har slettet alle kortene. '
                  'Du kan lage ditt eget kort eller '
                  'gjenopprette standardkortene.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: colors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _showAddCardDialog,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Lag et eget kort',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (_deletedDefaultCards.isNotEmpty) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: _restoreDefaultCards,
                child: Text(
                  'Gjenopprett standardkort',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Tilbake til Coping',
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}