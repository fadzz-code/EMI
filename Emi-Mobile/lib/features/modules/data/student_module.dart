class StudentModule {
  const StudentModule({
    required this.id,
    required this.title,
    required this.status,
    required this.sortOrder,
    required this.progress,
    this.description,
  });

  final String id;
  final String title;
  final String? description;
  final String status;
  final int sortOrder;
  final ModuleProgress progress;

  factory StudentModule.fromJson(Map<String, dynamic> json) {
    return StudentModule(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '-',
      description: json['description'] as String?,
      status: json['status'] as String? ?? '-',
      sortOrder: _int(json['sort_order']),
      progress: ModuleProgress.fromJson(
        json['progress'] as Map<String, dynamic>? ?? const {},
      ),
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
