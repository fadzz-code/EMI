import 'dart:convert';
import 'dart:io';

import 'e2e_config.dart';

class E2eApiHelper {
  const E2eApiHelper();

  Future<void> waitUntilReady({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final deadline = DateTime.now().add(timeout);
    Object? lastError;
    while (DateTime.now().isBefore(deadline)) {
      try {
        final response = await _request('GET', '/public/login-branding');
        if (response.statusCode == HttpStatus.ok) return;
        lastError = 'HTTP ${response.statusCode}: ${response.body}';
      } on Object catch (error) {
        lastError = error;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    throw StateError(
      'Backend tidak siap di ${E2eConfig.apiBaseUrl}: $lastError',
    );
  }

  Future<void> verifyDemoAccounts() async {
    await _verifyAccount(
      E2eConfig.adminEmail,
      E2eConfig.adminPassword,
      'admin',
    );
    await _verifyAccount(
      E2eConfig.teacherEmail,
      E2eConfig.teacherPassword,
      'teacher',
    );
    await _verifyAccount(
      E2eConfig.studentEmail,
      E2eConfig.studentPassword,
      'student',
    );
  }

  Future<void> _verifyAccount(
    String email,
    String password,
    String expectedRole,
  ) async {
    final login = await _request(
      'POST',
      '/auth/login',
      body: {
        'email': email,
        'password': password,
        'device_name': 'emi-mobile-e2e-readiness',
      },
    );
    if (login.statusCode != HttpStatus.ok) {
      throw StateError(
        'Akun demo $expectedRole gagal login: HTTP ${login.statusCode} ${login.body}',
      );
    }
    final payload = jsonDecode(login.body) as Map<String, dynamic>;
    final data = payload['data'] as Map<String, dynamic>;
    final token = data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw StateError('Akun demo $expectedRole tidak menghasilkan token');
    }
    try {
      final me = await _request('GET', '/auth/me', token: token);
      if (me.statusCode != HttpStatus.ok || !me.body.contains(expectedRole)) {
        throw StateError(
          'Akun demo $expectedRole tidak siap: HTTP ${me.statusCode} ${me.body}',
        );
      }
    } finally {
      await _request('POST', '/auth/logout', token: token);
    }
  }

  Future<_ApiResponse> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final base = E2eConfig.apiBaseUrl.replaceFirst(RegExp(r'/$'), '');
      final request = await client.openUrl(method, Uri.parse('$base$path'));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (token != null) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }
      final response = await request.close();
      return _ApiResponse(
        response.statusCode,
        await utf8.decoder.bind(response).join(),
      );
    } finally {
      client.close(force: true);
    }
  }
}

class _ApiResponse {
  const _ApiResponse(this.statusCode, this.body);

  final int statusCode;
  final String body;
}
