import 'dart:io';

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
  const DictionaryCategory({
    required this.id,
    required this.name,
    this.slug,
    this.description,
    this.status,
    this.entriesCount = 0,
  });
  final String id;
  final String name;
  final String? slug;
  final String? description;
  final String? status;
  final int entriesCount;
  factory DictionaryCategory.fromJson(Map<String, dynamic> json) =>
      DictionaryCategory(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        slug: json['slug'] as String?,
        description: json['description'] as String?,
        status: json['status'] as String?,
        entriesCount: _int(json['entries_count']) ?? 0,
      );
}

class DictionaryEntryAdmin {
  const DictionaryEntryAdmin({
    required this.id,
    required this.indonesia,
    required this.english,
    required this.mekongga,
    required this.categoryId,
    this.categoryName,
    this.status,
    this.exampleMekongga,
    this.exampleIndonesia,
    this.audioMediaId,
    this.audioUrl,
    this.audioMimeType,
    this.createdAt,
    this.updatedAt,
    this.sentenceExamples = const [],
  });
  final String id;
  final String indonesia;
  final String english;
  final String mekongga;
  final String categoryId;
  final String? categoryName;
  final String? status;
  final String? exampleMekongga;
  final String? exampleIndonesia;
  final String? audioMediaId;
  final String? audioUrl;
  final String? audioMimeType;
  final String? createdAt;
  final String? updatedAt;
  final List<DictionarySentenceExampleAdmin> sentenceExamples;
  factory DictionaryEntryAdmin.fromJson(Map<String, dynamic> json) {
    final category = json['category'] is Map<String, dynamic>
        ? json['category'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final audio = json['audio'] is Map<String, dynamic>
        ? json['audio'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return DictionaryEntryAdmin(
      id: json['id'] as String? ?? '',
      indonesia: json['indonesia'] as String? ?? '',
      english: json['english'] as String? ?? '',
      mekongga: json['mekongga'] as String? ?? '',
      categoryId: json['category_id'] as String? ?? '',
      categoryName: category['name'] as String?,
      status: json['status'] as String?,
      exampleMekongga: json['example_mekongga'] as String?,
      exampleIndonesia: json['example_indonesia'] as String?,
      audioMediaId: audio['id'] as String? ?? json['audio_media_id'] as String?,
      audioUrl: audio['url'] as String?,
      audioMimeType: audio['mime_type'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      sentenceExamples: (json['sentence_examples'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DictionarySentenceExampleAdmin.fromJson)
          .toList(),
    );
  }
}

class DictionarySentenceExampleAdmin {
  const DictionarySentenceExampleAdmin({
    required this.id,
    this.kode,
    this.mekongga,
    this.indonesia,
  });
  final String id;
  final String? kode;
  final String? mekongga;
  final String? indonesia;
  factory DictionarySentenceExampleAdmin.fromJson(Map<String, dynamic> json) =>
      DictionarySentenceExampleAdmin(
        id: json['id'] as String? ?? '',
        kode: json['kode'] as String?,
        mekongga: json['contoh_mekongga'] as String?,
        indonesia: json['contoh_indonesia'] as String?,
      );
}

class DictionaryImportJobAdmin {
  const DictionaryImportJobAdmin({
    required this.id,
    required this.status,
    this.importType,
    this.duplicateStrategy,
    this.totalRows = 0,
    this.validRows = 0,
    this.invalidRows = 0,
    this.insertedRows = 0,
    this.updatedRows = 0,
    this.skippedRows = 0,
    this.warningCount = 0,
    this.failureCode,
    this.failureMessage,
    this.originalName,
    this.createdAt,
    this.vocabInserted = 0,
    this.vocabUpdated = 0,
    this.sentenceInserted = 0,
    this.sentenceUpdated = 0,
    this.audioAttached,
    this.audioNotFound,
    this.audioAmbiguous,
    this.audioUnused,
    this.sheets = const {},
  });
  final String id;
  final String status;
  final String? importType;
  final String? duplicateStrategy;
  final int totalRows;
  final int validRows;
  final int invalidRows;
  final int insertedRows;
  final int updatedRows;
  final int skippedRows;
  final int warningCount;
  final String? failureCode;
  final String? failureMessage;
  final String? originalName;
  final String? createdAt;
  final int vocabInserted;
  final int vocabUpdated;
  final int sentenceInserted;
  final int sentenceUpdated;
  final int? audioAttached;
  final int? audioNotFound;
  final int? audioAmbiguous;
  final int? audioUnused;
  final Map<String, DictionaryImportSheetSummary> sheets;

  bool get isTerminal => const {
    'completed',
    'completed_with_errors',
    'failed',
    'cancelled',
  }.contains(status);

  factory DictionaryImportJobAdmin.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] is Map<String, dynamic>
        ? json['summary'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final vocabulary = summary['vocabulary'] is Map<String, dynamic>
        ? summary['vocabulary'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final sentences = summary['sentence_examples'] is Map<String, dynamic>
        ? summary['sentence_examples'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final vocabResult = summary['vocabulary_result'] is Map<String, dynamic>
        ? summary['vocabulary_result'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final sentenceResult =
        summary['sentence_examples_result'] is Map<String, dynamic>
        ? summary['sentence_examples_result'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final audio = summary['audio'] is Map<String, dynamic>
        ? summary['audio'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return DictionaryImportJobAdmin(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? '',
      importType: json['import_type'] as String?,
      duplicateStrategy: json['duplicate_strategy'] as String?,
      totalRows: _int(json['total_rows']) ?? 0,
      validRows: _int(json['valid_rows']) ?? 0,
      invalidRows: _int(json['invalid_rows']) ?? 0,
      insertedRows: _int(json['inserted_rows']) ?? 0,
      updatedRows: _int(json['updated_rows']) ?? 0,
      skippedRows: _int(json['skipped_rows']) ?? 0,
      warningCount: _int(json['warning_count']) ?? 0,
      failureCode: json['failure_code'] as String?,
      failureMessage: json['failure_message'] as String?,
      originalName: json['csv_original_name'] as String?,
      createdAt: json['created_at'] as String?,
      vocabInserted:
          _int(vocabResult['inserted']) ?? _int(vocabulary['new_rows']) ?? 0,
      vocabUpdated: _int(vocabResult['updated']) ?? 0,
      sentenceInserted:
          _int(sentenceResult['inserted']) ?? _int(sentences['new_rows']) ?? 0,
      sentenceUpdated: _int(sentenceResult['updated']) ?? 0,
      audioAttached: _int(audio['installed']) ?? _int(audio['matched']),
      audioNotFound: _int(audio['missing']),
      audioAmbiguous: _int(audio['ambiguous']),
      audioUnused: _int(audio['unused']),
      sheets: {
        if (vocabulary.isNotEmpty)
          'Kosakata': DictionaryImportSheetSummary.fromJson(vocabulary),
        if (sentences.isNotEmpty)
          'Contoh Kalimat': DictionaryImportSheetSummary.fromJson(sentences),
      },
    );
  }
}

class DictionaryImportSheetSummary {
  const DictionaryImportSheetSummary({
    this.total,
    this.valid,
    this.invalid,
    this.duplicate,
    this.skipped,
  });

  final int? total;
  final int? valid;
  final int? invalid;
  final int? duplicate;
  final int? skipped;

  factory DictionaryImportSheetSummary.fromJson(Map<String, dynamic> json) =>
      DictionaryImportSheetSummary(
        total: _int(json['total_rows']),
        valid: _int(json['valid_rows']),
        invalid: _int(json['invalid_rows']),
        duplicate: _int(json['duplicate_rows']),
        skipped: _int(json['skipped_rows']),
      );
}

class DictionaryImportErrorAdmin {
  const DictionaryImportErrorAdmin({
    required this.id,
    this.rowNumber,
    this.field,
    this.code,
    this.message,
    this.sheet,
    this.rawData,
    this.createdAt,
  });
  final String id;
  final int? rowNumber;
  final String? field;
  final String? code;
  final String? message;
  final String? sheet;
  final Map<String, dynamic>? rawData;
  final String? createdAt;
  factory DictionaryImportErrorAdmin.fromJson(Map<String, dynamic> json) =>
      DictionaryImportErrorAdmin(
        id: json['id'] as String? ?? '',
        rowNumber: _int(json['row_number']),
        field: json['field'] as String?,
        code: json['code'] as String?,
        message: json['message'] as String?,
        sheet: json['sheet'] as String?,
        rawData: json['raw_data'] is Map
            ? Map<String, dynamic>.from(json['raw_data'] as Map)
            : null,
        createdAt: json['created_at'] as String?,
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
    this.questionsCount = 0,
    this.createdAt,
    this.updatedAt,
    this.questions = const [],
  });
  final String id;
  final String title;
  final String? description;
  final String? instructions;
  final int durationMinutes;
  final int maxAttempts;
  final bool showResult;
  final String? status;
  final int questionsCount;
  final String? createdAt;
  final String? updatedAt;
  final List<QuizQuestionAdmin> questions;
  int get totalPoints =>
      questions.fold(0, (total, item) => total + item.points);
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
        questionsCount:
            _int(json['questions_count']) ??
            ((json['questions'] as List?)?.length ?? 0),
        createdAt: json['created_at'] as String?,
        updatedAt: json['updated_at'] as String?,
        questions:
            (json['questions'] as List? ?? const [])
                .whereType<Map<String, dynamic>>()
                .map(QuizQuestionAdmin.fromJson)
                .toList()
              ..sort((a, b) => a.orderNumber.compareTo(b.orderNumber)),
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
    this.imageMediaId,
    this.imageUrl,
    this.imageName,
    this.imageSize,
    this.imageMimeType,
    this.useFuzzyMatching = false,
    this.fuzzyThreshold,
  });
  final String id;
  final String type;
  final String text;
  final int points;
  final int orderNumber;
  final String? correctAnswerText;
  final String? explanation;
  final String? imageMediaId;
  final String? imageUrl;
  final String? imageName;
  final int? imageSize;
  final String? imageMimeType;
  final bool useFuzzyMatching;
  final int? fuzzyThreshold;
  final List<QuizOptionAdmin> options;
  factory QuizQuestionAdmin.fromJson(Map<String, dynamic> json) {
    final image = json['image_media'] is Map<String, dynamic>
        ? json['image_media'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return QuizQuestionAdmin(
      id: json['id'] as String? ?? '',
      type: json['question_type'] as String? ?? 'multiple_choice',
      text: json['question_text'] as String? ?? '',
      points: _int(json['points']) ?? 1,
      orderNumber: _int(json['order_number']) ?? 1,
      correctAnswerText: json['correct_answer_text'] as String?,
      explanation: json['explanation'] as String?,
      imageMediaId: image['id'] as String? ?? json['image_media_id'] as String?,
      imageUrl: image['url'] as String?,
      imageName: image['original_name'] as String?,
      imageSize: _int(image['size_bytes']),
      imageMimeType: image['mime_type'] as String?,
      useFuzzyMatching: json['use_fuzzy_matching'] == true,
      fuzzyThreshold: _int(json['fuzzy_threshold']),
      options: (json['options'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(QuizOptionAdmin.fromJson)
          .toList(),
    );
  }
}

class QuizApplySummary {
  const QuizApplySummary({
    required this.applied,
    required this.synced,
    required this.skipped,
    required this.failed,
  });
  final List<Map<String, dynamic>> applied;
  final List<Map<String, dynamic>> synced;
  final List<Map<String, dynamic>> skipped;
  final List<Map<String, dynamic>> failed;
  bool get hasPartialFailures => skipped.isNotEmpty || failed.isNotEmpty;
  factory QuizApplySummary.fromJson(Map<String, dynamic> json) =>
      QuizApplySummary(
        applied: _maps(json['applied']),
        synced: _maps(json['synced']),
        skipped: _maps(json['skipped']),
        failed: _maps(json['failed']),
      );
}

class QuizImageMediaAdmin {
  const QuizImageMediaAdmin({
    required this.id,
    this.url,
    this.name,
    this.size,
    this.mimeType,
  });
  final String id;
  final String? url;
  final String? name;
  final int? size;
  final String? mimeType;
  factory QuizImageMediaAdmin.fromJson(Map<String, dynamic> json) =>
      QuizImageMediaAdmin(
        id: _string(json['id']),
        url: json['url'] as String?,
        name: json['original_name'] as String?,
        size: _int(json['size_bytes']),
        mimeType: json['mime_type'] as String?,
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

  Future<DictionaryCategory> saveCategory({
    String? id,
    required Map<String, dynamic> data,
  }) async => _mutate(
    id == null ? 'post' : 'put',
    id == null
        ? '/admin/dictionary/categories'
        : '/admin/dictionary/categories/$id',
    data,
    DictionaryCategory.fromJson,
  );

  Future<void> deleteCategory(String id) =>
      _delete('/admin/dictionary/categories/$id');

  Future<AdminCrudPage<DictionaryEntryAdmin>> dictionary({
    String? search,
    String? categoryId,
    String? status,
    int page = 1,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/admin/dictionary/entries',
        queryParameters: {
          'page': page,
          'per_page': 15,
          if (search?.trim().isNotEmpty == true) 'search': search!.trim(),
          if (categoryId?.isNotEmpty == true) 'category_id': categoryId,
          if (status?.isNotEmpty == true) 'status': status,
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

  Future<String> uploadDictionaryAudio(File file) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
        'purpose': 'audio',
        'visibility': 'public',
      });
      final res = await _dio.post<Map<String, dynamic>>('/media', data: form);
      final data = res.data?['data'];
      if (data is Map<String, dynamic> && data['id'] is String) {
        return data['id'] as String;
      }
      throw AppError(
        type: AppErrorType.server,
        message: 'ID media tidak ditemukan.',
      );
    } catch (e) {
      if (e is AppError) rethrow;
      throw _map(e);
    }
  }

  Future<DictionaryImportJobAdmin> previewDictionaryImport({
    required File csvFile,
    File? audioZip,
    String importType = 'vocabulary',
    String? duplicateStrategy,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      final form = FormData.fromMap({
        'csv_file': await MultipartFile.fromFile(csvFile.path),
        if (audioZip != null)
          'audio_zip': await MultipartFile.fromFile(audioZip.path),
        'import_type': importType,
        'duplicate_strategy': ?duplicateStrategy,
      });
      final res = await _dio.post<Map<String, dynamic>>(
        '/admin/dictionary/imports/preview',
        data: form,
        onSendProgress: onSendProgress,
      );
      return DictionaryImportJobAdmin.fromJson(_dataObject(res.data));
    } catch (e) {
      throw _map(e);
    }
  }

  Future<DictionaryImportJobAdmin> confirmDictionaryImport(String id) async =>
      _mutate(
        'post',
        '/admin/dictionary/imports/$id/confirm',
        null,
        DictionaryImportJobAdmin.fromJson,
      );

  Future<DictionaryImportJobAdmin> dictionaryImportDetail(String id) =>
      _one('/admin/dictionary/imports/$id', DictionaryImportJobAdmin.fromJson);

  Future<AdminCrudPage<DictionaryImportJobAdmin>> dictionaryImports({
    int page = 1,
    String? status,
    String? duplicateStrategy,
    String? uploadedBy,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/admin/dictionary/imports',
        queryParameters: {
          'page': page,
          'per_page': 10,
          if (status?.isNotEmpty == true) 'status': status,
          if (duplicateStrategy?.isNotEmpty == true)
            'duplicate_strategy': duplicateStrategy,
          if (uploadedBy?.trim().isNotEmpty == true)
            'uploaded_by': uploadedBy!.trim(),
          if (dateFrom?.isNotEmpty == true) 'date_from': dateFrom,
          if (dateTo?.isNotEmpty == true) 'date_to': dateTo,
        },
      );
      return _page(res.data, DictionaryImportJobAdmin.fromJson);
    } catch (e) {
      throw _map(e);
    }
  }

  Future<AdminCrudPage<DictionaryImportErrorAdmin>> dictionaryImportErrors(
    String id, {
    int page = 1,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/admin/dictionary/imports/$id/errors',
        queryParameters: {'page': page, 'per_page': 15},
      );
      return _page(res.data, DictionaryImportErrorAdmin.fromJson);
    } catch (e) {
      throw _map(e);
    }
  }

  Future<List<int>> dictionaryImportTemplate() async {
    try {
      final res = await _dio.get<List<int>>(
        '/admin/dictionary/imports/xlsx-template',
        options: Options(responseType: ResponseType.bytes),
      );
      return res.data ?? const [];
    } catch (e) {
      throw _map(e);
    }
  }

  Future<void> deleteDictionaryImport(String id) =>
      _delete('/admin/dictionary/imports/$id', data: {'confirm': true});
  Future<void> deleteDictionaryImportError(String id, String errorId) =>
      _delete(
        '/admin/dictionary/imports/$id/errors/$errorId',
        data: {'confirm': true},
      );
  Future<void> clearDictionaryImportErrors(String id) =>
      _delete('/admin/dictionary/imports/$id/errors', data: {'confirm': true});

  Future<AdminCrudPage<QuizTemplateAdmin>> quizzes({
    String? search,
    String? status,
    int page = 1,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/admin/quiz-templates',
        queryParameters: {
          'page': page,
          'per_page': 15,
          if (search?.trim().isNotEmpty == true) 'search': search!.trim(),
          if (status?.trim().isNotEmpty == true) 'status': status!.trim(),
          'sort_by': 'created_at',
          'sort_direction': 'desc',
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
  Future<void> quizStatus(
    String id,
    String action, {
    bool applyToAllActiveClasses = false,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/admin/quiz-templates/$id/$action',
      data: action == 'publish'
          ? {'apply_to_all_active_classes': applyToAllActiveClasses}
          : null,
    );
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

  Future<void> reorderQuestions(String quizId, List<String> questionIds) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        '/admin/quiz-templates/$quizId/questions/reorder',
        data: {'question_ids': questionIds},
      );
    } catch (e) {
      throw _map(e);
    }
  }

  Future<QuizApplySummary> applyQuiz(
    String quizId,
    List<String> classIds, {
    bool syncExisting = false,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/admin/quiz-templates/$quizId/apply',
        data: {'class_ids': classIds, 'sync_existing': syncExisting},
      );
      return QuizApplySummary.fromJson(_dataObject(res.data));
    } catch (e) {
      throw _map(e);
    }
  }

  Future<QuizImageMediaAdmin> uploadQuestionImage(
    String path,
    String name,
  ) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(path, filename: name),
        'purpose': 'question_image',
        'visibility': 'public',
      });
      final res = await _dio.post<Map<String, dynamic>>('/media', data: form);
      return QuizImageMediaAdmin.fromJson(_dataObject(res.data));
    } catch (e) {
      throw _map(e);
    }
  }

  Future<void> deleteMedia(String id) => _delete('/media/$id');

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
    Map<String, dynamic>? data,
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

  Future<void> _delete(String path, {Map<String, dynamic>? data}) async {
    try {
      await _dio.delete<Map<String, dynamic>>(path, data: data);
    } catch (e) {
      throw _map(e);
    }
  }

  static Map<String, dynamic> _dataObject(Map<String, dynamic>? json) {
    final data = json?['data'];
    if (data is Map<String, dynamic>) return data;
    throw const AppError(
      type: AppErrorType.unknown,
      message: 'Data admin tidak valid.',
    );
  }

  Object _map(Object e) => e is AppError ? e : _mapper.map(e);
}

List<Map<String, dynamic>> _maps(Object? value) =>
    value is List ? value.whereType<Map<String, dynamic>>().toList() : const [];

String _string(Object? value) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  if (value is num) return '$value';
  return '';
}

int? _int(Object? value) => value is int
    ? value
    : value is String
    ? int.tryParse(value)
    : null;
