enum SituationCategory { red, yellow, green }

class Situation {
  final String id;
  final String userId;
  final String text;
  final SituationCategory category;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Situation({
    required this.id,
    required this.userId,
    required this.text,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
  });
}
