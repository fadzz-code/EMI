import 'dart:io';

class SpeakingReferenceAudio {
  const SpeakingReferenceAudio({
    required this.id,
    this.url,
    this.mimeType,
    this.fileName,
    this.visibility,
  });

  final String id;
  final String? url;
  final String? mimeType;
  final String? fileName;
  final String? visibility;

  factory SpeakingReferenceAudio.fromJson(Map<String, dynamic> json) {
    return SpeakingReferenceAudio(
      id: json['id'] as String? ?? '',
      url: json['url'] as String?,
      mimeType: json['mime_type'] as String?,
      fileName: (json['file_name'] ?? json['original_name']) as String?,
      visibility: json['visibility'] as String?,
    );
  }
}

class SpeakingExercise {
  const SpeakingExercise({
    required this.id,
    required this.title,
    required this.status,
    this.promptText,
    this.targetText,
    this.targetTranslation,
    this.referenceAudioMediaId,
    this.referenceAudio,
    this.languageCode,
    this.difficulty,
  });

  final String id;
  final String title;
  final String status;
  final String? promptText;
  final String? targetText;
  final String? targetTranslation;
  final String? referenceAudioMediaId;
  final SpeakingReferenceAudio? referenceAudio;
  final String? languageCode;
  final String? difficulty;

  bool get hasReferenceAudio => referenceAudio?.url?.isNotEmpty == true;

  factory SpeakingExercise.fromJson(Map<String, dynamic> json) {
    final audio = json['reference_audio'];
    return SpeakingExercise(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      promptText: json['prompt_text'] as String?,
      targetText: json['target_text'] as String?,
      targetTranslation: json['target_translation'] as String?,
      referenceAudioMediaId: json['reference_audio_media_id'] as String?,
      referenceAudio: audio is Map<String, dynamic>
          ? SpeakingReferenceAudio.fromJson(audio)
          : null,
      languageCode: json['language_code'] as String?,
      difficulty: json['difficulty'] as String?,
      status: json['status'] as String? ?? '',
    );
  }
}

class SpeakingAttempt {
  const SpeakingAttempt({
    required this.id,
    required this.exerciseId,
    required this.status,
    this.analysisStatus,
    this.targetText,
    this.aiScore,
    this.aiTranscription,
    this.aiAlignment,
    this.aiError,
    this.teacherScore,
    this.teacherFeedback,
    this.audioMediaId,
    this.audioUrl,
    this.createdAt,
    this.updatedAt,
    this.exercise,
  });

  final String id;
  final String exerciseId;
  final String status;
  final String? analysisStatus;
  final String? targetText;
  final double? aiScore;
  final String? aiTranscription;
  final Object? aiAlignment;
  final String? aiError;
  final double? teacherScore;
  final String? teacherFeedback;
  final String? audioMediaId;
  final String? audioUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final SpeakingExercise? exercise;

  String get effectiveAnalysisStatus => analysisStatus ?? status;
  bool get isProcessing =>
      effectiveAnalysisStatus == 'pending' ||
      effectiveAnalysisStatus == 'processing';
  bool get isCompleted => effectiveAnalysisStatus == 'completed';
  bool get isFailed => effectiveAnalysisStatus == 'failed';

  String get friendlyStatus {
    if (isProcessing) return 'Sedang dianalisis';
    if (isFailed) return 'Perlu dicoba lagi';
    if (teacherScore != null) return 'Sudah dinilai guru';
    if (isCompleted) return 'Analisis selesai';
    return 'Rekaman terkirim';
  }

  String get scoreLevel {
    final score = teacherScore ?? aiScore;
    if (score == null) return 'Terus berlatih';
    if (score >= 90) return 'Luar biasa';
    if (score >= 75) return 'Bagus sekali';
    if (score >= 60) return 'Sudah berkembang';
    return 'Ayo latihan lagi';
  }

  factory SpeakingAttempt.fromJson(Map<String, dynamic> json) {
    final exercise = json['exercise'];
    final analysis = json['analysis'];
    final review = json['review'];
    final recording = json['recording'];
    final audioMedia = json['audio_media'];
    final media = json['media'];
    return SpeakingAttempt(
      id: json['id'] as String? ?? '',
      exerciseId: json['exercise_id'] as String? ?? '',
      targetText: json['target_text'] as String?,
      status: json['status'] as String? ?? '',
      analysisStatus: json['analysis_status'] as String?,
      aiScore: _double(json['ai_score'] ?? _mapValue(analysis, 'score')),
      aiTranscription:
          (json['ai_transcription'] ?? _mapValue(analysis, 'transcription'))
              as String?,
      aiAlignment: json['ai_alignment'] ?? _mapValue(analysis, 'alignment'),
      aiError: (json['ai_error'] ?? _mapValue(analysis, 'error')) as String?,
      teacherScore: _double(
        json['teacher_score'] ?? _mapValue(review, 'score'),
      ),
      teacherFeedback:
          (json['teacher_feedback'] ?? _mapValue(review, 'feedback'))
              as String?,
      audioMediaId: _string(
        json['audio_media_id'] ??
            _mapValue(recording, 'media_id') ??
            _mapValue(audioMedia, 'id') ??
            _mapValue(media, 'id'),
      ),
      audioUrl: json['audio_url'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
      exercise: exercise is Map<String, dynamic>
          ? SpeakingExercise.fromJson(exercise)
          : null,
    );
  }

  static Object? _mapValue(Object? value, String key) =>
      value is Map<String, dynamic> ? value[key] : null;

  static String? _string(Object? value) => value is String ? value : null;

  static double? _double(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class SpeakingAttemptPage {
  const SpeakingAttemptPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<SpeakingAttempt> items;
  final int currentPage;
  final int lastPage;
  final int total;

  factory SpeakingAttemptPage.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final meta = json['meta'];
    return SpeakingAttemptPage(
      items: data is List
          ? data
                .whereType<Map<String, dynamic>>()
                .map(SpeakingAttempt.fromJson)
                .toList()
          : const [],
      currentPage: meta is Map<String, dynamic>
          ? _int(meta['current_page'], 1)
          : 1,
      lastPage: meta is Map<String, dynamic> ? _int(meta['last_page'], 1) : 1,
      total: meta is Map<String, dynamic> ? _int(meta['total']) : 0,
    );
  }

  static int _int(Object? value, [int fallback = 0]) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class SpeakingSubmissionFile {
  const SpeakingSubmissionFile({required this.path, required this.sizeBytes});

  final String path;
  final int sizeBytes;

  String get fileName => path.split(Platform.pathSeparator).last;
  String get extension => fileName.split('.').last.toLowerCase();
  String get mimeType => extension == 'm4a' || extension == 'mp4'
      ? 'audio/mp4'
      : extension == 'mp3'
      ? 'audio/mpeg'
      : extension == 'wav'
      ? 'audio/wav'
      : extension == 'ogg' || extension == 'oga'
      ? 'audio/ogg'
      : extension == 'webm'
      ? 'audio/webm'
      : 'application/octet-stream';

  String? validate({int maxBytes = 5 * 1024 * 1024}) {
    const allowed = {'m4a', 'mp4', 'mp3', 'wav', 'ogg', 'oga', 'webm'};
    if (!allowed.contains(extension)) return 'Format audio tidak didukung.';
    if (sizeBytes <= 0) return 'Rekaman kosong.';
    if (sizeBytes > maxBytes) return 'Ukuran audio melebihi 5 MB.';
    return null;
  }
}
