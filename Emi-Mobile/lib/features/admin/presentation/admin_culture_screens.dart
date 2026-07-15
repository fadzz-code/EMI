import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/role_dashboard_widgets.dart';
import '../data/admin_culture_providers.dart';
import '../data/admin_culture_repository.dart';
import 'admin_shell.dart';

typedef AdminCultureFilePicker =
    Future<PlatformFile?> Function(String contentType);

final adminCultureFilePickerProvider = Provider<AdminCultureFilePicker>(
  (_) => (type) async {
    final result = await FilePicker.platform.pickFiles(
      type: type == 'image'
          ? FileType.image
          : type == 'audio'
          ? FileType.audio
          : FileType.custom,
      allowedExtensions: type == 'pdf' ? const ['pdf'] : null,
      withData: false,
    );
    return result?.files.single;
  },
);

class AdminCultureScreen extends ConsumerStatefulWidget {
  const AdminCultureScreen({super.key});
  @override
  ConsumerState<AdminCultureScreen> createState() => _AdminCultureScreenState();
}

class _AdminCultureScreenState extends ConsumerState<AdminCultureScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(adminCultureItemsProvider);
    final query = ref.read(adminCultureItemsProvider.notifier).query;
    return AdminShell(
      title: 'Budaya Mekongga',
      child: RefreshIndicator(
        onRefresh: ref.read(adminCultureItemsProvider.notifier).refresh,
        child: ListView(
          padding: const EdgeInsets.all(EmiSpacing.md),
          children: [
            const Text('Kelola konten Budaya Mekongga.'),
            const SizedBox(height: EmiSpacing.md),
            FilledButton.icon(
              onPressed: () => context.push('/admin/culture/create'),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Konten'),
            ),
            const SizedBox(height: EmiSpacing.md),
            TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Cari judul konten',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Filter',
                  onPressed: () => _filter(query),
                  icon: Badge(
                    isLabelVisible:
                        query.status != null || query.contentType != null,
                    child: const Icon(Icons.tune),
                  ),
                ),
              ),
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 400), () {
                  ref.read(adminCultureItemsProvider.notifier).search(value);
                });
              },
            ),
            const SizedBox(height: EmiSpacing.md),
            data.when(
              skipError: true,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => FriendlyState(
                icon: Icons.wifi_off_outlined,
                title: 'Konten Belum Bisa Dimuat',
                message: 'Periksa koneksi internet, lalu coba lagi.',
                onRetry: () => ref.invalidate(adminCultureItemsProvider),
              ),
              data: (page) => page.items.isEmpty
                  ? const FriendlyState(
                      icon: Icons.public_off_outlined,
                      title: 'Konten Tidak Ditemukan',
                      message: 'Tambah konten atau ubah pencarian dan filter.',
                    )
                  : Column(
                      children: [
                        for (final item in page.items) ...[
                          _CultureTile(item: item),
                          const SizedBox(height: EmiSpacing.sm),
                        ],
                        if (data.hasError)
                          const Text(
                            'Konten lama tetap ditampilkan. Muat lagi belum berhasil.',
                          ),
                        if (page.hasMore)
                          FilledButton(
                            onPressed: ref
                                .read(adminCultureItemsProvider.notifier)
                                .loadMore,
                            child: const Text('Muat Lagi'),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _filter(AdminCultureQuery query) async {
    var status = query.status;
    var type = query.contentType;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(EmiSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String?>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Semua status')),
                    DropdownMenuItem(value: 'draft', child: Text('Draft')),
                    DropdownMenuItem(value: 'published', child: Text('Terbit')),
                    DropdownMenuItem(value: 'archived', child: Text('Arsip')),
                  ],
                  onChanged: (value) => setState(() => status = value),
                ),
                const SizedBox(height: EmiSpacing.md),
                DropdownButtonFormField<String?>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Semua kategori'),
                    ),
                    ..._types.map(
                      (e) =>
                          DropdownMenuItem(value: e, child: Text(_category(e))),
                    ),
                  ],
                  onChanged: (value) => setState(() => type = value),
                ),
                const SizedBox(height: EmiSpacing.md),
                FilledButton(
                  onPressed: () {
                    ref
                        .read(adminCultureItemsProvider.notifier)
                        .filter(status: status, contentType: type);
                    Navigator.pop(context);
                  },
                  child: const Text('Terapkan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CultureTile extends StatelessWidget {
  const _CultureTile({required this.item});
  final AdminCultureItem item;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.push('/admin/culture/${item.id}'),
    child: Container(
      padding: const EdgeInsets.all(EmiSpacing.md),
      decoration: BoxDecoration(
        color: EmiColors.surface,
        border: Border.all(color: EmiColors.border),
        borderRadius: BorderRadius.circular(EmiRadii.card),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: item.contentType == 'image' && item.mediaUrl != null
                ? Image.network(
                    item.mediaUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.image_not_supported_outlined),
                  )
                : Icon(_contentIcon(item.contentType)),
          ),
          const SizedBox(width: EmiSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${_category(item.contentType)} · ${_status(item.status)}',
                ),
                Text(
                  'Diubah ${_date(item.updatedAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _action(context, item, value),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'view', child: Text('Lihat')),
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              if (item.status != 'published')
                const PopupMenuItem(value: 'publish', child: Text('Terbitkan')),
              if (item.status != 'archived')
                const PopupMenuItem(value: 'archive', child: Text('Arsipkan')),
              const PopupMenuItem(value: 'delete', child: Text('Hapus')),
            ],
          ),
        ],
      ),
    ),
  );
}

class AdminCultureDetailScreen extends ConsumerWidget {
  const AdminCultureDetailScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => AdminShell(
    title: 'Detail Budaya Mekongga',
    fallbackRoute: '/admin/culture',
    child: ref
        .watch(adminCultureDetailProvider(id))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const FriendlyState(
            icon: Icons.error_outline,
            title: 'Konten Belum Bisa Dimuat',
            message: 'Silakan coba lagi.',
          ),
          data: (item) => ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              Text(
                item.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: EmiSpacing.lg),
              Text(
                'Informasi Konten',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              _Field(
                label: 'Deskripsi',
                value: item.description.isEmpty ? '-' : item.description,
              ),
              _Field(label: 'Kategori', value: _category(item.contentType)),
              _Field(label: 'Urutan tampil', value: '${item.displayOrder}'),
              _Field(label: 'Status', value: _status(item.status)),
              const SizedBox(height: EmiSpacing.lg),
              Text(
                'Media atau Tautan',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (item.contentType == 'image' && item.mediaUrl != null)
                Image.network(
                  item.mediaUrl!,
                  errorBuilder: (_, _, _) =>
                      const Text('Pratinjau gambar tidak tersedia.'),
                ),
              if (item.mediaName != null)
                Text('${item.mediaName} · ${_size(item.mediaSize)}'),
              if (item.externalUrl != null)
                const Text('Tautan eksternal tersedia.'),
              const SizedBox(height: EmiSpacing.lg),
              FilledButton(
                onPressed: () => context.push('/admin/culture/${item.id}/edit'),
                child: const Text('Edit Konten'),
              ),
              Wrap(
                spacing: EmiSpacing.sm,
                children: [
                  if (item.status != 'published')
                    OutlinedButton(
                      onPressed: () => _action(context, item, 'publish'),
                      child: const Text('Terbitkan'),
                    ),
                  if (item.status != 'archived')
                    OutlinedButton(
                      onPressed: () => _action(context, item, 'archive'),
                      child: const Text('Arsipkan'),
                    ),
                  TextButton(
                    onPressed: () => _action(context, item, 'delete'),
                    child: const Text('Hapus'),
                  ),
                ],
              ),
            ],
          ),
        ),
  );
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: EmiSpacing.sm),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        Text(value),
      ],
    ),
  );
}

class AdminCultureFormScreen extends ConsumerStatefulWidget {
  const AdminCultureFormScreen({super.key, this.id});
  final String? id;
  @override
  ConsumerState<AdminCultureFormScreen> createState() =>
      _AdminCultureFormScreenState();
}

class _AdminCultureFormScreenState
    extends ConsumerState<AdminCultureFormScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _url = TextEditingController();
  final _order = TextEditingController(text: '1');
  String _type = 'image';
  String _statusValue = 'draft';
  String? _oldMediaId;
  String? _filePath;
  String? _fileName;
  int? _fileSize;
  bool _hydrated = false;
  bool _saving = false;
  bool _dirty = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _url.dispose();
    _order.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.id == null
        ? null
        : ref.watch(adminCultureDetailProvider(widget.id!));
    return PopScope(
      canPop: !_dirty || _saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_saving) _confirmLeave();
      },
      child: AdminShell(
        title: widget.id == null
            ? 'Tambah Budaya Mekongga'
            : 'Edit Budaya Mekongga',
        fallbackRoute: widget.id == null
            ? '/admin/culture'
            : '/admin/culture/${widget.id}',
        onBack: _cancel,
        child: detail == null
            ? _content(null)
            : detail.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const FriendlyState(
                  icon: Icons.error_outline,
                  title: 'Konten Belum Bisa Dimuat',
                  message: 'Silakan coba lagi.',
                ),
                data: _content,
              ),
      ),
    );
  }

  Widget _content(AdminCultureItem? item) {
    if (item != null && !_hydrated) {
      _title.text = item.title;
      _description.text = item.description;
      _url.text = item.externalUrl ?? '';
      _order.text = '${item.displayOrder}';
      _type = item.contentType;
      _statusValue = item.status == 'archived' ? 'draft' : item.status;
      _oldMediaId = item.mediaId;
      _fileName = item.mediaName;
      _fileSize = item.mediaSize;
      _hydrated = true;
    }
    final fileType = const {'image', 'audio', 'pdf'}.contains(_type);
    return Form(
      key: _form,
      onChanged: () {
        if (!_dirty) setState(() => _dirty = true);
      },
      child: ListView(
        padding: const EdgeInsets.all(EmiSpacing.md),
        children: [
          Text(
            'Informasi Konten',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: EmiSpacing.sm),
          TextFormField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Judul'),
            validator: _required,
          ),
          const SizedBox(height: EmiSpacing.md),
          TextFormField(
            controller: _description,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(labelText: 'Deskripsi'),
          ),
          const SizedBox(height: EmiSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Kategori'),
            items: _types
                .map(
                  (e) => DropdownMenuItem(value: e, child: Text(_category(e))),
                )
                .toList(),
            onChanged: (value) => setState(() {
              _type = value ?? 'image';
              _dirty = true;
            }),
          ),
          const SizedBox(height: EmiSpacing.md),
          TextFormField(
            controller: _order,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Urutan tampil'),
            validator: (value) => (int.tryParse(value ?? '') ?? 0) < 1
                ? 'Masukkan angka minimal 1.'
                : null,
          ),
          const SizedBox(height: EmiSpacing.lg),
          Text(
            'Media atau Tautan',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: EmiSpacing.sm),
          if (fileType) ...[
            if (_filePath != null && _type == 'image')
              Image.file(
                File(_filePath!),
                height: 160,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    const Text('Pratinjau gambar tidak tersedia.'),
              ),
            if (_fileName != null) Text('$_fileName · ${_size(_fileSize)}'),
            if (_oldMediaId != null && _filePath == null)
              const Text('Media lama dipertahankan jika tidak diganti.'),
            FilledButton.icon(
              onPressed: _saving ? null : _pick,
              icon: const Icon(Icons.upload_file),
              label: Text(_oldMediaId == null ? 'Pilih Media' : 'Ganti Media'),
            ),
          ] else
            TextFormField(
              controller: _url,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'URL eksternal'),
              validator: (value) =>
                  Uri.tryParse(value ?? '')?.hasAbsolutePath == true &&
                      Uri.tryParse(value ?? '')?.hasScheme == true
                  ? null
                  : 'Masukkan URL lengkap.',
            ),
          const SizedBox(height: EmiSpacing.lg),
          Text('Publikasi', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: EmiSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: _statusValue,
            decoration: const InputDecoration(
              labelText: 'Status',
              helperText:
                  'Draft belum terlihat publik. Terbit langsung tersedia bagi pengguna.',
            ),
            items: const [
              DropdownMenuItem(value: 'draft', child: Text('Draft')),
              DropdownMenuItem(value: 'published', child: Text('Terbit')),
            ],
            onChanged: (value) => setState(() {
              _statusValue = value ?? 'draft';
              _dirty = true;
            }),
          ),
          const SizedBox(height: EmiSpacing.xl),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : _cancel,
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: EmiSpacing.sm),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Menyimpan...' : 'Simpan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _required(String? value) =>
      value?.trim().isEmpty != false ? 'Wajib diisi.' : null;

  Future<void> _pick() async {
    final file = await ref.read(adminCultureFilePickerProvider)(_type);
    if (!mounted || file?.path == null) return;
    final allowed = switch (_type) {
      'image' => {'jpg', 'jpeg', 'png', 'webp'},
      'audio' => {'mp3', 'm4a', 'wav', 'ogg'},
      _ => {'pdf'},
    };
    if (!allowed.contains(file!.extension?.toLowerCase())) {
      return _error('Format media tidak didukung.');
    }
    if (file.size <= 0 || file.size > 30 * 1024 * 1024) {
      return _error('Ukuran media harus antara 1 byte dan 30 MB.');
    }
    setState(() {
      _filePath = file.path;
      _fileName = file.name;
      _fileSize = file.size;
      _dirty = true;
    });
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    if (const {'image', 'audio', 'pdf'}.contains(_type) &&
        _filePath == null &&
        _oldMediaId == null) {
      return _error('Pilih media terlebih dahulu.');
    }
    setState(() => _saving = true);
    try {
      var mediaId = _oldMediaId;
      if (_filePath != null) {
        mediaId = await ref
            .read(adminCultureRepositoryProvider)
            .upload(path: _filePath!, name: _fileName ?? 'media');
      }
      final saved = await ref
          .read(adminCultureRepositoryProvider)
          .save(
            id: widget.id,
            request: AdminCultureSaveRequest(
              title: _title.text.trim(),
              description: _description.text.trim(),
              contentType: _type,
              mediaId: const {'image', 'audio', 'pdf'}.contains(_type)
                  ? mediaId
                  : null,
              externalUrl: const {'youtube', 'article', 'link'}.contains(_type)
                  ? _url.text.trim()
                  : null,
              displayOrder: int.parse(_order.text),
              status: _statusValue,
            ),
          );
      _dirty = false;
      ref.invalidate(adminCultureItemsProvider);
      ref.invalidate(adminCultureDetailProvider(saved.id));
      if (mounted) context.go('/admin/culture/${saved.id}');
    } catch (_) {
      if (mounted) {
        _error('Konten budaya belum bisa disimpan. Silakan coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _cancel() async {
    if (!_dirty || await _leaveDialog()) {
      _dirty = false;
      if (mounted) context.pop();
    }
  }

  Future<void> _confirmLeave() async {
    if (await _leaveDialog()) {
      _dirty = false;
      if (mounted) context.pop();
    }
  }

  Future<bool> _leaveDialog() async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Buang perubahan?'),
          content: const Text('Perubahan yang belum disimpan akan hilang.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Tetap di sini'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Buang'),
            ),
          ],
        ),
      ) ??
      false;
  void _error(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

Future<void> _action(
  BuildContext context,
  AdminCultureItem item,
  String action,
) async {
  if (action == 'view') {
    context.push('/admin/culture/${item.id}');
    return;
  }
  if (action == 'edit') {
    context.push('/admin/culture/${item.id}/edit');
    return;
  }
  final container = ProviderScope.containerOf(context);
  final destructive = action == 'archive' || action == 'delete';
  if (destructive) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(action == 'delete' ? 'Hapus Konten?' : 'Arsipkan Konten?'),
        content: Text(
          action == 'delete'
              ? 'Konten dihapus secara aman dan tidak lagi ditampilkan.'
              : 'Konten disembunyikan, tetapi data tetap tersimpan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action == 'delete' ? 'Hapus' : 'Arsipkan'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
  }
  try {
    final repository = container.read(adminCultureRepositoryProvider);
    if (action == 'publish') await repository.publish(item.id);
    if (action == 'archive') await repository.archive(item.id);
    if (action == 'delete') await repository.delete(item.id);
    container.invalidate(adminCultureItemsProvider);
    container.invalidate(adminCultureDetailProvider(item.id));
    if (context.mounted && destructive) context.go('/admin/culture');
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tindakan belum berhasil. Silakan coba lagi.'),
        ),
      );
    }
  }
}

const _types = ['image', 'audio', 'pdf', 'youtube', 'article', 'link'];
String _category(String value) => switch (value) {
  'image' => 'Gambar',
  'audio' => 'Audio',
  'pdf' => 'Dokumen PDF',
  'youtube' => 'YouTube',
  'article' => 'Artikel',
  _ => 'Tautan',
};
String _status(String value) => switch (value) {
  'published' => 'Terbit',
  'archived' => 'Arsip',
  _ => 'Draft',
};
IconData _contentIcon(String value) => switch (value) {
  'audio' => Icons.audiotrack,
  'pdf' => Icons.picture_as_pdf,
  'youtube' => Icons.play_circle_outline,
  'article' => Icons.article_outlined,
  'link' => Icons.link,
  _ => Icons.image_outlined,
};
String _size(int? bytes) {
  if (bytes == null) return 'Ukuran tidak tersedia';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
}

String _date(String? value) {
  final date = DateTime.tryParse(value ?? '')?.toLocal();
  return date == null
      ? '-'
      : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
