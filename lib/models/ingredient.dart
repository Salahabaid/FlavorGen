class Ingredient {
  final int id;
  final String name;
  final double? confidence;
  final List<double>? bbox; // [left, top, right, bottom]

  Ingredient({
    required this.id,
    required this.name,
    this.confidence,
    this.bbox, // <-- nouveau champ
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id:
          json['id'] is int
              ? json['id']
              : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      confidence:
          json['confidence'] != null
              ? (json['confidence'] as num).toDouble()
              : null,
      bbox: json['bbox'] != null
          ? List<double>.from(json['bbox'].map((x) => x.toDouble()))
          : null,
    );
  }
}
