import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../core/errors/app_error.dart';
import '../../../shared/widgets/emi_card.dart';
import '../../../shared/widgets/role_dashboard_widgets.dart';
import '../../culture/data/culture_models.dart';
import '../data/teacher_providers.dart';
import 'teacher_shell.dart';

typedef TeacherCultureFilePicker = Future<PlatformFile?> Function(String type);
final teacherCultureFilePickerProvider = Provider<TeacherCultureFilePicker>(
  (_) =>
      (type) async => (await FilePicker.platform.pickFiles(
        type: type == 'image'
            ? FileType.image
            : type == 'audio'
            ? FileType.audio
            : type == 'video'
            ? FileType.video
            : FileType.custom,
        allowedExtensions: type == 'pdf' ? const ['pdf'] : null,
      ))?.files.single,
);

class TeacherCultureScreen extends ConsumerStatefulWidget {
  const TeacherCultureScreen({super.key, this.classId});
  final String? classId;

  @override
  ConsumerState<TeacherCultureScreen> createState() => _CultureScreenState();
}

class _CultureScreenState extends ConsumerState<TeacherCultureScreen> {
  String? selectedClassId;

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(teacherDashboardProvider);
    final classes = ref.watch(teacherClassesProvider((page: 1, search: '')));
    return TeacherShell(
      title: 'Budaya Mekongga',
      child: dashboard.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _Error(
          error: error,
          retry: () => ref.invalidate(teacherDashboardProvider),
        ),
        data: (summary) => classes.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _Error(
            error: error,
            retry: () =>
                ref.invalidate(teacherClassesProvider((page: 1, search: ''))),
          ),
          data: (classPage) {
            if (classPage.items.isEmpty) {
              return const FriendlyState(
                icon: Icons.school_outlined,
                title: 'Belum Ada Kelas Aktif',
                message: 'Anda belum memiliki kelas aktif yang ditugaskan.',
              );
            }
            final defaultId =
                classPage.items.any((e) => e.id == summary.classId)
                ? summary.classId!
                : classPage.items.first.id;
            final requestedId = selectedClassId ?? widget.classId;
            final classId = classPage.items.any((e) => e.id == requestedId)
                ? requestedId!
                : defaultId;
            final selectedClass = classPage.items.firstWhere(
              (e) => e.id == classId,
            );
            final page = ref.watch(teacherCultureProvider(classId));
            return RefreshIndicator(
              onRefresh: () =>
                  ref.refresh(teacherCultureProvider(classId).future),
              child: ListView(
                padding: const EdgeInsets.all(EmiSpacing.md),
                children: [
                  const Text('Kelola materi budaya untuk kelas Anda.'),
                  const SizedBox(height: EmiSpacing.md),
                  if (classPage.items.length > 1) ...[
                    DropdownButtonFormField<String>(
                      key: ValueKey(classId),
                      initialValue: classId,
                      decoration: const InputDecoration(labelText: 'Kelas'),
                      items: classPage.items
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.id,
                              child: Text(e.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => selectedClassId = value),
                    ),
                    const SizedBox(height: EmiSpacing.md),
                  ],
                  FilledButton.icon(
                    onPressed: () => context.push(
                      '/teacher/culture/create?classId=$classId',
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Budaya'),
                  ),
                  const SizedBox(height: EmiSpacing.md),
                  page.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => SizedBox(
                      height: 320,
                      child: _Error(
                        error: error,
                        retry: () =>
                            ref.invalidate(teacherCultureProvider(classId)),
                      ),
                    ),
                    data: (value) => value.items.isEmpty
                        ? const SizedBox(
                            height: 320,
                            child: FriendlyState(
                              icon: Icons.public_off_outlined,
                              title: 'Belum Ada Budaya',
                              message:
                                  'Tambahkan materi budaya pertama untuk kelas ini.',
                            ),
                          )
                        : Column(
                            children: [
                              for (final item in value.items)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: EmiSpacing.sm,
                                  ),
                                  child: _Tile(
                                    item: item,
                                    className: selectedClass.name,
                                    classId: classId,
                                  ),
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Tile extends StatefulWidget {
  const _Tile({
    required this.item,
    required this.className,
    required this.classId,
  });
  final CultureItem item;
  final String className;
  final String classId;
  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  bool busy = false;
  @override
  Widget build(BuildContext context) => EmiCard(
    padding: EdgeInsets.zero,
    child: InkWell(
      borderRadius: BorderRadius.circular(EmiRadii.card),
      onTap: busy
          ? null
          : () => context.push('/teacher/culture/${widget.item.id}'),
      child: Padding(
        padding: const EdgeInsets.all(EmiSpacing.sm),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child:
                  widget.item.contentType == 'image' &&
                      widget.item.contentUrl != null
                  ? Image.network(
                      widget.item.contentUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.broken_image_outlined),
                    )
                  : Icon(_icon(widget.item.contentType)),
            ),
            const SizedBox(width: EmiSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(widget.className),
                  Text(
                    '${_type(widget.item.contentType)} · ${_date(widget.item.updatedAt)}',
                  ),
                  _Badge(widget.item.status),
                ],
              ),
            ),
            PopupMenuButton<String>(
              enabled: !busy,
              onSelected: (action) async {
                if (busy) return;
                setState(() => busy = true);
                await _action(context, widget.item, action, widget.classId);
                if (mounted) setState(() => busy = false);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'view', child: Text('Lihat')),
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                if (widget.item.status != 'published')
                  const PopupMenuItem(
                    value: 'publish',
                    child: Text('Terbitkan'),
                  ),
                if (widget.item.status != 'archived')
                  const PopupMenuItem(
                    value: 'archive',
                    child: Text('Arsipkan'),
                  ),
                const PopupMenuItem(value: 'delete', child: Text('Hapus')),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class TeacherCultureDetailScreen extends ConsumerStatefulWidget {
  const TeacherCultureDetailScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<TeacherCultureDetailScreen> createState() =>
      _TeacherCultureDetailScreenState();
}

class _TeacherCultureDetailScreenState
    extends ConsumerState<TeacherCultureDetailScreen> {
  bool busy = false;
  @override
  Widget build(BuildContext context) => TeacherShell(
    title: 'Detail Budaya Mekongga',
    fallbackRoute: '/teacher/culture',
    child: ref
        .watch(teacherCultureDetailProvider(widget.id))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _Error(
            error: error,
            retry: () =>
                ref.invalidate(teacherCultureDetailProvider(widget.id)),
          ),
          data: (item) => ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child:
                        item.contentType == 'image' && item.contentUrl != null
                        ? Image.network(
                            item.contentUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                Icon(_icon(item.contentType)),
                          )
                        : Icon(_icon(item.contentType), size: 40),
                  ),
                  const SizedBox(width: EmiSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(item.schoolClass?.name ?? 'Kelas'),
                        _Badge(item.status),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    enabled: !busy,
                    onSelected: (a) async {
                      if (busy) return;
                      setState(() => busy = true);
                      await _action(context, item, a, item.classId);
                      if (mounted) setState(() => busy = false);
                    },
                    itemBuilder: (_) => [
                      if (item.status != 'published')
                        const PopupMenuItem(
                          value: 'publish',
                          child: Text('Terbitkan'),
                        ),
                      if (item.status != 'archived')
                        const PopupMenuItem(
                          value: 'archive',
                          child: Text('Arsipkan'),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Hapus'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: EmiSpacing.lg),
              Text(
                'Informasi Budaya',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              _Field(
                'Deskripsi',
                item.description?.isNotEmpty == true ? item.description! : '-',
              ),
              _Field('Jenis konten', _type(item.contentType)),
              _Field('Urutan tampil', '${item.displayOrder ?? 1}'),
              _Field('Status', _status(item.status)),
              _Field('Terakhir diubah', _date(item.updatedAt)),
              const SizedBox(height: EmiSpacing.lg),
              Text('Pratinjau', style: Theme.of(context).textTheme.titleLarge),
              if (item.contentType == 'image' && item.contentUrl != null)
                Image.network(
                  item.contentUrl!,
                  errorBuilder: (_, _, _) =>
                      const Text('Pratinjau gambar tidak tersedia.'),
                )
              else if (item.contentUrl != null)
                SelectableText(item.contentUrl!)
              else
                const Text('Pratinjau tidak tersedia.'),
              const SizedBox(height: EmiSpacing.lg),
              FilledButton(
                onPressed: () =>
                    context.push('/teacher/culture/${item.id}/edit'),
                child: const Text('Edit Budaya'),
              ),
            ],
          ),
        ),
  );
}

class TeacherCultureFormScreen extends ConsumerStatefulWidget {
  const TeacherCultureFormScreen({super.key, this.id, this.classId});
  final String? id;
  final String? classId;
  @override
  ConsumerState<TeacherCultureFormScreen> createState() => _FormState();
}

class _FormState extends ConsumerState<TeacherCultureFormScreen> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController(),
      description = TextEditingController(),
      url = TextEditingController(),
      order = TextEditingController(text: '1');
  String type = 'image', status = 'draft';
  String? mediaId, filePath, fileName, classId;
  bool hydrated = false, dirty = false, saving = false;
  static const mediaTypes = {'image', 'audio', 'pdf', 'video'};
  @override
  void dispose() {
    title.dispose();
    description.dispose();
    url.dispose();
    order.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.id == null
        ? null
        : ref.watch(teacherCultureDetailProvider(widget.id!));
    return TeacherShell(
      title: widget.id == null
          ? 'Tambah Budaya Mekongga'
          : 'Edit Budaya Mekongga',
      fallbackRoute: '/teacher/culture',
      onBack: _back,
      child: detail == null
          ? _body(null)
          : detail.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _Error(
                error: e,
                retry: () =>
                    ref.invalidate(teacherCultureDetailProvider(widget.id!)),
              ),
              data: _body,
            ),
    );
  }

  Widget _body(CultureItem? item) {
    if (item != null && !hydrated) {
      title.text = item.title;
      description.text = item.description ?? '';
      url.text = item.externalUrl ?? '';
      order.text = '${item.displayOrder ?? 1}';
      type = item.contentType;
      status = item.status;
      mediaId = item.media?.id;
      classId = item.classId;
      hydrated = true;
    }
    classId ??= widget.classId;
    return Form(
      key: form,
      onChanged: () {
        if (!dirty) setState(() => dirty = true);
      },
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(EmiSpacing.md),
              children: [
                Text(
                  'Informasi Budaya',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextFormField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Judul'),
                  validator: (v) =>
                      v?.trim().isEmpty != false ? 'Wajib diisi.' : null,
                ),
                const SizedBox(height: EmiSpacing.md),
                TextFormField(
                  controller: description,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                ),
                const SizedBox(height: EmiSpacing.md),
                DropdownButtonFormField<String>(
                  key: ValueKey('type-$type'),
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Jenis konten'),
                  items: _types
                      .map(
                        (e) =>
                            DropdownMenuItem(value: e, child: Text(_type(e))),
                      )
                      .toList(),
                  onChanged: (v) => setState(() {
                    type = v!;
                    dirty = true;
                  }),
                ),
                const SizedBox(height: 24),
                Text('Urutan', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: EmiSpacing.md),
                TextFormField(
                  controller: order,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Urutan tampil'),
                  validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1
                      ? 'Masukkan angka minimal 1.'
                      : null,
                ),
                const SizedBox(height: 24),
                Text(
                  'Media atau Tautan',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (mediaTypes.contains(type)) ...[
                  if (filePath != null && type == 'image')
                    Image.file(
                      File(filePath!),
                      height: 160,
                      errorBuilder: (_, _, _) =>
                          const Text('Pratinjau gambar tidak tersedia.'),
                    ),
                  if (mediaId != null &&
                      filePath == null &&
                      type == 'image' &&
                      item?.contentUrl != null)
                    Image.network(
                      item!.contentUrl!,
                      height: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const Text('Pratinjau gambar tidak tersedia.'),
                    ),
                  if (mediaId != null && filePath == null)
                    const Text('Media lama dipertahankan jika tidak diganti.'),
                  FilledButton.icon(
                    onPressed: saving ? null : _pick,
                    icon: const Icon(Icons.upload_file),
                    label: Text(
                      mediaId == null ? 'Pilih Media' : 'Ganti Media',
                    ),
                  ),
                ] else
                  TextFormField(
                    controller: url,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'URL eksternal',
                    ),
                    validator: (v) => Uri.tryParse(v ?? '')?.hasScheme == true
                        ? null
                        : 'Masukkan URL lengkap.',
                  ),
                const SizedBox(height: 24),
                Text('Status', style: Theme.of(context).textTheme.titleLarge),
                DropdownButtonFormField<String>(
                  key: ValueKey('status-$status'),
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'draft', child: Text('Draft')),
                    DropdownMenuItem(value: 'published', child: Text('Terbit')),
                    DropdownMenuItem(value: 'archived', child: Text('Arsip')),
                  ],
                  onChanged: (v) => setState(() {
                    status = v!;
                    dirty = true;
                  }),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(EmiSpacing.md),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: saving ? null : _save,
                child: Text(saving ? 'Menyimpan...' : 'Simpan'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pick() async {
    final file = await ref.read(teacherCultureFilePickerProvider)(type);
    if (!mounted || file?.path == null) return;
    final allowed = switch (type) {
      'image' => {'jpg', 'jpeg', 'png', 'webp'},
      'audio' => {'mp3', 'm4a', 'wav', 'ogg'},
      'video' => {'mp4', 'webm', 'mov'},
      _ => {'pdf'},
    };
    if (!allowed.contains(file!.extension?.toLowerCase())) {
      return _message('Format media tidak didukung.');
    }
    if (file.size <= 0 || file.size > 30 * 1024 * 1024) {
      return _message('Ukuran media harus antara 1 byte dan 30 MB.');
    }
    setState(() {
      filePath = file.path;
      fileName = file.name;
      dirty = true;
    });
  }

  Future<void> _save() async {
    if (saving || !form.currentState!.validate()) return;
    if (classId == null) return _message('Kelas aktif tidak tersedia.');
    if (mediaTypes.contains(type) && mediaId == null && filePath == null) {
      return _message('Pilih media terlebih dahulu.');
    }
    setState(() => saving = true);
    try {
      var nextMedia = mediaId;
      if (filePath != null) {
        nextMedia = await ref
            .read(teacherRepositoryProvider)
            .uploadCulture(filePath!, fileName!);
      }
      final saved = await ref
          .read(teacherRepositoryProvider)
          .saveCulture(
            classId: classId!,
            id: widget.id,
            data: {
              'title': title.text.trim(),
              'description': description.text.trim().isEmpty
                  ? null
                  : description.text.trim(),
              'content_type': type,
              'media_id': mediaTypes.contains(type) ? nextMedia : null,
              'external_url': mediaTypes.contains(type)
                  ? null
                  : url.text.trim(),
              'display_order': int.parse(order.text),
              'status': status,
            },
          );
      dirty = false;
      hydrated = true;
      final detail = await ref.refresh(
        teacherCultureDetailProvider(saved.id).future,
      );
      final page = await ref.refresh(teacherCultureProvider(classId!).future);
      hydrated = detail.id == saved.id && page.currentPage > 0;
      if (mounted) context.go('/teacher/culture/${saved.id}');
    } catch (e) {
      _message(
        e is AppError
            ? e.message
            : 'Konten budaya belum bisa disimpan. Silakan coba lagi.',
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _back() async {
    if (!dirty || await _leave()) {
      dirty = false;
      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/teacher/culture');
        }
      }
    }
  }

  Future<bool> _leave() async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Buang perubahan?'),
          content: const Text('Perubahan yang belum disimpan akan hilang.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Tetap di sini'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Buang'),
            ),
          ],
        ),
      ) ??
      false;
  void _message(String value) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(value)));
    }
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value);
  final String label, value;
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

class _Badge extends StatelessWidget {
  const _Badge(this.value);
  final String value;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Chip(
      label: Text(_status(value)),
      visualDensity: VisualDensity.compact,
    ),
  );
}

class _Error extends StatelessWidget {
  const _Error({required this.error, required this.retry});
  final Object error;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => FriendlyState(
    icon: Icons.error_outline,
    title: 'Budaya Belum Bisa Dimuat',
    message: 'Materi budaya belum bisa dimuat. Silakan coba lagi.',
    onRetry: retry,
  );
}

Future<void> _action(
  BuildContext context,
  CultureItem item,
  String action,
  String classId,
) async {
  if (action == 'view') {
    context.push('/teacher/culture/${item.id}');
    return;
  }
  if (action == 'edit') {
    context.push('/teacher/culture/${item.id}/edit');
    return;
  }
  final container = ProviderScope.containerOf(context);
  if (action != 'publish') {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(action == 'delete' ? 'Hapus Konten?' : 'Arsipkan Konten?'),
        content: Text(
          action == 'delete'
              ? 'Konten akan dihapus dan tidak dapat ditampilkan lagi.'
              : 'Konten akan disembunyikan dari siswa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(action == 'delete' ? 'Hapus' : 'Arsipkan'),
          ),
        ],
      ),
    );
    if (yes != true) return;
  }
  try {
    final repo = container.read(teacherRepositoryProvider);
    if (action == 'publish') await repo.publishCulture(item.id);
    if (action == 'archive') await repo.archiveCulture(item.id);
    if (action == 'delete') await repo.deleteCulture(item.id);
    await container.refresh(teacherCultureProvider(classId).future);
    if (action != 'delete') {
      await container.refresh(teacherCultureDetailProvider(item.id).future);
    }
    if (context.mounted && action == 'delete') context.go('/teacher/culture');
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is AppError
                ? e.message
                : 'Tindakan belum berhasil. Silakan coba lagi.',
          ),
        ),
      );
    }
  }
}

const _types = ['image', 'audio', 'pdf', 'video', 'youtube', 'article', 'link'];
String _type(String v) => switch (v) {
  'image' => 'Gambar',
  'audio' => 'Audio',
  'pdf' => 'Dokumen PDF',
  'video' => 'Video',
  'youtube' => 'YouTube',
  'article' => 'Artikel',
  _ => 'Tautan',
};
String _status(String v) => switch (v) {
  'published' => 'Terbit',
  'archived' => 'Arsip',
  _ => 'Draft',
};
IconData _icon(String v) => switch (v) {
  'audio' => Icons.audiotrack,
  'pdf' => Icons.picture_as_pdf,
  'video' || 'youtube' => Icons.play_circle_outline,
  'article' => Icons.article_outlined,
  'link' => Icons.link,
  _ => Icons.image_outlined,
};
String _date(DateTime? d) => d == null
    ? '-'
    : '${d.toLocal().day.toString().padLeft(2, '0')}/${d.toLocal().month.toString().padLeft(2, '0')}/${d.toLocal().year}';
