import 'package:flutter_test/flutter_test.dart';
import 'package:my_recovery_manager/features/recommendation/models/mrm_cra_assessment.dart';

MrmCraAssessment createAssessment() => MrmCraAssessment(
      auditInterpretationCategory: AuditInterpretationCategory.otherOrUnspecified,
    );

void main() {
  group('AUDIT-poengberegning', () {
    test('spørsmål 1–8 gir 0–4 poeng i samme rekkefølge som svarene', () {
      for (var questionIndex = 0; questionIndex < 8; questionIndex++) {
        for (var answerIndex = 0; answerIndex <= 4; answerIndex++) {
          expect(
            MrmCraAssessment.scoreForAnswerIndex(
              questionIndex: questionIndex,
              answerIndex: answerIndex,
            ),
            answerIndex,
            reason: 'Spørsmål ${questionIndex + 1}, svarindeks $answerIndex',
          );
        }
      }
    });

    test('spørsmål 9 og 10 gir 0, 2 og 4 poeng', () {
      for (var questionIndex = 8; questionIndex < 10; questionIndex++) {
        expect(
          MrmCraAssessment.scoreForAnswerIndex(
            questionIndex: questionIndex,
            answerIndex: 0,
          ),
          0,
        );
        expect(
          MrmCraAssessment.scoreForAnswerIndex(
            questionIndex: questionIndex,
            answerIndex: 1,
          ),
          2,
        );
        expect(
          MrmCraAssessment.scoreForAnswerIndex(
            questionIndex: questionIndex,
            answerIndex: 2,
          ),
          4,
        );
      }
    });

    test('avviser ugyldig spørsmålsindeks og svarindeks', () {
      expect(
        () => MrmCraAssessment.scoreForAnswerIndex(
          questionIndex: -1,
          answerIndex: 0,
        ),
        throwsRangeError,
      );
      expect(
        () => MrmCraAssessment.scoreForAnswerIndex(
          questionIndex: 10,
          answerIndex: 0,
        ),
        throwsRangeError,
      );
      expect(
        () => MrmCraAssessment.scoreForAnswerIndex(
          questionIndex: 0,
          answerIndex: 5,
        ),
        throwsRangeError,
      );
      expect(
        () => MrmCraAssessment.scoreForAnswerIndex(
          questionIndex: 8,
          answerIndex: 3,
        ),
        throwsRangeError,
      );
    });
  });

  group('MrmCraAssessment', () {
    test('registrerer skår og viser ikke totalskår før alle spørsmål er besvart', () {
      final assessment = createAssessment();
      assessment.setAuditAnswer(questionIndex: 0, answerIndex: 3);

      expect(assessment.auditScores[0], 3);
      expect(assessment.auditComplete, isFalse);
      expect(assessment.auditTotalScore, isNull);
    });

    test('beregner totalskår korrekt når alle ti spørsmål er besvart', () {
      final assessment = createAssessment();
      for (var i = 0; i < 8; i++) {
        assessment.setAuditAnswer(questionIndex: i, answerIndex: 1);
      }
      assessment.setAuditAnswer(questionIndex: 8, answerIndex: 1);
      assessment.setAuditAnswer(questionIndex: 9, answerIndex: 2);

      expect(assessment.auditComplete, isTrue);
      expect(assessment.auditTotalScore, 8 + 2 + 4);
      expect(assessment.auditItem9, 2);
      expect(assessment.auditItem10, 4);
    });

    test('clear nullstiller alle kartleggingsdata', () {
      final assessment = createAssessment();
      for (var i = 0; i < 8; i++) {
        assessment.setAuditAnswer(questionIndex: i, answerIndex: 1);
      }
      assessment.setAuditAnswer(questionIndex: 8, answerIndex: 1);
      assessment.setAuditAnswer(questionIndex: 9, answerIndex: 2);
      assessment.motivationImportance = 8;
      assessment.motivationConfidence = 6;
      assessment.closeFamilyAlcoholProblems = true;
      assessment.mentalHealthCondition = true;
      assessment.possiblePhysicalDependence = true;
      assessment.supportivePeople = true;
      assessment.employedOrInEducation = true;
      assessment.previousUnsuccessfulAttempts = true;

      assessment.clear();

      expect(assessment.auditScores, everyElement(isNull));
      expect(assessment.auditComplete, isFalse);
      expect(assessment.auditTotalScore, isNull);
      expect(assessment.auditInterpretationCategory, isNull);
      expect(assessment.motivationImportance, isNull);
      expect(assessment.motivationConfidence, isNull);
      expect(assessment.closeFamilyAlcoholProblems, isFalse);
      expect(assessment.mentalHealthCondition, isFalse);
      expect(assessment.possiblePhysicalDependence, isFalse);
      expect(assessment.supportivePeople, isFalse);
      expect(assessment.employedOrInEducation, isFalse);
      expect(assessment.previousUnsuccessfulAttempts, isFalse);
    });
  });
}
