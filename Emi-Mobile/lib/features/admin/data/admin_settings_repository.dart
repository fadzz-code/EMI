import 'package:dio/dio.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/dio_error_mapper.dart';

class AdminSettings {
  const AdminSettings({
    required this.application,
    required this.banner,
    required this.security,
    required this.activityLogs,
  });

  final ApplicationSettings application;
  final BannerSettings banner;
  final SecuritySettings security;
  final List<SettingsActivityLog> activityLogs;

  factory AdminSettings.fromJson(Map<String, dynamic> json) => AdminSettings(
    application: ApplicationSettings.fromJson(_map(json['application'])),
    banner: BannerSettings.fromJson(_map(json['banner'])),
    security: SecuritySettings.fromJson(_map(json['security'])),
    activityLogs: (json['activity_logs'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(SettingsActivityLog.fromJson)
        .toList(),
  );
}

class ApplicationSettings {
  const ApplicationSettings({
    required this.name,
    required this.subtitle,
    required this.activeAcademicYear,
    required this.timezone,
  });

  final String name;
  final String subtitle;
  final String activeAcademicYear;
  final String timezone;

  factory ApplicationSettings.fromJson(Map<String, dynamic> json) =>
      ApplicationSettings(
        name: json['name'] as String? ?? 'EMI',
        subtitle: json['subtitle'] as String? ?? '',
        activeAcademicYear: json['active_academic_year'] as String? ?? '',
        timezone: json['timezone'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'name': name,
    'subtitle': subtitle,
    'active_academic_year': activeAcademicYear,
    'timezone': timezone,
  };
}

class BannerSettings {
  const BannerSettings({
    required this.enabled,
    this.title,
    this.subtitle,
    this.imageMediaId,
    this.imageUrl,
  });

  final bool enabled;
  final String? title;
  final String? subtitle;
  final String? imageMediaId;
  final String? imageUrl;

  factory BannerSettings.fromJson(Map<String, dynamic> json) => BannerSettings(
    enabled: _bool(json['enabled']),
    title: json['title'] as String?,
    subtitle: json['subtitle'] as String?,
    imageMediaId: json['image_media_id'] as String?,
    imageUrl: json['image_url'] as String?,
  );
}

class SecuritySettings {
  const SecuritySettings({
    required this.newLoginAlert,
    required this.weeklyReportEmail,
  });

  final bool newLoginAlert;
  final bool weeklyReportEmail;

  factory SecuritySettings.fromJson(Map<String, dynamic> json) =>
      SecuritySettings(
        newLoginAlert: _bool(json['new_login_alert']),
        weeklyReportEmail: _bool(json['weekly_report_email']),
      );

  Map<String, dynamic> toJson() => {
    'new_login_alert': newLoginAlert,
    'weekly_report_email': weeklyReportEmail,
  };
}

class SettingsActivityLog {
  const SettingsActivityLog({
    required this.id,
    required this.admin,
    required this.title,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String admin;
  final String title;
  final bool status;
  final String? createdAt;

  factory SettingsActivityLog.fromJson(Map<String, dynamic> json) =>
      SettingsActivityLog(
        id: json['id'] as String? ?? '',
        admin: json['admin'] as String? ?? 'Admin',
        title: json['title'] as String? ?? '',
        status: _bool(json['status'], fallback: true),
        createdAt: json['created_at'] as String?,
      );
}

class AdminSettingsRepository {
  const AdminSettingsRepository(this._dio, this._mapper);

  final Dio _dio;
  final DioErrorMapper _mapper;

  Future<AdminSettings> get() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/admin/settings');
      return AdminSettings.fromJson(_data(res.data));
    } catch (e) {
      throw _map(e);
    }
  }

  Future<ApplicationSettings> updateApplication(
    ApplicationSettings settings,
  ) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/admin/settings/application',
        data: settings.toJson(),
      );
      return ApplicationSettings.fromJson(_data(res.data));
    } catch (e) {
      throw _map(e);
    }
  }

  Future<BannerSettings> updateBanner({
    required bool enabled,
    String? path,
    String? fileName,
  }) async {
    try {
      final data = <String, dynamic>{'enabled': enabled ? '1' : '0'};
      if (path != null && fileName != null) {
        data['file'] = await MultipartFile.fromFile(path, filename: fileName);
      }
      final res = await _dio.post<Map<String, dynamic>>(
        '/admin/settings/banner',
        data: FormData.fromMap(data),
      );
      return BannerSettings.fromJson(_data(res.data));
    } catch (e) {
      throw _map(e);
    }
  }

  Future<SecuritySettings> updateSecurity(SecuritySettings settings) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/admin/settings/security',
        data: settings.toJson(),
      );
      return SecuritySettings.fromJson(_data(res.data));
    } catch (e) {
      throw _map(e);
    }
  }

  Object _map(Object e) => e is AppError ? e : _mapper.map(e);
}

Map<String, dynamic> _data(Map<String, dynamic>? json) {
  final data = json?['data'];
  if (data is Map<String, dynamic>) return data;
  throw const AppError(
    type: AppErrorType.unknown,
    message: 'Data pengaturan tidak valid.',
  );
}

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : const <String, dynamic>{};

bool _bool(Object? value, {bool fallback = false}) => value is bool
    ? value
    : value is num
    ? value != 0
    : value is String
    ? value == '1' || value.toLowerCase() == 'true'
    : fallback;
