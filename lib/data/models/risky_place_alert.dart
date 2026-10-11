class RiskyPlaceAlert {
  final String id;
  final String riskyPlaceId;
  final String daysOfWeek;
  final String fromTime;
  final String toTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RiskyPlaceAlert({
    required this.id,
    required this.riskyPlaceId,
    required this.daysOfWeek,
    required this.fromTime,
    required this.toTime,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'risky_place_id': riskyPlaceId,
      'days_of_week': daysOfWeek,
      'from_time': fromTime,
      'to_time': toTime,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory RiskyPlaceAlert.fromMap(Map<String, dynamic> map) {
    return RiskyPlaceAlert(
      id: map['id'] as String,
      riskyPlaceId: map['risky_place_id'] as String,
      daysOfWeek: map['days_of_week'] as String,
      fromTime: map['from_time'] as String,
      toTime: map['to_time'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
