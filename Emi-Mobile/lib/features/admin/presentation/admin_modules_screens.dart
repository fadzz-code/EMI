import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../core/errors/app_error.dart';
import '../../../shared/widgets/role_dashboard_widgets.dart';
import '../../../shared/widgets/status_badge.dart';
import '../data/admin_modules_providers.dart';
import '../data/admin_modules_repository.dart';
import 'admin_shell.dart';
import 'admin_widgets.dart';

class AdminModulesScreen extends ConsumerStatefulWidget {
  const AdminModulesScreen({super.key});

  @override
  ConsumerState<AdminModulesScreen> createState() => _AdminModulesScreenState();
}

class _AdminModulesScreenState extends ConsumerState<AdminModulesScreen> {
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
    final summary = ref.watch(adminModuleSummaryProvider);
    final page = ref.watch(adminModulesProvider);
    final query = ref.read(adminModulesProvider.notifier).query;
    return AdminShell(
      title: 'Modul Pembelajaran',
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminModuleSummaryProvider);
          await ref.read(adminModulesProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.all(EmiSpacing.md),
          children: [
            const Text(
              'Kelola bahan belajar yang dapat digunakan Guru dan Siswa dalam kegiatan pembelajaran.',
            ),
            const SizedBox(height: EmiSpacing.md),
            summary.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const SizedBox.shrink(),
              data: (data) => Wrap(
                spacing: EmiSpacing.md,
                runSpacing: EmiSpacing.sm,
                children: [
                  _StatText('Total', data.total),
                  _StatText('Draft', data.draft),
                  _StatText('Terbit', data.published),
                  _StatText('Arsip', data.archived),
                ],
              ),
            ),
            const SizedBox(height: EmiSpacing.md),
            FilledButton.icon(
              key: const Key('adminAdd-modules'),
              onPressed: () => context.push('/admin/modules/create'),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Modul'),
            ),
            const SizedBox(height: EmiSpacing.md),
            TextField(
              key: const Key('adminSearch-modules'),
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Cari judul Modul',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Filter',
                  onPressed: () => _showFilter(context, query),
                  icon: Badge(
                    isLabelVisible: query.status != null,
                    child: const Icon(Icons.tune),
                  ),
                ),
              ),
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 400), () {
                  ref.read(adminModulesProvider.notifier).search(value);
                });
              },
            ),
            if (query.status != null) ...[
              const SizedBox(height: EmiSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(label: Text(_statusLabel(query.status!))),
              ),
            ],
            const SizedBox(height: EmiSpacing.md),
            page.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => FriendlyState(
                icon: Icons.wifi_off_outlined,
                title: 'Data Modul Belum Bisa Dimuat',
                message: 'Periksa koneksi internet, lalu coba lagi.',
                onRetry: () => ref.invalidate(adminModulesProvider),
              ),
              data: (data) {
                if (data.items.isEmpty) {
                  final hasSearch =
                      _search.text.trim().isNotEmpty || query.status != null;
                  return FriendlyState(
                    key: const Key('adminEmpty-modules'),
                    icon: Icons.menu_book_outlined,
                    title: hasSearch
                        ? 'Modul Tidak Ditemukan'
                        : 'Belum Ada Modul',
                    message: hasSearch
                        ? 'Coba gunakan judul atau filter yang berbeda.'
                        : 'Tambahkan Modul agar Guru dan Siswa memiliki bahan pembelajaran.',
                  );
                }
                return Column(
                  children: [
                    for (final item in data.items) ...[
                      _ModuleTile(item: item),
                      const SizedBox(height: 12),
                    ],
                    if (data.hasMore)
                      FilledButton(
                        onPressed: () =>
                            ref.read(adminModulesProvider.notifier).loadMore(),
                        child: const Text('Muat Lagi'),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFilter(BuildContext context, AdminModuleQuery query) async {
    String? status = query.status;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(EmiSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Filter', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: EmiSpacing.md),
              DropdownButtonFormField<String?>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Semua')),
                  DropdownMenuItem(value: 'draft', child: Text('Draft')),
                  DropdownMenuItem(value: 'published', child: Text('Terbit')),
                  DropdownMenuItem(value: 'archived', child: Text('Arsip')),
                ],
                onChanged: (value) => setSheetState(() => status = value),
              ),
              const SizedBox(height: EmiSpacing.lg),
              FilledButton(
                onPressed: () {
                  ref
                      .read(adminModulesProvider.notifier)
                      .filter(status: status);
                  Navigator.pop(context);
                },
                child: const Text('Terapkan'),
              ),
              TextButton(
                onPressed: () {
                  ref.read(adminModulesProvider.notifier).filter();
                  Navigator.pop(context);
                },
                child: const Text('Hapus Filter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({required this.item});

  final AdminModuleItem item;

  @override
  Widget build(BuildContext context) => AdminCard(
    onTap: () => context.push('/admin/modules/${item.id}'),
    padding: const EdgeInsets.symmetric(
      horizontal: EmiSpacing.md,
      vertical: EmiSpacing.sm,
    ),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 72),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: EmiColors.secondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.menu_book_outlined),
          ),
          const SizedBox(width: EmiSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: EmiSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.lessonsCount} Materi',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    EmiStatusBadge(
                      label: _statusLabel(item.status),
                      tone: emiStatusToneFromKey(item.status),
                    ),
                  ],
                ),
                Text(
                  'Diubah ${_shortDate(item.updatedAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Tindakan',
            onSelected: (value) {
              if (value == 'view') context.push('/admin/modules/${item.id}');
              if (value == 'edit') {
                context.push('/admin/modules/${item.id}/edit');
              }
              if (value == 'publish') _confirmPublish(context, item);
              if (value == 'archive') _confirmArchive(context, item);
              if (value == 'delete') _confirmDelete(context, item);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'view', child: Text('Lihat')),
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              if (item.status != 'published')
                const PopupMenuItem(value: 'publish', child: Text('Terbitkan')),
              if (item.status != 'archived')
                const PopupMenuItem(value: 'archive', child: Text('Arsipkan')),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Hapus', style: TextStyle(color: EmiColors.error)),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class AdminModuleDetailScreen extends ConsumerWidget {
  const AdminModuleDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(adminModuleDetailProvider(id));
    final materials = ref.watch(adminModuleMaterialsProvider(id));
    return AdminShell(
      title: 'Detail Modul',
      fallbackRoute: '/admin/modules',
      child: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => FriendlyState(
          icon: Icons.wifi_off_outlined,
          title: 'Data Modul Belum Bisa Dimuat',
          message: 'Periksa koneksi internet, lalu coba lagi.',
          onRetry: () => ref.invalidate(adminModuleDetailProvider(id)),
        ),
        data: (item) => ListView(
          padding: const EdgeInsets.all(EmiSpacing.md),
          children: [
            _InfoSection(
              title: 'Informasi Modul',
              rows: {
                'Judul': item.title,
                'Deskripsi': item.description.isEmpty ? '-' : item.description,
              },
            ),
            const SizedBox(height: EmiSpacing.md),
            _InfoSection(
              title: 'Status dan Riwayat',
              rows: {
                'Status': _statusLabel(item.status),
                'Dibuat': _shortDate(item.createdAt),
                'Terakhir Diubah': _shortDate(item.updatedAt),
              },
            ),
            const SizedBox(height: EmiSpacing.md),
            Text(
              'Materi Modul',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: EmiSpacing.sm),
            materials.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const Text('Materi belum bisa dimuat.'),
              data: (lessons) => lessons.isEmpty
                  ? const Text('Belum Ada Materi')
                  : Column(
                      children: [
                        for (final lesson in lessons)
                          _LessonTile(moduleId: id, lesson: lesson),
                      ],
                    ),
            ),
            const SizedBox(height: EmiSpacing.md),
            _InfoSection(
              title: 'Media dan Lampiran',
              rows: {'Lampiran': 'Dikelola pada materi sesuai jenis konten.'},
            ),
            const SizedBox(height: EmiSpacing.md),
            FilledButton(
              onPressed: () => context.push('/admin/modules/${item.id}/edit'),
              child: const Text('Edit Modul'),
            ),
            const SizedBox(height: EmiSpacing.sm),
            FilledButton.tonal(
              onPressed: () =>
                  context.push('/admin/modules/${item.id}/materials/create'),
              child: const Text('Tambah Materi'),
            ),
            const SizedBox(height: EmiSpacing.sm),
            OutlinedButton(
              onPressed: () => _showReorder(context, ref, item.id),
              child: const Text('Atur Urutan Materi'),
            ),
            const SizedBox(height: EmiSpacing.sm),
            Wrap(
              spacing: EmiSpacing.xs,
              children: [
                if (item.status != 'published')
                  OutlinedButton(
                    key: const Key('adminPublish-modules'),
                    onPressed: () => _confirmPublish(context, item),
                    child: const Text('Terbitkan'),
                  ),
                if (item.status == 'published')
                  OutlinedButton(
                    onPressed: () => _applyModule(context, item),
                    child: const Text('Terapkan ke Kelas'),
                  ),
                if (item.status != 'archived')
                  OutlinedButton(
                    key: const Key('adminArchive-modules'),
                    onPressed: () => _confirmArchive(context, item),
                    child: const Text('Arsipkan'),
                  ),
                OutlinedButton(
                  key: const Key('adminDelete-modules'),
                  onPressed: () => _confirmDelete(context, item),
                  child: const Text('Hapus'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.moduleId, required this.lesson});

  final String moduleId;
  final AdminLessonItem lesson;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(lesson.title, maxLines: 1, overflow: TextOverflow.ellipsis),
    subtitle: Row(
      children: [
        Flexible(
          child: Text(
            _contentLabel(lesson.contentType),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: EmiSpacing.xs),
        EmiStatusBadge(
          label: _statusLabel(lesson.status),
          tone: emiStatusToneFromKey(lesson.status),
        ),
      ],
    ),
    trailing: PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') {
          context.push('/admin/modules/$moduleId/materials/${lesson.id}/edit');
        }
        if (value == 'publish') {
          _confirmLessonPublish(context, moduleId, lesson);
        }
        if (value == 'archive') {
          _confirmLessonArchive(context, moduleId, lesson);
        }
        if (value == 'delete') _confirmLessonDelete(context, moduleId, lesson);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        if (lesson.status != 'published')
          const PopupMenuItem(value: 'publish', child: Text('Terbitkan')),
        if (lesson.status != 'archived')
          const PopupMenuItem(value: 'archive', child: Text('Arsipkan')),
        const PopupMenuItem(value: 'delete', child: Text('Hapus')),
      ],
    ),
  );
}

class AdminModuleFormScreen extends ConsumerStatefulWidget {
  const AdminModuleFormScreen({super.key, this.id});

  final String? id;

  @override
  ConsumerState<AdminModuleFormScreen> createState() =>
      _AdminModuleFormScreenState();
}

class _AdminModuleFormScreenState extends ConsumerState<AdminModuleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  String _status = 'draft';
  bool _filled = false;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.id == null
        ? null
        : ref.watch(adminModuleDetailProvider(widget.id!));
    return AdminShell(
      title: widget.id == null ? 'Tambah Modul' : 'Edit Modul',
      fallbackRoute: widget.id == null
          ? '/admin/modules'
          : '/admin/modules/${widget.id}',
      child: widget.id == null
          ? _form(null)
          : detail!.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const FriendlyState(
                icon: Icons.wifi_off_outlined,
                title: 'Data Modul Belum Bisa Dimuat',
                message: 'Periksa koneksi internet, lalu coba lagi.',
              ),
              data: _form,
            ),
    );
  }

  Widget _form(AdminModuleItem? item) {
    if (item != null && !_filled) {
      _title.text = item.title;
      _description.text = item.description;
      _status = item.status;
      _filled = true;
    }
    return PopScope(
      canPop: !_changed(item),
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _confirmLeave(context);
        if (!mounted || leave != true) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(
            widget.id == null
                ? '/admin/modules'
                : '/admin/modules/${widget.id}',
          );
        }
      },
      child: ListView(
        padding: const EdgeInsets.all(EmiSpacing.md),
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Gunakan judul yang singkat dan mudah dikenali.'),
                const SizedBox(height: EmiSpacing.md),
                _SectionTitle('Identitas Modul'),
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Judul'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Judul wajib diisi.'
                      : null,
                ),
                const SizedBox(height: EmiSpacing.lg),
                _SectionTitle('Deskripsi'),
                TextFormField(
                  controller: _description,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi',
                    helperText: 'Jelaskan isi dan tujuan Modul secara singkat.',
                  ),
                ),
                const SizedBox(height: EmiSpacing.lg),
                _SectionTitle('Status'),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    helperText:
                        'Draft belum dapat digunakan dalam pembelajaran. Terbit membutuhkan minimal satu materi terbit.',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'draft', child: Text('Draft')),
                    DropdownMenuItem(value: 'published', child: Text('Terbit')),
                    DropdownMenuItem(value: 'archived', child: Text('Arsip')),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _status = value ?? 'draft'),
                ),
                const SizedBox(height: EmiSpacing.xl),
                SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving ? null : () => _leave(),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: EmiSpacing.sm),
                      Expanded(
                        child: FilledButton(
                          key: const Key('adminSave-modules'),
                          onPressed: _saving ? null : () => _save(item),
                          child: Text(
                            _saving ? 'Menyimpan...' : 'Simpan Modul',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _changed(AdminModuleItem? item) =>
      _title.text.trim() != (item?.title ?? '') ||
      _description.text.trim() != (item?.description ?? '') ||
      _status != (item?.status ?? 'draft');

  Future<void> _save(AdminModuleItem? item) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final saved = await ref
          .read(adminModuleRepositoryProvider)
          .save(
            id: widget.id,
            request: AdminModuleSaveRequest(
              title: _title.text.trim(),
              description: _description.text.trim(),
              status: _status,
            ),
          );
      if (!mounted) return;
      ref.invalidate(adminModulesProvider);
      ref.invalidate(adminModuleSummaryProvider);
      ref.invalidate(adminModuleDetailProvider(saved.id));
      context.go('/admin/modules/${saved.id}');
    } catch (error) {
      if (!mounted) return;
      _showError(context, _friendlyError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _leave() async {
    if (!_changed(null) || await _confirmLeave(context) == true) {
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/admin/modules');
      }
    }
  }
}

class AdminLessonFormScreen extends ConsumerStatefulWidget {
  const AdminLessonFormScreen({super.key, required this.moduleId, this.id});

  final String moduleId;
  final String? id;

  @override
  ConsumerState<AdminLessonFormScreen> createState() =>
      _AdminLessonFormScreenState();
}

class _AdminLessonFormScreenState extends ConsumerState<AdminLessonFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _body = TextEditingController();
  final _url = TextEditingController();
  final _player = AudioPlayer();
  String _type = 'text';
  String _status = 'draft';
  String? _existingMediaId;
  String? _selectedPath;
  String? _selectedName;
  int? _selectedSize;
  double? _uploadProgress;
  bool _filled = false;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _body.dispose();
    _url.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lessons = ref.watch(adminModuleMaterialsProvider(widget.moduleId));
    return AdminShell(
      title: widget.id == null ? 'Tambah Materi' : 'Edit Materi',
      fallbackRoute: '/admin/modules/${widget.moduleId}',
      child: lessons.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const FriendlyState(
          icon: Icons.wifi_off_outlined,
          title: 'Materi Belum Bisa Dimuat',
          message: 'Periksa koneksi internet, lalu coba lagi.',
        ),
        data: (items) =>
            _form(items.where((item) => item.id == widget.id).firstOrNull),
      ),
    );
  }

  Widget _form(AdminLessonItem? item) {
    if (item != null && !_filled) {
      _title.text = item.title;
      _description.text = item.description;
      _body.text = item.contentBody;
      _url.text = item.externalUrl ?? '';
      _existingMediaId = item.mediaId;
      _type = item.contentType;
      _status = item.status;
      _filled = true;
    }
    return ListView(
      padding: const EdgeInsets.all(EmiSpacing.md),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionTitle('Identitas Materi'),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Judul'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Judul wajib diisi.'
                    : null,
              ),
              const SizedBox(height: EmiSpacing.md),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
              ),
              const SizedBox(height: EmiSpacing.lg),
              _SectionTitle('Konten Materi'),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Jenis Konten'),
                items: const [
                  DropdownMenuItem(value: 'text', child: Text('Teks')),
                  DropdownMenuItem(value: 'image', child: Text('Gambar')),
                  DropdownMenuItem(value: 'audio', child: Text('Audio')),
                  DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                  DropdownMenuItem(value: 'video', child: Text('Video')),
                  DropdownMenuItem(value: 'link', child: Text('Tautan')),
                ],
                onChanged: _saving
                    ? null
                    : (value) {
                        _player.stop();
                        setState(() {
                          _type = value ?? 'text';
                          _selectedPath = null;
                          _selectedName = null;
                          _selectedSize = null;
                          _uploadProgress = null;
                        });
                      },
              ),
              const SizedBox(height: EmiSpacing.md),
              if (_type == 'text')
                TextFormField(
                  controller: _body,
                  minLines: 6,
                  maxLines: 12,
                  decoration: const InputDecoration(labelText: 'Isi Materi'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Tambahkan isi materi terlebih dahulu.'
                      : null,
                ),
              if (['image', 'audio', 'pdf'].contains(_type)) _mediaPicker(item),
              if (['video', 'link'].contains(_type))
                TextFormField(
                  controller: _url,
                  decoration: const InputDecoration(labelText: 'Tautan Materi'),
                  validator: (value) =>
                      value == null || !value.trim().startsWith('https://')
                      ? 'Masukkan tautan yang valid.'
                      : null,
                ),
              const SizedBox(height: EmiSpacing.lg),
              _SectionTitle('Status'),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'draft', child: Text('Draft')),
                  DropdownMenuItem(value: 'published', child: Text('Terbit')),
                  DropdownMenuItem(value: 'archived', child: Text('Arsip')),
                ],
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _status = value ?? 'draft'),
              ),
              if (_uploadProgress != null) ...[
                const SizedBox(height: EmiSpacing.md),
                LinearProgressIndicator(value: _uploadProgress),
              ],
              const SizedBox(height: EmiSpacing.xl),
              SafeArea(
                child: FilledButton(
                  onPressed: _saving ? null : () => _save(item),
                  child: Text(_saving ? 'Menyimpan...' : 'Simpan Materi'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mediaPicker(AdminLessonItem? item) {
    final hasExisting = _selectedPath == null && _existingMediaId != null;
    final label = switch (_type) {
      'image' => 'Gambar',
      'audio' => 'Audio',
      _ => 'PDF',
    };
    return Container(
      padding: const EdgeInsets.all(EmiSpacing.md),
      decoration: BoxDecoration(
        color: EmiColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EmiColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            hasExisting ? '$label Saat Ini' : 'Belum Ada $label Dipilih',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: EmiSpacing.xs),
          if (_selectedName != null)
            Text('$_selectedName · ${_fileSize(_selectedSize ?? 0)}'),
          if (hasExisting)
            const Text('Media lama dipertahankan jika tidak diganti.'),
          if (_type == 'image' && _selectedPath != null) ...[
            const SizedBox(height: EmiSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(_selectedPath!),
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
          ],
          if (_type == 'audio' && _selectedPath != null) ...[
            const SizedBox(height: EmiSpacing.sm),
            Wrap(
              spacing: EmiSpacing.xs,
              children: [
                OutlinedButton(
                  onPressed: _playAudio,
                  child: const Text('Putar'),
                ),
                OutlinedButton(
                  onPressed: () => _player.pause(),
                  child: const Text('Jeda'),
                ),
                OutlinedButton(
                  onPressed: () => _player.stop(),
                  child: const Text('Berhenti'),
                ),
              ],
            ),
          ],
          const SizedBox(height: EmiSpacing.md),
          FilledButton.icon(
            onPressed: _saving ? null : _pickMedia,
            icon: const Icon(Icons.upload_file),
            label: Text(
              _selectedPath == null && !hasExisting ? 'Pilih $label' : 'Ganti',
            ),
          ),
          if (_selectedPath != null)
            TextButton(
              onPressed: _saving
                  ? null
                  : () {
                      _player.stop();
                      setState(() {
                        _selectedPath = null;
                        _selectedName = null;
                        _selectedSize = null;
                      });
                    },
              child: const Text('Hapus Pilihan'),
            ),
        ],
      ),
    );
  }

  Future<void> _pickMedia() async {
    final type = _type == 'image'
        ? FileType.image
        : _type == 'audio'
        ? FileType.audio
        : FileType.custom;
    final result = await FilePicker.platform.pickFiles(
      type: type,
      allowedExtensions: _type == 'pdf' ? const ['pdf'] : null,
      withData: false,
    );
    if (!mounted || result == null || result.files.single.path == null) return;
    final file = result.files.single;
    final max = switch (_type) {
      'image' => 5 * 1024 * 1024,
      'pdf' => 25 * 1024 * 1024,
      _ => 30 * 1024 * 1024,
    };
    if (file.size > max) {
      _showError(context, 'Ukuran file terlalu besar.');
      return;
    }
    setState(() {
      _selectedPath = file.path;
      _selectedName = file.name;
      _selectedSize = file.size;
      _uploadProgress = null;
    });
  }

  Future<void> _playAudio() async {
    final path = _selectedPath;
    if (path == null) return;
    try {
      await _player.setFilePath(path);
      await _player.play();
    } catch (_) {
      if (mounted) _showError(context, 'Audio belum bisa diputar.');
    }
  }

  Future<void> _save(AdminLessonItem? item) async {
    if (!_formKey.currentState!.validate()) return;
    final mediaRequired = ['image', 'audio', 'pdf'].contains(_type);
    if (mediaRequired && _selectedPath == null && _existingMediaId == null) {
      _showError(context, switch (_type) {
        'image' => 'Pilih gambar terlebih dahulu.',
        'audio' => 'Pilih audio terlebih dahulu.',
        _ => 'Pilih PDF terlebih dahulu.',
      });
      return;
    }
    setState(() => _saving = true);
    try {
      var mediaId = mediaRequired ? _existingMediaId ?? '' : '';
      if (_selectedPath != null) {
        final uploaded = await ref
            .read(adminModuleRepositoryProvider)
            .uploadMedia(
              path: _selectedPath!,
              name: _selectedName ?? 'media',
              purpose: switch (_type) {
                'image' => 'lesson_image',
                'audio' => 'audio',
                _ => 'document',
              },
              visibility: _type == 'image' ? 'public' : 'private',
              onProgress: (sent, total) {
                if (!mounted || total <= 0) return;
                setState(() => _uploadProgress = sent / total);
              },
            );
        mediaId = uploaded.id;
      }
      await ref
          .read(adminModuleRepositoryProvider)
          .saveLesson(
            moduleId: widget.moduleId,
            id: widget.id,
            request: AdminLessonSaveRequest(
              title: _title.text.trim(),
              description: _description.text.trim(),
              contentType: _type,
              contentBody: _body.text.trim(),
              mediaId: mediaId,
              externalUrl: _url.text.trim(),
              sortOrder: null,
              status: _status,
            ),
          );
      if (!mounted) return;
      ref.invalidate(adminModuleMaterialsProvider(widget.moduleId));
      ref.invalidate(adminModuleDetailProvider(widget.moduleId));
      ref.invalidate(adminModulesProvider);
      context.go('/admin/modules/${widget.moduleId}');
    } catch (error) {
      if (!mounted) return;
      _showError(context, _friendlyError(error));
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _uploadProgress = null;
        });
      }
    }
  }
}

Future<void> _showReorder(
  BuildContext context,
  WidgetRef ref,
  String moduleId,
) async {
  final lessons = ref.read(adminModuleMaterialsProvider(moduleId)).valueOrNull;
  if (lessons == null || lessons.length < 2) {
    _showError(context, 'Minimal dua materi dibutuhkan untuk mengatur urutan.');
    return;
  }
  final original = [...lessons]
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  final ordered = [...original];
  var saving = false;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(EmiSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Atur Urutan Materi',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: EmiSpacing.md),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: ordered.length,
                  itemBuilder: (context, index) {
                    final item = ordered[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Text('${index + 1}'),
                      title: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(_contentLabel(item.contentType)),
                      trailing: Wrap(
                        children: [
                          IconButton(
                            tooltip: 'Naik',
                            onPressed: saving || index == 0
                                ? null
                                : () => setSheetState(() {
                                    final current = ordered.removeAt(index);
                                    ordered.insert(index - 1, current);
                                  }),
                            icon: const Icon(Icons.arrow_upward),
                          ),
                          IconButton(
                            tooltip: 'Turun',
                            onPressed: saving || index == ordered.length - 1
                                ? null
                                : () => setSheetState(() {
                                    final current = ordered.removeAt(index);
                                    ordered.insert(index + 1, current);
                                  }),
                            icon: const Icon(Icons.arrow_downward),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: EmiSpacing.md),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        setSheetState(() => saving = true);
                        try {
                          await ref
                              .read(adminModuleRepositoryProvider)
                              .reorderLessons(
                                moduleId,
                                ordered.map((item) => item.id).toList(),
                              );
                          ref.invalidate(
                            adminModuleMaterialsProvider(moduleId),
                          );
                          ref.invalidate(adminModuleDetailProvider(moduleId));
                          if (context.mounted) Navigator.pop(context);
                        } catch (error) {
                          ordered
                            ..clear()
                            ..addAll(original);
                          setSheetState(() => saving = false);
                          if (context.mounted) {
                            _showError(
                              context,
                              'Urutan materi belum berhasil disimpan.',
                            );
                          }
                        }
                      },
                child: Text(saving ? 'Menyimpan...' : 'Simpan Urutan'),
              ),
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.rows});

  final String title;
  final Map<String, String> rows;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: EmiSpacing.sm),
      for (final row in rows.entries) ...[
        Text(row.key, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(row.value.isEmpty ? '-' : row.value),
        const Divider(),
      ],
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: EmiSpacing.sm),
    child: Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    ),
  );
}

class _StatText extends StatelessWidget {
  const _StatText(this.label, this.value);

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        '$value',
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(width: EmiSpacing.xs),
      Text(label),
    ],
  );
}

Future<void> _confirmPublish(BuildContext context, AdminModuleItem item) async {
  final ok = await _confirm(
    context,
    'Terbitkan Modul?',
    'Modul dapat digunakan sesuai aturan kelas dan pengguna.',
  );
  if (ok != true || !context.mounted) return;
  await _moduleAction(context, item.id, (repo) => repo.publish(item.id));
}

Future<void> _applyModule(BuildContext context, AdminModuleItem item) async {
  final container = ProviderScope.containerOf(context);
  final repository = container.read(adminModuleRepositoryProvider);
  List<AdminModuleClassTarget> classes;
  try {
    classes = await repository.activeClasses();
  } on AppError catch (error) {
    if (context.mounted) _message(context, error.message, error: true);
    return;
  }
  if (!context.mounted) return;
  if (classes.isEmpty) {
    _message(context, 'Belum ada kelas aktif.', error: true);
    return;
  }
  final selected = <String>{};
  final apply = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Terapkan Modul ke Kelas'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final target in classes)
                CheckboxListTile(
                  value: selected.contains(target.id),
                  title: Text(target.name),
                  onChanged: (checked) => setDialogState(() {
                    checked == true
                        ? selected.add(target.id)
                        : selected.remove(target.id);
                  }),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: selected.isEmpty
                ? null
                : () => Navigator.pop(context, true),
            child: const Text('Terapkan'),
          ),
        ],
      ),
    ),
  );
  if (apply != true || !context.mounted) return;
  try {
    await repository.apply(item.id, selected.toList());
    if (context.mounted) _message(context, 'Modul berhasil diterapkan.');
  } on AppError catch (error) {
    if (context.mounted) _message(context, error.message, error: true);
  }
}

void _message(BuildContext context, String text, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      backgroundColor: error ? EmiColors.error : null,
    ),
  );
}

Future<void> _confirmArchive(BuildContext context, AdminModuleItem item) async {
  final ok = await _confirm(
    context,
    'Arsipkan Modul ini?',
    'Modul tetap tersimpan, tetapi tidak dapat digunakan dalam pembelajaran.',
  );
  if (ok != true || !context.mounted) return;
  await _moduleAction(context, item.id, (repo) => repo.archive(item.id));
}

Future<void> _confirmDelete(BuildContext context, AdminModuleItem item) async {
  final ok = await _confirm(
    context,
    'Hapus Modul ini?',
    'Modul tidak lagi tampil pada daftar aktif, tetapi datanya tetap disimpan oleh sistem.',
  );
  if (ok != true || !context.mounted) return;
  await _moduleAction(context, item.id, (repo) => repo.delete(item.id));
  if (context.mounted) context.go('/admin/modules');
}

Future<void> _confirmLessonPublish(
  BuildContext context,
  String moduleId,
  AdminLessonItem item,
) async {
  final ok = await _confirm(
    context,
    'Terbitkan Materi?',
    'Materi dapat digunakan saat Modul diterbitkan.',
  );
  if (ok == true && context.mounted) {
    await _lessonAction(
      context,
      moduleId,
      (repo) => repo.publishLesson(item.id),
    );
  }
}

Future<void> _confirmLessonArchive(
  BuildContext context,
  String moduleId,
  AdminLessonItem item,
) async {
  final ok = await _confirm(
    context,
    'Arsipkan Materi?',
    'Materi tetap tersimpan pada Modul.',
  );
  if (ok == true && context.mounted) {
    await _lessonAction(
      context,
      moduleId,
      (repo) => repo.archiveLesson(item.id),
    );
  }
}

Future<void> _confirmLessonDelete(
  BuildContext context,
  String moduleId,
  AdminLessonItem item,
) async {
  final ok = await _confirm(
    context,
    'Hapus Materi?',
    'Materi akan dihapus dari Modul.',
  );
  if (ok == true && context.mounted) {
    await _lessonAction(
      context,
      moduleId,
      (repo) => repo.deleteLesson(item.id),
    );
  }
}

Future<void> _moduleAction(
  BuildContext context,
  String id,
  Future<Object?> Function(AdminModuleRepository repo) action,
) async {
  final container = ProviderScope.containerOf(context, listen: false);
  try {
    await action(container.read(adminModuleRepositoryProvider));
    container.invalidate(adminModulesProvider);
    container.invalidate(adminModuleSummaryProvider);
    container.invalidate(adminModuleDetailProvider(id));
  } catch (error) {
    if (context.mounted) _showError(context, _friendlyError(error));
  }
}

Future<void> _lessonAction(
  BuildContext context,
  String moduleId,
  Future<Object?> Function(AdminModuleRepository repo) action,
) async {
  final container = ProviderScope.containerOf(context, listen: false);
  try {
    await action(container.read(adminModuleRepositoryProvider));
    container.invalidate(adminModuleMaterialsProvider(moduleId));
    container.invalidate(adminModuleDetailProvider(moduleId));
    container.invalidate(adminModulesProvider);
  } catch (error) {
    if (context.mounted) _showError(context, _friendlyError(error));
  }
}

Future<bool?> _confirm(BuildContext context, String title, String message) =>
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lanjut'),
          ),
        ],
      ),
    );

Future<bool?> _confirmLeave(BuildContext context) => showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Batalkan perubahan?'),
    content: const Text('Perubahan yang belum disimpan akan hilang.'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Tetap di Halaman'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, true),
        child: const Text('Keluar'),
      ),
    ],
  ),
);

void _showError(BuildContext context, String message) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: Text(message)));

String _friendlyError(Object error) {
  if (error is AppError) {
    if (error.message.contains('MODULE_HAS_NO_PUBLISHED_LESSONS')) {
      return 'Modul Belum Siap Diterbitkan. Lengkapi materi dan informasi Modul terlebih dahulu.';
    }
    return error.message;
  }
  return 'Data Modul Belum Bisa Dimuat. Periksa koneksi internet, lalu coba lagi.';
}

String _statusLabel(String status) => switch (status) {
  'published' => 'Terbit',
  'archived' => 'Arsip',
  'inactive' => 'Tidak Aktif',
  'active' => 'Aktif',
  _ => 'Draft',
};

String _contentLabel(String type) => switch (type) {
  'image' => 'Gambar',
  'audio' => 'Audio',
  'pdf' => 'PDF',
  'video' => 'Video',
  'link' => 'Tautan',
  _ => 'Teks',
};

String _fileSize(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '$bytes B';
}

String _shortDate(String? value) {
  if (value == null || value.isEmpty) return '-';
  final parsed = DateTime.tryParse(value)?.toLocal();
  if (parsed == null) return '-';
  return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
}
