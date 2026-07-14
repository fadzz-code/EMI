import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../core/errors/app_error.dart';
import '../../../shared/widgets/emi_card.dart';
import '../data/admin_crud_providers.dart';
import '../data/admin_crud_repository.dart';
import 'admin_shell.dart';

class AdminDictionaryScreen extends ConsumerStatefulWidget {
  const AdminDictionaryScreen({super.key});
  @override
  ConsumerState<AdminDictionaryScreen> createState() =>
      _AdminDictionaryScreenState();
}

class _AdminDictionaryScreenState extends ConsumerState<AdminDictionaryScreen> {
  String? _search;
  String? _categoryId;
  String? _status;
  var _page = 1;
  final _items = <DictionaryEntryAdmin>[];
  @override
  Widget build(BuildContext context) {
    final query = AdminSearchQuery(
      search: _search,
      categoryId: _categoryId,
      status: _status,
      page: _page,
    );
    final data = ref.watch(adminDictionaryProvider(query));
    final categories = ref.watch(dictionaryCategoriesProvider);
    return AdminShell(
      title: 'Kamus',
      child: Column(
        children: [
          _SearchBar(
            onChanged: (v) => setState(() {
              _search = v;
              _page = 1;
              _items.clear();
            }),
            onFilter: () => _showFilters(categories),
            onCategories: () async {
              await context.push('/admin/dictionary/categories');
              if (mounted) ref.invalidate(dictionaryCategoriesProvider);
            },
            onImport: () async {
              await context.push('/admin/dictionary/import');
              if (mounted) ref.invalidate(adminDictionaryProvider);
            },
            onAdd: () async {
              await context.push('/admin/dictionary/create');
              if (mounted) {
                setState(() {
                  _page = 1;
                  _items.clear();
                });
              }
            },
          ),
          Expanded(
            child: data.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _Error(
                message: _friendlyError(e),
                onRetry: () => ref.invalidate(adminDictionaryProvider(query)),
              ),
              data: (page) {
                if (_page == 1) _items.clear();
                for (final item in page.items) {
                  if (!_items.any((old) => old.id == item.id)) _items.add(item);
                }
                return _PagedList(
                  header: _AudioPreviewCard(item: _firstAudioEntry(_items)),
                  empty:
                      (_search?.isNotEmpty == true ||
                          _categoryId != null ||
                          _status != null)
                      ? 'Kosakata Tidak Ditemukan\nCoba gunakan kata, arti, atau filter yang berbeda.'
                      : 'Belum Ada Kosakata\nTambahkan kosakata agar Kamus EMI dapat digunakan.',
                  hasMore: page.hasMore,
                  onMore: () => setState(() => _page++),
                  children: [
                    for (final item in _items)
                      _Tile(
                        title: item.mekongga,
                        subtitle: [
                          'Indonesia: ${item.indonesia}',
                          'Inggris: ${item.english}',
                          [
                            if (item.categoryName?.isNotEmpty == true)
                              item.categoryName!,
                            _statusLabel(item.status),
                          ].join(' • '),
                          item.audioUrl?.isNotEmpty == true
                              ? 'Audio Tersedia'
                              : 'Belum Ada Audio',
                        ].join('\n'),
                        status: _statusLabel(item.status),
                        onTap: () =>
                            context.push('/admin/dictionary/${item.id}'),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFilters(
    AsyncValue<AdminCrudPage<DictionaryCategory>> categories,
  ) async {
    final result =
        await showModalBottomSheet<({String? categoryId, String? status})>(
          context: context,
          builder: (context) => _DictionaryFilterSheet(
            categories: categories.value?.items ?? const [],
            categoryId: _categoryId,
            status: _status,
          ),
        );
    if (result == null || !mounted) return;
    setState(() {
      _categoryId = result.categoryId;
      _status = result.status;
      _page = 1;
      _items.clear();
    });
  }
}

class AdminDictionaryFormScreen extends ConsumerStatefulWidget {
  const AdminDictionaryFormScreen({super.key, this.id});
  final String? id;
  @override
  ConsumerState<AdminDictionaryFormScreen> createState() =>
      _AdminDictionaryFormScreenState();
}

class _AdminDictionaryFormScreenState
    extends ConsumerState<AdminDictionaryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _indonesia = TextEditingController();
  final _english = TextEditingController();
  final _mekongga = TextEditingController();
  final _exampleMekongga = TextEditingController();
  final _exampleIndonesia = TextEditingController();
  String? _categoryId;
  String _status = 'active';
  bool _saving = false;
  AppError? _error;
  bool _hydrated = false;

  bool get _editing => widget.id != null && widget.id != 'new';
  @override
  void dispose() {
    _indonesia.dispose();
    _english.dispose();
    _mekongga.dispose();
    _exampleMekongga.dispose();
    _exampleIndonesia.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(dictionaryCategoriesProvider);
    final detail = _editing
        ? ref.watch(adminDictionaryDetailProvider(widget.id!))
        : null;
    if (detail?.hasValue == true && !_hydrated) {
      final item = detail!.value!;
      _indonesia.text = item.indonesia;
      _english.text = item.english;
      _mekongga.text = item.mekongga;
      _exampleMekongga.text = item.exampleMekongga ?? '';
      _exampleIndonesia.text = item.exampleIndonesia ?? '';
      _categoryId = item.categoryId;
      _status = item.status ?? 'active';
      _hydrated = true;
    }
    return AdminShell(
      title: _editing ? 'Edit Kosakata' : 'Tambah Kosakata',
      child: detail?.isLoading == true
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(EmiSpacing.md),
                children: [
                  if (_error != null) _ValidationBox(error: _error!),
                  EmiCard(
                    child: Column(
                      children: [
                        categories.when(
                          loading: () => const LinearProgressIndicator(),
                          error: (e, _) => Text(e.toString()),
                          data: (page) => DropdownButtonFormField<String>(
                            initialValue: _categoryId?.isEmpty == true
                                ? null
                                : _categoryId,
                            decoration: const InputDecoration(
                              labelText: 'Kategori',
                            ),
                            items: [
                              for (final c in page.items)
                                DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name),
                                ),
                            ],
                            onChanged: _saving
                                ? null
                                : (v) => setState(() => _categoryId = v),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Kategori wajib diisi.'
                                : null,
                          ),
                        ),
                        TextFormField(
                          controller: _indonesia,
                          decoration: const InputDecoration(
                            labelText: 'Arti Bahasa Indonesia',
                          ),
                          validator: _required,
                        ),
                        TextFormField(
                          controller: _english,
                          decoration: const InputDecoration(
                            labelText: 'English',
                          ),
                          validator: _required,
                        ),
                        TextFormField(
                          controller: _mekongga,
                          decoration: const InputDecoration(
                            labelText: 'Kata Mekongga',
                          ),
                          validator: _required,
                        ),
                        TextFormField(
                          controller: _exampleMekongga,
                          decoration: const InputDecoration(
                            labelText: 'Contoh Mekongga',
                          ),
                        ),
                        TextFormField(
                          controller: _exampleIndonesia,
                          decoration: const InputDecoration(
                            labelText: 'Contoh Indonesia',
                          ),
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: _status,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'active',
                              child: Text('Aktif'),
                            ),
                            DropdownMenuItem(
                              value: 'inactive',
                              child: Text('Tidak Aktif'),
                            ),
                          ],
                          onChanged: _saving
                              ? null
                              : (v) => setState(() => _status = v ?? 'active'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: EmiSpacing.md),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Menyimpan...' : 'Simpan'),
                  ),
                  if (_editing)
                    TextButton(
                      onPressed: _saving ? null : _delete,
                      child: const Text('Hapus'),
                    ),
                ],
              ),
            ),
    );
  }

  String? _required(String? v) =>
      v == null || v.trim().isEmpty ? 'Wajib diisi.' : null;
  Map<String, dynamic> _payload() => {
    'category_id': _categoryId,
    'indonesia': _indonesia.text.trim(),
    'english': _english.text.trim(),
    'mekongga': _mekongga.text.trim(),
    'example_mekongga': _exampleMekongga.text.trim().isEmpty
        ? null
        : _exampleMekongga.text.trim(),
    'example_indonesia': _exampleIndonesia.text.trim().isEmpty
        ? null
        : _exampleIndonesia.text.trim(),
    'status': _status,
  };
  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(adminCrudRepositoryProvider)
          .saveDictionary(id: _editing ? widget.id : null, data: _payload());
      ref.invalidate(adminDictionaryProvider);
      if (_editing) ref.invalidate(adminDictionaryDetailProvider(widget.id!));
      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is AppError
              ? e
              : AppError(type: AppErrorType.unknown, message: e.toString()),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await _confirm(
      context,
      'Hapus kosakata ini?\nTindakan ini tidak dapat dibatalkan.',
    );
    if (ok != true || _saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(adminCrudRepositoryProvider).deleteDictionary(widget.id!);
      ref.invalidate(adminDictionaryProvider);
      if (mounted) context.go('/admin/dictionary');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class AdminDictionaryDetailScreen extends ConsumerWidget {
  const AdminDictionaryDetailScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(adminDictionaryDetailProvider(id));
    return AdminShell(
      title: 'Detail Kosakata',
      child: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Error(
          message: _friendlyError(e),
          onRetry: () => ref.invalidate(adminDictionaryDetailProvider(id)),
        ),
        data: (item) => ListView(
          padding: const EdgeInsets.all(EmiSpacing.md),
          children: [
            EmiCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.mekongga,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(item.indonesia),
                  if (item.english.isNotEmpty) Text(item.english),
                  const SizedBox(height: EmiSpacing.sm),
                  Text(
                    'Kategori: ${item.categoryName ?? 'Kategori tidak tersedia'}',
                  ),
                  Text('Status: ${_statusLabel(item.status)}'),
                  if (item.audioMediaId?.isNotEmpty == true)
                    Text('ID Media Audio: ${item.audioMediaId}'),
                  if (item.createdAt?.isNotEmpty == true)
                    Text('Dibuat: ${item.createdAt}'),
                  if (item.updatedAt?.isNotEmpty == true)
                    Text('Terakhir Diubah: ${item.updatedAt}'),
                  const Text(
                    'Tinjau terjemahan, contoh kalimat, status, kategori, dan audio yang terhubung dengan kata ini.',
                  ),
                ],
              ),
            ),
            EmiCard(
              child: Text(
                item.exampleMekongga?.isNotEmpty == true
                    ? item.exampleMekongga!
                    : 'Belum Ada Contoh',
              ),
            ),
            EmiCard(
              child: Text(
                item.exampleIndonesia?.isNotEmpty == true
                    ? item.exampleIndonesia!
                    : 'Belum Ada Contoh',
              ),
            ),
            EmiCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: item.sentenceExamples.isEmpty
                    ? const [Text('Belum ada contoh kalimat.')]
                    : [
                        const Text('Contoh Kalimat'),
                        for (final example in item.sentenceExamples)
                          Text(
                            '${example.mekongga ?? ''}\n${example.indonesia ?? ''}',
                          ),
                      ],
              ),
            ),
            EmiCard(
              child: Text(
                item.audioUrl?.isNotEmpty == true
                    ? 'Audio Pelafalan tersedia'
                    : 'Audio belum tersedia.',
              ),
            ),
            const SizedBox(height: EmiSpacing.md),
            FilledButton(
              onPressed: () async {
                await context.push('/admin/dictionary/$id/edit');
                ref.invalidate(adminDictionaryDetailProvider(id));
              },
              child: const Text('Edit Entri'),
            ),
            TextButton(
              onPressed: () async {
                final ok = await _confirm(
                  context,
                  'Hapus kosakata ini dari Kamus?\nKosakata tidak akan tampil pada daftar aktif, tetapi datanya tetap disimpan oleh sistem.',
                );
                if (ok != true) return;
                await ref
                    .read(adminCrudRepositoryProvider)
                    .deleteDictionary(id);
                ref.invalidate(adminDictionaryProvider);
                if (context.mounted) context.go('/admin/dictionary');
              },
              child: const Text('Hapus'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DictionaryFilterSheet extends StatefulWidget {
  const _DictionaryFilterSheet({
    required this.categories,
    this.categoryId,
    this.status,
  });
  final List<DictionaryCategory> categories;
  final String? categoryId;
  final String? status;
  @override
  State<_DictionaryFilterSheet> createState() => _DictionaryFilterSheetState();
}

class _DictionaryFilterSheetState extends State<_DictionaryFilterSheet> {
  String? _categoryId;
  String? _status;
  @override
  void initState() {
    super.initState();
    _categoryId = widget.categoryId;
    _status = widget.status;
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(EmiSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _categoryId,
            decoration: const InputDecoration(labelText: 'Kategori'),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Semua Kategori'),
              ),
              for (final c in widget.categories)
                DropdownMenuItem(value: c.id, child: Text(c.name)),
            ],
            onChanged: (v) => setState(() => _categoryId = v),
          ),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: const [
              DropdownMenuItem(value: null, child: Text('Semua')),
              DropdownMenuItem(value: 'active', child: Text('Aktif')),
              DropdownMenuItem(value: 'inactive', child: Text('Tidak Aktif')),
            ],
            onChanged: (v) => setState(() => _status = v),
          ),
          FilledButton(
            onPressed: () =>
                context.pop((categoryId: _categoryId, status: _status)),
            child: const Text('Terapkan'),
          ),
          TextButton(
            onPressed: () => context.pop((categoryId: null, status: null)),
            child: const Text('Hapus Filter'),
          ),
        ],
      ),
    ),
  );
}

class AdminDictionaryCategoryScreen extends ConsumerWidget {
  const AdminDictionaryCategoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(dictionaryCategoriesProvider);
    return AdminShell(
      title: 'Kategori Kamus',
      child: categories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Error(
          message: _friendlyError(e),
          onRetry: () => ref.invalidate(dictionaryCategoriesProvider),
        ),
        data: (page) => ListView(
          padding: const EdgeInsets.all(EmiSpacing.md),
          children: [
            FilledButton(
              onPressed: () => _showCategoryForm(context, ref),
              child: const Text('Tambah Kategori'),
            ),
            for (final category in page.items)
              EmiCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(category.name),
                  subtitle: Text(
                    '${category.entriesCount} kosakata • ${_statusLabel(category.status)}',
                  ),
                  trailing: Wrap(
                    children: [
                      IconButton(
                        onPressed: () =>
                            _showCategoryForm(context, ref, category: category),
                        icon: const Icon(Icons.edit),
                      ),
                      IconButton(
                        onPressed: () =>
                            _deleteCategory(context, ref, category),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AdminDictionaryImportScreen extends ConsumerStatefulWidget {
  const AdminDictionaryImportScreen({super.key});
  @override
  ConsumerState<AdminDictionaryImportScreen> createState() =>
      _AdminDictionaryImportScreenState();
}

class _AdminDictionaryImportScreenState
    extends ConsumerState<AdminDictionaryImportScreen> {
  File? _csv;
  File? _zip;
  var _importType = 'vocabulary';
  var _duplicateStrategy = 'skip';
  bool _uploading = false;
  double? _progress;
  DictionaryImportJobAdmin? _job;
  AdminCrudPage<DictionaryImportErrorAdmin>? _errors;
  String? _error;

  @override
  Widget build(BuildContext context) => AdminShell(
    title: 'Import Data',
    child: ListView(
      padding: const EdgeInsets.all(EmiSpacing.md),
      children: [
        EmiCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Format CSV: kode, indonesia, english, mekongga, kategori, audio_filename',
              ),
              DropdownButtonFormField<String>(
                initialValue: _importType,
                decoration: const InputDecoration(labelText: 'Jenis Import'),
                items: const [
                  DropdownMenuItem(
                    value: 'vocabulary',
                    child: Text('Kosakata'),
                  ),
                  DropdownMenuItem(
                    value: 'sentence_examples',
                    child: Text('Contoh Kalimat'),
                  ),
                ],
                onChanged: _uploading
                    ? null
                    : (v) => setState(() => _importType = v ?? 'vocabulary'),
              ),
              DropdownButtonFormField<String>(
                initialValue: _duplicateStrategy,
                decoration: const InputDecoration(labelText: 'Duplikasi'),
                items: const [
                  DropdownMenuItem(value: 'skip', child: Text('Lewati')),
                  DropdownMenuItem(value: 'update', child: Text('Perbarui')),
                  DropdownMenuItem(value: 'reject', child: Text('Tolak')),
                ],
                onChanged: _uploading
                    ? null
                    : (v) => setState(() => _duplicateStrategy = v ?? 'skip'),
              ),
              OutlinedButton(
                onPressed: _uploading ? null : _pickCsv,
                child: Text(
                  _csv == null
                      ? 'Pilih CSV'
                      : _csv!.path.split(Platform.pathSeparator).last,
                ),
              ),
              OutlinedButton(
                onPressed: _uploading ? null : _pickZip,
                child: Text(
                  _zip == null
                      ? 'Pilih ZIP Audio'
                      : _zip!.path.split(Platform.pathSeparator).last,
                ),
              ),
              if (_progress != null) LinearProgressIndicator(value: _progress),
              if (_uploading) const Text('Mengunggah data Kamus...'),
              if (_error != null) Text(_error!),
              FilledButton(
                onPressed: _uploading || _csv == null ? null : _preview,
                child: const Text('Import Data'),
              ),
            ],
          ),
        ),
        if (_job != null)
          _ImportResult(job: _job!, errors: _errors?.items ?? const []),
      ],
    ),
  );

  Future<void> _pickCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    final path = result?.files.single.path;
    if (path != null) setState(() => _csv = File(path));
  }

  Future<void> _pickZip() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    final path = result?.files.single.path;
    if (path != null) setState(() => _zip = File(path));
  }

  Future<void> _preview() async {
    final csv = _csv;
    if (csv == null || _uploading) return;
    setState(() {
      _uploading = true;
      _error = null;
      _progress = null;
    });
    try {
      final job = await ref
          .read(adminCrudRepositoryProvider)
          .previewDictionaryImport(
            csvFile: csv,
            audioZip: _zip,
            importType: _importType,
            duplicateStrategy: _duplicateStrategy,
            onSendProgress: (sent, total) {
              if (mounted && total > 0) {
                setState(() => _progress = sent / total);
              }
            },
          );
      final confirmed = await ref
          .read(adminCrudRepositoryProvider)
          .confirmDictionaryImport(job.id);
      final errors = await ref
          .read(adminCrudRepositoryProvider)
          .dictionaryImportErrors(job.id);
      if (mounted) {
        setState(() {
          _job = confirmed;
          _errors = errors;
        });
        ref.invalidate(adminDictionaryProvider);
      }
    } catch (e) {
      if (mounted) setState(() => _error = _importError(e));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }
}

class _ImportResult extends StatelessWidget {
  const _ImportResult({required this.job, required this.errors});
  final DictionaryImportJobAdmin job;
  final List<DictionaryImportErrorAdmin> errors;
  @override
  Widget build(BuildContext context) => EmiCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Import Selesai'),
        Text('Berhasil: ${job.insertedRows + job.updatedRows} kosakata'),
        Text('Dilewati: ${job.skippedRows} kosakata'),
        Text('Gagal: ${job.invalidRows} kosakata'),
        for (final error in errors.take(10))
          Text('Baris ${error.rowNumber ?? '-'}: ${_importErrorText(error)}'),
      ],
    ),
  );
}

class _AudioPreviewCard extends StatefulWidget {
  const _AudioPreviewCard({this.item});
  final DictionaryEntryAdmin? item;
  @override
  State<_AudioPreviewCard> createState() => _AudioPreviewCardState();
}

class _AudioPreviewCardState extends State<_AudioPreviewCard> {
  final _player = AudioPlayer();
  String? _error;

  @override
  void didUpdateWidget(covariant _AudioPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item?.audioUrl != widget.item?.audioUrl) {
      _player.stop();
      _error = null;
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => EmiCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pratinjau Audio Kamus',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const Text(
          'Audio pertama yang tersedia dari hasil filter ditampilkan untuk pemeriksaan cepat.',
        ),
        if (widget.item == null) ...const [
          SizedBox(height: EmiSpacing.sm),
          Text('Belum Ada Audio untuk Ditinjau'),
          Text(
            'Audio akan muncul setelah kosakata memiliki file audio publik yang valid.',
          ),
        ] else ...[
          const SizedBox(height: EmiSpacing.sm),
          Text(widget.item!.mekongga),
          Text(widget.item!.indonesia),
          if (_error != null) Text(_error!),
          Wrap(
            spacing: EmiSpacing.sm,
            children: [
              OutlinedButton(onPressed: _play, child: const Text('Putar')),
              OutlinedButton(
                onPressed: _player.pause,
                child: const Text('Jeda'),
              ),
              OutlinedButton(
                onPressed: _player.stop,
                child: const Text('Berhenti'),
              ),
            ],
          ),
        ],
      ],
    ),
  );

  Future<void> _play() async {
    final url = widget.item?.audioUrl;
    if (url == null || url.isEmpty) return;
    try {
      await _player.setUrl(url);
      await _player.play();
    } catch (_) {
      if (mounted) setState(() => _error = 'Audio belum bisa diputar.');
    }
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.onChanged,
    required this.onFilter,
    required this.onCategories,
    required this.onImport,
    required this.onAdd,
  });
  final ValueChanged<String> onChanged;
  final VoidCallback onFilter;
  final VoidCallback onCategories;
  final VoidCallback onImport;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(EmiSpacing.md),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Cari kata atau arti',
                ),
                onChanged: onChanged,
              ),
            ),
            IconButton(
              onPressed: onFilter,
              icon: const Icon(Icons.filter_list),
            ),
            IconButton.filled(onPressed: onAdd, icon: const Icon(Icons.add)),
          ],
        ),
        Wrap(
          spacing: EmiSpacing.sm,
          children: [
            OutlinedButton(
              onPressed: onCategories,
              child: const Text('Kelola Kategori'),
            ),
            OutlinedButton(
              onPressed: onImport,
              child: const Text('Import Data'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.title,
    this.subtitle,
    this.status,
    required this.onTap,
  });
  final String title;
  final String? subtitle;
  final String? status;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => EmiCard(
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, maxLines: 5, overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        children: [Text(status ?? ''), const Icon(Icons.chevron_right)],
      ),
      onTap: onTap,
    ),
  );
}

class _PagedList extends StatelessWidget {
  const _PagedList({
    this.header,
    required this.children,
    required this.empty,
    required this.hasMore,
    required this.onMore,
  });
  final Widget? header;
  final List<Widget> children;
  final String empty;
  final bool hasMore;
  final VoidCallback onMore;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(EmiSpacing.md),
    children: [
      ?header,
      if (children.isEmpty)
        EmiCard(child: Text(empty))
      else ...[
        ...children,
        if (hasMore)
          OutlinedButton(onPressed: onMore, child: const Text('Muat Lagi')),
      ],
    ],
  );
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(EmiSpacing.md),
    children: [
      EmiCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            OutlinedButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    ],
  );
}

class _ValidationBox extends StatelessWidget {
  const _ValidationBox({required this.error});
  final AppError error;
  @override
  Widget build(BuildContext context) => EmiCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(error.message),
        for (final entry in error.fieldErrors.entries)
          Text('${entry.key}: ${entry.value.join(', ')}'),
      ],
    ),
  );
}

Future<void> _showCategoryForm(
  BuildContext context,
  WidgetRef ref, {
  DictionaryCategory? category,
}) async {
  final name = TextEditingController(text: category?.name ?? '');
  final description = TextEditingController(text: category?.description ?? '');
  var status = category?.status ?? 'active';
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(category == null ? 'Tambah Kategori' : 'Edit Kategori'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Nama Kategori'),
          ),
          TextField(
            controller: description,
            decoration: const InputDecoration(labelText: 'Deskripsi'),
          ),
          DropdownButtonFormField<String>(
            initialValue: status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: const [
              DropdownMenuItem(value: 'active', child: Text('Aktif')),
              DropdownMenuItem(value: 'inactive', child: Text('Tidak Aktif')),
            ],
            onChanged: (v) => status = v ?? 'active',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => context.pop(true),
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
  if (ok != true || name.text.trim().isEmpty) return;
  await ref
      .read(adminCrudRepositoryProvider)
      .saveCategory(
        id: category?.id,
        data: {
          'name': name.text.trim(),
          'description': description.text.trim().isEmpty
              ? null
              : description.text.trim(),
          'status': status,
        },
      );
  ref.invalidate(dictionaryCategoriesProvider);
}

Future<void> _deleteCategory(
  BuildContext context,
  WidgetRef ref,
  DictionaryCategory category,
) async {
  final ok = await _confirm(context, 'Hapus kategori ini?');
  if (ok != true) return;
  try {
    await ref.read(adminCrudRepositoryProvider).deleteCategory(category.id);
    ref.invalidate(dictionaryCategoriesProvider);
  } catch (e) {
    if (context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Kategori Belum Bisa Dihapus'),
          content: Text(_categoryError(e)),
          actions: [
            FilledButton(
              onPressed: () => context.pop(),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
    }
  }
}

DictionaryEntryAdmin? _firstAudioEntry(List<DictionaryEntryAdmin> items) {
  for (final item in items) {
    if (item.audioUrl?.isNotEmpty == true) return item;
  }
  return null;
}

String _statusLabel(String? status) => switch (status) {
  'active' => 'Aktif',
  'inactive' => 'Tidak Aktif',
  _ => 'Status tidak tersedia',
};

String _categoryError(Object error) {
  final message = error is AppError ? error.message : error.toString();
  if (message.contains('CATEGORY_IN_USE') ||
      message.contains('DICTIONARY_CATEGORY_IN_USE')) {
    return 'Kategori ini masih digunakan oleh kosakata. Pindahkan atau ubah kategori kosakata terlebih dahulu.';
  }
  return 'Kategori belum dapat diproses. Silakan coba kembali.';
}

String _importError(Object error) {
  final message = error is AppError ? error.message : error.toString();
  if (message.contains('INVALID_CSV_HEADER')) {
    return 'Susunan kolom CSV belum sesuai dengan format Kamus EMI.';
  }
  if (message.contains('INVALID_ZIP')) {
    return 'File ZIP tidak dapat dibaca atau formatnya belum sesuai.';
  }
  if (message.contains('413')) return 'Ukuran file terlalu besar.';
  if (message.contains('415')) return 'Format file belum didukung.';
  if (message.contains('AUDIO') && message.contains('MISSING')) {
    return 'Beberapa file audio yang disebutkan pada CSV tidak ditemukan di dalam ZIP.';
  }
  if (error is AppError && error.type == AppErrorType.networkUnavailable) {
    return 'Import belum berhasil. Periksa koneksi internet, lalu coba lagi.';
  }
  return 'Data belum dapat diproses. Silakan periksa file dan coba kembali.';
}

String _importErrorText(DictionaryImportErrorAdmin error) {
  final code = error.code ?? '';
  if (code.contains('DUPLICATE')) return 'Kosakata sudah tersedia.';
  if (code.contains('CATEGORY')) return 'Kategori tidak ditemukan.';
  if (code.contains('REQUIRED')) return 'Field wajib belum diisi.';
  return error.message ?? 'Data belum valid.';
}

String _friendlyError(Object error) {
  final message = error is AppError ? error.message : error.toString();
  if (message.contains('DICTIONARY_DUPLICATE') ||
      message.toLowerCase().contains('duplicate')) {
    return 'Kosakata ini sudah tersedia.';
  }
  if (message.contains('403')) return 'Akses tidak tersedia.';
  if (message.contains('401')) return 'Sesi berakhir. Silakan masuk kembali.';
  return 'Data belum bisa dimuat\nPeriksa koneksi internet, lalu coba lagi.';
}

Future<bool?> _confirm(BuildContext context, String text) => showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    content: Text(text),
    actions: [
      TextButton(
        onPressed: () => context.pop(false),
        child: const Text('Batal'),
      ),
      FilledButton(onPressed: () => context.pop(true), child: const Text('Ya')),
    ],
  ),
);
