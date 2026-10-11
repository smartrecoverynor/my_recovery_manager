class RecommendationFactor {
  final String title;
  final String? infoTitle;
  final String? infoMessage;
  bool selected;

  RecommendationFactor({
    required this.title,
    this.infoTitle,
    this.infoMessage,
    this.selected = false,
  });
}
