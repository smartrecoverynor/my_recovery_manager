import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/assessment_header.dart';
import '../../core/widgets/info_icon.dart';
import '../../core/widgets/primary_button.dart';
import 'data/recommendation_factors.dart';
import 'models/mrm_cra_assessment.dart';

class RecommendationFactorsPage extends StatefulWidget {
  final MrmCraAssessment? assessment;

  const RecommendationFactorsPage({super.key, this.assessment});

  @override
  State<RecommendationFactorsPage> createState() =>
      _RecommendationFactorsPageState();
}

class _RecommendationFactorsPageState
    extends State<RecommendationFactorsPage> {
  late final MrmCraAssessment _assessment;

  @override
  void initState() {
    super.initState();
    _assessment = widget.assessment ??
        MrmCraAssessment(
          auditInterpretationCategory:
              AuditInterpretationCategory.otherOrUnspecified,
        );
  }

  bool _isSelected(int index) {
    switch (index) {
      case 0:
        return _assessment.closeFamilyAlcoholProblems;
      case 1:
        return _assessment.mentalHealthCondition;
      case 2:
        return _assessment.possiblePhysicalDependence;
      case 3:
        return _assessment.supportivePeople;
      case 4:
        return _assessment.employedOrInEducation;
      case 5:
        return _assessment.previousUnsuccessfulAttempts;
      default:
        return false;
    }
  }

  void _setSelected(int index, bool selected) {
    switch (index) {
      case 0:
        _assessment.closeFamilyAlcoholProblems = selected;
        break;
      case 1:
        _assessment.mentalHealthCondition = selected;
        break;
      case 2:
        _assessment.possiblePhysicalDependence = selected;
        break;
      case 3:
        _assessment.supportivePeople = selected;
        break;
      case 4:
        _assessment.employedOrInEducation = selected;
        break;
      case 5:
        _assessment.previousUnsuccessfulAttempts = selected;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Kartlegging')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const AssessmentHeader(
                step: 'Steg 3 av 5',
                title: 'Faglig vurdering',
                description:
                    'Svar på noen få spørsmål som hjelper oss å gi en best mulig anbefaling.',
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: recommendationFactors.length,
                  itemBuilder: (context, index) {
                    final factor = recommendationFactors[index];

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            value: _isSelected(index),
                            onChanged: (value) {
                              setState(() {
                                _setSelected(index, value ?? false);
                              });
                            },
                            title: Text(
                              factor.title,
                              style: TextStyle(color: colors.onSurface),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            activeColor: colors.primary,
                            checkColor: colors.onPrimary,
                          ),
                        ),
                        if (factor.infoTitle != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: InfoIcon(
                              title: factor.infoTitle!,
                              message: factor.infoMessage!,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              PrimaryButton(
                text: 'Neste',
                onPressed: () {
                  context.go('/recommendation', extra: _assessment);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
