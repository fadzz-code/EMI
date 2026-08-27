class DictionaryEntry {
  const DictionaryEntry({
    required this.id,
    required this.indonesia,
    required this.english,
    required this.mekongga,
    required this.status,
    required this.examples,
    this.category,
    this.categoryId,
    this.exampleMekongga,
    this.exampleIndonesia,
    this.audio,
  });

  final String id;
  final DictionaryCategory? category;
  final String? categoryId;
  final String indonesia;
  final String english;
  final String mekongga;
  final String? exampleMekongga;
  final String? exampleIndonesia;
  final List<DictionaryExample> examples;
  final DictionaryAudio? audio;
  final String status;

  bool get hasAudio => audio?.url.isNotEmpty == true;

  factory DictionaryEntry.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    final examples = json['sentence_examples'];
    return DictionaryEntry(
      id: json['id'] as String? ?? '',
      category: category is Map<String, dynamic>
          ? DictionaryCategory.fromJson(category)
          : null,
      categoryId: json['category_id'] as String?,
      indonesia: json['indonesia'] as String? ?? '-',
      english: json['english'] as String? ?? '-',
      mekongga: json['mekongga'] as String? ?? '-',
      exampleMekongga: json['example_mekongga'] as String?,
      exampleIndonesia: json['example_indonesia'] as String?,
      examples: examples is List
          ? examples
                .whereType<Map<String, dynamic>>()
                .map(DictionaryExample.fromJson)
                .toList()
          : const [],
      audio: json['audio'] is Map<String, dynamic>
          ? DictionaryAudio.fromJson(json['audio'] as Map<String, dynamic>)
          : null,
      status: json['status'] as String? ?? '-',
    );
  }
}

class DictionaryCategory {
  const DictionaryCategory({
    required this.id,
    required this.name,
    this.slug,
    this.entriesCount,
  });

  final String id;
  final String name;
  final String? slug;
  final int? entriesCount;

  factory DictionaryCategory.fromJson(Map<String, dynamic> json) {
    return DictionaryCategory(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '-',
      slug: json['slug'] as String?,
      entriesCount: _nullableInt(json['entries_count']),
    );
  }
}

class DictionaryExample {
  const DictionaryExample({
    required this.id,
    this.code,
    this.mekongga,
    this.indonesia,
    this.status = 'active',
    this.audio,
  });

  final String id;
  final String? code;
  final String? mekongga;
  final String? indonesia;
  final String status;
  final DictionaryAudio? audio;

  factory DictionaryExample.fromJson(Map<String, dynamic> json) {
    return DictionaryExample(
      id: json['id'] as String? ?? '',
      code: json['kode'] as String? ?? json['code'] as String?,
      mekongga:
          json['contoh_mekongga'] as String? ??
          json['example_mekongga'] as String?,
      indonesia:
          json['contoh_indonesia'] as String? ??
          json['example_indonesia'] as String?,
      status: json['status'] as String? ?? 'active',
      audio: json['audio'] is Map<String, dynamic>
          ? DictionaryAudio.fromJson(json['audio'] as Map<String, dynamic>)
          : null,
    );
  }
}

class DictionaryAudio {
  const DictionaryAudio({
    required this.id,
    required this.url,
    this.mimeType,
    this.sizeBytes,
    this.checksumSha256,
  });

  final String id;
  final String url;
  final String? mimeType;
  final int? sizeBytes;
  final String? checksumSha256;

  bool get hasIntegrity =>
      sizeBytes != null && checksumSha256?.isNotEmpty == true;

  factory DictionaryAudio.fromJson(Map<String, dynamic> json) {
    return DictionaryAudio(
      id: json['id'] as String? ?? '',
      url: json['url'] as String? ?? '',
      mimeType: json['mime_type'] as String?,
      sizeBytes: _nullableInt(json['size_bytes']),
      checksumSha256: json['checksum_sha256'] as String?,
    );
  }
}

class DictionaryPage {
  const DictionaryPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<DictionaryEntry> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasNextPage => currentPage < lastPage;

  factory DictionaryPage.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final meta = json['meta'];
    return DictionaryPage(
      items: data is List
          ? data
                .whereType<Map<String, dynamic>>()
                .map(DictionaryEntry.fromJson)
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

int _int(Object? value) => _nullableInt(value) ?? 0;

int? _nullableInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '');
}
