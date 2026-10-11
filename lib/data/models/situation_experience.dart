class SituationExperience {
  final String id;
  final String situationId;
  final String userId;

  final String? whatWorked;
  final String? whatDidNotWork;
  final String? learning;

  final DateTime createdAt;
  final DateTime updatedAt;

  const SituationExperience({
    required this.id,
    required this.situationId,
    required this.userId,
    this.whatWorked,
    this.whatDidNotWork,
    this.learning,
    required this.createdAt,
    required this.updatedAt,
  });
}
