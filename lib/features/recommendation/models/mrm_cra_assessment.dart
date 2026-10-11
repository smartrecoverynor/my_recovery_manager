/// Midlertidige opplysninger som brukes under MRM-CRAs førstegangsvurdering.
///
/// Klassen har ingen database- eller filtilkobling. Opprett instansen når
/// kartleggingen starter, og kast den når brukeren har valgt mål eller
/// avbryter oppsettet.
///
/// auditScores inneholder faktiske AUDIT-poeng, ikke indeksene til svarene:
/// - spørsmål 1–8: 0–4 poeng
/// - spørsmål 9–10: 0, 2 eller 4 poeng
///
/// Ikke serialiser denne modellen til database, SharedPreferences, logger
/// eller backup.
enum AuditInterpretationCategory {
  woman,
  man,
  otherOrUnspecified,
}

class MrmCraAssessment {
  MrmCraAssessment({
    required this.auditInterpretationCategory,
  });

  /// Kategori som brukes midlertidig ved tolkning av AUDIT-totalen.
  AuditInterpretationCategory? auditInterpretationCategory;

  /// AUDIT-poeng for spørsmål 1–10. Null betyr at spørsmålet ikke er besvart.
  final List<int?> auditScores = List<int?>.filled(10, null);

  /// Hvor viktig brukeren synes det er å endre alkoholbruken (1–10).
  int? motivationImportance;

  /// Brukerens tro på egen evne til å endre alkoholbruken (1–10).
  int? motivationConfidence;

  /// Risikofaktorer og beskyttende faktorer fra vurderingssteget.
  bool closeFamilyAlcoholProblems = false;
  bool mentalHealthCondition = false;
  bool possiblePhysicalDependence = false;
  bool supportivePeople = false;
  bool employedOrInEducation = false;
  bool previousUnsuccessfulAttempts = false;

  /// Oversetter indeks for valgt svar (0-basert) til faktiske AUDIT-poeng.
  ///
  /// [questionIndex] er 0-basert: 0 betyr spørsmål 1, 9 betyr spørsmål 10.
  /// [answerIndex] er 0-basert plassering i spørsmålets svarliste.
  /// Spørsmål 1–8 har fem svaralternativer (0–4 poeng). Spørsmål 9–10
  /// har tre svaralternativer som gir henholdsvis 0, 2 og 4 poeng.
  static int scoreForAnswerIndex({
    required int questionIndex,
    required int answerIndex,
  }) {
    if (questionIndex < 0 || questionIndex >= 10) {
      throw RangeError.range(questionIndex, 0, 9, 'questionIndex');
    }

    final maxAnswerIndex = questionIndex < 8 ? 4 : 2;
    if (answerIndex < 0 || answerIndex > maxAnswerIndex) {
      throw RangeError.range(answerIndex, 0, maxAnswerIndex, 'answerIndex');
    }

    return questionIndex < 8 ? answerIndex : answerIndex * 2;
  }

  /// Registrerer svaret som faktisk AUDIT-skår i den midlertidige modellen.
  void setAuditAnswer({
    required int questionIndex,
    required int answerIndex,
  }) {
    auditScores[questionIndex] = scoreForAnswerIndex(
      questionIndex: questionIndex,
      answerIndex: answerIndex,
    );
  }

  /// Samlet AUDIT-skår når alle ti spørsmål er besvart.
  int? get auditTotalScore {
    if (!auditComplete) return null;
    return auditScores.fold<int>(0, (total, score) => total + score!);
  }

  bool get auditComplete => auditScores.every((score) => score != null);

  /// AUDIT 4: tap av kontroll.
  int? get auditItem4 => auditScores[3];

  /// AUDIT 5: forsømmelse av forpliktelser.
  int? get auditItem5 => auditScores[4];

  /// AUDIT 6: behov for morgenalkohol.
  int? get auditItem6 => auditScores[5];

  /// AUDIT 8: hukommelsestap.
  int? get auditItem8 => auditScores[7];

  /// AUDIT 9: alkoholrelatert skade.
  int? get auditItem9 => auditScores[8];

  /// AUDIT 10: bekymring fra andre.
  int? get auditItem10 => auditScores[9];

  bool get motivationComplete =>
      motivationImportance != null && motivationConfidence != null;

  /// Nullstiller kartleggingsverdiene dersom oppsettet avbrytes eller startes
  /// på nytt. Etter fullført målvalg bør hele instansen i tillegg kastes.
  void clear() {
    auditInterpretationCategory = null;

    for (var i = 0; i < auditScores.length; i++) {
      auditScores[i] = null;
    }

    motivationImportance = null;
    motivationConfidence = null;
    closeFamilyAlcoholProblems = false;
    mentalHealthCondition = false;
    possiblePhysicalDependence = false;
    supportivePeople = false;
    employedOrInEducation = false;
    previousUnsuccessfulAttempts = false;
  }
}
