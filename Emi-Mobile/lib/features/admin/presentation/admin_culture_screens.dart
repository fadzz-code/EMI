import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/media/media_opener.dart';
import '../../../shared/widgets/role_dashboard_widgets.dart';
import '../../../shared/widgets/status_badge.dart';
import '../data/admin_culture_providers.dart';
import '../data/admin_culture_repository.dart';
import 'admin_shell.dart';
import 'admin_style.dart';
import 'admin_widgets.dart';

typedef AdminCultureFilePicker =
    Future<PlatformFile?> Function(String contentType);

final adminCultureFilePickerProvider = Provider<AdminCultureFilePicker>(
  (_) => (type) async {
    final extensions = switch (type) {
      'pdf' => const ['pdf'],
      'video' => const ['mp4', 'webm'],
      _ => null,
    };
    final result = await FilePicker.platform.pickFiles(
      type: type == 'image'
          ? FileType.image
          : type == 'audio'
          ? FileType.audio
          : FileType.custom,
      allowedExtensions: extensions,
      withData: false,
    );
    return result?.files.single;
  },
);

final adminCultureMediaOpenerProvider = Provider<MediaOpener>(
  (_) => const ExternalMediaOpener(),
);

abstract interface class AdminCultureAudioPlayer {
  Stream<PlayerState> get playerStateStream;
  bool get prepared;
  Future<void> prepare(String url);
  Future<void> play();
  Future<void> pause();
  Future<void> dispose();
}

class JustAudioAdminCulturePlayer implements AdminCultureAudioPlayer {
  JustAudioAdminCulturePlayer() : _player = AudioPlayer();
  final AudioPlayer _player;

  @override
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  @override
  bool get prepared => _player.audioSource != null;
  @override
  Future<void> prepare(String url) => _player.setUrl(url);
  @override
  Future<void> play() => _player.play();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> dispose() => _player.dispose();
}

final adminCultureAudioPlayerFactoryProvider =
    Provider<AdminCultureAudioPlayer Function()>(
      (_) => JustAudioAdminCulturePlayer.new,
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
            Wrap(
              spacing: EmiSpacing.sm,
              runSpacing: EmiSpacing.sm,
              children: [
                FilledButton.icon(
                  key: const Key('adminAdd-culture'),
                  onPressed: () => context.push('/admin/culture/create'),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Konten'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.push('/admin/culture/templates'),
                  icon: const Icon(Icons.collections_bookmark_outlined),
                  label: const Text('Template Budaya'),
                ),
              ],
            ),
            const SizedBox(height: EmiSpacing.md),
            TextField(
              key: const Key('adminSearch-culture'),
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
                      key: Key('adminEmpty-culture'),
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
  Widget build(BuildContext context) => AdminCard(
    onTap: () => context.push('/admin/culture/${item.id}'),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 56,
            height: 56,
            child: item.contentType == 'image' && item.mediaUrl != null
                ? Image.network(
                    item.mediaUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AdminStyle.tint,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: AdminStyle.inkMuted,
                      ),
                    ),
                  )
                : Container(
                    color: AdminStyle.tint,
                    child: Icon(
                      _contentIcon(item.contentType),
                      color: EmiColors.primary,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: EmiSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _category(item.contentType),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AdminStyle.inkMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: EmiSpacing.xs),
              Wrap(
                spacing: EmiSpacing.xs,
                children: [
                  EmiStatusBadge(
                    label: _status(item.status),
                    tone: emiStatusToneFromKey(item.status),
                  ),
                ],
              ),
              const SizedBox(height: EmiSpacing.xs),
              Text(
                'Diubah ${_date(item.updatedAt)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AdminStyle.inkMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
          error: (_, _) => FriendlyState(
            icon: Icons.error_outline,
            title: 'Konten Belum Bisa Dimuat',
            message: 'Silakan coba lagi.',
            onRetry: () => ref.invalidate(adminCultureDetailProvider(id)),
          ),
          data: (item) => Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(EmiSpacing.md),
                  children: [
                    AdminCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: EmiSpacing.sm),
                          Wrap(
                            spacing: EmiSpacing.xs,
                            children: [
                              EmiStatusBadge(
                                label: _status(item.status),
                                tone: emiStatusToneFromKey(item.status),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const AdminSectionHeader('Media atau Tautan'),
                    AdminCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _AdminCultureMedia(item: item),
                          if (item.mediaName != null) ...[
                            const SizedBox(height: EmiSpacing.xs),
                            Text(
                              '${item.mediaName} · ${_size(item.mediaSize)}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AdminStyle.inkMuted),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const AdminSectionHeader('Informasi Konten'),
                    AdminCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Field(
                            label: 'Deskripsi',
                            value: item.description.isEmpty
                                ? '-'
                                : item.description,
                          ),
                          _Field(
                            label: 'Kategori',
                            value: _category(item.contentType),
                          ),
                          _Field(
                            label: 'Urutan tampil',
                            value: '${item.displayOrder}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  EmiSpacing.md,
                  0,
                  EmiSpacing.md,
                  EmiSpacing.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton(
                      onPressed: () =>
                          context.push('/admin/culture/${item.id}/edit'),
                      child: const Text('Edit Konten'),
                    ),
                    const SizedBox(height: EmiSpacing.sm),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: EmiSpacing.sm,
                      children: [
                        if (item.status != 'published')
                          OutlinedButton(
                            key: const Key('adminPublish-culture'),
                            onPressed: () => _action(context, item, 'publish'),
                            child: const Text('Terbitkan'),
                          ),
                        if (item.status != 'archived')
                          OutlinedButton(
                            key: const Key('adminArchive-culture'),
                            onPressed: () => _action(context, item, 'archive'),
                            child: const Text('Arsipkan'),
                          ),
                        TextButton(
                          key: const Key('adminDelete-culture'),
                          onPressed: () => _action(context, item, 'delete'),
                          child: const Text('Hapus'),
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

class _AdminCultureMedia extends ConsumerStatefulWidget {
  const _AdminCultureMedia({required this.item});
  final AdminCultureItem item;

  @override
  ConsumerState<_AdminCultureMedia> createState() => _AdminCultureMediaState();
}

class _AdminCultureMediaState extends ConsumerState<_AdminCultureMedia> {
  late final AdminCultureAudioPlayer _player;
  bool _loading = false;
  bool _disposed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _player = ref.read(adminCultureAudioPlayerFactoryProvider)();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final url = item.mediaUrl ?? item.externalUrl;
    if (url == null) return const Text('Media belum tersedia.');
    if (item.contentType == 'image') {
      return Image.network(
        url,
        errorBuilder: (_, _, _) =>
            const Text('Pratinjau gambar tidak tersedia.'),
      );
    }
    if (item.contentType == 'audio') {
      return StreamBuilder<PlayerState>(
        stream: _player.playerStateStream,
        builder: (context, snapshot) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: IconButton.filled(
            key: const Key('adminCultureAudioToggle'),
            onPressed: _loading
                ? null
                : () => _toggle(url, snapshot.data?.playing == true),
            icon: _loading
                ? const CircularProgressIndicator()
                : Icon(
                    snapshot.data?.playing == true
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
          ),
          title: Text(_error ?? 'Putar audio'),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilledButton.icon(
          key: const Key('adminCultureOpenMedia'),
          onPressed: _loading ? null : () => _open(url),
          icon: Icon(
            item.contentType == 'pdf'
                ? Icons.picture_as_pdf
                : item.contentType == 'video' || item.contentType == 'youtube'
                ? Icons.play_circle_outline
                : Icons.open_in_new,
          ),
          label: Text(
            item.contentType == 'pdf'
                ? 'Buka PDF'
                : item.contentType == 'video' || item.contentType == 'youtube'
                ? 'Putar video'
                : 'Buka tautan',
          ),
        ),
        if (_error != null) Text(_error!),
      ],
    );
  }

  Future<void> _toggle(String url, bool playing) async {
    if (playing) {
      try {
        await _player.pause();
      } catch (_) {
        _fail('Audio belum bisa dijeda.');
      }
      return;
    }
    if (!_validUrl(url)) return _fail('Alamat media tidak valid.');
    if (!_player.prepared) {
      setState(() {
        _loading = true;
        _error = null;
      });
      try {
        await _player.prepare(url);
      } catch (_) {
        _fail('Audio belum bisa diputar.');
        return;
      } finally {
        if (!_disposed && mounted) setState(() => _loading = false);
      }
    }
    if (_disposed) return;
    unawaited(
      _player.play().catchError((_) {
        _fail('Audio belum bisa diputar.');
      }),
    );
  }

  Future<void> _open(String url) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (!await ref.read(adminCultureMediaOpenerProvider).open(url)) {
        _fail(
          _validUrl(url)
              ? 'Konten belum bisa dibuka.'
              : 'Alamat media tidak valid.',
        );
      }
    } catch (_) {
      _fail('Konten belum bisa dibuka.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() => _error = message);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

bool _validUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  return uri != null &&
      uri.hasAuthority &&
      {'http', 'https'}.contains(uri.scheme);
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: EmiSpacing.sm),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AdminStyle.inkMuted),
        ),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: AdminStyle.ink)),
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
    final fileType = const {'image', 'audio', 'video', 'pdf'}.contains(_type);
    return Form(
      key: _form,
      onChanged: () {
        if (!_dirty) setState(() => _dirty = true);
      },
      child: ListView(
        padding: const EdgeInsets.all(EmiSpacing.md),
        children: [
          const AdminSectionHeader('Informasi Konten', leading: false),
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
          const AdminSectionHeader('Media atau Tautan'),
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
              validator: (value) => _validUrl(value ?? '')
                  ? null
                  : 'Masukkan URL HTTP/HTTPS yang valid.',
            ),
          const AdminSectionHeader('Publikasi'),
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
                  key: const Key('adminSave-culture'),
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
      'video' => {'mp4', 'webm'},
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
    if (const {'image', 'audio', 'video', 'pdf'}.contains(_type) &&
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
              mediaId: const {'image', 'audio', 'video', 'pdf'}.contains(_type)
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

const _types = ['image', 'audio', 'video', 'pdf', 'youtube', 'article', 'link'];
String _category(String value) => switch (value) {
  'image' => 'Gambar',
  'audio' => 'Audio',
  'video' => 'Video',
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
  'video' => Icons.play_circle_outline,
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
