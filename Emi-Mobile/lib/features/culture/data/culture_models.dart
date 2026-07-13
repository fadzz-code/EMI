class CultureMedia {
  const CultureMedia({
    required this.id,
    this.originalName,
    this.mimeType,
    this.visibility,
    this.url,
  });

  final String id;
  final String? originalName;
  final String? mimeType;
  final String? visibility;
  final String? url;

  factory CultureMedia.fromJson(Map<String, dynamic> json) {
    return CultureMedia(
      id: json['id'] as String? ?? '',
      originalName: json['original_name'] as String?,
      mimeType: json['mime_type'] as String?,
      visibility: json['visibility'] as String?,
      url: json['url'] as String?,
    );
  }
}

class CultureSchoolClass {
  const CultureSchoolClass({
    required this.id,
    required this.name,
    this.schoolName,
  });

  final String id;
  final String name;
  final String? schoolName;

  factory CultureSchoolClass.fromJson(Map<String, dynamic> json) {
    final school = json['school'];
    return CultureSchoolClass(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      schoolName: school is Map<String, dynamic>
          ? school['name'] as String?
          : null,
    );
  }
}

class CultureItem {
  const CultureItem({
    required this.id,
    required this.classId,
    required this.title,
    required this.contentType,
    required this.status,
    this.description,
    this.media,
    this.externalUrl,
    this.displayOrder,
    this.schoolClass,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String classId;
  final String title;
  final String contentType;
  final String status;
  final String? description;
  final CultureMedia? media;
  final String? externalUrl;
  final int? displayOrder;
  final CultureSchoolClass? schoolClass;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String? get contentUrl => media?.url ?? externalUrl;

  factory CultureItem.fromJson(Map<String, dynamic> json) {
    final media = json['media'];
    final schoolClass = json['school_class'];
    return CultureItem(
      id: json['id'] as String? ?? '',
      classId: json['class_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      contentType: json['content_type'] as String? ?? '',
      media: media is Map<String, dynamic>
          ? CultureMedia.fromJson(media)
          : null,
      externalUrl: json['external_url'] as String?,
      displayOrder: json['display_order'] as int?,
      status: json['status'] as String? ?? '',
      schoolClass: schoolClass is Map<String, dynamic>
          ? CultureSchoolClass.fromJson(schoolClass)
          : null,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }
}

class CulturePage {
  const CulturePage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<CultureItem> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasNextPage => currentPage < lastPage;

  factory CulturePage.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final meta = json['meta'];
    return CulturePage(
      items: data is List
          ? data
                .whereType<Map<String, dynamic>>()
                .map(CultureItem.fromJson)
                .toList()
          : const [],
      currentPage: meta is Map<String, dynamic>
          ? meta['current_page'] as int? ?? 1
          : 1,
      lastPage: meta is Map<String, dynamic>
          ? meta['last_page'] as int? ?? 1
          : 1,
      total: meta is Map<String, dynamic> ? meta['total'] as int? ?? 0 : 0,
    );
  }
}

class CultureQuery {
  const CultureQuery({this.page = 1, this.perPage = 15});

  final int page;
  final int perPage;

  @override
  bool operator ==(Object other) {
    return other is CultureQuery &&
        other.page == page &&
        other.perPage == perPage;
  }

  @override
  int get hashCode => Object.hash(page, perPage);
}
