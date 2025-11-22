class LoginData {
  String email;
  String password;
  bool rememberMe;

  LoginData({
    required this.email,
    required this.password,
    required this.rememberMe,
  });

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password, 'rememberMe': rememberMe};
  }
}

// Response models
class LoginResponse {
  final bool success;
  final String message;
  final LoginResponseData? data;
  final Map<String, dynamic>? errors;

  LoginResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? LoginResponseData.fromJson(json['data']) : null,
      errors: json['errors'] as Map<String, dynamic>?,
    );
  }
}

class LoginResponseData {
  final UserData user;
  final TokenData tokens;

  LoginResponseData({
    required this.user,
    required this.tokens,
  });

  factory LoginResponseData.fromJson(Map<String, dynamic> json) {
    return LoginResponseData(
      user: UserData.fromJson(json['user']),
      tokens: TokenData.fromJson(json['tokens']),
    );
  }
}

class UserData {
  final int id;
  final String fullName;
  final String email;
  final int? age;
  final String? gender;
  final String? nationality;
  final String? language;
  final bool? rememberMe;

  UserData({
    required this.id,
    required this.fullName,
    required this.email,
    this.age,
    this.gender,
    this.nationality,
    this.language,
    this.rememberMe,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] ?? 0,
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      age: json['age'],
      gender: json['gender'],
      nationality: json['nationality'],
      language: json['language'],
      rememberMe: json['rememberMe'],
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
      'rememberMe': rememberMe,
    };
  }
}

class TokenData {
  final String access;
  final String refresh;

  TokenData({
    required this.access,
    required this.refresh,
  });

  factory TokenData.fromJson(Map<String, dynamic> json) {
    return TokenData(
      access: json['access'] ?? '',
      refresh: json['refresh'] ?? '',
    );
  }
}