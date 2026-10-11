class Reminder {
  final String id;
  final String planId;

  /// 'relative' eller 'custom'
  final String type;

  /// Brukes når type == 'relative'.
  /// Antall minutter før hendelsen.
  final int? offsetMinutes;

  /// Brukes når type == 'custom'.
  final DateTime? scheduledAt;

  /// Kort, valgfri tekst som vises i varslingen.
  final String? message;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Reminder({
    required this.id,
    required this.planId,
    required this.type,
    this.offsetMinutes,
    this.scheduledAt,
    this.message,
    required this.createdAt,
    required this.updatedAt,
  });
}
