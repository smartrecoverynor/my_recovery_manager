import 'mrm_cra_assessment.dart';

/// Anbefalingskategori fra MRM-CRA.
///
/// Dette er beslutningsstøtte, ikke diagnose eller klinisk validert prediksjon.
enum MrmCraRecommendation {
  moderation,
  trialAbstinence,
  abstinence,
}

class MrmCraRecommendationResult {
  const MrmCraRecommendationResult({
    required this.recommendation,
    required this.auditTotalScore,
    required this.significantRiskFactorCount,
    required this.reasons,
  });

  final MrmCraRecommendation recommendation;
  final int auditTotalScore;
  final int significantRiskFactorCount;

  /// Forklaringer basert på svarene, egnet for intern kontroll og senere UI.
  final List<String> reasons;
}

/// Første, eksplisitte og testbare versjon av MRM-CRA-beslutningsreglene.
///
/// Reglene er produktvalg under utvikling. At de automatiserte testene består,
/// viser at implementasjonen følger disse reglene – ikke at modellen er klinisk
/// validert eller at anbefalingen nødvendigvis er riktig for den enkelte.
class MrmCraRecommendationEngine {
  const MrmCraRecommendationEngine();

  MrmCraRecommendationResult recommend(MrmCraAssessment assessment) {
    final total = assessment.auditTotalScore;
    if (total == null) {
      throw StateError('Alle ti AUDIT-spørsmål må være besvart før anbefaling.');
    }

    final significant = <String>[];
    if ((assessment.auditItem4 ?? 0) >= 2) {
      significant.add('Tilbakevendende tap av kontroll (AUDIT 4).');
    }
    if ((assessment.auditItem5 ?? 0) >= 2) {
      significant.add('Tilbakevendende funksjonssvikt (AUDIT 5).');
    }
    if ((assessment.auditItem8 ?? 0) >= 2) {
      significant.add('Tilbakevendende hukommelsestap (AUDIT 8).');
    }
    if ((assessment.auditItem9 ?? 0) > 0) {
      significant.add('Alkoholrelatert skade siste år (AUDIT 9).');
    }
    if ((assessment.auditItem10 ?? 0) > 0) {
      significant.add('Bekymring fra andre siste år (AUDIT 10).');
    }
    if (assessment.previousUnsuccessfulAttempts) {
      significant.add('Tidligere mislykkede endringsforsøk.');
    }

    final reasons = <String>[];
    final hasPossibleDependence = assessment.possiblePhysicalDependence;
    final hasMorningAlcohol = (assessment.auditItem6 ?? 0) > 0;

    if (hasPossibleDependence) {
      reasons.add('Oppgitte tegn på mulig fysisk avhengighet tilsier særlig forsiktighet.');
    }
    if (hasMorningAlcohol) {
      reasons.add('Positivt svar på AUDIT 6 gir en sterk sikkerhetsindikator.');
    }
    if (total >= 16) {
      reasons.add('AUDIT-totalen er $total; grønn anbefaling brukes ikke ved skår 16 eller høyere.');
    }
    if (significant.isNotEmpty) {
      reasons.addAll(significant);
    }
    if (assessment.mentalHealthCondition) {
      reasons.add('Psykisk helseproblem inngår som en moderat risikofaktor.');
    }
    if (assessment.closeFamilyAlcoholProblems) {
      reasons.add('Alkoholproblemer i nær familie inngår som støtteinformasjon.');
    }

    // Faste sikkerhetsregler: beskyttende forhold overstyrer ikke disse.
    if (hasPossibleDependence || hasMorningAlcohol) {
      return MrmCraRecommendationResult(
        recommendation: MrmCraRecommendation.abstinence,
        auditTotalScore: total,
        significantRiskFactorCount: significant.length,
        reasons: List.unmodifiable(reasons),
      );
    }

    // Tre eller flere betydelige faktorer gir rød anbefaling i denne
    // foreløpige operasjonaliseringen.
    if (significant.length >= 3) {
      reasons.add('Tre eller flere betydelige risikofaktorer er registrert.');
      return MrmCraRecommendationResult(
        recommendation: MrmCraRecommendation.abstinence,
        auditTotalScore: total,
        significantRiskFactorCount: significant.length,
        reasons: List.unmodifiable(reasons),
      );
    }

    // AUDIT >= 16 kan ikke gi grønn anbefaling, men betyr ikke automatisk rødt.
    if (total >= 16) {
      reasons.add('Samlet risiko er usikker eller forhøyet; prøveperiode med avhold anbefales som utgangspunkt.');
      return MrmCraRecommendationResult(
        recommendation: MrmCraRecommendation.trialAbstinence,
        auditTotalScore: total,
        significantRiskFactorCount: significant.length,
        reasons: List.unmodifiable(reasons),
      );
    }

    // To betydelige faktorer, tidligere mislykkede forsøk eller psykisk
    // helseproblem gir gul anbefaling, men ikke automatisk rød.
    if (significant.length >= 2 ||
        assessment.previousUnsuccessfulAttempts ||
        assessment.mentalHealthCondition) {
      reasons.add('Kartleggingen tilsier en mer forsiktig prøveperiode med avhold.');
      return MrmCraRecommendationResult(
        recommendation: MrmCraRecommendation.trialAbstinence,
        auditTotalScore: total,
        significantRiskFactorCount: significant.length,
        reasons: List.unmodifiable(reasons),
      );
    }

    // Familiehistorikk alene og beskyttende faktorer endrer ikke kategorien.
    reasons.add('Ingen av de definerte tersklene for gul eller rød anbefaling er nådd.');
    return MrmCraRecommendationResult(
      recommendation: MrmCraRecommendation.moderation,
      auditTotalScore: total,
      significantRiskFactorCount: significant.length,
      reasons: List.unmodifiable(reasons),
    );
  }
}
