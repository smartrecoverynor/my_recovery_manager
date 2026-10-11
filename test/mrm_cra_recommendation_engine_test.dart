import 'package:flutter_test/flutter_test.dart';
import 'package:my_recovery_manager/features/recommendation/models/mrm_cra_assessment.dart';
import 'package:my_recovery_manager/features/recommendation/models/mrm_cra_recommendation_engine.dart';

MrmCraAssessment assessmentWithScores(List<int> scores) {
  final assessment = MrmCraAssessment(
    auditInterpretationCategory: AuditInterpretationCategory.otherOrUnspecified,
  );
  for (var i = 0; i < scores.length; i++) {
    final score = scores[i];
    final answerIndex = i < 8 ? score : score ~/ 2;
    assessment.setAuditAnswer(questionIndex: i, answerIndex: answerIndex);
  }
  return assessment;
}

void main() {
  const engine = MrmCraRecommendationEngine();

  group('MRM-CRA faste regler', () {
    test('krever fullstendig AUDIT', () {
      final assessment = MrmCraAssessment(
        auditInterpretationCategory: AuditInterpretationCategory.otherOrUnspecified,
      );
      expect(() => engine.recommend(assessment), throwsStateError);
    });

    test('mulig fysisk avhengighet gir rød uansett beskyttende faktorer', () {
      final a = assessmentWithScores(List<int>.filled(10, 0));
      a.possiblePhysicalDependence = true;
      a.supportivePeople = true;
      a.employedOrInEducation = true;
      expect(engine.recommend(a).recommendation, MrmCraRecommendation.abstinence);
    });

    test('ethvert positivt svar på AUDIT 6 gir rød', () {
      final a = assessmentWithScores([0, 0, 0, 0, 0, 1, 0, 0, 0, 0]);
      expect(engine.recommend(a).recommendation, MrmCraRecommendation.abstinence);
    });

    test('AUDIT 15 kan være grønn når øvrige indikatorer ikke er til stede', () {
      final a = assessmentWithScores([3, 3, 3, 1, 1, 0, 1, 1, 0, 2]);
      expect(a.auditTotalScore, 15);
      expect(engine.recommend(a).recommendation, MrmCraRecommendation.moderation);
    });

    test('AUDIT 16 utelukker grønn, men gir ikke automatisk rød', () {
      final a = assessmentWithScores([2, 3, 3, 1, 1, 0, 1, 1, 2, 2]);
      expect(a.auditTotalScore, 16);
      expect(engine.recommend(a).recommendation, MrmCraRecommendation.trialAbstinence);
    });

    test('tre betydelige faktorer gir rød', () {
      final a = assessmentWithScores([0, 0, 0, 2, 2, 0, 0, 2, 0, 0]);
      expect(engine.recommend(a).recommendation, MrmCraRecommendation.abstinence);
    });

    test('to betydelige faktorer gir gul når ingen rød regel gjelder', () {
      final a = assessmentWithScores([0, 0, 0, 2, 2, 0, 0, 0, 0, 0]);
      expect(engine.recommend(a).recommendation, MrmCraRecommendation.trialAbstinence);
    });

    test('tidligere mislykket forsøk alene trekker mot gul, ikke automatisk rød', () {
      final a = assessmentWithScores(List<int>.filled(10, 0));
      a.previousUnsuccessfulAttempts = true;
      expect(engine.recommend(a).recommendation, MrmCraRecommendation.trialAbstinence);
    });

    test('psykisk helseproblem alene gir gul, ikke rød', () {
      final a = assessmentWithScores(List<int>.filled(10, 0));
      a.mentalHealthCondition = true;
      expect(engine.recommend(a).recommendation, MrmCraRecommendation.trialAbstinence);
    });

    test('familiehistorikk alene endrer ikke grønn til gul', () {
      final a = assessmentWithScores(List<int>.filled(10, 0));
      a.closeFamilyAlcoholProblems = true;
      expect(engine.recommend(a).recommendation, MrmCraRecommendation.moderation);
    });

    test('AUDIT 20 med gode beskyttende faktorer og uten morgenalkohol er gul', () {
      final a = assessmentWithScores([4, 4, 4, 1, 1, 0, 1, 1, 2, 2]);
      a.supportivePeople = true;
      a.employedOrInEducation = true;
      expect(a.auditTotalScore, 20);
      expect(engine.recommend(a).recommendation, MrmCraRecommendation.trialAbstinence);
    });
  });

  group('ti profiler – kategoriutfall', () {
    test('profilene gir forventet kategori i syntetiske grense-/kombinasjonstester', () {
      final profiles = <({List<int> scores, bool dependence, bool previous, bool mental, MrmCraRecommendation expected})>[
        (scores: List<int>.filled(10, 0), dependence: false, previous: false, mental: false, expected: MrmCraRecommendation.moderation),
        (scores: [2, 2, 2, 1, 1, 0, 1, 1, 0, 2], dependence: false, previous: false, mental: false, expected: MrmCraRecommendation.moderation),
        (scores: [3, 3, 3, 1, 1, 0, 0, 0, 0, 0], dependence: false, previous: false, mental: false, expected: MrmCraRecommendation.moderation),
        (scores: [3, 3, 3, 2, 1, 0, 1, 1, 0, 2], dependence: false, previous: false, mental: false, expected: MrmCraRecommendation.trialAbstinence),
        (scores: [0, 0, 0, 2, 2, 0, 0, 2, 0, 0], dependence: false, previous: false, mental: false, expected: MrmCraRecommendation.abstinence),
        (scores: [4, 4, 4, 1, 1, 0, 1, 1, 2, 2], dependence: false, previous: false, mental: false, expected: MrmCraRecommendation.trialAbstinence),
        (scores: [2, 2, 2, 1, 1, 0, 1, 1, 0, 2], dependence: false, previous: true, mental: false, expected: MrmCraRecommendation.trialAbstinence),
        (scores: [0, 0, 0, 2, 2, 0, 0, 2, 0, 0], dependence: true, previous: false, mental: false, expected: MrmCraRecommendation.abstinence),
        (scores: [2, 2, 2, 0, 0, 0, 1, 1, 0, 0], dependence: false, previous: false, mental: false, expected: MrmCraRecommendation.moderation),
        (scores: [3, 3, 3, 1, 1, 0, 1, 1, 0, 2], dependence: false, previous: false, mental: true, expected: MrmCraRecommendation.trialAbstinence),
      ];

      for (var i = 0; i < profiles.length; i++) {
        final profile = profiles[i];
        final a = assessmentWithScores(profile.scores);
        a.possiblePhysicalDependence = profile.dependence;
        a.previousUnsuccessfulAttempts = profile.previous;
        a.mentalHealthCondition = profile.mental;
        expect(
          engine.recommend(a).recommendation,
          profile.expected,
          reason: 'Syntetisk profil ${i + 1}',
        );
      }
    });
  });
}
