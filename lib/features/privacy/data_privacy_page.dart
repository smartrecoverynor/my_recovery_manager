import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/data_deletion_service.dart';

class DataPrivacyPage extends StatelessWidget {
  const DataPrivacyPage({super.key});

  Future<void> _confirmDeletion(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          title: const Text('Slett alle mine data?'),
          content: const Text(
            'Dette vil slette brukerdata som er lagret lokalt i '
                'My Recovery Manager på denne enheten.\n\n'
                'Dette inkluderer registreringer, mål, planer, '
                'situasjoner, refleksjoner, Panic Button-data, '
                'risikosituasjoner og andre personlige data i appen.\n\n'
                'Handlingen kan ikke angres. Data du allerede har '
                'eksportert eller delt utenfor appen, kan ikke slettes '
                'av MRM.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Avbryt'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
              ),
              onPressed: () {
                debugPrint('SLETT: bekreftelsesknappen trykket');
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Slett alle data'),
            ),
          ],
        );
      },
    );

    debugPrint('SLETT: dialogresultat = $shouldDelete');

    if (shouldDelete != true || !context.mounted) {
      return;
    }

    try {
      debugPrint('SLETT: starter sletting');

      await DataDeletionService.instance.deleteAllUserData();

      debugPrint('SLETT: sletting fullført');

      if (!context.mounted) {
        return;
      }

      // Sletting av lokale brukerdata medfører automatisk
      // tilbakestilling/utlogging av appens brukerstatus.
      context.go('/');
    } catch (e) {
      debugPrint('SLETT: feil under sletting: $e');

      if (!context.mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Kunne ikke slette alle data'),
            content: const Text(
              'MRM kunne ikke fullføre slettingen av alle lokale data. '
                  'Kontroller at appen har tilgang til nødvendig lagring '
                  'og prøv igjen.',
            ),
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
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Tilbake',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: const Text('Data og personvern'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(
            'Dine data',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'My Recovery Manager er utviklet som en local-first app. '
                'Personlige registreringer lagres lokalt på enheten og '
                'skal ikke lagres på en MRM-server.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          _InfoCard(
            title: 'Hva lagres lokalt?',
            icon: Icons.lock_outline,
            children: const [
              'Daglige registreringer av blant annet humør, sug og alkohol.',
              'Mål, planer, situasjoner og refleksjoner.',
              'Informasjon du selv legger inn i Panic Button og andre '
                  'støttefunksjoner.',
              'Lokale påminnelser og enkelte appinnstillinger.',
              'Informasjon knyttet til registrerte risikosituasjoner, '
                  'inkludert sted og posisjon.',
            ],
          ),
          const SizedBox(height: 16),
          _InfoCard(
            title: 'Lokal lagring og sikkerhet',
            icon: Icons.security_outlined,
            children: const [
              'MRM bruker lokal kryptert lagring for appens '
                  'registrerte brukerdata.',
              'Det finnes ikke en MRM-konto eller en MRM-server som '
                  'lagrer dine personlige registreringer i første versjon.',
            ],
          ),
          const SizedBox(height: 16),
          _InfoCard(
            title: 'Deling og eksport',
            icon: Icons.ios_share_outlined,
            children: const [
              'Du kan eksportere egne data og rapporter fra appen.',
              'En eksportert fil som du selv har lagret eller delt, '
                  'befinner seg utenfor MRM og kan derfor ikke slettes '
                  'av appen.',
            ],
          ),
          const SizedBox(height: 16),
          _InfoCard(
            title: 'Eksterne tjenester',
            icon: Icons.public_outlined,
            children: const [
              'Enkelte funksjoner kan bruke eksterne tjenester, for '
                  'eksempel kart- og stedssøk.',
              'Informasjon som sendes til slike tjenester håndteres '
                  'etter vilkårene og personvernreglene som gjelder '
                  'for den aktuelle tjenesten.',
            ],
          ),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.errorContainer,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colors.outlineVariant,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.delete_outline,
                  color: colors.onErrorContainer,
                  size: 28,
                ),
                const SizedBox(height: 12),
                Text(
                  'Slett alle mine data',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Du kan når som helst slette brukerdata som MRM '
                      'har lagret lokalt på denne enheten.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onErrorContainer,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _confirmDeletion(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: colors.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Slett alle mine data',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.onError,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<String> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: colors.primary,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children.map(
                (text) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Icon(
                      Icons.circle,
                      size: 5,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      text,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}