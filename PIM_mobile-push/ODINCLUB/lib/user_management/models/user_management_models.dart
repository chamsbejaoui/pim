class ClubModel {
  ClubModel({
    required this.id,
    required this.name,
    required this.league,
    this.country,
    required this.status,
  });

  final String id;
  final String name;
  final String league;
  final String? country;
  final String status;

  factory ClubModel.fromJson(Map<String, dynamic> json) {
    return ClubModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      league: (json['league'] ?? '').toString(),
      country: json['country']?.toString(),
      status: (json['status'] ?? '').toString(),
    );
  }
}

class UserModel {
  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.photoUrl,
    this.clubId,
    required this.role,
    required this.status,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? photoUrl;
  final String? clubId;
  final String role;
  final String status;

  String get fullName => '$firstName $lastName';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      photoUrl: json['photoUrl']?.toString(),
      clubId: (json['clubId'] ?? json['club']?['_id'])?.toString(),
      role: (json['role'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
    );
  }
}

class SessionModel {
  SessionModel({
    required this.token,
    required this.userId,
    required this.role,
    required this.email,
    required this.status,
    required this.clubId,
    this.clubName,
    this.firstName,
    this.lastName,
    this.photoUrl,
  });

  final String token;
  final String userId;
  final String role;
  final String email;
  final String status;
  final String? clubId;
  final String? clubName;
  final String? firstName;
  final String? lastName;
  final String? photoUrl;
}
