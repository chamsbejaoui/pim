class StaffMember {
  final String id;
  final String clubId;
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final String? nationality;
  final String? photoUrl;
  final String? email;
  final String? phone;
  final String role;
  final String? specialization;
  final String? licenseNumber;
  final String? teamId;
  final Map<String, dynamic>? team;
  final DateTime? contractStartDate;
  final DateTime? contractEndDate;
  final double? salary;
  final String status;
  final String? bio;
  final DateTime? createdAt;

  StaffMember({
    required this.id,
    required this.clubId,
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    this.nationality,
    this.photoUrl,
    this.email,
    this.phone,
    required this.role,
    this.specialization,
    this.licenseNumber,
    this.teamId,
    this.team,
    this.contractStartDate,
    this.contractEndDate,
    this.salary,
    this.status = 'active',
    this.bio,
    this.createdAt,
  });

  String get fullName => '$firstName $lastName';
  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
  String? get teamName => team?['name'];

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      id: json['id'] ?? '',
      clubId: json['clubId'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'].toString())
          : null,
      nationality: json['nationality'],
      photoUrl: json['photoUrl'],
      email: json['email'],
      phone: json['phone'],
      role: json['role'] ?? '',
      specialization: json['specialization'],
      licenseNumber: json['licenseNumber'],
      teamId: json['teamId'],
      team: json['team'] is Map<String, dynamic> ? json['team'] : null,
      contractStartDate: json['contractStartDate'] != null
          ? DateTime.tryParse(json['contractStartDate'].toString())
          : null,
      contractEndDate: json['contractEndDate'] != null
          ? DateTime.tryParse(json['contractEndDate'].toString())
          : null,
      salary: json['salary'] != null
          ? double.tryParse(json['salary'].toString())
          : null,
      status: json['status'] ?? 'active',
      bio: json['bio'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'dateOfBirth': dateOfBirth?.toIso8601String().split('T').first,
    'nationality': nationality,
    'photoUrl': photoUrl,
    'email': email,
    'phone': phone,
    'role': role,
    'specialization': specialization,
    'licenseNumber': licenseNumber,
    'teamId': teamId,
    'contractStartDate': contractStartDate?.toIso8601String().split('T').first,
    'contractEndDate': contractEndDate?.toIso8601String().split('T').first,
    'salary': salary,
    'bio': bio,
  };
}
