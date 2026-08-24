import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/role_dashboard_widgets.dart';
import '../../../shared/widgets/status_badge.dart';
import '../data/admin_providers.dart';
import '../data/admin_repository.dart';
import '../data/admin_speaking_providers.dart';
import '../data/admin_speaking_repository.dart';
import 'admin_shell.dart';
import 'admin_style.dart';
import 'admin_widgets.dart';

typedef AdminSpeakingAudioPicker = Future<PlatformFile?> Function();

final adminSpeakingAudioPickerProvider = Provider<AdminSpeakingAudioPicker>(
  (_) => () async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      withData: false,
    );
    return result?.files.single;
  },
);

final _activeSpeakingClassesProvider = FutureProvider<List<AdminClass>>((
  ref,
) async {
  final repo = ref.watch(adminRepositoryProvider);
  final items = <AdminClass>[];
  var page = 1;
  while (true) {
    final result = await repo.classes(
      AdminListQuery(status: 'active', page: page),
    );
    items.addAll(result.items);
    if (!result.hasMore) break;
    page++;
  }
  return items;
});

class AdminSpeakingScreen extends ConsumerStatefulWidget {
  const AdminSpeakingScreen({super.key});

  @override
  ConsumerState<AdminSpeakingScreen> createState() =>
      _AdminSpeakingScreenState();
}

class _AdminSpeakingScreenState extends ConsumerState<AdminSpeakingScreen> {
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
    final data = ref.watch(adminSpeakingTemplatesProvider);
    final query = ref.read(adminSpeakingTemplatesProvider.notifier).query;
    return AdminShell(
      title: 'Template Speaking',
      child: RefreshIndicator(
        onRefresh: ref.read(adminSpeakingTemplatesProvider.notifier).refresh,
        child: ListView(
          padding: const EdgeInsets.all(EmiSpacing.md),
          children: [
            const Text('Kelola template global untuk latihan speaking.'),
            const SizedBox(height: EmiSpacing.md),
            FilledButton.icon(
              key: const Key('adminAdd-speaking'),
              onPressed: () => context.push('/admin/speaking/create'),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Template'),
            ),
            const SizedBox(height: EmiSpacing.md),
            TextField(
              key: const Key('adminSearch-speaking'),
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Cari judul atau kalimat latihan',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Filter',
                  onPressed: () => _filter(query.status),
                  icon: Badge(
                    isLabelVisible: query.status != null,
                    child: const Icon(Icons.tune),
                  ),
                ),
              ),
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 400), () {
                  ref
                      .read(adminSpeakingTemplatesProvider.notifier)
                      .search(value);
                });
              },
            ),
            const SizedBox(height: EmiSpacing.md),
            data.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => FriendlyState(
                icon: Icons.wifi_off_outlined,
                title: 'Template Speaking Belum Bisa Dimuat',
                message: 'Periksa koneksi internet, lalu coba lagi.',
                onRetry: () => ref.invalidate(adminSpeakingTemplatesProvider),
              ),
              data: (page) => page.items.isEmpty
                  ? const FriendlyState(
                      key: Key('adminEmpty-speaking'),
                      icon: Icons.mic_none_outlined,
                      title: 'Template Speaking Tidak Ditemukan',
                      message:
                          'Tambah template atau ubah pencarian dan filter.',
                    )
                  : Column(
                      children: [
                        for (final item in page.items) ...[
                          _SpeakingTile(item: item),
                          const SizedBox(height: EmiSpacing.sm),
                        ],
                        if (page.hasMore)
                          FilledButton(
                            onPressed: ref
                                .read(adminSpeakingTemplatesProvider.notifier)
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

  Future<void> _filter(String? current) async {
    var status = current;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: const EdgeInsets.all(EmiSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String?>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Semua')),
                  DropdownMenuItem(value: 'draft', child: Text('Draft')),
                  DropdownMenuItem(value: 'published', child: Text('Terbit')),
                  DropdownMenuItem(value: 'archived', child: Text('Arsip')),
                ],
                onChanged: (value) => setState(() => status = value),
              ),
              const SizedBox(height: EmiSpacing.md),
              FilledButton(
                onPressed: () {
                  ref
                      .read(adminSpeakingTemplatesProvider.notifier)
                      .filter(status);
                  Navigator.pop(context);
                },
                child: const Text('Terapkan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpeakingTile extends StatelessWidget {
  const _SpeakingTile({required this.item});
  final AdminSpeakingTemplate item;

  @override
  Widget build(BuildContext context) => AdminCard(
    onTap: () => context.push('/admin/speaking/${item.id}'),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AdminStyle.tint,
            borderRadius: BorderRadius.circular(EmiRadii.pill),
          ),
          child: const Icon(
            Icons.headphones_outlined,
            color: EmiColors.primary,
            size: 22,
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                item.targetText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AdminStyle.inkMuted),
              ),
              const SizedBox(height: EmiSpacing.xs),
              Wrap(
                spacing: EmiSpacing.xs,
                runSpacing: EmiSpacing.xs,
                children: [
                  EmiStatusBadge(
                    label: _status(item.status),
                    tone: emiStatusToneFromKey(item.status),
                  ),
                  EmiStatusBadge(
                    label: item.referenceAudioMediaId == null
                        ? 'Tanpa audio'
                        : 'Audio tersedia',
                    icon: item.referenceAudioMediaId == null
                        ? Icons.volume_off_outlined
                        : Icons.volume_up_outlined,
                  ),
                ],
              ),
              const SizedBox(height: EmiSpacing.xs),
              Text(
                '${_difficulty(item.difficulty)} · Diubah ${_date(item.updatedAt)}',
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
          onSelected: (value) {
            if (value == 'view') {
              context.push('/admin/speaking/${item.id}');
            }
            if (value == 'edit') {
              context.push('/admin/speaking/${item.id}/edit');
            }
            if (value == 'apply') _showApplyDialog(context, item);
            if (value == 'publish') _publish(context, item);
            if (value == 'archive') _archive(context, item);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'view', child: Text('Lihat')),
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            if (item.status == 'published')
              const PopupMenuItem(value: 'apply', child: Text('Terapkan')),
            if (item.status != 'published' && item.status != 'archived')
              const PopupMenuItem(value: 'publish', child: Text('Terbitkan')),
            if (item.status != 'archived')
              const PopupMenuItem(value: 'archive', child: Text('Arsipkan')),
          ],
        ),
      ],
    ),
  );
}

class AdminSpeakingDetailScreen extends ConsumerWidget {
  const AdminSpeakingDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(adminSpeakingDetailProvider(id));
    return AdminShell(
      title: 'Detail Template Speaking',
      fallbackRoute: '/admin/speaking',
      child: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const FriendlyState(
          icon: Icons.wifi_off_outlined,
          title: 'Template Speaking Belum Bisa Dimuat',
          message: 'Periksa koneksi internet, lalu coba lagi.',
        ),
        data: (item) => ListView(
          padding: const EdgeInsets.all(EmiSpacing.md),
          children: [
            AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
            const AdminSectionHeader('Audio Referensi', leading: false),
            AdminCard(
              child: item.referenceAudioUrl != null
                  ? SpeakingAudioControls(
                      source: item.referenceAudioUrl!,
                      remote: true,
                    )
                  : Text(
                      'Belum ada audio referensi.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AdminStyle.inkMuted,
                      ),
                    ),
            ),
            const AdminSectionHeader('Kalimat Latihan'),
            AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Row(label: 'Target bacaan', value: item.targetText),
                  _Row(
                    label: 'Terjemahan',
                    value: item.targetTranslation ?? '-',
                  ),
                ],
              ),
            ),
            const AdminSectionHeader('Panduan'),
            AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Row(label: 'Petunjuk', value: item.promptText ?? '-'),
                  _Row(label: 'Kesulitan', value: _difficulty(item.difficulty)),
                ],
              ),
            ),
            const SizedBox(height: EmiSpacing.lg),
            FilledButton(
              onPressed: () => context.push('/admin/speaking/${item.id}/edit'),
              child: const Text('Edit Template'),
            ),
            if (item.status == 'published') ...[
              const SizedBox(height: EmiSpacing.sm),
              OutlinedButton(
                onPressed: () => _showApplyDialog(context, item),
                child: const Text('Terapkan'),
              ),
            ],
            if (item.status != 'archived') ...[
              const SizedBox(height: EmiSpacing.sm),
              OutlinedButton(
                key: const Key('adminArchive-speaking'),
                onPressed: () => _archive(context, item),
                child: const Text('Arsipkan'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
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

class AdminSpeakingFormScreen extends ConsumerStatefulWidget {
  const AdminSpeakingFormScreen({super.key, this.id});
  final String? id;

  @override
  ConsumerState<AdminSpeakingFormScreen> createState() =>
      _AdminSpeakingFormScreenState();
}

class _AdminSpeakingFormScreenState
    extends ConsumerState<AdminSpeakingFormScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _target = TextEditingController();
  final _translation = TextEditingController();
  final _prompt = TextEditingController();
  String _difficultyValue = 'beginner';
  String _statusValue = 'draft';
  String? _existingAudioId;
  String? _existingAudioUrl;
  String? _audioPath;
  String? _audioName;
  bool _clearAudio = false;
  bool _hydrated = false;
  bool _saving = false;
  double? _progress;

  @override
  void dispose() {
    _title.dispose();
    _target.dispose();
    _translation.dispose();
    _prompt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.id == null
        ? null
        : ref.watch(adminSpeakingDetailProvider(widget.id!));
    return AdminShell(
      title: widget.id == null
          ? 'Tambah Template Speaking'
          : 'Edit Template Speaking',
      fallbackRoute: widget.id == null
          ? '/admin/speaking'
          : '/admin/speaking/${widget.id}',
      child: detail == null
          ? _content(null)
          : detail.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const FriendlyState(
                icon: Icons.wifi_off_outlined,
                title: 'Template Speaking Belum Bisa Dimuat',
                message: 'Periksa koneksi internet, lalu coba lagi.',
              ),
              data: _content,
            ),
    );
  }

  Widget _content(AdminSpeakingTemplate? item) {
    if (item != null && !_hydrated) {
      _title.text = item.title;
      _target.text = item.targetText;
      _translation.text = item.targetTranslation ?? '';
      _prompt.text = item.promptText ?? '';
      _difficultyValue = item.difficulty;
      _statusValue = item.status == 'archived' ? 'draft' : item.status;
      _existingAudioId = item.referenceAudioMediaId;
      _existingAudioUrl = item.referenceAudioUrl;
      _hydrated = true;
    }
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(EmiSpacing.md),
        children: [
          const AdminSectionHeader('Identitas Template', leading: false),
          TextFormField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Judul latihan'),
            validator: _required,
          ),
          const AdminSectionHeader('Kalimat Latihan'),
          TextFormField(
            controller: _target,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Target bacaan Mekongga',
            ),
            validator: _required,
          ),
          const SizedBox(height: EmiSpacing.md),
          TextFormField(
            controller: _translation,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Terjemahan opsional'),
          ),
          const SizedBox(height: EmiSpacing.md),
          TextFormField(
            controller: _prompt,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Petunjuk untuk siswa opsional',
            ),
          ),
          const SizedBox(height: EmiSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _difficultyValue,
            decoration: const InputDecoration(labelText: 'Tingkat kesulitan'),
            items: const [
              DropdownMenuItem(value: 'beginner', child: Text('Pemula')),
              DropdownMenuItem(value: 'intermediate', child: Text('Menengah')),
              DropdownMenuItem(value: 'advanced', child: Text('Mahir')),
            ],
            onChanged: (value) =>
                setState(() => _difficultyValue = value ?? 'beginner'),
          ),
          const AdminSectionHeader('Publikasi'),
          DropdownButtonFormField<String>(
            initialValue: _statusValue,
            decoration: const InputDecoration(
              labelText: 'Status',
              helperText:
                  'Terbitkan setelah judul dan kalimat latihan siap digunakan.',
            ),
            items: const [
              DropdownMenuItem(value: 'draft', child: Text('Draft')),
              DropdownMenuItem(value: 'published', child: Text('Terbit')),
            ],
            onChanged: (value) =>
                setState(() => _statusValue = value ?? 'draft'),
          ),
          const AdminSectionHeader('Audio referensi opsional'),
          if (_audioPath != null)
            SpeakingAudioControls(source: _audioPath!, remote: false),
          if (_audioPath == null && !_clearAudio && _existingAudioUrl != null)
            SpeakingAudioControls(source: _existingAudioUrl!, remote: true),
          if (_audioName != null) Text('Dipilih: $_audioName'),
          if (_audioPath == null && !_clearAudio && _existingAudioId != null)
            const Text('Audio lama dipertahankan jika tidak diubah.'),
          FilledButton.icon(
            onPressed: _saving ? null : _pickAudio,
            icon: const Icon(Icons.upload_file),
            label: Text(
              _existingAudioId == null ? 'Pilih Audio' : 'Ganti Audio',
            ),
          ),
          if (_audioPath != null)
            TextButton(
              onPressed: _saving
                  ? null
                  : () => setState(() {
                      _audioPath = null;
                      _audioName = null;
                    }),
              child: const Text('Hapus Pilihan'),
            ),
          if (_existingAudioId != null && _audioPath == null && !_clearAudio)
            TextButton(
              onPressed: _saving
                  ? null
                  : () => setState(() => _clearAudio = true),
              child: const Text('Hapus Audio Lama'),
            ),
          if (_clearAudio)
            TextButton(
              onPressed: _saving
                  ? null
                  : () => setState(() => _clearAudio = false),
              child: const Text('Batalkan Hapus Audio'),
            ),
          if (_progress != null) LinearProgressIndicator(value: _progress),
          const SizedBox(height: EmiSpacing.xl),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => context.pop(),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: EmiSpacing.sm),
              Expanded(
                child: FilledButton(
                  key: const Key('adminSave-speaking'),
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

  Future<void> _pickAudio() async {
    final file = await ref.read(adminSpeakingAudioPickerProvider)();
    if (!mounted || file?.path == null) return;
    final selected = file!;
    const allowed = {'mp3', 'm4a', 'mp4', 'wav', 'ogg', 'oga', 'webm'};
    final extension = selected.extension?.toLowerCase();
    if (!allowed.contains(extension)) {
      return _error('Format audio tidak didukung.');
    }
    if (selected.size <= 0) return _error('Audio kosong.');
    if (selected.size > 30 * 1024 * 1024) {
      return _error('Ukuran audio melebihi 30 MB.');
    }
    setState(() {
      _audioPath = selected.path;
      _audioName = selected.name;
      _clearAudio = false;
    });
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    if (_statusValue == 'published' &&
        (_title.text.trim().isEmpty || _target.text.trim().isEmpty)) {
      return _error('Lengkapi judul dan kalimat latihan sebelum diterbitkan.');
    }
    setState(() => _saving = true);
    try {
      String? audioId = _clearAudio ? null : _existingAudioId;
      if (_audioPath != null) {
        audioId = await ref
            .read(adminSpeakingRepositoryProvider)
            .uploadAudio(
              path: _audioPath!,
              name: _audioName ?? 'audio',
              onProgress: (sent, total) {
                if (mounted && total > 0) {
                  setState(() => _progress = sent / total);
                }
              },
            );
      }
      final saved = await ref
          .read(adminSpeakingRepositoryProvider)
          .save(
            id: widget.id,
            request: AdminSpeakingSaveRequest(
              title: _title.text.trim(),
              targetText: _target.text.trim(),
              targetTranslation: _translation.text.trim(),
              promptText: _prompt.text.trim(),
              difficulty: _difficultyValue,
              status: _statusValue,
              referenceAudioMediaId: audioId,
            ),
          );
      ref.invalidate(adminSpeakingTemplatesProvider);
      ref.invalidate(adminSpeakingDetailProvider(saved.id));
      if (mounted) context.go('/admin/speaking/${saved.id}');
    } catch (_) {
      if (mounted) {
        _error('Template speaking belum bisa disimpan. Silakan coba lagi.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _progress = null;
        });
      }
    }
  }

  void _error(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class SpeakingAudioControls extends StatefulWidget {
  const SpeakingAudioControls({
    super.key,
    required this.source,
    required this.remote,
  });
  final String source;
  final bool remote;

  @override
  State<SpeakingAudioControls> createState() => _SpeakingAudioControlsState();
}

class _SpeakingAudioControlsState extends State<SpeakingAudioControls> {
  final _player = AudioPlayer();
  bool _loaded = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    try {
      if (!_loaded) {
        if (widget.remote) {
          await _player.setUrl(widget.source);
        } else {
          await _player.setFilePath(widget.source);
        }
        _loaded = true;
      }
      await _player.play();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio belum bisa diputar.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: EmiSpacing.xs,
    children: [
      OutlinedButton(onPressed: _play, child: const Text('Putar')),
      OutlinedButton(onPressed: _player.pause, child: const Text('Jeda')),
      OutlinedButton(onPressed: _player.stop, child: const Text('Berhenti')),
    ],
  );
}

Future<void> _showApplyDialog(
  BuildContext context,
  AdminSpeakingTemplate item,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _ApplySpeakingDialog(item: item),
  );
}

class _ApplySpeakingDialog extends ConsumerStatefulWidget {
  const _ApplySpeakingDialog({required this.item});
  final AdminSpeakingTemplate item;

  @override
  ConsumerState<_ApplySpeakingDialog> createState() =>
      _ApplySpeakingDialogState();
}

class _ApplySpeakingDialogState extends ConsumerState<_ApplySpeakingDialog> {
  final Set<String> _selected = {};
  bool _syncExisting = false;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(_activeSpeakingClassesProvider);
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, scrollController) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(EmiSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Terapkan "${widget.item.title}"',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: EmiSpacing.xs),
              Text(
                'Pilih kelas aktif. Target kelas akan dibuat sebagai draft.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AdminStyle.inkMuted,
                ),
              ),
              const SizedBox(height: EmiSpacing.md),
              Expanded(
                child: classesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => FriendlyState(
                    icon: Icons.wifi_off_outlined,
                    title: 'Kelas Belum Bisa Dimuat',
                    message: 'Periksa koneksi internet, lalu coba lagi.',
                    onRetry: () =>
                        ref.invalidate(_activeSpeakingClassesProvider),
                  ),
                  data: (classes) => classes.isEmpty
                      ? const FriendlyState(
                          icon: Icons.school_outlined,
                          title: 'Tidak Ada Kelas Aktif',
                          message: 'Buat atau aktifkan kelas terlebih dahulu.',
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: classes.length,
                          itemBuilder: (context, index) {
                            final klass = classes[index];
                            final selected = _selected.contains(klass.id);
                            return CheckboxListTile(
                              value: selected,
                              onChanged: (_) => _toggle(klass.id),
                              title: Text(
                                klass.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${klass.schoolName ?? '-'} · ${klass.academicYear ?? '-'}',
                                style: TextStyle(color: AdminStyle.inkMuted),
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                            );
                          },
                        ),
                ),
              ),
              CheckboxListTile(
                value: _syncExisting,
                onChanged: (value) =>
                    setState(() => _syncExisting = value ?? false),
                title: const Text('Sync ulang kelas yang sudah diterapkan'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              FilledButton(
                onPressed: _submitting || _selected.isEmpty ? null : _submit,
                child: Text(
                  _submitting
                      ? 'Menerapkan...'
                      : 'Terapkan (${_selected.length})',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(adminSpeakingRepositoryProvider)
          .applyTemplate(
            widget.item.id,
            classIds: _selected.toList(),
            syncExisting: _syncExisting,
          );
      final applied = ((result['applied'] ?? []) as List).length;
      final synced = ((result['synced'] ?? []) as List).length;
      final skipped = ((result['skipped'] ?? []) as List).length;
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Berhasil diterapkan ke ${applied + synced} kelas${skipped > 0 ? ' ($skipped dilewati)' : ''}.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

Future<void> _publish(BuildContext context, AdminSpeakingTemplate item) async {
  final ref = ProviderScope.containerOf(context);
  if (item.title.trim().isEmpty || item.targetText.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Lengkapi judul dan kalimat latihan sebelum diterbitkan.',
        ),
      ),
    );
    return;
  }
  try {
    await ref
        .read(adminSpeakingRepositoryProvider)
        .save(
          id: item.id,
          request: AdminSpeakingSaveRequest(
            title: item.title,
            targetText: item.targetText,
            targetTranslation: item.targetTranslation ?? '',
            promptText: item.promptText ?? '',
            difficulty: item.difficulty,
            status: 'published',
            referenceAudioMediaId: item.referenceAudioMediaId,
          ),
        );
    ref.invalidate(adminSpeakingTemplatesProvider);
    ref.invalidate(adminSpeakingDetailProvider(item.id));
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Template speaking belum bisa diterbitkan. Periksa kelengkapan data.',
          ),
        ),
      );
    }
  }
}

Future<void> _archive(BuildContext context, AdminSpeakingTemplate item) async {
  final ref = ProviderScope.containerOf(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Arsipkan Template Speaking?'),
      content: const Text(
        'Template akan disembunyikan dari latihan baru, tetapi data tetap tersimpan.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Arsipkan'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  try {
    await ref.read(adminSpeakingRepositoryProvider).archive(item.id);
    ref.invalidate(adminSpeakingTemplatesProvider);
    ref.invalidate(adminSpeakingDetailProvider(item.id));
    if (context.mounted) context.go('/admin/speaking');
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Template speaking belum bisa diarsipkan. Silakan coba lagi.',
          ),
        ),
      );
    }
  }
}

String _status(String value) => switch (value) {
  'published' => 'Terbit',
  'archived' => 'Arsip',
  _ => 'Draft',
};
String _difficulty(String value) => switch (value) {
  'intermediate' => 'Menengah',
  'advanced' => 'Mahir',
  _ => 'Pemula',
};
String _date(String? value) {
  final date = DateTime.tryParse(value ?? '')?.toLocal();
  if (date == null) return '-';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
