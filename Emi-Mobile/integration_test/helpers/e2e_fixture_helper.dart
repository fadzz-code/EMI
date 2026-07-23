import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'e2e_config.dart';

class E2eFixtureHelper {
  E2eFixtureHelper({HttpClient? client, String? tokenOverride})
    : _client = client ?? HttpClient(),
      _tokenOverride = tokenOverride,
      runId =
          '${DateTime.now().toUtc().microsecondsSinceEpoch}-${pid.toRadixString(36)}';

  static const prefix = '[E2E Admin]';

  final HttpClient _client;
  final String? _tokenOverride;
  final String runId;
  final List<({String path, String id, bool remainsInactive})> _cleanup = [];
  final List<String> _usersToDeactivate = [];
  String? _adminToken;

  String unique(String value) => '$prefix $value $runId';

  Future<String> loginAdmin() async {
    if (_adminToken case final token?) return token;
    _adminToken = await loginToken(
      E2eConfig.adminEmail,
      E2eConfig.adminPassword,
    );
    return _adminToken!;
  }

  Future<String> loginToken(String email, String password) async {
    final response = await post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
        'device_name': 'emi-mobile-admin-e2e-$runId',
      },
      authenticated: false,
    );
    final token = response.requireDataMap()['token'];
    if (token is! String || token.isEmpty) {
      throw StateError(
        '${response.context}: data.token must be a non-empty string',
      );
    }
    return token;
  }

  Future<E2eJsonResponse> get(
    String path, {
    Map<String, Object?> query = const {},
    bool authenticated = true,
    Set<int> expectedStatuses = const {HttpStatus.ok},
  }) => _request(
    'GET',
    path,
    query: query,
    authenticated: authenticated,
    expectedStatuses: expectedStatuses,
  );

  Future<E2eJsonResponse> post(
    String path, {
    Map<String, Object?>? body,
    Map<String, Object?> query = const {},
    bool authenticated = true,
    Set<int> expectedStatuses = const {HttpStatus.ok, HttpStatus.created},
  }) => _request(
    'POST',
    path,
    body: body,
    query: query,
    authenticated: authenticated,
    expectedStatuses: expectedStatuses,
  );

  Future<E2eJsonResponse> put(
    String path, {
    Map<String, Object?>? body,
    Map<String, Object?> query = const {},
    bool authenticated = true,
    Set<int> expectedStatuses = const {HttpStatus.ok},
  }) => _request(
    'PUT',
    path,
    body: body,
    query: query,
    authenticated: authenticated,
    expectedStatuses: expectedStatuses,
  );

  Future<E2eJsonResponse> patch(
    String path, {
    Map<String, Object?>? body,
    Map<String, Object?> query = const {},
    bool authenticated = true,
    Set<int> expectedStatuses = const {HttpStatus.ok},
  }) => _request(
    'PATCH',
    path,
    body: body,
    query: query,
    authenticated: authenticated,
    expectedStatuses: expectedStatuses,
  );

  Future<E2eJsonResponse> delete(
    String path, {
    Map<String, Object?>? body,
    Map<String, Object?> query = const {},
    bool authenticated = true,
    Set<int> expectedStatuses = const {HttpStatus.ok, HttpStatus.noContent},
  }) => _request(
    'DELETE',
    path,
    body: body,
    query: query,
    authenticated: authenticated,
    expectedStatuses: expectedStatuses,
  );

  void cleanupById(
    String collectionPath,
    Object id, {
    bool remainsInactive = false,
  }) {
    final value = id.toString();
    if (value.isEmpty) throw ArgumentError.value(id, 'id', 'must not be empty');
    _cleanup.add((
      path: collectionPath,
      id: value,
      remainsInactive: remainsInactive,
    ));
  }

  void deactivateUserOnCleanup(Object id) {
    final value = id.toString();
    if (value.isEmpty) throw ArgumentError.value(id, 'id', 'must not be empty');
    _usersToDeactivate.add(value);
  }

  Future<E2eRegistrationFixture> register({
    required String requestedRole,
    Object? schoolId,
    Object? classId,
    String? fullName,
    String? email,
    String password = 'Password123',
  }) async {
    final safeRole = requestedRole.trim().toLowerCase();
    if (safeRole != 'teacher' && safeRole != 'student') {
      throw ArgumentError.value(
        requestedRole,
        'requestedRole',
        'must be teacher or student',
      );
    }
    final fixtureEmail = email ?? 'e2e-admin-$runId-$safeRole@example.test';
    final fixtureName = fullName ?? unique('Registration $safeRole');
    final response = await post(
      '/auth/register',
      authenticated: false,
      expectedStatuses: const {HttpStatus.created},
      body: {
        'full_name': fixtureName,
        'email': fixtureEmail,
        'password': password,
        'password_confirmation': password,
        'requested_role': safeRole,
        'school_id': schoolId,
        'class_id': classId,
      },
    );
    final data = response.requireDataMap();
    return E2eRegistrationFixture(
      response: response,
      userId: data['user_id']?.toString() ?? data['id']?.toString(),
      requestId:
          data['registration_request_id']?.toString() ??
          data['request_id']?.toString(),
      fullName: fixtureName,
      email: fixtureEmail,
      password: password,
      requestedRole: safeRole,
      status: data['status']?.toString(),
    );
  }

  Future<PlatformFile> createPdf({String name = 'basis-ai-e2e.pdf'}) async {
    final objects = <String>[
      '1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n',
      '2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n',
      '3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 200 200] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>\nendobj\n',
      '4 0 obj\n<< /Length 43 >>\nstream\nBT /F1 12 Tf 20 100 Td (Basis AI E2E) Tj ET\nendstream\nendobj\n',
      '5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n',
    ];
    final output = StringBuffer('%PDF-1.4\n');
    final offsets = <int>[0];
    for (final object in objects) {
      offsets.add(ascii.encode(output.toString()).length);
      output.write(object);
    }
    final xref = ascii.encode(output.toString()).length;
    output.write('xref\n0 6\n0000000000 65535 f \n');
    for (final offset in offsets.skip(1)) {
      output.writeln('${offset.toString().padLeft(10, '0')} 00000 n ');
    }
    output.write(
      'trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n$xref\n%%EOF\n',
    );
    final directory = await Directory.systemTemp.createTemp(
      'emi-basis-ai-$runId-',
    );
    final file = File('${directory.path}${Platform.pathSeparator}$name');
    final bytes = ascii.encode(output.toString());
    await file.writeAsBytes(bytes, flush: true);
    return PlatformFile(name: name, size: bytes.length, path: file.path);
  }

  Future<E2eJsonResponse> postMultipart(
    String path, {
    required PlatformFile file,
    String fileField = 'file',
    Map<String, String> fields = const {},
    Set<int> expectedStatuses = const {HttpStatus.ok, HttpStatus.created},
  }) async {
    if (!path.startsWith('/')) {
      throw ArgumentError.value(path, 'path', 'must start with /');
    }
    if (file.path == null) {
      throw ArgumentError.value(file, 'file', 'must have a path');
    }
    final uri = Uri.parse(
      '${E2eConfig.apiBaseUrl.replaceFirst(RegExp(r'/$'), '')}$path',
    );
    final boundary = 'emi-e2e-$runId';
    final request = await _client.postUrl(uri);
    request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'multipart/form-data; boundary=$boundary',
    );
    request.headers.set(
      HttpHeaders.authorizationHeader,
      'Bearer ${await loginAdmin()}',
    );
    for (final field in fields.entries) {
      request.write('--$boundary\r\n');
      request.write(
        'Content-Disposition: form-data; name="${field.key}"\r\n\r\n${field.value}\r\n',
      );
    }
    request.write('--$boundary\r\n');
    request.write(
      'Content-Disposition: form-data; name="$fileField"; filename="${file.name}"\r\n',
    );
    request.write('Content-Type: application/pdf\r\n\r\n');
    await request.addStream(File(file.path!).openRead());
    request.write('\r\n--$boundary--\r\n');
    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();
    final context = 'POST $uri returned HTTP ${response.statusCode}';
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('$context with invalid envelope; body: $body');
    }
    if (!expectedStatuses.contains(response.statusCode)) {
      throw StateError('$context: ${decoded['message']}; body: $body');
    }
    return E2eJsonResponse(
      statusCode: response.statusCode,
      success: decoded['success'] == true,
      message: decoded['message']?.toString() ?? '',
      data: decoded['data'],
      meta: decoded['meta'] is Map<String, dynamic>
          ? decoded['meta'] as Map<String, dynamic>
          : null,
      code: decoded['code']?.toString(),
      errors: decoded['errors'],
      body: Map.unmodifiable(decoded),
      context: context,
    );
  }

  Future<void> cleanup() async {
    final failures = <String>[];
    for (final id in _usersToDeactivate.reversed) {
      final path = '/users/${Uri.encodeComponent(id)}/status';
      try {
        await patch(
          path,
          body: {
            'status': 'inactive',
            'reason': 'Pembersihan fixture Admin E2E',
          },
        );
        final user = (await get(
          '/users/${Uri.encodeComponent(id)}',
        )).requireDataMap();
        if (user['status'] != 'inactive') {
          throw StateError('$path tidak menonaktifkan pengguna');
        }
      } on Object catch (error) {
        failures.add('$path: $error');
      }
    }
    _usersToDeactivate.clear();
    for (final target in _cleanup.reversed) {
      final path =
          '${target.path.replaceFirst(RegExp(r'/$'), '')}/${Uri.encodeComponent(target.id)}';
      try {
        final deleted = await delete(
          path,
          expectedStatuses: const {
            HttpStatus.ok,
            HttpStatus.noContent,
            HttpStatus.notFound,
          },
        );
        if (deleted.statusCode == HttpStatus.notFound) continue;
        if (target.remainsInactive) {
          final response = await get(
            path,
            expectedStatuses: const {HttpStatus.ok, HttpStatus.notFound},
          );
          if (response.statusCode == HttpStatus.ok &&
              response.requireDataMap()['status'] != 'inactive') {
            throw StateError('$path tidak berstatus inactive setelah cleanup');
          }
        } else {
          await get(path, expectedStatuses: const {HttpStatus.notFound});
        }
      } on Object catch (error) {
        failures.add('$path: $error');
      }
    }
    _cleanup.clear();
    try {
      await logout();
    } on Object catch (error) {
      failures.add('/auth/logout: $error');
    }
    if (failures.isNotEmpty) {
      throw StateError('E2E cleanup failed:\n${failures.join('\n')}');
    }
  }

  Future<void> logoutToken(String token) => _request(
    'POST',
    '/auth/logout',
    token: token,
    expectedStatuses: const {HttpStatus.ok, HttpStatus.unauthorized},
  );

  Future<void> logout() async {
    final token = _adminToken;
    _adminToken = null;
    if (token == null) return;
    await _request(
      'POST',
      '/auth/logout',
      token: token,
      expectedStatuses: const {HttpStatus.ok, HttpStatus.unauthorized},
    );
  }

  Future<void> close() async {
    try {
      await cleanup();
    } finally {
      _client.close(force: true);
    }
  }

  Future<E2eJsonResponse> _request(
    String method,
    String path, {
    Map<String, Object?>? body,
    Map<String, Object?> query = const {},
    bool authenticated = true,
    String? token,
    required Set<int> expectedStatuses,
  }) async {
    if (!path.startsWith('/')) {
      throw ArgumentError.value(path, 'path', 'must start with /');
    }
    final base = E2eConfig.apiBaseUrl.replaceFirst(RegExp(r'/$'), '');
    final uri = Uri.parse('$base$path').replace(
      queryParameters: query.isEmpty
          ? null
          : query.map((key, value) => MapEntry(key, value?.toString() ?? '')),
    );
    final request = await _client.openUrl(method, uri);
    request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
    final bearer =
        token ?? (authenticated ? _tokenOverride ?? await loginAdmin() : null);
    if (bearer != null) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $bearer');
    }
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }
    final rawResponse = await request.close();
    final rawBody = await utf8.decoder.bind(rawResponse).join();
    final context = '$method $uri returned HTTP ${rawResponse.statusCode}';
    Object? decoded;
    if (rawBody.isNotEmpty) {
      try {
        decoded = jsonDecode(rawBody);
      } on FormatException catch (error) {
        throw StateError(
          '$context with invalid JSON: ${error.message}; body: $rawBody',
        );
      }
    }
    if (decoded is! Map<String, dynamic>) {
      throw StateError(
        '$context with invalid envelope: expected JSON object; body: $rawBody',
      );
    }
    final success = decoded['success'];
    final message = decoded['message'];
    if (success is! bool || message is! String || message.isEmpty) {
      throw StateError(
        '$context with invalid envelope: success must be bool and message must be non-empty string; body: $rawBody',
      );
    }
    if (!expectedStatuses.contains(rawResponse.statusCode)) {
      throw StateError('$context: $message; body: $rawBody');
    }
    final expectsSuccess =
        rawResponse.statusCode >= 200 && rawResponse.statusCode < 300;
    if (success != expectsSuccess) {
      throw StateError(
        '$context with inconsistent envelope success=$success; body: $rawBody',
      );
    }
    return E2eJsonResponse(
      statusCode: rawResponse.statusCode,
      success: success,
      message: message,
      data: decoded['data'],
      meta: decoded['meta'] is Map<String, dynamic>
          ? decoded['meta'] as Map<String, dynamic>
          : null,
      code: decoded['code']?.toString(),
      errors: decoded['errors'],
      body: Map.unmodifiable(decoded),
      context: context,
    );
  }
}

class E2eJsonResponse {
  const E2eJsonResponse({
    required this.statusCode,
    required this.success,
    required this.message,
    required this.data,
    required this.meta,
    required this.code,
    required this.errors,
    required this.body,
    required this.context,
  });

  final int statusCode;
  final bool success;
  final String message;
  final Object? data;
  final Map<String, dynamic>? meta;
  final String? code;
  final Object? errors;
  final Map<String, dynamic> body;
  final String context;

  Map<String, dynamic> requireDataMap() {
    if (data is Map<String, dynamic>) return data! as Map<String, dynamic>;
    throw StateError('$context: data must be a JSON object');
  }

  List<dynamic> requireDataList() {
    if (data is List<dynamic>) return data! as List<dynamic>;
    throw StateError('$context: data must be a JSON array');
  }
}

class E2eRegistrationFixture {
  const E2eRegistrationFixture({
    required this.response,
    required this.userId,
    required this.requestId,
    required this.fullName,
    required this.email,
    required this.password,
    required this.requestedRole,
    required this.status,
  });

  final E2eJsonResponse response;
  final String? userId;
  final String? requestId;
  final String fullName;
  final String email;
  final String password;
  final String requestedRole;
  final String? status;
}
