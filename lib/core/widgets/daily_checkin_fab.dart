import 'package:flutter/material.dart';

import '../../features/checkins/mood/mood_checkin_page.dart';
import '../../features/checkins/craving/craving_checkin_page.dart';
import '../../features/checkins/alcohol/alcohol_checkin_page.dart';
import '../../features/checkins/journal/journal_checkin_page.dart';

class DailyCheckinFab extends StatefulWidget {
  const DailyCheckinFab({super.key});

  @override
  State<DailyCheckinFab> createState() => _DailyCheckinFabState();
}

class _DailyCheckinFabState extends State<DailyCheckinFab> {
  bool _expanded = false;

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_expanded) {
      return GestureDetector(
        onTap: _toggleExpanded,
        child: _buildMainButton(icon: Icons.add),
      );
    }

    return SizedBox(
      width: 280,
      height: 220,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 92,
            child: _buildCheckinOption(
              icon: Icons.sentiment_satisfied_alt,
              label: 'Humør',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MoodCheckinPage(),
                  ),
                );
              },
            ),
          ),

          Positioned(
            left: 55,
            top: 20,
            child: _buildCheckinOption(
              icon: Icons.local_bar,
              label: 'Alkohol',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AlcoholCheckinPage(),
                  ),
                );
              },
            ),
          ),

          Positioned(
            right: 55,
            top: 20,
            child: _buildCheckinOption(
              icon: Icons.local_fire_department,
              label: 'Craving',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CravingCheckinPage(),
                  ),
                );
              },
            ),
          ),

          Positioned(
            right: 0,
            top: 92,
            child: _buildCheckinOption(
              icon: Icons.menu_book,
              label: 'Dagbok',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const JournalCheckinPage(),
                  ),
                );
              },
            ),
          ),

          Positioned(
            left: 99,
            bottom: 0,
            child: GestureDetector(
              onTap: _toggleExpanded,
              child: _buildMainButton(icon: Icons.close),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainButton({required IconData icon}) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.secondary,
            colors.primary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.30
                  : 0.20,
            ),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 8,
            child: Container(
              width: 50,
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.33),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Icon(
            icon,
            size: 38,
            color: colors.onPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckinOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 62,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.outlineVariant,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: Theme.of(context).brightness == Brightness.dark
                          ? 0.22
                          : 0.12,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 30,
                color: colors.primary,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}