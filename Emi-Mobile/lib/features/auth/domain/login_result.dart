class LoginResult {
  const LoginResult({
    required this.token,
    required this.tokenType,
    required this.user,
  });

  final String token;
  final String tokenType;
  final dynamic user;
}
