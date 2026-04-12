class Category {
  final String id;
  final String clubId;
  final String name;
  final int? ageMin;
  final int? ageMax;
  final DateTime? createdAt;

  Category({
    required this.id,
    required this.clubId,
    required this.name,
    this.ageMin,
    this.ageMax,
    this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      clubId: json['clubId'] ?? '',
      name: json['name'] ?? '',
      ageMin: json['ageMin'] != null ? int.tryParse(json['ageMin'].toString()) : null,
      ageMax: json['ageMax'] != null ? int.tryParse(json['ageMax'].toString()) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'ageMin': ageMin,
    'ageMax': ageMax,
  };
}
