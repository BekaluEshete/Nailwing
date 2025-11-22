// registration_model.dart
import 'login_model.dart';

class RegistrationData {
  String fullName;
  String age;
  String gender;
  String email;
  String password;
  String nationality;
  String language;
  String? profileImage;

  RegistrationData({
    required this.fullName,
    required this.age,
    required this.gender,
    required this.email,
    required this.password,
    required this.nationality,
    required this.language,
    this.profileImage,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'age': age,
      'gender': gender,
      'email': email,
      'password': password,
      'password2': password, // Backend requires password2
      'nationality': nationality,
      'language': language,
      'profileImage': profileImage,
    };
  }

  RegistrationData copyWith({
    String? fullName,
    String? age,
    String? gender,
    String? email,
    String? password,
    String? nationality,
    String? language,
    String? profileImage,
  }) {
    return RegistrationData(
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      email: email ?? this.email,
      password: password ?? this.password,
      nationality: nationality ?? this.nationality,
      language: language ?? this.language,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}

class Country {
  final String name;
  final String code;
  final List<String> languages;

  Country({required this.name, required this.code, required this.languages});
}

class Language {
  final String name;
  final String code;

  Language({required this.name, required this.code});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Language &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          code == other.code;

  @override
  int get hashCode => name.hashCode ^ code.hashCode;
}

// Registration Response Models
class RegistrationResponse {
  final bool success;
  final String message;
  final RegistrationResponseData? data;
  final Map<String, dynamic>? errors;

  RegistrationResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory RegistrationResponse.fromJson(Map<String, dynamic> json) {
    return RegistrationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null 
          ? RegistrationResponseData.fromJson(json['data']) 
          : null,
      errors: json['errors'] as Map<String, dynamic>?,
    );
  }
}

class RegistrationResponseData {
  final UserData user;
  final TokenData tokens;

  RegistrationResponseData({
    required this.user,
    required this.tokens,
  });

  factory RegistrationResponseData.fromJson(Map<String, dynamic> json) {
    return RegistrationResponseData(
      user: UserData.fromJson(json['user']),
      tokens: TokenData.fromJson(json['tokens']),
    );
  }
}
