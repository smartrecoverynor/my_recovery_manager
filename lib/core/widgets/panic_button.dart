import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/coping/coping_exercises_page.dart';

class PanicButton extends StatefulWidget {
  const PanicButton({super.key});

  @override
  State<PanicButton> createState() => _PanicButtonState();
}

class _PanicButtonState extends State<PanicButton> {
  static const String _selectedActionsKey = 'panic_button_selected_actions';

  static const String _callFriendContactIdKey =
      'panic_button_call_friend_contact_id';

  static const String _consequencesKey = 'panic_button_consequences';

  static const String _imagePathKey = 'panic_button_selected_image_path';

  static const String _supportCardsCountKey =
      'panic_button_support_cards_count';

  static const String _selectedSupportCardsKey =
      'panic_button_selected_support_cards';

  static const List<String> _defaultActionIds = [
    'call_friend',
    'start_exercise',
    'show_consequences',
    'show_image',
  ];

  bool _isOpening = false;

  Future<List<String>> _loadSelectedActions() async {
    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getStringList(_selectedActionsKey);

    if (saved == null) {
      return List<String>.from(_defaultActionIds);
    }

    return saved;
  }

  Future<int> _loadSupportCardsCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_supportCardsCountKey) ?? 1;

    if (count < 1 || count > 3) {
      return 1;
    }

    return count;
  }

  Future<List<String>> _loadActiveSupportCards() async {
    final prefs = await SharedPreferences.getInstance();

    const defaultCards = [
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

    final deletedCards =
        prefs.getStringList('support_cards_deleted') ?? <String>[];
    final customCards =
        prefs.getStringList('support_cards_custom') ?? <String>[];

    return [
      ...defaultCards.where((card) => !deletedCards.contains(card)),
      ...customCards,
    ];
  }

  Future<List<String>> _loadSelectedSupportCards() async {
    final prefs = await SharedPreferences.getInstance();
    final activeCards = await _loadActiveSupportCards();
    final saved = prefs.getStringList(_selectedSupportCardsKey);

    if (saved == null) {
      return activeCards;
    }

    return saved.where(activeCards.contains).toList();
  }

  Future<void> _handlePanicButton() async {
    if (_isOpening) {
      return;
    }

    setState(() {
      _isOpening = true;
    });

    try {
      final selectedActions = await _loadSelectedActions();

      if (!mounted) {
        return;
      }

      if (selectedActions.isEmpty) {
        await _showNoActionsDialog();
        return;
      }

      await _showActionMenu(selectedActions);
    } finally {
      if (mounted) {
        setState(() {
          _isOpening = false;
        });
      }
    }
  }

  Future<void> _showActionMenu(List<String> actionIds) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;

        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: colors.outline.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Hva trenger du akkurat nå?',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...actionIds
                    .where(_isKnownAction)
                    .map(
                      (actionId) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildActionTile(context, actionId),
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isKnownAction(String id) {
    return id == 'call_friend' ||
        id == 'start_exercise' ||
        id == 'show_consequences' ||
        id == 'show_image' ||
        id == 'show_support_cards';
  }

  Widget _buildActionTile(BuildContext context, String actionId) {
    final action = _getActionData(actionId);

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () async {
          Navigator.of(context).pop();
          await _performAction(actionId);
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE7E7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  action.icon,
                  color: const Color(0xFFE00000),
                  size: 25,
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
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      action.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.62),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _PanicActionData _getActionData(String actionId) {
    switch (actionId) {
      case 'call_friend':
        return const _PanicActionData(
          title: 'Ring en venn',
          description: 'Kontakt en person du stoler på.',
          icon: Icons.phone_outlined,
        );

      case 'start_exercise':
        return const _PanicActionData(
          title: 'Start en øvelse',
          description: 'Start en kort coping- eller mindfulnessøvelse.',
          icon: Icons.self_improvement_outlined,
        );

      case 'show_consequences':
        return const _PanicActionData(
          title: 'Vis konsekvensliste',
          description: 'Minn deg på hvorfor du ikke vil drikke.',
          icon: Icons.list_alt_outlined,
        );

      case 'show_image':
        return const _PanicActionData(
          title: 'Vis et bilde',
          description: 'Vis et bilde du har valgt som støtte.',
          icon: Icons.image_outlined,
        );

      case 'show_support_cards':
        return const _PanicActionData(
          title: 'Vis støttende kort',
          description: 'Se korte påminnelser som kan hjelpe akkurat nå.',
          icon: Icons.chat_bubble_outline_rounded,
        );

      default:
        return const _PanicActionData(
          title: 'Ukjent handling',
          description: '',
          icon: Icons.help_outline,
        );
    }
  }

  Future<void> _performAction(String actionId) async {
    switch (actionId) {
      case 'call_friend':
        await _callFriend();
        break;

      case 'start_exercise':
        await _startExercise();
        break;

      case 'show_consequences':
        await _showConsequences();
        break;

      case 'show_image':
        await _showSelectedImage();
        break;

      case 'show_support_cards':
        await _showSupportCards();
        break;
    }
  }

  Future<void> _showSupportCards() async {
    final count = await _loadSupportCardsCount();
    final selectedCards = await _loadSelectedSupportCards();

    if (!mounted) {
      return;
    }

    if (selectedCards.isEmpty) {
      await _showMessage(
        'Ingen kort er valgt',
        'Velg minst ett støttende kort i konfigurasjonen av panic button.',
      );
      return;
    }

    final cards = List<String>.from(selectedCards)..shuffle(Random());

    final cardsToShow = cards.take(min(count, cards.length)).toList();

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    if (!mounted) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PanicSupportCardsPage(cards: cardsToShow),
      ),
    );

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  Future<void> _callFriend() async {
    final prefs = await SharedPreferences.getInstance();

    final contactId = prefs.getString(_callFriendContactIdKey);

    if (!mounted) {
      return;
    }

    if (contactId == null || contactId.isEmpty) {
      await _showMessage(
        'Ingen venn er valgt',
        'Gå til «Konfigurer panic button» og velg hvem du vil ringe.',
      );
      return;
    }

    try {
      final contact = await FlutterContacts.get(
        contactId,
        properties: {ContactProperty.phone},
      );

      if (!mounted) {
        return;
      }

      if (contact == null || contact.phones.isEmpty) {
        await _showMessage(
          'Telefonnummer mangler',
          'Den valgte kontakten har ikke et tilgjengelig telefonnummer.',
        );
        return;
      }

      final phoneNumber = contact.phones.first.number;

      final uri = Uri(scheme: 'tel', path: phoneNumber);

      final launched = await launchUrl(uri);

      if (!mounted) {
        return;
      }

      if (!launched) {
        await _showMessage(
          'Kunne ikke starte telefonen',
          'Telefonappen kunne ikke åpnes på denne enheten.',
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      await _showMessage(
        'Kunne ikke ringe',
        'Det oppsto en feil da kontakten skulle hentes.',
      );
    }
  }

  Future<void> _startExercise() async {
    if (!mounted) {
      return;
    }

    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CopingExercisesPage()));
  }

  Future<void> _showConsequences() async {
    final prefs = await SharedPreferences.getInstance();

    final consequences = prefs.getStringList(_consequencesKey) ?? <String>[];

    if (!mounted) {
      return;
    }

    if (consequences.isEmpty) {
      await _showMessage(
        'Konsekvenslisten er tom',
        'Legg til noen korte påminnelser i konfigurasjonen av panic button.',
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;

        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.78,
            ),
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: colors.outline.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Husk hvorfor',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Dette er dine egne korte påminnelser akkurat når du trenger dem.',
                    style: TextStyle(
                      color: colors.onSurface.withValues(alpha: 0.62),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: consequences.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF3A2025)
                              : const Color(0xFFFFF4F4),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.favorite_border_rounded,
                                color: Color(0xFFE00000),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                consequences[index],
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showSelectedImage() async {
    final prefs = await SharedPreferences.getInstance();

    final imagePath = prefs.getString(_imagePathKey);

    if (!mounted) {
      return;
    }

    if (imagePath == null || imagePath.isEmpty) {
      await _showMessage(
        'Ingen bilde valgt',
        'Velg et bilde i konfigurasjonen av panic button.',
      );
      return;
    }

    final file = File(imagePath);

    if (!await file.exists()) {
      if (!mounted) {
        return;
      }

      await _showMessage(
        'Bildet ble ikke funnet',
        'Det lagrede bildet er ikke lenger tilgjengelig.',
      );
      return;
    }

    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                InteractiveViewer(child: Image.file(file, fit: BoxFit.contain)),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showNoActionsDialog() async {
    await _showMessage(
      'Ingen handlinger er aktive',
      'Gå til «Konfigurer panic button» og velg minst én handling.',
    );
  }

  Future<void> _showMessage(String title, String message) async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 165,
        height: 165,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF5A5A), Color(0xFFE00000)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: _handlePanicButton,
              customBorder: const CircleBorder(),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 12,
                    left: 27,
                    child: SizedBox(
                      width: 111,
                      height: 54,
                      child: CustomPaint(painter: _GlossyHighlightPainter()),
                    ),
                  ),
                  const Text(
                    'Hjelp!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                      shadows: [
                        Shadow(
                          color: Color(0x55000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PanicSupportCardsPage extends StatefulWidget {
  final List<String> cards;

  const _PanicSupportCardsPage({required this.cards});

  @override
  State<_PanicSupportCardsPage> createState() => _PanicSupportCardsPageState();
}

class _PanicSupportCardsPageState extends State<_PanicSupportCardsPage> {
  int _currentIndex = 0;

  void _next() {
    if (_currentIndex >= widget.cards.length - 1) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _currentIndex++;
    });
  }

  void _previous() {
    if (_currentIndex == 0) {
      return;
    }

    setState(() {
      _currentIndex--;
    });
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.cards[_currentIndex];

    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;

            if (velocity < -250) {
              _next();
            } else if (velocity > 250) {
              _previous();
            }
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Container(
              key: ValueKey(_currentIndex),
              width: double.infinity,
              height: double.infinity,
              color: colors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 32),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      card,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 28,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 4,
                    child: Semantics(
                      button: true,
                      label: _currentIndex == widget.cards.length - 1
                          ? 'Ferdig'
                          : 'Neste kort',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _next,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${_currentIndex + 1}/${widget.cards.length}',
                                  style: TextStyle(
                                    color: colors.onSurface.withValues(alpha: 0.55),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _currentIndex == widget.cards.length - 1
                                      ? Icons.check_rounded
                                      : Icons.double_arrow_rounded,
                                  color: colors.primary,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PanicActionData {
  final String title;
  final String description;
  final IconData icon;

  const _PanicActionData({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class _GlossyHighlightPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.fromRGBO(255, 255, 255, 0.48),
          Color.fromRGBO(255, 255, 255, 0.20),
          Color.fromRGBO(255, 255, 255, 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();

    path.moveTo(7, 25);

    path.cubicTo(19, 5, 88, 2, 105, 19);

    path.cubicTo(111, 26, 106, 37, 96, 41);

    path.cubicTo(73, 51, 32, 48, 12, 37);

    path.cubicTo(5, 33, 3, 28, 7, 25);

    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _GlossyHighlightPainter oldDelegate) {
    return false;
  }
}
