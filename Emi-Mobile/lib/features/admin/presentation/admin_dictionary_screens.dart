import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
                          item.indonesia,
                          if (item.categoryName?.isNotEmpty == true)
                            item.categoryName!,
                          if (item.audioUrl?.isNotEmpty == true) 'Ada Audio',
                        ].join(' • '),
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
                  Text(item.categoryName ?? 'Kategori tidak tersedia'),
                  Text(_statusLabel(item.status)),
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
              child: Text(
                item.audioUrl?.isNotEmpty == true
                    ? 'Audio Pelafalan tersedia'
                    : 'Belum Ada Audio',
              ),
            ),
            const SizedBox(height: EmiSpacing.md),
            FilledButton(
              onPressed: () async {
                await context.push('/admin/dictionary/$id/edit');
                ref.invalidate(adminDictionaryDetailProvider(id));
              },
              child: const Text('Edit Kosakata'),
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

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.onChanged,
    required this.onFilter,
    required this.onAdd,
  });
  final ValueChanged<String> onChanged;
  final VoidCallback onFilter;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(EmiSpacing.md),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            decoration: const InputDecoration(hintText: 'Cari kata atau arti'),
            onChanged: onChanged,
          ),
        ),
        IconButton(onPressed: onFilter, icon: const Icon(Icons.filter_list)),
        IconButton.filled(onPressed: onAdd, icon: const Icon(Icons.add)),
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
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: Text(status ?? ''),
      onTap: onTap,
    ),
  );
}

class _PagedList extends StatelessWidget {
  const _PagedList({
    required this.children,
    required this.empty,
    required this.hasMore,
    required this.onMore,
  });
  final List<Widget> children;
  final String empty;
  final bool hasMore;
  final VoidCallback onMore;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(EmiSpacing.md),
    children: children.isEmpty
        ? [EmiCard(child: Text(empty))]
        : [
            ...children,
            if (hasMore)
              OutlinedButton(onPressed: onMore, child: const Text('Muat lagi')),
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

String _statusLabel(String? status) => switch (status) {
  'active' => 'Aktif',
  'inactive' => 'Tidak Aktif',
  _ => 'Status tidak tersedia',
};

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
