class StudentModule {
  const StudentModule({
    required this.id,
    required this.title,
    required this.status,
    required this.sortOrder,
    required this.progress,
    required this.lessons,
    this.description,
  });

  final String id;
  final String title;
  final String? description;
  final String status;
  final int sortOrder;
  final ModuleProgress progress;
  final List<StudentLesson> lessons;

  factory StudentModule.fromJson(Map<String, dynamic> json) {
    final lessons = json['lessons'];
    return StudentModule(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '-',
      description: json['description'] as String?,
      status: json['status'] as String? ?? '-',
      sortOrder: _int(json['sort_order']),
      progress: ModuleProgress.fromJson(
        json['progress'] as Map<String, dynamic>? ?? const {},
      ),
      lessons: lessons is List
          ? lessons
                .whereType<Map<String, dynamic>>()
                .map(StudentLesson.fromJson)
                .toList()
          : const [],
    );
  }
}

class StudentLesson {
  const StudentLesson({
    required this.id,
    required this.classModuleId,
    required this.title,
    required this.contentType,
    required this.sortOrder,
    required this.status,
    this.description,
    this.contentBody,
    this.externalUrl,
    this.media,
  });

  final String id;
  final String classModuleId;
  final String title;
  final String? description;
  final String contentType;
  final String? contentBody;
  final String? externalUrl;
  final LessonMedia? media;
  final int sortOrder;
  final String status;

  bool get hasTextContent =>
      contentBody != null && contentBody!.trim().isNotEmpty;
  bool get hasExternalUrl =>
      externalUrl != null && externalUrl!.trim().isNotEmpty;

  factory StudentLesson.fromJson(Map<String, dynamic> json) {
    final media = json['media'];
    return StudentLesson(
      id: json['id'] as String? ?? '',
      classModuleId: json['class_module_id'] as String? ?? '',
      title: json['title'] as String? ?? '-',
      description: json['description'] as String?,
      contentType: json['content_type'] as String? ?? '-',
      contentBody: json['content_body'] as String?,
      externalUrl: json['external_url'] as String?,
      media: media is Map<String, dynamic> ? LessonMedia.fromJson(media) : null,
      sortOrder: _int(json['sort_order']),
      status: json['status'] as String? ?? '-',
    );
  }
}

class LessonMedia {
  const LessonMedia({
    required this.id,
    required this.mimeType,
    required this.visibility,
    this.sizeBytes,
    this.checksumSha256,
    this.extension,
    this.updatedAt,
  });

  final String id;
  final String mimeType;
  final String visibility;
  final int? sizeBytes;
  final String? checksumSha256;
  final String? extension;
  final DateTime? updatedAt;

  bool get isImage => mimeType.startsWith('image/');
  bool get isAudio => mimeType.startsWith('audio/');
  bool get isVideo => mimeType.startsWith('video/');

  factory LessonMedia.fromJson(Map<String, dynamic> json) {
    return LessonMedia(
      id: json['id'] as String? ?? '',
      mimeType: json['mime_type'] as String? ?? '',
      visibility: json['visibility'] as String? ?? '',
      sizeBytes: json['size_bytes'] as int?,
      checksumSha256: json['checksum_sha256'] as String?,
      extension: json['extension'] as String?,
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }
}

class LessonContent {
  const LessonContent({
    this.url,
    this.type,
    this.contentBody,
    this.expiresAt,
    this.media,
  });

  final String? url;
  final String? type;
  final String? contentBody;
  final String? expiresAt;
  final LessonMedia? media;

  bool get hasUrl => url != null && url!.trim().isNotEmpty;
  bool get hasText => contentBody != null && contentBody!.trim().isNotEmpty;

  factory LessonContent.fromJson(Map<String, dynamic> json) {
    final media = json['media'];
    return LessonContent(
      url: json['url'] as String? ?? json['content_url'] as String?,
      type: json['type'] as String? ?? json['content_type'] as String?,
      contentBody: json['content_body'] as String?,
      expiresAt: json['expires_at'] as String?,
      media: media is Map<String, dynamic> ? LessonMedia.fromJson(media) : null,
    );
  }
}

class LessonProgress {
  const LessonProgress({
    required this.status,
    required this.progressPercent,
    this.id,
    this.classLessonId,
  });

  final String? id;
  final String? classLessonId;
  final String status;
  final int progressPercent;

  factory LessonProgress.fromJson(Map<String, dynamic> json) {
    return LessonProgress(
      id: json['id'] as String?,
      classLessonId: json['class_lesson_id'] as String?,
      status: json['status'] as String? ?? 'not_started',
      progressPercent: _int(json['progress_percent']),
    );
  }
}

class ModuleProgress {
  const ModuleProgress({
    required this.status,
    required this.progressPercent,
    required this.completedLessons,
    required this.totalLessons,
  });

  final String status;
  final int progressPercent;
  final int completedLessons;
  final int totalLessons;

  factory ModuleProgress.fromJson(Map<String, dynamic> json) {
    return ModuleProgress(
      status: json['status'] as String? ?? 'not_started',
      progressPercent: _int(json['progress_percent']),
      completedLessons: _int(json['completed_lessons']),
      totalLessons: _int(json['total_lessons']),
    );
  }
}

class StudentModulePage {
  const StudentModulePage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<StudentModule> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasNextPage => currentPage < lastPage;

  factory StudentModulePage.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final meta = json['meta'];
    return StudentModulePage(
      items: data is List
          ? data
                .whereType<Map<String, dynamic>>()
                .map(StudentModule.fromJson)
                .toList()
          : const [],
      currentPage: meta is Map<String, dynamic>
          ? _int(meta['current_page'])
          : 1,
      lastPage: meta is Map<String, dynamic> ? _int(meta['last_page']) : 1,
      total: meta is Map<String, dynamic> ? _int(meta['total']) : 0,
    );
  }
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
