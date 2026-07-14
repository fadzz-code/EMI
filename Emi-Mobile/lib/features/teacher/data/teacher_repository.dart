import 'package:dio/dio.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/dio_error_mapper.dart';

class TeacherMetric {
  const TeacherMetric({
    required this.label,
    required this.value,
    required this.iconName,
    this.highlight = false,
  });

  final String label;
  final String value;
  final String iconName;
  final bool highlight;
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
      metrics: _dashboardMetrics(json),
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

List<TeacherMetric> _dashboardMetrics(Map<String, dynamic> json) {
  final students = _map(json['students']);
  final learning = _map(json['learning']);
  final quizzes = _map(json['quizzes']);
  return [
    TeacherMetric(
      label: 'Kelas Saya',
      value: _value(_map(json['class'])['name'], empty: '-'),
      iconName: 'class',
    ),
    TeacherMetric(
      label: 'Jumlah Siswa',
      value: _value(students['total_students'] ?? students['total']),
      iconName: 'students',
    ),
    TeacherMetric(
      label: 'Sudah Belajar',
      value: _value(
        learning['students_with_learning_activity'] ??
            students['with_learning_activity'],
      ),
      iconName: 'learning',
    ),
    TeacherMetric(
      label: 'Perlu Diperiksa',
      value: _value(
        quizzes['submitted_attempts'] ??
            quizzes['pending_review'] ??
            quizzes['final_attempts'],
      ),
      iconName: 'review',
      highlight: true,
    ),
  ];
}

String _value(Object? value, {String empty = '0'}) {
  if (value == null) return empty;
  if (value is String && value.trim().isEmpty) return empty;
  return value.toString();
}

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : const <String, dynamic>{};

bool _bool(Object? value) => value is bool
    ? value
    : value is num
    ? value != 0
    : value is String
    ? value == '1' || value.toLowerCase() == 'true'
    : false;
