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
