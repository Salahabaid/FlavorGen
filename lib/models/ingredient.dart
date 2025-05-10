class Ingredient {
  final int id;
  final String name;
  final String? image;
  final double? confidence;

  Ingredient({
    required this.id,
    required this.name,
    this.image,
    this.confidence,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id:
          json['id'] is int
              ? json['id']
              : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      image: json['image'],
      confidence:
          json['confidence'] != null
              ? (json['confidence'] as num).toDouble()
              : null,
    );
  }
}
