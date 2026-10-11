import 'package:flutter/material.dart';

class AssessmentHeader extends StatelessWidget {
  final String title;
  final String step;
  final String description;

  const AssessmentHeader({
    super.key,
    required this.title,
    required this.step,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          step,
          style: TextStyle(
            fontSize: 14,
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          title,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          description,
          style: TextStyle(
            fontSize: 16,
            color: colors.onSurface.withValues(alpha: 0.78),
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}