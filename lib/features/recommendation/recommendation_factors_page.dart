import 'package:flutter/material.dart';

import '../../core/widgets/assessment_header.dart';
import '../../core/widgets/info_icon.dart';
import '../../core/widgets/primary_button.dart';

import 'data/recommendation_factors.dart';

class RecommendationFactorsPage extends StatefulWidget {
  const RecommendationFactorsPage({super.key});

  @override
  State<RecommendationFactorsPage> createState() =>
      _RecommendationFactorsPageState();
}

class _RecommendationFactorsPageState
    extends State<RecommendationFactorsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kartlegging'),
      ),
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
                            value: factor.selected,
                            onChanged: (value) {
                              setState(() {
                                factor.selected = value ?? false;
                              });
                            },
                            title: Text(factor.title),
                            controlAffinity:
                            ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
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
                  // Neste steg kommer senere
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}