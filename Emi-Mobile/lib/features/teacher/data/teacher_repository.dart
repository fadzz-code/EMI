import 'package:dio/dio.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/dio_error_mapper.dart';

class TeacherMetric {
  const TeacherMetric({required this.label, required this.value});

  final String label;
  final String value;
}

class TeacherDashboardSummary {
  const TeacherDashboardSummary({
    required this.emptyState,
    required this.metrics,
    required this.recentActivity,
    this.className,
    this.schoolName,
    this.generatedAt,
  });

  final bool emptyState;
  final String? className;
  final String? schoolName;
  final String? generatedAt;
  final List<TeacherMetric> metrics;
  final List<TeacherRecentActivity> recentActivity;

  factory TeacherDashboardSummary.fromJson(Map<String, dynamic> json) {
    final klass = _map(json['class']);
    final school = _map(klass['school']);
    return TeacherDashboardSummary(
      emptyState: _bool(json['empty_state']),
      className: klass['name'] as String?,
      schoolName: school['name'] as String?,
      generatedAt: json['generated_at'] as String?,
      metrics: [
        ..._metrics('Siswa', _map(json['students'])),
        ..._metrics('Pembelajaran', _map(json['learning'])),
        ..._metrics('Kuis', _map(json['quizzes'])),
      ],
      recentActivity: (json['recent_activity'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(TeacherRecentActivity.fromJson)
          .toList(),
    );
  }
}

class TeacherRecentActivity {
  const TeacherRecentActivity({
    this.type,
    this.studentName,
    this.title,
    this.occurredAt,
  });

  final String? type;
  final String? studentName;
  final String? title;
  final String? occurredAt;

  factory TeacherRecentActivity.fromJson(Map<String, dynamic> json) =>
      TeacherRecentActivity(
        type: json['type'] as String?,
        studentName: json['student_name'] as String?,
        title: json['title'] as String?,
        occurredAt: json['occurred_at'] as String?,
      );
}

class TeacherRepository {
  const TeacherRepository(this._dio, this._mapper);

  final Dio _dio;
  final DioErrorMapper _mapper;

  Future<TeacherDashboardSummary> dashboard() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/teacher/dashboard/summary',
      );
      final data = res.data?['data'];
      if (data is Map<String, dynamic>) {
        return TeacherDashboardSummary.fromJson(data);
      }
      throw const AppError(
        type: AppErrorType.unknown,
        message: 'Dashboard guru tidak valid.',
      );
    } catch (e) {
      throw e is AppError ? e : _mapper.map(e);
    }
  }
}

List<TeacherMetric> _metrics(String group, Map<String, dynamic> values) => [
  for (final entry in values.entries)
    TeacherMetric(label: '$group ${entry.key}', value: _value(entry.value)),
];

String _value(Object? value) => value == null ? '-' : value.toString();

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : const <String, dynamic>{};

bool _bool(Object? value) => value is bool
    ? value
    : value is num
    ? value != 0
    : value is String
    ? value == '1' || value.toLowerCase() == 'true'
    : false;
