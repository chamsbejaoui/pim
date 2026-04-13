class Team {
  final String id;
  final String clubId;
  final String name;
  final String? categoryId;
  final Map<String, dynamic>? category;
  final DateTime? createdAt;

  Team({
    required this.id,
    required this.clubId,
    required this.name,
    this.categoryId,
    this.category,
    this.createdAt,
  });

  String? get categoryName => category?['name'];

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] ?? '',
      clubId: json['clubId'] ?? '',
      name: json['name'] ?? '',
      categoryId: json['categoryId'],
      category: json['category'] is Map<String, dynamic> ? json['category'] : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'categoryId': categoryId,
  };
}
