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
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _SearchBar(
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
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: EmiSpacing.md,
                  ),
                  child: _AudioPreviewCard(item: _firstAudioEntry(_items)),
                ),
              ),
              if (_items.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(EmiSpacing.md),
                    child: Text(
                      (_search?.isNotEmpty == true ||
                              _categoryId != null ||
                              _status != null)
                          ? 'Kosakata Tidak Ditemukan\nCoba gunakan kata, arti, atau filter yang berbeda.'
                          : 'Belum Ada Kosakata\nTambahkan kosakata agar Kamus EMI dapat digunakan.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(EmiSpacing.md),
                  sliver: SliverList.separated(
                    itemCount: _items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: EmiSpacing.md),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return _DictionaryTile(
                        item: item,
                        onTap: () =>
                            context.push('/admin/dictionary/${item.id}'),
                      );
                    },
                  ),
                ),
              if (page.hasMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: EmiSpacing.md,
                      vertical: EmiSpacing.sm,
                    ),
                    child: OutlinedButton(
                      onPressed: () => setState(() => _page++),
                      child: const Text('Muat Lagi'),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: EmiSpacing.xl)),
            ],
          );
        },
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
  String? _audioMediaId;
  String? _initialAudioUrl;
  File? _audioFile;
  bool _removeAudio = false;
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
      _audioMediaId = item.audioMediaId;
      _initialAudioUrl = item.audioUrl;
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
                  _PageIntro(
                    title: _editing ? 'Edit Kosakata' : 'Tambah Kosakata',
                    subtitle:
                        'Isi data dengan bahasa yang mudah dipahami siswa.',
                    icon: Icons.menu_book_outlined,
                  ),
                  if (_error != null) _ValidationBox(error: _error!),
                  _SectionCard(
                    title: 'Arti Kosakata',
                    icon: Icons.translate,
                    children: [
                      _GapField(
                        child: TextFormField(
                          controller: _mekongga,
                          decoration: const InputDecoration(
                            labelText: 'Kata Mekongga',
                            hintText: 'Contoh: mowila',
                          ),
                          validator: _required,
                        ),
                      ),
                      _GapField(
                        child: TextFormField(
                          controller: _indonesia,
                          decoration: const InputDecoration(
                            labelText: 'Arti Bahasa Indonesia',
                          ),
                          validator: _required,
                        ),
                      ),
                      _GapField(
                        child: TextFormField(
                          controller: _english,
                          decoration: const InputDecoration(
                            labelText: 'Arti Bahasa Inggris',
                          ),
                          validator: _required,
                        ),
                      ),
                    ],
                  ),
                  _SectionCard(
                    title: 'Pengelompokan',
                    icon: Icons.category_outlined,
                    children: [
                      _GapField(
                        child: categories.when(
                          loading: () => const LinearProgressIndicator(),
                          error: (e, _) =>
                              const Text('Kategori belum bisa dimuat.'),
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
                      ),
                      _GapField(
                        child: DropdownButtonFormField<String>(
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
                      ),
                    ],
                  ),
                  _SectionCard(
                    title: 'Contoh Kalimat',
                    icon: Icons.format_quote,
                    children: [
                      _GapField(
                        child: TextFormField(
                          controller: _exampleMekongga,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Contoh Mekongga',
                          ),
                        ),
                      ),
                      _GapField(
                        child: TextFormField(
                          controller: _exampleIndonesia,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Contoh Indonesia',
                          ),
                        ),
                      ),
                    ],
                  ),
                  _SectionCard(
                    title: 'Audio Pelafalan',
                    icon: Icons.volume_up_outlined,
                    children: [
                      _AudioField(
                        initialAudioUrl: _initialAudioUrl,
                        audioFile: _audioFile,
                        removeAudio: _removeAudio,
                        disabled: _saving,
                        onPick: _pickAudio,
                        onRemove: () => setState(() => _removeAudio = true),
                        onRestore: () => setState(() => _removeAudio = false),
                        onClearSelected: () =>
                            setState(() => _audioFile = null),
                      ),
                    ],
                  ),
                  const SizedBox(height: EmiSpacing.md),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Menyimpan...' : 'Simpan'),
                  ),
                  if (_editing)
                    TextButton.icon(
                      onPressed: _saving ? null : _delete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Hapus'),
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
    'audio_media_id': _removeAudio ? null : _audioMediaId,
  };
  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_audioFile != null) {
        _audioMediaId = await ref
            .read(adminCrudRepositoryProvider)
            .uploadDictionaryAudio(_audioFile!);
      }
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

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'ogg', 'm4a', 'webm'],
    );
    final path = result?.files.single.path;
    if (path != null) {
      setState(() {
        _audioFile = File(path);
        _removeAudio = false;
      });
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
            _PageIntro(
              title: item.mekongga,
              subtitle:
                  'Tinjau arti, contoh kalimat, kategori, status, dan audio kosakata ini.',
              icon: Icons.auto_stories_outlined,
            ),
            _SectionCard(
              title: 'Arti Utama',
              icon: Icons.translate,
              children: [
                _InfoLine(
                  icon: Icons.record_voice_over,
                  text: 'Mekongga: ${item.mekongga}',
                ),
                _InfoLine(
                  icon: Icons.flag_outlined,
                  text: 'Indonesia: ${item.indonesia}',
                ),
                _InfoLine(
                  icon: Icons.language,
                  text: 'Inggris: ${item.english.isEmpty ? '-' : item.english}',
                ),
                Wrap(
                  spacing: EmiSpacing.xs,
                  runSpacing: EmiSpacing.xs,
                  children: [
                    _Chip(text: item.categoryName ?? 'Kategori tidak tersedia'),
                    _Chip(
                      text: _statusLabel(item.status),
                      color: EmiColors.secondary,
                    ),
                  ],
                ),
              ],
            ),
            _SectionCard(
              title: 'Data Admin',
              icon: Icons.info_outline,
              children: [
                if (item.createdAt?.isNotEmpty == true)
                  _InfoLine(
                    icon: Icons.event_outlined,
                    text: 'Dibuat: ${_shortDate(item.createdAt)}',
                  ),
                if (item.updatedAt?.isNotEmpty == true)
                  _InfoLine(
                    icon: Icons.update,
                    text: 'Terakhir Diubah: ${_shortDate(item.updatedAt)}',
                  ),
              ],
            ),
            _SectionCard(
              title: 'Contoh Kalimat',
              icon: Icons.format_quote,
              children: [
                _InfoLine(
                  icon: Icons.chat_bubble_outline,
                  text: item.exampleMekongga?.isNotEmpty == true
                      ? item.exampleMekongga!
                      : 'Belum ada contoh Mekongga.',
                ),
                _InfoLine(
                  icon: Icons.chat_outlined,
                  text: item.exampleIndonesia?.isNotEmpty == true
                      ? item.exampleIndonesia!
                      : 'Belum ada contoh Indonesia.',
                ),
                if (item.sentenceExamples.isEmpty)
                  const Text('Belum ada contoh kalimat.')
                else
                  for (final example in item.sentenceExamples)
                    Padding(
                      padding: const EdgeInsets.only(top: EmiSpacing.sm),
                      child: Text(
                        '${example.mekongga ?? '-'}\n${example.indonesia ?? '-'}',
                      ),
                    ),
              ],
            ),
            _SectionCard(
              title: 'Audio',
              icon: Icons.volume_up_outlined,
              children: [
                if (item.audioUrl?.isNotEmpty == true) ...[
                  const Text('Audio pelafalan tersedia.'),
                  const SizedBox(height: EmiSpacing.sm),
                  _AudioPlayerButtons(url: item.audioUrl!),
                ] else
                  const Text('Audio belum tersedia.'),
              ],
            ),
            const SizedBox(height: EmiSpacing.md),
            FilledButton.icon(
              onPressed: () async {
                await context.push('/admin/dictionary/$id/edit');
                ref.invalidate(adminDictionaryDetailProvider(id));
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Entri'),
            ),
            TextButton.icon(
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
              icon: const Icon(Icons.delete_outline),
              label: const Text('Hapus'),
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
            _PageIntro(
              title: 'Kategori Kamus',
              subtitle:
                  'Rapikan kelompok kosakata agar siswa lebih mudah mencari kata.',
              icon: Icons.category_outlined,
            ),
            FilledButton.icon(
              onPressed: () => _showCategoryForm(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Kategori'),
            ),
            const SizedBox(height: EmiSpacing.md),
            for (final category in page.items)
              EmiCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (category.description?.isNotEmpty == true) ...[
                      const SizedBox(height: EmiSpacing.xs),
                      Text(category.description!),
                    ],
                    const SizedBox(height: EmiSpacing.sm),
                    Wrap(
                      spacing: EmiSpacing.xs,
                      runSpacing: EmiSpacing.xs,
                      children: [
                        _Chip(text: '${category.entriesCount} kosakata'),
                        _Chip(
                          text: _statusLabel(category.status),
                          color: EmiColors.secondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: EmiSpacing.sm),
                    Wrap(
                      spacing: EmiSpacing.sm,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _showCategoryForm(
                            context,
                            ref,
                            category: category,
                          ),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit'),
                        ),
                        TextButton.icon(
                          onPressed: () =>
                              _deleteCategory(context, ref, category),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Hapus'),
                        ),
                      ],
                    ),
                  ],
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
        _PageIntro(
          title: 'Import Data',
          subtitle: 'Pilih file, cek nama file, lalu mulai import Kamus.',
          icon: Icons.upload_file,
        ),
        _SectionCard(
          title: 'Pilih File',
          icon: Icons.folder_open_outlined,
          children: [
            const Text(
              'Format CSV: kode, indonesia, english, mekongga, kategori, audio_filename',
            ),
            const SizedBox(height: EmiSpacing.md),
            _GapField(
              child: DropdownButtonFormField<String>(
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
            ),
            _GapField(
              child: DropdownButtonFormField<String>(
                initialValue: _duplicateStrategy,
                decoration: const InputDecoration(labelText: 'Data yang Sama'),
                items: const [
                  DropdownMenuItem(value: 'skip', child: Text('Lewati')),
                  DropdownMenuItem(value: 'update', child: Text('Perbarui')),
                  DropdownMenuItem(value: 'reject', child: Text('Tolak')),
                ],
                onChanged: _uploading
                    ? null
                    : (v) => setState(() => _duplicateStrategy = v ?? 'skip'),
              ),
            ),
            Wrap(
              spacing: EmiSpacing.sm,
              runSpacing: EmiSpacing.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: _uploading ? null : _pickCsv,
                  icon: const Icon(Icons.description_outlined),
                  label: Text(
                    _csv == null
                        ? 'Pilih CSV'
                        : _csv!.path.split(Platform.pathSeparator).last,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _uploading ? null : _pickZip,
                  icon: const Icon(Icons.volume_up_outlined),
                  label: Text(
                    _zip == null
                        ? 'Pilih ZIP Audio'
                        : _zip!.path.split(Platform.pathSeparator).last,
                  ),
                ),
              ],
            ),
            if (_progress != null) ...[
              const SizedBox(height: EmiSpacing.md),
              LinearProgressIndicator(value: _progress),
            ],
            if (_uploading)
              const Padding(
                padding: EdgeInsets.only(top: EmiSpacing.sm),
                child: Text('Mengunggah data Kamus...'),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: EmiSpacing.sm),
                child: Text(_error!),
              ),
            const SizedBox(height: EmiSpacing.md),
            FilledButton.icon(
              onPressed: _uploading || _csv == null ? null : _preview,
              icon: const Icon(Icons.upload_file),
              label: const Text('Import Data'),
            ),
          ],
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: EmiSpacing.md),
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
        Text('${widget.item!.mekongga} - ${widget.item!.indonesia}'),
        if (_error != null) Text(_error!),
        Wrap(
          spacing: EmiSpacing.sm,
          children: [
            OutlinedButton(onPressed: _play, child: const Text('Putar')),
            OutlinedButton(onPressed: _player.pause, child: const Text('Jeda')),
            OutlinedButton(
              onPressed: _player.stop,
              child: const Text('Berhenti'),
            ),
          ],
        ),
      ],
      const SizedBox(height: EmiSpacing.sm),
    ],
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
    padding: const EdgeInsets.symmetric(
      horizontal: EmiSpacing.md,
      vertical: EmiSpacing.md,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PageIntro(
          title: 'Kamus',
          subtitle: 'Kelola kosakata Mekongga agar mudah dipelajari siswa.',
          icon: Icons.auto_stories_outlined,
        ),
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Cari kata atau arti',
          ),
          onChanged: onChanged,
        ),
        const SizedBox(height: EmiSpacing.md),
        Wrap(
          spacing: EmiSpacing.sm,
          runSpacing: EmiSpacing.sm,
          children: [
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Kosakata'),
            ),
            OutlinedButton.icon(
              onPressed: onFilter,
              icon: const Icon(Icons.tune),
              label: const Text('Filter'),
            ),
            OutlinedButton.icon(
              onPressed: onCategories,
              icon: const Icon(Icons.category_outlined),
              label: const Text('Kelola Kategori'),
            ),
            OutlinedButton.icon(
              onPressed: onImport,
              icon: const Icon(Icons.upload_file),
              label: const Text('Import Data'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _DictionaryTile extends StatelessWidget {
  const _DictionaryTile({required this.item, required this.onTap});
  final DictionaryEntryAdmin item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => EmiCard(
    child: InkWell(
      borderRadius: BorderRadius.circular(EmiRadii.card),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(EmiSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.mekongga,
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            const SizedBox(height: EmiSpacing.sm),
            _InfoLine(icon: Icons.translate, text: item.indonesia),
            if (item.english.isNotEmpty)
              _InfoLine(icon: Icons.language, text: item.english),
            const SizedBox(height: EmiSpacing.sm),
            Wrap(
              spacing: EmiSpacing.xs,
              runSpacing: EmiSpacing.xs,
              children: [
                _Chip(text: item.categoryName ?? 'Tanpa Kategori'),
                _Chip(
                  text: _statusLabel(item.status),
                  color: EmiColors.secondary,
                ),
                _Chip(
                  text: item.audioUrl?.isNotEmpty == true
                      ? 'Audio Tersedia'
                      : 'Belum Ada Audio',
                  icon: item.audioUrl?.isNotEmpty == true
                      ? Icons.volume_up_outlined
                      : Icons.volume_off_outlined,
                  color: item.audioUrl?.isNotEmpty == true
                      ? EmiColors.success
                      : EmiColors.surfaceSoft,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _AudioField extends StatefulWidget {
  const _AudioField({
    required this.initialAudioUrl,
    required this.audioFile,
    required this.removeAudio,
    required this.disabled,
    required this.onPick,
    required this.onRemove,
    required this.onRestore,
    required this.onClearSelected,
  });
  final String? initialAudioUrl;
  final File? audioFile;
  final bool removeAudio;
  final bool disabled;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  final VoidCallback onRestore;
  final VoidCallback onClearSelected;
  @override
  State<_AudioField> createState() => _AudioFieldState();
}

class _AudioFieldState extends State<_AudioField> {
  final _player = AudioPlayer();
  String? _error;

  @override
  void didUpdateWidget(covariant _AudioField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioFile?.path != widget.audioFile?.path ||
        oldWidget.initialAudioUrl != widget.initialAudioUrl ||
        oldWidget.removeAudio != widget.removeAudio) {
      _player.stop();
      _error = null;
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    if (widget.removeAudio) return;
    try {
      if (widget.audioFile != null) {
        await _player.setFilePath(widget.audioFile!.path);
      } else if (widget.initialAudioUrl?.isNotEmpty == true) {
        await _player.setUrl(widget.initialAudioUrl!);
      } else {
        return;
      }
      await _player.play();
    } catch (_) {
      if (mounted) setState(() => _error = 'Audio belum bisa diputar.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveAudio =
        !widget.removeAudio &&
        (widget.audioFile != null ||
            widget.initialAudioUrl?.isNotEmpty == true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasActiveAudio) ...[
          _InfoLine(
            icon: Icons.audio_file_outlined,
            text: widget.audioFile != null
                ? widget.audioFile!.path.split(Platform.pathSeparator).last
                : 'Audio tersedia',
          ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: EmiColors.error)),
          Wrap(
            spacing: EmiSpacing.sm,
            runSpacing: EmiSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: widget.disabled ? null : _play,
                icon: const Icon(Icons.play_arrow_outlined),
                label: const Text('Putar'),
              ),
              OutlinedButton.icon(
                onPressed: widget.disabled ? null : _player.pause,
                icon: const Icon(Icons.pause_outlined),
                label: const Text('Jeda'),
              ),
              OutlinedButton.icon(
                onPressed: widget.disabled ? null : _player.stop,
                icon: const Icon(Icons.stop_outlined),
                label: const Text('Berhenti'),
              ),
            ],
          ),
          const SizedBox(height: EmiSpacing.md),
        ] else if (widget.removeAudio) ...[
          const Text('Audio akan dihapus setelah disimpan.'),
          const SizedBox(height: EmiSpacing.sm),
        ] else ...[
          const Text(
            'Belum Ada Audio\nTambahkan audio agar pelafalan kosakata dapat didengarkan.',
          ),
          const SizedBox(height: EmiSpacing.sm),
        ],
        Wrap(
          spacing: EmiSpacing.sm,
          runSpacing: EmiSpacing.sm,
          children: [
            OutlinedButton.icon(
              onPressed: widget.disabled ? null : widget.onPick,
              icon: const Icon(Icons.file_upload_outlined),
              label: Text(
                widget.audioFile != null ||
                        widget.initialAudioUrl?.isNotEmpty == true
                    ? 'Ganti Audio'
                    : 'Pilih Audio',
              ),
            ),
            if (widget.audioFile != null)
              OutlinedButton.icon(
                onPressed: widget.disabled ? null : widget.onClearSelected,
                icon: const Icon(Icons.clear_outlined),
                label: const Text('Batal Pilih'),
              )
            else if (widget.initialAudioUrl?.isNotEmpty == true)
              if (widget.removeAudio)
                OutlinedButton.icon(
                  onPressed: widget.disabled ? null : widget.onRestore,
                  icon: const Icon(Icons.restore_outlined),
                  label: const Text('Batal Hapus'),
                )
              else
                OutlinedButton.icon(
                  onPressed: widget.disabled ? null : widget.onRemove,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Hapus Audio'),
                ),
          ],
        ),
      ],
    );
  }
}

class _AudioPlayerButtons extends StatefulWidget {
  const _AudioPlayerButtons({required this.url});
  final String url;
  @override
  State<_AudioPlayerButtons> createState() => _AudioPlayerButtonsState();
}

class _AudioPlayerButtonsState extends State<_AudioPlayerButtons> {
  final _player = AudioPlayer();
  String? _error;

  @override
  void didUpdateWidget(covariant _AudioPlayerButtons oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _player.stop();
      _error = null;
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    try {
      await _player.setUrl(widget.url);
      await _player.play();
    } catch (_) {
      if (mounted) setState(() => _error = 'Audio belum bisa diputar.');
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (_error != null)
        Text(_error!, style: const TextStyle(color: EmiColors.error)),
      Wrap(
        spacing: EmiSpacing.sm,
        runSpacing: EmiSpacing.sm,
        children: [
          OutlinedButton.icon(
            onPressed: _play,
            icon: const Icon(Icons.play_arrow_outlined),
            label: const Text('Putar'),
          ),
          OutlinedButton.icon(
            onPressed: _player.pause,
            icon: const Icon(Icons.pause_outlined),
            label: const Text('Jeda'),
          ),
          OutlinedButton.icon(
            onPressed: _player.stop,
            icon: const Icon(Icons.stop_outlined),
            label: const Text('Berhenti'),
          ),
        ],
      ),
    ],
  );
}

class _PageIntro extends StatelessWidget {
  const _PageIntro({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: EmiSpacing.lg),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 32),
        const SizedBox(width: EmiSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: EmiSpacing.xs),
              Text(subtitle),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: EmiSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: EmiColors.textPrimary.withValues(alpha: 0.7),
            ),
            const SizedBox(width: EmiSpacing.sm),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: EmiSpacing.sm),
        ...children,
      ],
    ),
  );
}

class _GapField extends StatelessWidget {
  const _GapField({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: EmiSpacing.md),
    child: child,
  );
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: EmiSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: EmiSpacing.xs),
        Expanded(child: Text(text.isEmpty ? '-' : text)),
      ],
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.text,
    this.icon,
    this.color = EmiColors.surfaceAccent,
  });
  final String text;
  final IconData? icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Chip(
    avatar: icon == null ? null : Icon(icon, size: 16),
    label: Text(text),
    backgroundColor: color,
    side: const BorderSide(color: EmiColors.border),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(EmiRadii.pill),
    ),
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

String _shortDate(String? value) {
  final date = DateTime.tryParse(value ?? '')?.toLocal();
  if (date == null) return '-';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

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
