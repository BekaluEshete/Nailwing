class UserProfile {
  final int id;
  final String fullName;
  final String email;
  final int? age;
  final String? gender;
  final String? nationality;
  final String? language;
  final String? profileImageUrl;
  final bool rememberMe;
  final DateTime? dateJoined;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.age,
    this.gender,
    this.nationality,
    this.language,
    this.profileImageUrl,
    this.rememberMe = false,
    this.dateJoined,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? 0,
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      age: json['age'],
      gender: json['gender'],
      nationality: json['nationality'],
      language: json['language'],
      profileImageUrl: json['profileImageUrl'] ?? json['profileImage'],
      rememberMe: json['rememberMe'] ?? false,
      dateJoined: json['date_joined'] != null
          ? DateTime.parse(json['date_joined'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'age': age,
      'gender': gender,
      'nationality': nationality,
      'language': language,
      'profileImageUrl': profileImageUrl,
      'rememberMe': rememberMe,
      'date_joined': dateJoined?.toIso8601String(),
    };
  }

  UserProfile copyWith({
    int? id,
    String? fullName,
    String? email,
    int? age,
    String? gender,
    String? nationality,
    String? language,
    String? profileImageUrl,
    bool? rememberMe,
    DateTime? dateJoined,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      nationality: nationality ?? this.nationality,
      language: language ?? this.language,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      rememberMe: rememberMe ?? this.rememberMe,
      dateJoined: dateJoined ?? this.dateJoined,
    );
  }
}

