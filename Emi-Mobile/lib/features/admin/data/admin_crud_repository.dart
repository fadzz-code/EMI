import 'package:dio/dio.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/dio_error_mapper.dart';

class AdminCrudPage<T> {
  const AdminCrudPage({
    required this.items,
    this.hasMore = false,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
  });
  final List<T> items;
  final bool hasMore;
  final int currentPage;
  final int lastPage;
  final int total;
}

class DictionaryCategory {
  const DictionaryCategory({required this.id, required this.name, this.status});
  final String id;
  final String name;
  final String? status;
  factory DictionaryCategory.fromJson(Map<String, dynamic> json) =>
      DictionaryCategory(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        status: json['status'] as String?,
      );
}

class DictionaryEntryAdmin {
  const DictionaryEntryAdmin({
    required this.id,
    required this.indonesia,
    required this.english,
    required this.mekongga,
    required this.categoryId,
    this.status,
    this.exampleMekongga,
    this.exampleIndonesia,
    this.audioMediaId,
  });
  final String id;
  final String indonesia;
  final String english;
  final String mekongga;
  final String categoryId;
  final String? status;
  final String? exampleMekongga;
  final String? exampleIndonesia;
  final String? audioMediaId;
  factory DictionaryEntryAdmin.fromJson(Map<String, dynamic> json) =>
      DictionaryEntryAdmin(
        id: json['id'] as String? ?? '',
        indonesia: json['indonesia'] as String? ?? '',
        english: json['english'] as String? ?? '',
        mekongga: json['mekongga'] as String? ?? '',
        categoryId: json['category_id'] as String? ?? '',
        status: json['status'] as String?,
        exampleMekongga: json['example_mekongga'] as String?,
        exampleIndonesia: json['example_indonesia'] as String?,
        audioMediaId: (json['audio'] is Map<String, dynamic>)
            ? (json['audio']['id'] as String?)
            : json['audio_media_id'] as String?,
      );
}

class QuizTemplateAdmin {
  const QuizTemplateAdmin({
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.maxAttempts,
    required this.showResult,
    this.description,
    this.instructions,
    this.status,
  });
  final String id;
  final String title;
  final String? description;
  final String? instructions;
  final int durationMinutes;
  final int maxAttempts;
  final bool showResult;
  final String? status;
  factory QuizTemplateAdmin.fromJson(Map<String, dynamic> json) =>
      QuizTemplateAdmin(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        instructions: json['instructions'] as String?,
        durationMinutes: _int(json['duration_minutes']) ?? 1,
        maxAttempts: _int(json['max_attempts']) ?? 1,
        showResult: json['show_result'] == true,
        status: json['status'] as String?,
      );
}

class QuizQuestionAdmin {
  const QuizQuestionAdmin({
    required this.id,
    required this.type,
    required this.text,
    required this.points,
    required this.orderNumber,
    required this.options,
    this.correctAnswerText,
    this.explanation,
  });
  final String id;
  final String type;
  final String text;
  final int points;
  final int orderNumber;
  final String? correctAnswerText;
  final String? explanation;
  final List<QuizOptionAdmin> options;
  factory QuizQuestionAdmin.fromJson(Map<String, dynamic> json) =>
      QuizQuestionAdmin(
        id: json['id'] as String? ?? '',
        type: json['question_type'] as String? ?? 'multiple_choice',
        text: json['question_text'] as String? ?? '',
        points: _int(json['points']) ?? 1,
        orderNumber: _int(json['order_number']) ?? 1,
        correctAnswerText: json['correct_answer_text'] as String?,
        explanation: json['explanation'] as String?,
        options: (json['options'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(QuizOptionAdmin.fromJson)
            .toList(),
      );
}

class QuizOptionAdmin {
  const QuizOptionAdmin({
    required this.text,
    required this.isCorrect,
    required this.orderNumber,
  });
  final String text;
  final bool isCorrect;
  final int orderNumber;
  factory QuizOptionAdmin.fromJson(Map<String, dynamic> json) =>
      QuizOptionAdmin(
        text: json['option_text'] as String? ?? '',
        isCorrect: json['is_correct'] == true,
        orderNumber: _int(json['order_number']) ?? 1,
      );
  Map<String, dynamic> toJson() => {
    'option_text': text,
    'is_correct': isCorrect,
    'order_number': orderNumber,
  };
}

class RegistrationApprovalAdmin {
  const RegistrationApprovalAdmin({
    required this.id,
    required this.requestedRole,
    required this.status,
    required this.userName,
    required this.userEmail,
    this.schoolName,
    this.className,
    this.classId,
    this.reviewNote,
    this.createdAt,
    this.reviewedAt,
    this.userStatus,
  });
  final String id;
  final String requestedRole;
  final String status;
  final String userName;
  final String userEmail;
  final String? schoolName;
  final String? className;
  final String? classId;
  final String? reviewNote;
  final String? createdAt;
  final String? reviewedAt;
  final String? userStatus;
  factory RegistrationApprovalAdmin.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final school = json['school'] is Map<String, dynamic>
        ? json['school'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final schoolClass = json['school_class'] is Map<String, dynamic>
        ? json['school_class'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return RegistrationApprovalAdmin(
      id: json['id'] as String? ?? '',
      requestedRole: json['requested_role'] as String? ?? '',
      status: json['status'] as String? ?? '',
      userName: user['full_name'] as String? ?? '',
      userEmail: user['email'] as String? ?? '',
      schoolName: school['name'] as String?,
      className: schoolClass['name'] as String?,
      classId: schoolClass['id'] as String?,
      reviewNote: json['review_note'] as String?,
      createdAt: json['created_at'] as String?,
      reviewedAt: json['reviewed_at'] as String?,
      userStatus: user['status'] as String?,
    );
  }
}

class ReportPage {
  const ReportPage({
    required this.rows,
    this.summary = const {},
    this.hasMore = false,
  });
  final List<Map<String, dynamic>> rows;
  final Map<String, dynamic> summary;
  final bool hasMore;
}

class AdminCrudRepository {
  const AdminCrudRepository(this._dio, this._mapper);
  final Dio _dio;
  final DioErrorMapper _mapper;

  Future<AdminCrudPage<DictionaryCategory>> categories() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/admin/dictionary/categories',
        queryParameters: {'per_page': 100},
      );
      return _page(res.data, DictionaryCategory.fromJson);
    } catch (e) {
      throw _map(e);
    }
  }

  Future<AdminCrudPage<DictionaryEntryAdmin>> dictionary({
    String? search,
    int page = 1,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/admin/dictionary/entries',
        queryParameters: {
          'page': page,
          'per_page': 15,
          if (search?.trim().isNotEmpty == true) 'search': search!.trim(),
        },
      );
      return _page(res.data, DictionaryEntryAdmin.fromJson);
    } catch (e) {
      throw _map(e);
    }
  }

  Future<DictionaryEntryAdmin> dictionaryDetail(String id) =>
      _one('/admin/dictionary/entries/$id', DictionaryEntryAdmin.fromJson);
  Future<DictionaryEntryAdmin> saveDictionary({
    String? id,
    required Map<String, dynamic> data,
  }) async => _mutate(
    id == null ? 'post' : 'put',
    id == null ? '/admin/dictionary/entries' : '/admin/dictionary/entries/$id',
    data,
    DictionaryEntryAdmin.fromJson,
  );
  Future<void> deleteDictionary(String id) =>
      _delete('/admin/dictionary/entries/$id');

  Future<AdminCrudPage<QuizTemplateAdmin>> quizzes({
    String? search,
    int page = 1,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/admin/quiz-templates',
        queryParameters: {
          'page': page,
          'per_page': 15,
          if (search?.trim().isNotEmpty == true) 'search': search!.trim(),
        },
      );
      return _page(res.data, QuizTemplateAdmin.fromJson);
    } catch (e) {
      throw _map(e);
    }
  }

  Future<QuizTemplateAdmin> quizDetail(String id) =>
      _one('/admin/quiz-templates/$id', QuizTemplateAdmin.fromJson);
  Future<QuizTemplateAdmin> saveQuiz({
    String? id,
    required Map<String, dynamic> data,
  }) async => _mutate(
    id == null ? 'post' : 'put',
    id == null ? '/admin/quiz-templates' : '/admin/quiz-templates/$id',
    data,
    QuizTemplateAdmin.fromJson,
  );
  Future<void> deleteQuiz(String id) => _delete('/admin/quiz-templates/$id');
  Future<void> quizStatus(String id, String action) async {
    await _dio.post<Map<String, dynamic>>('/admin/quiz-templates/$id/$action');
  }

  Future<List<QuizQuestionAdmin>> questions(String quizId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/admin/quiz-templates/$quizId/questions',
      );
      return (res.data?['data'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(QuizQuestionAdmin.fromJson)
          .toList();
    } catch (e) {
      throw _map(e);
    }
  }

  Future<QuizQuestionAdmin> questionDetail(String id) =>
      _one('/admin/quiz-template-questions/$id', QuizQuestionAdmin.fromJson);
  Future<QuizQuestionAdmin> saveQuestion({
    required String quizId,
    String? id,
    required Map<String, dynamic> data,
  }) async => _mutate(
    id == null ? 'post' : 'put',
    id == null
        ? '/admin/quiz-templates/$quizId/questions'
        : '/admin/quiz-template-questions/$id',
    data,
    QuizQuestionAdmin.fromJson,
  );
  Future<void> deleteQuestion(String id) =>
      _delete('/admin/quiz-template-questions/$id');

  Future<AdminCrudPage<RegistrationApprovalAdmin>> approvals({
    String? search,
    String? status,
    String? role,
    int page = 1,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/admin/registration-requests',
        queryParameters: {
          'page': page,
          'per_page': 15,
          if (search?.trim().isNotEmpty == true) 'search': search!.trim(),
          if (status?.trim().isNotEmpty == true) 'status': status!.trim(),
          if (role?.trim().isNotEmpty == true) 'requested_role': role!.trim(),
        },
      );
      return _page(res.data, RegistrationApprovalAdmin.fromJson);
    } catch (e) {
      throw _map(e);
    }
  }

  Future<RegistrationApprovalAdmin> approvalDetail(String id) => _one(
    '/admin/registration-requests/$id',
    RegistrationApprovalAdmin.fromJson,
  );

  Future<RegistrationApprovalAdmin> reviewApproval(
    String id,
    String action,
    String? note,
  ) async => _mutate(
    'post',
    '/admin/registration-requests/$id/$action',
    {'review_note': note},
    RegistrationApprovalAdmin.fromJson,
  );

  Future<ReportPage> report(String kind, {int page = 1}) async {
    final path = switch (kind) {
      'quiz' => '/admin/reports/quiz-results',
      'schools' => '/admin/reports/progress/schools',
      'classes' => '/admin/reports/progress/classes',
      _ => '/admin/reports/progress/students',
    };
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: {'page': page, 'per_page': 15},
      );
      final data = res.data?['data'];
      final rows = data is Map<String, dynamic> ? data['rows'] : data;
      final summary =
          data is Map<String, dynamic> &&
              data['summary'] is Map<String, dynamic>
          ? data['summary'] as Map<String, dynamic>
          : <String, dynamic>{};
      final meta = res.data?['meta'];
      return ReportPage(
        rows: (rows as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList(),
        summary: summary,
        hasMore:
            meta is Map<String, dynamic> &&
            (_int(meta['current_page']) ?? 1) < (_int(meta['last_page']) ?? 1),
      );
    } catch (e) {
      throw _map(e);
    }
  }

  AdminCrudPage<T> _page<T>(
    Map<String, dynamic>? json,
    T Function(Map<String, dynamic>) parse,
  ) {
    final meta = json?['meta'];
    final currentPage = meta is Map<String, dynamic>
        ? (_int(meta['current_page']) ?? 1)
        : 1;
    final lastPage = meta is Map<String, dynamic>
        ? (_int(meta['last_page']) ?? 1)
        : 1;
    return AdminCrudPage(
      items: (json?['data'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(parse)
          .toList(),
      hasMore: currentPage < lastPage,
      currentPage: currentPage,
      lastPage: lastPage,
      total: meta is Map<String, dynamic> ? (_int(meta['total']) ?? 0) : 0,
    );
  }

  Future<T> _one<T>(String path, T Function(Map<String, dynamic>) parse) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(path);
      final data = res.data?['data'];
      if (data is Map<String, dynamic>) return parse(data);
      throw const AppError(
        type: AppErrorType.unknown,
        message: 'Data admin tidak valid.',
      );
    } catch (e) {
      throw _map(e);
    }
  }

  Future<T> _mutate<T>(
    String method,
    String path,
    Map<String, dynamic> data,
    T Function(Map<String, dynamic>) parse,
  ) async {
    try {
      final res = method == 'post'
          ? await _dio.post<Map<String, dynamic>>(path, data: data)
          : await _dio.put<Map<String, dynamic>>(path, data: data);
      final body = res.data?['data'];
      if (body is Map<String, dynamic>) return parse(body);
      throw const AppError(
        type: AppErrorType.unknown,
        message: 'Data admin tidak valid.',
      );
    } catch (e) {
      throw _map(e);
    }
  }

  Future<void> _delete(String path) async {
    try {
      await _dio.delete<Map<String, dynamic>>(path);
    } catch (e) {
      throw _map(e);
    }
  }

  Object _map(Object e) => e is AppError ? e : _mapper.map(e);
}

int? _int(Object? value) => value is int
    ? value
    : value is String
    ? int.tryParse(value)
    : null;
