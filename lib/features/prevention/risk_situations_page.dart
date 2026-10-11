import 'package:flutter/material.dart';
import 'mar_a_page.dart';
import 'my_situations_page.dart';
import 'risky_places_page.dart';

class RiskSituationsPage extends StatelessWidget {
  const RiskSituationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Kartlegg risikosituasjoner')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kartlegg risikosituasjoner',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Bli bedre kjent med situasjoner som kan '
                    'påvirke alkoholbruken din.',
                style: TextStyle(
                  fontSize: 16,
                  color: colors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 32),

              _buildResourceCard(
                context: context,
                icon: Icons.assignment_outlined,
                title: 'MAR-A',
                description:
                'Kartlegg forventninger om mestring '
                    'av ulike risikosituasjoner.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MarAPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              _buildResourceCard(
                context: context,
                icon: Icons.palette_outlined,
                title: 'Mine situasjoner',
                description:
                'Lag din egen oversikt over risikosituasjoner '
                    'og forebyggende aktiviteter.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MySituationsPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              _buildResourceCard(
                context: context,
                icon: Icons.location_on_outlined,
                title: 'Risikofylte steder',
                description:
                'Marker steder som kan være forbundet med '
                    'økt risiko for alkoholbruk.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const RiskyPlacesPage(),
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

  Widget _buildResourceCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: colors.onPrimaryContainer,
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
                        color: colors.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Icon(
                Icons.chevron_right,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}