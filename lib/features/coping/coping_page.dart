import 'package:flutter/material.dart';
import 'coping_exercises_page.dart';
import 'panic_button_config_page.dart';
import 'support_cards_page.dart';
import 'permissive_thoughts_page.dart';

class CopingPage extends StatelessWidget {
  const CopingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Coping',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Verktøy du kan bruke når du opplever '
                    'sug, uro eller står i en vanskelig situasjon.',
                style: TextStyle(
                  fontSize: 16,
                  color: colors.onSurface.withValues(alpha: 0.65),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 32),

              _buildCopingCard(
                context,
                icon: Icons.self_improvement_outlined,
                title: 'Øvelser',
                description:
                'Urge surfing, mindfulness og andre '
                    'øvelser som kan hjelpe deg gjennom et sug.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CopingExercisesPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              _buildCopingCard(
                context,
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Støttende kort',
                description:
                'Korte utsagn du kan bruke når du trenger '
                    'en påminnelse eller litt støtte.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SupportCardsPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              _buildCopingCard(
                context,
                icon: Icons.psychology_outlined,
                title: 'Tillatelsestanker',
                description:
                'Utforsk tanker som kan gjøre det lettere '
                    'å vike fra målet ditt.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PermissiveThoughtsPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              _buildCopingCard(
                context,
                icon: Icons.warning_amber_rounded,
                title: 'Konfigurer panic button',
                description:
                'Velg hva som skal skje når du trenger '
                    'hjelp raskt.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PanicButtonConfigPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCopingCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String description,
        required VoidCallback onTap,
      }) {
    final colors = Theme.of(context).colorScheme;
    const accentColor = Color(0xFF69B9C2);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colors.outline.withValues(alpha: 0.65),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: accentColor,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.onSurface.withValues(alpha: 0.62),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Icon(
                Icons.chevron_right,
                color: colors.onSurface.withValues(alpha: 0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }
}