import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../core/errors/app_error.dart';
import '../../../shared/widgets/status_badge.dart';
import '../data/admin_crud_providers.dart';
import '../data/admin_crud_repository.dart';
import 'admin_shell.dart';
import 'admin_style.dart';
import 'admin_widgets.dart';

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
  bool _submitted = false;
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
    return Semantics(
      key: const Key('adminScreen-dictionary-form'),
      child: AdminShell(
        title: _editing ? 'Edit Kosakata' : 'Tambah Kosakata',
        child: detail?.isLoading == true
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                autovalidateMode: _submitted
                    ? AutovalidateMode.always
                    : AutovalidateMode.disabled,
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
                            key: const Key('adminField-dictionary-mekongga'),
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
                            key: const Key('adminField-dictionary-indonesia'),
                            controller: _indonesia,
                            decoration: const InputDecoration(
                              labelText: 'Arti Bahasa Indonesia',
                            ),
                            validator: _required,
                          ),
                        ),
                        _GapField(
                          child: TextFormField(
                            key: const Key('adminField-dictionary-english'),
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
                            loading: () => Semantics(
                              key: const Key('adminLoading-dictionary-form'),
                              child: const LinearProgressIndicator(),
                            ),
                            error: (e, _) => Semantics(
                              key: const Key('adminError-dictionary-form'),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Kategori belum bisa dimuat.'),
                                  TextButton(
                                    key: const Key(
                                      'adminRetry-dictionary-form',
                                    ),
                                    onPressed: () => ref.invalidate(
                                      dictionaryCategoriesProvider,
                                    ),
                                    child: const Text('Coba lagi'),
                                  ),
                                ],
                              ),
                            ),
                            data: (page) => DropdownButtonFormField<String>(
                              key: const Key('adminField-dictionary-category'),
                              isExpanded: true,
                              initialValue:
                                  _categoryId?.isEmpty == true ||
                                      page.items.every(
                                        (c) => c.id != _categoryId,
                                      )
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
                                : (v) =>
                                      setState(() => _status = v ?? 'active'),
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
                    if (categories.hasValue) ...[
                      const SizedBox(height: EmiSpacing.md),
                      FilledButton.icon(
                        key: const Key('adminSave-dictionary'),
                        onPressed: _saving ? null : _save,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(_saving ? 'Menyimpan...' : 'Simpan'),
                      ),
                    ],
                    if (_editing)
                      TextButton.icon(
                        key: const Key('adminDelete-dictionary'),
                        onPressed: _saving ? null : _delete,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Hapus'),
                      ),
                  ],
                ),
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
    if (_saving) return;
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;
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
    if (_saving) return;
    final ok = await _confirm(
      context,
      'Hapus kosakata ini?\nTindakan ini tidak dapat dibatalkan.',
    );
    if (ok != true || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(adminCrudRepositoryProvider).deleteDictionary(widget.id!);
      ref.invalidate(adminDictionaryProvider);
      if (mounted) context.go('/admin/dictionary');
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = AppError(
            type: AppErrorType.unknown,
            message: 'Kosakata belum dapat dihapus. Silakan coba lagi.',
          ),
        );
      }
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

class AdminDictionaryDetailScreen extends ConsumerStatefulWidget {
  const AdminDictionaryDetailScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<AdminDictionaryDetailScreen> createState() =>
      _AdminDictionaryDetailScreenState();
}

class _AdminDictionaryDetailScreenState
    extends ConsumerState<AdminDictionaryDetailScreen> {
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    final id = widget.id;
    final detail = ref.watch(adminDictionaryDetailProvider(id));
    return AdminShell(
      title: 'Detail Kosakata',
      fallbackRoute: '/admin/dictionary',
      child: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Error(
          message: _friendlyError(e),
          onRetry: () => ref.invalidate(adminDictionaryDetailProvider(id)),
        ),
        data: (item) => ListView(
          key: const Key('adminScreen-dictionary-detail'),
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
                    EmiStatusBadge(
                      label: _statusLabel(item.status),
                      tone: emiStatusToneFromKey(item.status),
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
              key: const Key('adminEdit-dictionary'),
              onPressed: () async {
                await context.push('/admin/dictionary/$id/edit');
                ref.invalidate(adminDictionaryDetailProvider(id));
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Entri'),
            ),
            TextButton.icon(
              key: const Key('adminDelete-dictionary'),
              onPressed: _deleting ? null : () => _delete(id),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Hapus'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(String id) async {
    if (_deleting) return;
    final ok = await _confirm(
      context,
      'Hapus kosakata ini dari Kamus?\nKosakata tidak akan tampil pada daftar aktif, tetapi datanya tetap disimpan oleh sistem.',
    );
    if (ok != true || _deleting) return;
    setState(() => _deleting = true);
    try {
      await ref.read(adminCrudRepositoryProvider).deleteDictionary(id);
      ref.invalidate(adminDictionaryProvider);
      if (mounted) context.go('/admin/dictionary');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kosakata belum dapat dihapus. Silakan coba lagi.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
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
            initialValue: widget.categories.any((c) => c.id == _categoryId)
                ? _categoryId
                : null,
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
      fallbackRoute: '/admin/dictionary',
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
            for (final category in page.items) ...[
              AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (category.description?.isNotEmpty == true) ...[
                      const SizedBox(height: EmiSpacing.xs),
                      Text(
                        category.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AdminStyle.inkMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: EmiSpacing.sm),
                    Wrap(
                      spacing: EmiSpacing.xs,
                      runSpacing: EmiSpacing.xs,
                      children: [
                        _Chip(text: '${category.entriesCount} kosakata'),
                        EmiStatusBadge(
                          label: _statusLabel(category.status),
                          tone: emiStatusToneFromKey(category.status),
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
              const SizedBox(height: EmiSpacing.sm),
            ],
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
  File? _file;
  File? _zip;
  var _page = 1;
  var _errorPage = 1;
  var _busy = false;
  var _polling = false;
  String? _historyStatus;
  String? _historyStrategy;
  String? _historyDateFrom;
  String? _historyDateTo;
  final _historyUploader = TextEditingController();
  DictionaryImportJobAdmin? _job;
  AdminCrudPage<DictionaryImportJobAdmin>? _history;
  AdminCrudPage<DictionaryImportErrorAdmin>? _errors;
  String? _actionError;
  String? _historyError;
  String? _pollError;
  String? _errorListError;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _historyUploader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AdminShell(
    title: 'Import Data',
    fallbackRoute: '/admin/dictionary',
    child: ListView(
      padding: const EdgeInsets.all(EmiSpacing.md),
      children: [
        const _PageIntro(
          title: 'Import Kamus',
          subtitle:
              'Buat pratinjau Excel, periksa hasil, lalu konfirmasi import.',
          icon: Icons.upload_file,
        ),
        _SectionCard(
          title: 'File Import',
          icon: Icons.folder_open_outlined,
          children: [
            const Text(
              'Excel gabungan memuat Kosakata dan Contoh Kalimat. CSV lama tetap didukung.',
            ),
            const SizedBox(height: EmiSpacing.sm),
            OutlinedButton.icon(
              key: const Key('dictionaryImport-template'),
              onPressed: _busy ? null : _shareTemplate,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Download Template Excel'),
            ),
            const SizedBox(height: EmiSpacing.sm),
            Wrap(
              spacing: EmiSpacing.sm,
              runSpacing: EmiSpacing.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: _busy ? null : _pickFile,
                  icon: const Icon(Icons.description_outlined),
                  label: Text(
                    _file == null ? 'Pilih XLSX atau CSV' : _name(_file!),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _pickZip,
                  icon: const Icon(Icons.volume_up_outlined),
                  label: Text(_zip == null ? 'Pilih ZIP Audio' : _name(_zip!)),
                ),
              ],
            ),
            if (_actionError != null)
              Text(
                _actionError!,
                style: const TextStyle(color: EmiColors.error),
              ),
            const SizedBox(height: EmiSpacing.sm),
            FilledButton.icon(
              key: const Key('dictionaryImport-preview'),
              onPressed: _busy || _file == null ? null : _preview,
              icon: const Icon(Icons.preview_outlined),
              label: Text(_busy ? 'Memproses...' : 'Lihat Preview'),
            ),
          ],
        ),
        if (_job != null)
          _ImportResult(
            job: _job!,
            errors: _errors?.items ?? const [],
            errorPage: _errors,
            loadingError: _errorListError ?? _pollError,
            busy: _busy,
            onConfirm: _job!.status == 'preview_ready' && _job!.validRows > 0
                ? _confirm
                : null,
            onDeleteError: _deleteError,
            onPreviousErrors: _errorPage > 1
                ? () => _changeErrorPage(_errorPage - 1)
                : null,
            onNextErrors: _errorPage < (_errors?.lastPage ?? 1)
                ? () => _changeErrorPage(_errorPage + 1)
                : null,
            onClearErrors: _errors?.items.isNotEmpty == true
                ? _clearErrors
                : null,
          ),
        _SectionCard(
          title: 'Riwayat Import',
          icon: Icons.history,
          children: [
            ExpansionTile(
              key: const Key('dictionaryImport-history-filters'),
              title: const Text('Filter'),
              children: [
                DropdownButtonFormField<String?>(
                  initialValue: _historyStatus,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Semua')),
                    for (final value in const [
                      'previewing',
                      'preview_ready',
                      'queued',
                      'processing',
                      'completed',
                      'completed_with_errors',
                      'failed',
                    ])
                      DropdownMenuItem(value: value, child: Text(value)),
                  ],
                  onChanged: (value) => setState(() => _historyStatus = value),
                ),
                DropdownButtonFormField<String?>(
                  initialValue: _historyStrategy,
                  decoration: const InputDecoration(
                    labelText: 'Strategi duplikat',
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Semua')),
                    DropdownMenuItem(value: 'skip', child: Text('skip')),
                    DropdownMenuItem(value: 'update', child: Text('update')),
                    DropdownMenuItem(value: 'reject', child: Text('reject')),
                  ],
                  onChanged: (value) =>
                      setState(() => _historyStrategy = value),
                ),
                TextField(
                  controller: _historyUploader,
                  decoration: const InputDecoration(labelText: 'ID pengunggah'),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _DateFilterField(
                        label: 'Dari tanggal',
                        value: _historyDateFrom,
                        onChanged: (value) =>
                            setState(() => _historyDateFrom = value),
                      ),
                    ),
                    const SizedBox(width: EmiSpacing.sm),
                    Expanded(
                      child: _DateFilterField(
                        label: 'Sampai tanggal',
                        value: _historyDateTo,
                        onChanged: (value) =>
                            setState(() => _historyDateTo = value),
                      ),
                    ),
                  ],
                ),
                FilledButton(
                  onPressed: () {
                    _page = 1;
                    _loadHistory();
                  },
                  child: const Text('Terapkan Filter'),
                ),
              ],
            ),
            if (_history == null && _historyError == null)
              const LinearProgressIndicator(),
            if (_historyError != null)
              Text(
                _historyError!,
                style: const TextStyle(color: EmiColors.error),
              ),
            for (final item
                in _history?.items ?? const <DictionaryImportJobAdmin>[])
              ListTile(
                title: Text(item.originalName ?? 'Import Kamus'),
                subtitle: Text(
                  '${item.status} · ${item.validRows}/${item.invalidRows} valid/tidak valid',
                ),
                onTap: () => _select(item),
                trailing: IconButton(
                  onPressed:
                      item.status == 'queued' || item.status == 'processing'
                      ? null
                      : () => _deleteJob(item.id),
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            if ((_history?.lastPage ?? 1) > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _page > 1 ? () => _changePage(_page - 1) : null,
                    child: const Text('Sebelumnya'),
                  ),
                  Text('$_page / ${_history?.lastPage ?? 1}'),
                  TextButton(
                    onPressed: _page < (_history?.lastPage ?? 1)
                        ? () => _changePage(_page + 1)
                        : null,
                    child: const Text('Berikutnya'),
                  ),
                ],
              ),
          ],
        ),
      ],
    ),
  );

  String _name(File file) => file.path.split(Platform.pathSeparator).last;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'csv'],
    );
    final path = result?.files.single.path;
    if (path != null) setState(() => _file = File(path));
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
    final file = _file;
    if (file == null) return;
    await _run(() async {
      final xlsx = file.path.toLowerCase().endsWith('.xlsx');
      _job = await ref
          .read(adminCrudRepositoryProvider)
          .previewDictionaryImport(
            csvFile: file,
            audioZip: _zip,
            importType: xlsx ? 'combined' : 'vocabulary',
          );
      await _refreshErrors();
      await _loadHistory();
    });
  }

  Future<void> _confirm() async {
    final job = _job;
    if (job == null ||
        await _confirmDialog('Import data valid dari preview ini?') != true) {
      return;
    }
    await _run(() async {
      _job = await ref
          .read(adminCrudRepositoryProvider)
          .confirmDictionaryImport(job.id);
      if (_job!.isTerminal) {
        await _refreshErrors();
        ref.invalidate(adminDictionaryProvider);
      } else {
        _startPolling();
      }
      await _loadHistory();
    });
  }

  void _startPolling() {
    _poll?.cancel();
    final id = _job?.id;
    if (id == null) return;
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _pollJob(id));
  }

  Future<void> _pollJob(String id) async {
    if (_polling || !mounted || _job?.id != id) return;
    _polling = true;
    try {
      final latest = await ref
          .read(adminCrudRepositoryProvider)
          .dictionaryImportDetail(id);
      if (!mounted || _job?.id != id) return;
      setState(() {
        _job = latest;
        _pollError = null;
      });
      if (latest.isTerminal) {
        _poll?.cancel();
        await _refreshErrors(id: id);
        await _loadHistory();
        ref.invalidate(adminDictionaryProvider);
      }
    } catch (e) {
      if (mounted && _job?.id == id) {
        setState(() => _pollError = _importError(e));
      }
    } finally {
      _polling = false;
    }
  }

  Future<void> _loadHistory() async {
    try {
      final history = await ref
          .read(adminCrudRepositoryProvider)
          .dictionaryImports(
            page: _page,
            status: _historyStatus,
            duplicateStrategy: _historyStrategy,
            uploadedBy: _historyUploader.text,
            dateFrom: _historyDateFrom,
            dateTo: _historyDateTo,
          );
      if (mounted) {
        setState(() {
          _history = history;
          _historyError = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _historyError = _importError(e));
    }
  }

  Future<void> _select(DictionaryImportJobAdmin job) async {
    _poll?.cancel();
    setState(() {
      _job = job;
      _errors = null;
      _errorPage = 1;
      _pollError = null;
    });
    await _refreshErrors(id: job.id);
    if (!job.isTerminal && job.status != 'preview_ready') _startPolling();
  }

  Future<void> _refreshErrors({String? id}) async {
    final jobId = id ?? _job?.id;
    if (jobId == null) return;
    try {
      final errors = await ref
          .read(adminCrudRepositoryProvider)
          .dictionaryImportErrors(jobId, page: _errorPage);
      if (mounted && _job?.id == jobId) {
        setState(() {
          _errors = errors;
          _errorListError = null;
        });
      }
    } catch (e) {
      if (mounted && _job?.id == jobId) {
        setState(() => _errorListError = _importError(e));
      }
    }
  }

  Future<void> _deleteJob(String id) async {
    if (await _confirmDialog(
          'Hapus riwayat import ini? Data kamus tetap tersimpan.',
        ) !=
        true) {
      return;
    }
    await _run(() async {
      await ref.read(adminCrudRepositoryProvider).deleteDictionaryImport(id);
      if (_job?.id == id) {
        _job = null;
        _errors = null;
      }
      await _loadHistory();
      if (_history?.items.isEmpty == true && _page > 1) {
        _page--;
        await _loadHistory();
      }
    });
  }

  Future<void> _deleteError(String errorId) async {
    if (await _confirmDialog('Hapus error import ini?') != true) return;
    try {
      await ref
          .read(adminCrudRepositoryProvider)
          .deleteDictionaryImportError(_job!.id, errorId);
      await _refreshErrors();
      if (_errors?.items.isEmpty == true && _errorPage > 1) {
        _errorPage--;
        await _refreshErrors();
      }
    } catch (e) {
      if (mounted) setState(() => _errorListError = _importError(e));
    }
  }

  Future<void> _clearErrors() async {
    if (await _confirmDialog('Hapus semua error import ini?') != true) return;
    try {
      await ref
          .read(adminCrudRepositoryProvider)
          .clearDictionaryImportErrors(_job!.id);
      _errorPage = 1;
      await _refreshErrors();
    } catch (e) {
      if (mounted) setState(() => _errorListError = _importError(e));
    }
  }

  Future<void> _shareTemplate() async {
    await _run(() async {
      final bytes = await ref
          .read(adminCrudRepositoryProvider)
          .dictionaryImportTemplate();
      final file = File(
        '${(await getTemporaryDirectory()).path}/template-import-kamus-emi.xlsx',
      );
      await file.writeAsBytes(bytes, flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'Template Import Kamus EMI',
        ),
      );
    });
  }

  void _changePage(int page) {
    setState(() => _page = page);
    _loadHistory();
  }

  void _changeErrorPage(int page) {
    setState(() => _errorPage = page);
    _refreshErrors();
  }

  Future<bool?> _confirmDialog(String text) => showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(text),
      actions: [
        TextButton(
          onPressed: () => context.pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const Key('dictionaryImport-confirm-dialog'),
          onPressed: () => context.pop(true),
          child: const Text('Lanjutkan'),
        ),
      ],
    ),
  );

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _actionError = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _actionError = _importError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _DateFilterField extends StatelessWidget {
  const _DateFilterField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: Text(value ?? 'Semua'),
    trailing: value == null
        ? const Icon(Icons.calendar_today_outlined)
        : IconButton(
            onPressed: () => onChanged(null),
            icon: const Icon(Icons.clear),
          ),
    onTap: () async {
      final selected = await showDatePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDate: DateTime.tryParse(value ?? '') ?? DateTime.now(),
      );
      if (selected != null) {
        onChanged(selected.toIso8601String().split('T').first);
      }
    },
  );
}

class _ImportResult extends StatelessWidget {
  const _ImportResult({
    required this.job,
    required this.errors,
    required this.errorPage,
    required this.loadingError,
    required this.busy,
    this.onConfirm,
    required this.onDeleteError,
    this.onPreviousErrors,
    this.onNextErrors,
    this.onClearErrors,
  });
  final DictionaryImportJobAdmin job;
  final List<DictionaryImportErrorAdmin> errors;
  final AdminCrudPage<DictionaryImportErrorAdmin>? errorPage;
  final String? loadingError;
  final bool busy;
  final VoidCallback? onConfirm;
  final ValueChanged<String> onDeleteError;
  final VoidCallback? onPreviousErrors;
  final VoidCallback? onNextErrors;
  final VoidCallback? onClearErrors;
  @override
  Widget build(BuildContext context) => AdminCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ringkasan Preview',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text('Status: ${job.status}'),
        if (!job.isTerminal && job.status != 'preview_ready')
          const LinearProgressIndicator(),
        Text(
          'Total: ${job.totalRows} · Valid: ${job.validRows} · Tidak valid: ${job.invalidRows}',
        ),
        if (job.warningCount > 0) Text('Peringatan: ${job.warningCount}'),
        Text(
          'Kosakata baru: ${job.vocabInserted} · Kosakata diperbarui: ${job.vocabUpdated}',
        ),
        Text(
          'Contoh kalimat baru: ${job.sentenceInserted} · Contoh kalimat diperbarui: ${job.sentenceUpdated}',
        ),
        for (final sheet in job.sheets.entries)
          Text('${sheet.key}: ${_sheetSummaryText(sheet.value)}'),
        if (job.audioAttached != null)
          Text('Audio terpasang: ${job.audioAttached}'),
        if (job.audioNotFound != null)
          Text('Audio tidak ditemukan: ${job.audioNotFound}'),
        if (job.audioAmbiguous != null)
          Text('Audio ambigu: ${job.audioAmbiguous}'),
        if (job.audioUnused != null)
          Text('Audio tidak terpakai: ${job.audioUnused}'),
        Text(
          'Ditambahkan: ${job.insertedRows} · Diperbarui: ${job.updatedRows} · Dilewati: ${job.skippedRows}',
        ),
        if (job.failureMessage != null)
          Text(
            job.failureMessage!,
            style: const TextStyle(color: EmiColors.error),
          ),
        FilledButton(
          key: const Key('dictionaryImport-confirm'),
          onPressed: busy ? null : onConfirm,
          child: const Text('Import'),
        ),
        if (loadingError != null)
          Text(loadingError!, style: const TextStyle(color: EmiColors.error)),
        if (errors.isNotEmpty) ...[
          const Text('Ringkasan error halaman ini'),
          for (final breakdown in _errorBreakdown(errors).entries)
            Text('${breakdown.key}: ${breakdown.value}'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Error Import'),
              TextButton(
                onPressed: onClearErrors,
                child: const Text('Hapus Semua Error'),
              ),
            ],
          ),
          for (final error in errors)
            ListTile(
              title: Text(
                '${error.sheet == null ? '' : '${error.sheet} · '}Baris ${error.rowNumber ?? '-'}: ${_importErrorText(error)}',
              ),
              subtitle: Text(
                [
                  if (error.createdAt != null) error.createdAt!,
                  if (error.rawData?.isNotEmpty == true)
                    error.rawData.toString(),
                ].join(' · '),
              ),
              trailing: IconButton(
                onPressed: () => onDeleteError(error.id),
                icon: const Icon(Icons.delete_outline),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: onPreviousErrors,
                child: const Text('Sebelumnya'),
              ),
              Text(
                '${errorPage?.currentPage ?? 1} / ${errorPage?.lastPage ?? 1} · ${errorPage?.total ?? errors.length}',
              ),
              TextButton(
                onPressed: onNextErrors,
                child: const Text('Berikutnya'),
              ),
            ],
          ),
        ],
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
          key: const Key('adminSearch-dictionary'),
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
              key: const Key('adminAdd-dictionary'),
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
  Widget build(BuildContext context) => AdminCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                item.mekongga,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right, color: AdminStyle.inkMuted),
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
            EmiStatusBadge(
              label: _statusLabel(item.status),
              tone: emiStatusToneFromKey(item.status),
            ),
            _Chip(
              text: item.audioUrl?.isNotEmpty == true
                  ? 'Audio Tersedia'
                  : 'Belum Ada Audio',
              icon: item.audioUrl?.isNotEmpty == true
                  ? Icons.volume_up_outlined
                  : Icons.volume_off_outlined,
              color: item.audioUrl?.isNotEmpty == true
                  ? AdminStyle.statusFill('published')
                  : AdminStyle.tint,
            ),
          ],
        ),
      ],
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
    padding: const EdgeInsets.only(bottom: EmiSpacing.md),
    child: AdminPageHeader(icon: icon, title: title, subtitle: subtitle),
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
    padding: const EdgeInsets.only(bottom: EmiSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSectionHeader(title, icon: icon, leading: false),
        AdminCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
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
  const _Chip({required this.text, this.icon, this.color});
  final String text;
  final IconData? icon;
  final Color? color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: EmiSpacing.sm, vertical: 5),
    decoration: BoxDecoration(
      color: color ?? AdminStyle.tint,
      borderRadius: BorderRadius.circular(EmiRadii.pill),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: AdminStyle.inkMuted),
          const SizedBox(width: 4),
        ],
        Text(
          text,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AdminStyle.ink,
          ),
        ),
      ],
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
      AdminCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: EmiSpacing.sm),
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: EmiSpacing.md),
    child: AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(error.message, style: const TextStyle(color: EmiColors.error)),
          for (final entry in error.fieldErrors.entries)
            Text('${entry.key}: ${entry.value.join(', ')}'),
        ],
      ),
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

String _sheetSummaryText(DictionaryImportSheetSummary sheet) => [
  if (sheet.total != null) 'Total ${sheet.total}',
  if (sheet.valid != null) 'Valid ${sheet.valid}',
  if (sheet.invalid != null) 'Tidak valid ${sheet.invalid}',
  if (sheet.duplicate != null) 'Duplikat ${sheet.duplicate}',
  if (sheet.skipped != null) 'Dilewati ${sheet.skipped}',
].join(' · ');

Map<String, int> _errorBreakdown(List<DictionaryImportErrorAdmin> errors) {
  final result = <String, int>{};
  for (final error in errors) {
    final key = [
      if (error.code?.isNotEmpty == true) error.code!,
      _importErrorText(error),
    ].join(' · ');
    result[key] = (result[key] ?? 0) + 1;
  }
  return result;
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
      FilledButton(
        key: const Key('adminConfirmDelete-dictionary'),
        onPressed: () => context.pop(true),
        child: const Text('Ya'),
      ),
    ],
  ),
);
