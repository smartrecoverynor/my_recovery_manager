class Plan {
  final String id;
  final String userId;
  final String situationText;
  final String category;
  final DateTime plannedDate;
  final String? plannedTime;
  final String repeat;
  final int? repeatCount;
  final DateTime? repeatUntil;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Plan({
    required this.id,
    required this.userId,
    required this.situationText,
    required this.category,
    required this.plannedDate,
    this.plannedTime,
    required this.repeat,
    this.repeatCount,
    this.repeatUntil,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });
}
