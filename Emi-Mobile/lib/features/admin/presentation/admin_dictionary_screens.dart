import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../core/errors/app_error.dart';
import '../../../shared/widgets/emi_card.dart';
import '../data/admin_crud_providers.dart';
import 'admin_shell.dart';

class AdminDictionaryScreen extends ConsumerStatefulWidget {
  const AdminDictionaryScreen({super.key});
  @override
  ConsumerState<AdminDictionaryScreen> createState() =>
      _AdminDictionaryScreenState();
}

class _AdminDictionaryScreenState extends ConsumerState<AdminDictionaryScreen> {
  String? _search;
  var _page = 1;
  @override
  Widget build(BuildContext context) {
    final query = AdminSearchQuery(search: _search, page: _page);
    final data = ref.watch(adminDictionaryProvider(query));
    return AdminShell(
      title: 'Kamus',
      child: Column(
        children: [
          _SearchBar(
            onChanged: (v) => setState(() {
              _search = v;
              _page = 1;
            }),
            onAdd: () => context.go('/admin/dictionary/new'),
          ),
          Expanded(
            child: data.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _Error(
                message: e.toString(),
                onRetry: () => ref.invalidate(adminDictionaryProvider(query)),
              ),
              data: (page) => _PagedList(
                empty: 'Data kamus belum tersedia.',
                hasMore: page.hasMore,
                onMore: () => setState(() => _page++),
                children: [
                  for (final item in page.items)
                    _Tile(
                      title: item.indonesia,
                      subtitle: '${item.mekongga} • ${item.english}',
                      status: item.status,
                      onTap: () => context.go('/admin/dictionary/${item.id}'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
      title: _editing ? 'Edit Kamus' : 'Tambah Kamus',
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
                            labelText: 'Indonesia',
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
                            labelText: 'Mekongga',
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
                              child: Text('active'),
                            ),
                            DropdownMenuItem(
                              value: 'inactive',
                              child: Text('inactive'),
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
      if (mounted) context.go('/admin/dictionary');
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
    final ok = await _confirm(context, 'Hapus data kamus?');
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

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged, required this.onAdd});
  final ValueChanged<String> onChanged;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(EmiSpacing.md),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            decoration: const InputDecoration(hintText: 'Search'),
            onChanged: onChanged,
          ),
        ),
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
