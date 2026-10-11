import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/assessment_header.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/recommendation_card.dart';
import 'models/mrm_cra_assessment.dart';
import 'models/mrm_cra_recommendation_engine.dart';

class RecommendationPage extends StatelessWidget {
  final MrmCraAssessment? assessment;

  const RecommendationPage({super.key, this.assessment});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final currentAssessment = assessment;

    final MrmCraRecommendationResult? result =
    currentAssessment != null && currentAssessment.auditComplete
        ? const MrmCraRecommendationEngine().recommend(
      currentAssessment,
    )
        : null;

    final recommendation = result?.recommendation;

    final String title;
    final String description;
    final IconData icon;

    switch (recommendation) {
      case MrmCraRecommendation.moderation:
        title = 'Moderasjon kan være et realistisk mål';
        description =
        'Basert på svarene dine vurderer vi at kontrollert alkoholbruk '
            'kan være et realistisk mål dersom du ønsker å endre alkoholbruken.';
        icon = Icons.eco;

      case MrmCraRecommendation.trialAbstinence:
        title = 'Vurder en prøveperiode med avhold';
        description =
        'Basert på svarene dine er det vanskelig å gi en sikker '
            'anbefaling om hvilket mål som vil være mest realistisk for deg. '
            'Vi anbefaler derfor at du vurderer en prøveperiode med avhold, '
            'for eksempel i seks måneder. Etter denne perioden kan du ta '
            'en ny vurdering av hvilket mål som passer best for deg.';
        icon = Icons.hourglass_top;

      case MrmCraRecommendation.abstinence:
        title = 'Vi anbefaler avhold';
        description =
        'Basert på svarene dine anbefaler vi at målet ditt er avhold '
            'fra alkohol. Dersom du kan være fysisk avhengig, bør du '
            'vurdere behovet for medisinsk hjelp før du slutter brått.';
        icon = Icons.health_and_safety;

      case null:
        title = 'Vi kan ikke beregne en anbefaling';
        description =
        'Kartleggingen ser ut til å være ufullstendig. Du kan likevel '
            'gå videre og velge målsettingen som passer for deg.';
        icon = Icons.info_outline;
    }

    final reasons = _buildReasons(currentAssessment, result);

    return Scaffold(
      appBar: AppBar(title: const Text('Kartlegging')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AssessmentHeader(
                step: 'Steg 4 av 5',
                title: 'Vår anbefaling',
                description:
                'Basert på svarene dine har vi laget en veiledende '
                    'anbefaling.',
              ),
              const SizedBox(height: 24),
              RecommendationCard(
                icon: icon,
                title: title,
                description: description,
              ),
              const SizedBox(height: 24),
              Text(
                'Hvorfor anbefaler vi dette?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              if (reasons.isEmpty)
                Text(
                  result == null
                      ? 'Vi trenger en fullstendig kartlegging for å '
                      'beregne en anbefaling.'
                      : 'Anbefalingen bygger på en samlet vurdering av '
                      'svarene dine etter MRM-CRAs foreløpige regler.',
                  style: TextStyle(color: colors.onSurface),
                )
              else
                ...reasons.map(
                      (reason) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.circle,
                            size: 7,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            reason,
                            style: TextStyle(color: colors.onSurface),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'MRM-CRA er en foreløpig beslutningsmodell. Den er ikke '
                      'et diagnostisk verktøy og er ikke klinisk validert. '
                      'Anbefalingen er veiledende, og du bestemmer selv '
                      'hvilket mål du ønsker å sette.',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Velg mål',
                onPressed: () {
                  context.go('/goal-selection');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _buildReasons(
      MrmCraAssessment? assessment,
      MrmCraRecommendationResult? result,
      ) {
    if (assessment == null || result == null) {
      return [];
    }

    final reasons = <String>[];

    if (assessment.possiblePhysicalDependence) {
      reasons.add(
        'Du har markert mulige tegn på fysisk avhengighet. '
            'Dette er en sterk sikkerhetsindikator i modellen.',
      );
    }

    if ((assessment.auditItem6 ?? 0) > 0) {
      reasons.add(
        'Du svarte positivt på AUDIT-spørsmålet om morgenalkohol. '
            'Dette gjør at modellen anbefaler særlig forsiktighet.',
      );
    }

    if (result.recommendation == MrmCraRecommendation.abstinence &&
        !assessment.possiblePhysicalDependence &&
        (assessment.auditItem6 ?? 0) == 0) {
      reasons.add(
        'Kartleggingen inneholder minst tre av modellens definerte '
            'betydelige risikofaktorer.',
      );
    }

    if (result.auditTotalScore >= 16) {
      reasons.add(
        'AUDIT-skåren din er ${result.auditTotalScore}. I MRM-CRA '
            'brukes 16 som øvre grense for grønn anbefaling. En høyere '
            'skår fører ikke automatisk til anbefaling om varig avhold.',
      );
    }

    if (result.significantRiskFactorCount >= 2 &&
        result.recommendation != MrmCraRecommendation.abstinence) {
      reasons.add(
        'Flere betydelige risikofaktorer er registrert. '
            'Modellen anbefaler derfor en mer forsiktig tilnærming.',
      );
    }

    if (assessment.previousUnsuccessfulAttempts &&
        result.significantRiskFactorCount < 2 &&
        result.auditTotalScore < 16 &&
        !assessment.possiblePhysicalDependence &&
        (assessment.auditItem6 ?? 0) == 0) {
      reasons.add(
        'Du har oppgitt tidligere mislykkede forsøk på å endre '
            'alkoholbruken. Dette trekker vurderingen i retning av '
            'en prøveperiode med avhold.',
      );
    }

    if (assessment.mentalHealthCondition &&
        result.recommendation == MrmCraRecommendation.trialAbstinence &&
        result.auditTotalScore < 16 &&
        result.significantRiskFactorCount < 2 &&
        !assessment.previousUnsuccessfulAttempts) {
      reasons.add(
        'Psykisk helse inngår som en moderat risikofaktor i den '
            'samlede vurderingen, men avgjør ikke anbefalingen alene.',
      );
    }

    if (result.recommendation == MrmCraRecommendation.moderation) {
      reasons.add(
        'Ingen av modellens definerte terskler for gul eller rød '
            'anbefaling er nådd. Dette betyr ikke at moderasjon '
            'garantert vil lykkes.',
      );
    }

    return reasons.take(3).toList();
  }
}