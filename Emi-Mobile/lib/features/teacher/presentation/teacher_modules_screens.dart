import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../core/errors/app_error.dart';
import '../../../shared/widgets/role_dashboard_widgets.dart';
import '../data/teacher_providers.dart';
import '../data/teacher_repository.dart';
import 'teacher_shell.dart';
import 'teacher_style.dart';
import 'teacher_widgets.dart';

class TeacherModulesScreen extends ConsumerWidget {
  const TeacherModulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(teacherDashboardProvider);
    final classId = dashboard.valueOrNull?.classId;
    if (dashboard.isLoading) {
      return const TeacherShell(title: 'Modul Kelas', child: _Loading());
    }
    if (dashboard.hasError) {
      return TeacherShell(
        title: 'Modul Kelas',
        child: _State(
          icon: Icons.wifi_off_outlined,
          title: 'Kelas aktif belum bisa dimuat',
          message: 'Periksa koneksi internet, lalu coba lagi.',
          onRetry: () => ref.invalidate(teacherDashboardProvider),
        ),
      );
    }
    if (classId == null || classId.isEmpty) {
      return const TeacherShell(
        title: 'Modul Kelas',
        child: _State(
          icon: Icons.school_outlined,
          title: 'Belum ada kelas aktif',
          message: 'Minta Admin menetapkan Anda ke kelas aktif.',
        ),
      );
    }
    final modules = ref.watch(teacherModulesProvider(classId));
    return TeacherShell(
      title: 'Modul Kelas',
      actions: [
        IconButton(
          tooltip: 'Ubah Urutan Modul',
          onPressed: () => _showReorderModulesDialog(context, ref, classId, modules.valueOrNull ?? const []),
          icon: const Icon(Icons.swap_vert),
        ),
        IconButton(
          tooltip: 'Tambah Modul',
          onPressed: () =>
              context.push('/teacher/modules/create?classId=$classId'),
          icon: const Icon(Icons.add),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(teacherModulesProvider(classId).future),
        child: modules.when(
          loading: () => const _Loading(),
          error: (_, _) => _State(
            icon: Icons.wifi_off_outlined,
            title: 'Modul belum bisa dimuat',
            message: 'Periksa koneksi internet, lalu coba lagi.',
            onRetry: () => ref.invalidate(teacherModulesProvider(classId)),
          ),
          data: (items) => items.isEmpty
              ? const _State(
                  icon: Icons.menu_book_outlined,
                  title: 'Modul belum tersedia',
                  message: 'Belum ada modul kelas yang bisa dikelola.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(EmiSpacing.md),
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: EmiSpacing.md),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return TeacherListCard(
                      padding: EdgeInsets.zero,
                      onTap: () =>
                          context.push('/teacher/modules/${item.id}/edit'),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: TeacherStyle.tint,
                          foregroundColor: EmiColors.primary,
                          child: const Icon(Icons.menu_book_outlined),
                        ),
                        title: Text(
                          item.title,
                          style: const TextStyle(color: TeacherStyle.ink),
                        ),
                        subtitle: Text(
                          '${_status(item.status)} • Urutan ${item.sortOrder}\n${item.lessons.length} materi',
                          style: const TextStyle(color: TeacherStyle.inkMuted),
                        ),
                        isThreeLine: true,
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: TeacherStyle.inkMuted,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class TeacherModuleCreateScreen extends ConsumerStatefulWidget {
  const TeacherModuleCreateScreen({super.key, required this.classId});
  final String classId;

  @override
  ConsumerState<TeacherModuleCreateScreen> createState() =>
      _TeacherModuleCreateScreenState();
}

class _TeacherModuleCreateScreenState
    extends ConsumerState<TeacherModuleCreateScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _sort = TextEditingController(text: '1');
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _sort.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TeacherShell(
    title: 'Tambah Modul',
    fallbackRoute: '/teacher/modules',
    child: Form(
      key: _form,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(EmiSpacing.md),
              children: [
                TeacherSectionHeader(
                  'Identitas Modul',
                  icon: Icons.menu_book_outlined,
                  leading: false,
                ),
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Judul Modul'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Judul wajib diisi.'
                      : null,
                ),
                const SizedBox(height: EmiSpacing.md),
                TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi Modul',
                  ),
                  minLines: 3,
                  maxLines: 6,
                ),
                TeacherSectionHeader('Urutan Tampil'),
                TextFormField(
                  controller: _sort,
                  decoration: const InputDecoration(labelText: 'Urutan Tampil'),
                  keyboardType: TextInputType.number,
                  validator: (value) => (int.tryParse(value ?? '') ?? 0) < 1
                      ? 'Urutan minimal 1.'
                      : null,
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.all(EmiSpacing.md),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Menyimpan...' : 'Simpan Modul'),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (widget.classId.isEmpty) {
      return _notice('Kelas aktif tidak tersedia.');
    }
    setState(() => _saving = true);
    try {
      await ref.read(teacherRepositoryProvider).createModule(widget.classId, {
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'sort_order': int.parse(_sort.text),
      });
      ref.invalidate(teacherModulesProvider(widget.classId));
      ref.invalidate(teacherDashboardProvider);
      if (mounted) context.go('/teacher/modules');
    } catch (error) {
      if (mounted) _notice(_error(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _notice(String value) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(value)));
}

class TeacherModuleEditScreen extends ConsumerStatefulWidget {
  const TeacherModuleEditScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<TeacherModuleEditScreen> createState() =>
      _TeacherModuleEditScreenState();
}

class _TeacherModuleEditScreenState
    extends ConsumerState<TeacherModuleEditScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _sort = TextEditingController();
  bool _filled = false;
  bool _saving = false;
  String _baselineTitle = '';
  String _baselineDescription = '';
  int _baselineSortOrder = 1;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _sort.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(teacherModuleDetailProvider(widget.id));
    return TeacherShell(
      title: 'Edit Modul',
      fallbackRoute: '/teacher/modules',
      child: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => FriendlyState(
          icon: Icons.wifi_off_outlined,
          title: 'Detail modul belum bisa dimuat',
          message: 'Periksa koneksi internet, lalu coba lagi.',
          onRetry: () => ref.invalidate(teacherModuleDetailProvider(widget.id)),
        ),
        data: _body,
      ),
    );
  }

  Widget _body(TeacherModule item) {
    if (!_filled) {
      _fill(item);
    }
    final dirty =
        _title.text.trim() != _baselineTitle ||
        _description.text.trim() != _baselineDescription ||
        _sort.text != '$_baselineSortOrder';
    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && await _leave() == true && mounted) {
          context.go('/teacher/modules');
        }
      },
      child: ListView(
        padding: const EdgeInsets.all(EmiSpacing.md),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TeacherStatusChip(label: _status(item.status)),
          ),
          TeacherSectionHeader(
            'Identitas Modul',
            icon: Icons.menu_book_outlined,
            leading: false,
          ),
          Form(
            key: _form,
            child: Column(
              children: [
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Judul Modul'),
                  onChanged: (_) => setState(() {}),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Judul wajib diisi.'
                      : null,
                ),
                const SizedBox(height: EmiSpacing.md),
                TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi Modul',
                  ),
                  minLines: 3,
                  maxLines: 6,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: EmiSpacing.md),
                TextFormField(
                  controller: _sort,
                  decoration: const InputDecoration(labelText: 'Urutan Tampil'),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  validator: (value) => (int.tryParse(value ?? '') ?? 0) < 1
                      ? 'Urutan minimal 1.'
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: EmiSpacing.lg),
          FilledButton(
            onPressed: _saving ? null : () => _save(item),
            child: Text(_saving ? 'Menyimpan...' : 'Simpan Perubahan'),
          ),
          const SizedBox(height: EmiSpacing.sm),
          Wrap(
            spacing: EmiSpacing.sm,
            runSpacing: EmiSpacing.sm,
            children: [
              if (item.status != 'published')
                OutlinedButton(
                  onPressed: _saving ? null : () => _publish(item),
                  child: const Text('Terbitkan Modul'),
                ),
              if (item.status != 'archived')
                OutlinedButton(
                  onPressed: _saving ? null : () => _archive(item),
                  child: const Text('Arsipkan Modul'),
                ),
              if (item.status == 'draft')
                OutlinedButton(
                  onPressed: _saving ? null : () => _delete(item),
                  child: const Text('Hapus Draft'),
                ),
            ],
          ),
          TeacherSectionHeader(
            'Daftar Materi',
            subtitle: 'Kelola urutan dan isi materi yang termasuk modul ini.',
            icon: Icons.article_outlined,
            trailing: Wrap(
              spacing: EmiSpacing.xs,
              children: [
                if (item.lessons.length > 1)
                  IconButton(
                    tooltip: 'Ubah Urutan Materi',
                    onPressed: () => _showReorderLessonsDialog(context, ref, item.id, item.lessons),
                    icon: const Icon(Icons.swap_vert),
                  ),
                FilledButton.icon(
                  onPressed: () =>
                      context.push('/teacher/modules/${item.id}/lessons/create'),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Materi'),
                ),
              ],
            ),
          ),
          if (item.lessons.isEmpty)
            TeacherListCard(
              child: Text(
                'Modul ini belum memiliki materi.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: EmiColors.textSecondary,
                ),
              ),
            )
          else
            for (final lesson in item.lessons) ...[
              TeacherListCard(
                padding: EdgeInsets.zero,
                onTap: () => context.push(
                  '/teacher/modules/${item.id}/lessons/${lesson.id}/preview',
                ),
                child: ListTile(
                  title: Text(
                    lesson.title,
                    style: const TextStyle(color: TeacherStyle.ink),
                  ),
                  subtitle: Text(
                    '${_contentLabel(lesson.contentType)} • ${_status(lesson.status)} • Urutan ${lesson.sortOrder}',
                    style: const TextStyle(color: TeacherStyle.inkMuted),
                  ),
                  trailing: IconButton(
                    onPressed: () => context.push(
                      '/teacher/modules/${item.id}/lessons/${lesson.id}/edit',
                    ),
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: TeacherStyle.inkMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: EmiSpacing.sm),
            ],
        ],
      ),
    );
  }

  Future<void> _save(TeacherModule item) async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updated = await ref
          .read(teacherRepositoryProvider)
          .updateModule(item.id, {
            'title': _title.text.trim(),
            'description': _description.text.trim(),
            'sort_order': int.parse(_sort.text),
          });
      _fill(updated);
      final refreshed = await ref.refresh(
        teacherModuleDetailProvider(item.id).future,
      );
      _fill(refreshed);
      if (item.classId != null) {
        final _ = await ref.refresh(
          teacherModulesProvider(item.classId!).future,
        );
      }
      final _ = await ref.refresh(teacherDashboardProvider.future);
      if (mounted) _notice('Modul berhasil disimpan.');
    } catch (error) {
      if (mounted) _notice(_error(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _publish(TeacherModule item) async {
    if (await _confirm(
          context,
          'Terbitkan modul?',
          'Modul dapat diakses siswa setelah diterbitkan.',
        ) !=
        true) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(teacherRepositoryProvider).publishModule(item.id);
      ref.invalidate(teacherModuleDetailProvider(item.id));
      if (item.classId != null) {
        ref.invalidate(teacherModulesProvider(item.classId!));
      }
      ref.invalidate(teacherDashboardProvider);
      if (mounted) _notice('Modul berhasil diterbitkan.');
    } catch (error) {
      if (mounted) _notice(_error(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _archive(TeacherModule item) async {
    if (await _confirm(
          context,
          'Arsipkan modul?',
          'Modul tidak lagi tersedia untuk pembelajaran aktif.',
        ) !=
        true) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(teacherRepositoryProvider).archiveModule(item.id);
      ref.invalidate(teacherModuleDetailProvider(item.id));
      if (item.classId != null) {
        ref.invalidate(teacherModulesProvider(item.classId!));
      }
      ref.invalidate(teacherDashboardProvider);
      if (mounted) _notice('Modul berhasil diarsipkan.');
    } catch (error) {
      if (mounted) _notice(_error(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(TeacherModule item) async {
    if (await _confirm(
          context,
          'Hapus draft modul?',
          'Draft hanya dapat dihapus jika belum memiliki progress siswa.',
        ) !=
        true) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(teacherRepositoryProvider).deleteModule(item.id);
      if (item.classId != null) {
        ref.invalidate(teacherModulesProvider(item.classId!));
      }
      ref.invalidate(teacherDashboardProvider);
      if (mounted) context.go('/teacher/modules');
    } catch (error) {
      if (mounted) _notice(_error(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _fill(TeacherModule item) {
    _title.text = item.title;
    _description.text = item.description;
    _sort.text = '${item.sortOrder}';
    _baselineTitle = item.title;
    _baselineDescription = item.description;
    _baselineSortOrder = item.sortOrder;
    _filled = true;
  }

  Future<bool?> _leave() => _confirm(
    context,
    'Batalkan perubahan?',
    'Perubahan yang belum disimpan akan hilang.',
  );
  void _notice(String value) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(value)));
}

class TeacherModulePreviewScreen extends ConsumerWidget {
  const TeacherModulePreviewScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) => TeacherShell(
    title: 'Preview Modul',
    fallbackRoute: '/teacher/modules/$id/edit',
    child: ref
        .watch(teacherModuleDetailProvider(id))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _State(
            icon: Icons.error_outline,
            title: 'Preview belum bisa dimuat',
            message: 'Periksa koneksi internet, lalu coba lagi.',
            onRetry: () => ref.invalidate(teacherModuleDetailProvider(id)),
          ),
          data: (module) => ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              TeacherPageHeader(
                icon: Icons.visibility_outlined,
                title: module.title,
                subtitle: module.description.isEmpty
                    ? 'Tampilan modul untuk siswa'
                    : module.description,
              ),
              const SizedBox(height: EmiSpacing.sm),
              Wrap(
                spacing: EmiSpacing.sm,
                children: [
                  TeacherStatusChip(label: _status(module.status)),
                  TeacherStatusChip(label: '${module.lessons.length} materi'),
                ],
              ),
              TeacherSectionHeader('Materi'),
              if (module.lessons.isEmpty)
                const TeacherListCard(
                  child: Text('Modul ini belum memiliki materi.'),
                )
              else
                for (var index = 0; index < module.lessons.length; index++) ...[
                  TeacherListCard(
                    padding: EdgeInsets.zero,
                    onTap: () => context.push(
                      '/teacher/modules/$id/lessons/${module.lessons[index].id}/preview',
                    ),
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text(module.lessons[index].title),
                      subtitle: Text(
                        '${_contentLabel(module.lessons[index].contentType)} • ${_status(module.lessons[index].status)}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                  const SizedBox(height: EmiSpacing.sm),
                ],
            ],
          ),
        ),
  );
}

class TeacherLessonPreviewScreen extends ConsumerStatefulWidget {
  const TeacherLessonPreviewScreen({
    super.key,
    required this.moduleId,
    required this.id,
  });
  final String moduleId;
  final String id;
  @override
  ConsumerState<TeacherLessonPreviewScreen> createState() =>
      _TeacherLessonPreviewScreenState();
}

class _TeacherLessonPreviewScreenState
    extends ConsumerState<TeacherLessonPreviewScreen> {
  final player = AudioPlayer();
  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TeacherShell(
    title: 'Preview Materi',
    fallbackRoute: '/teacher/modules/${widget.moduleId}/edit',
    child: ref
        .watch(teacherLessonContentProvider(widget.id))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _State(
            icon: Icons.error_outline,
            title: 'Preview belum bisa dimuat',
            message: 'Muat ulang untuk mendapatkan tautan media baru.',
            onRetry: () =>
                ref.invalidate(teacherLessonContentProvider(widget.id)),
          ),
          data: (content) => ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              if (content.type == 'text')
                SelectableText(content.contentBody ?? 'Konten belum tersedia.')
              else if (content.type == 'image' && content.url != null)
                Image.network(
                  content.url!,
                  errorBuilder: (_, _, _) =>
                      const Text('Gambar tidak dapat ditampilkan.'),
                )
              else if (content.type == 'audio' && content.url != null)
                FilledButton.icon(
                  onPressed: () async {
                    try {
                      await player.setUrl(content.url!);
                      await player.play();
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Audio tidak dapat diputar.'),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Putar Audio'),
                )
              else if (content.url != null)
                FilledButton.icon(
                  onPressed: () => _open(content.url!),
                  icon: const Icon(Icons.open_in_new),
                  label: Text(
                    content.type == 'pdf' ? 'Buka PDF' : 'Buka Materi',
                  ),
                )
              else
                const Text('Konten belum tersedia.'),
            ],
          ),
        ),
  );

  Future<void> _open(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Materi tidak dapat dibuka.')),
        );
      }
    }
  }
}

class TeacherLessonCreateScreen extends ConsumerStatefulWidget {
  const TeacherLessonCreateScreen({super.key, required this.moduleId});
  final String moduleId;

  @override
  ConsumerState<TeacherLessonCreateScreen> createState() =>
      _TeacherLessonCreateScreenState();
}

class _TeacherLessonCreateScreenState
    extends ConsumerState<TeacherLessonCreateScreen> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController();
  final description = TextEditingController();
  final content = TextEditingController();
  final url = TextEditingController();
  final sort = TextEditingController(text: '1');
  String type = 'text';
  String? mediaId;
  String? mediaName;
  bool saving = false;

  @override
  void dispose() {
    for (final controller in [title, description, content, url, sort]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TeacherShell(
    title: 'Tambah Materi',
    fallbackRoute: '/teacher/modules/${widget.moduleId}/edit',
    child: Form(
      key: form,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(EmiSpacing.md),
              children: [
                TeacherSectionHeader(
                  'Identitas Materi',
                  icon: Icons.article_outlined,
                  leading: false,
                ),
                TextFormField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Judul Materi'),
                  validator: (value) => value?.trim().isEmpty != false
                      ? 'Judul wajib diisi.'
                      : null,
                ),
                const SizedBox(height: EmiSpacing.md),
                TextFormField(
                  controller: description,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi Singkat',
                  ),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: EmiSpacing.lg),
                TeacherSectionHeader('Jenis Konten'),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Jenis Konten'),
                  items: const [
                    DropdownMenuItem(value: 'text', child: Text('Teks')),
                    DropdownMenuItem(value: 'image', child: Text('Gambar')),
                    DropdownMenuItem(value: 'audio', child: Text('Audio')),
                    DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                    DropdownMenuItem(value: 'video', child: Text('Video URL')),
                    DropdownMenuItem(value: 'link', child: Text('Tautan')),
                  ],
                  onChanged: (value) => setState(() => type = value!),
                ),
                if (type == 'text') ...[
                  const SizedBox(height: EmiSpacing.md),
                  TextFormField(
                    controller: content,
                    decoration: const InputDecoration(labelText: 'Isi Materi'),
                    minLines: 5,
                    maxLines: 12,
                    validator: (value) => value?.trim().isEmpty != false
                        ? 'Isi materi wajib diisi.'
                        : null,
                  ),
                ],
                if (type == 'video' || type == 'link') ...[
                  const SizedBox(height: EmiSpacing.md),
                  TextFormField(
                    controller: url,
                    decoration: const InputDecoration(labelText: 'URL HTTPS'),
                    keyboardType: TextInputType.url,
                    validator: (value) {
                      final uri = Uri.tryParse(value ?? '');
                      return uri?.scheme == 'https'
                          ? null
                          : 'Masukkan URL HTTPS yang valid.';
                    },
                  ),
                ],
                if (type == 'image' || type == 'audio' || type == 'pdf') ...[
                  const SizedBox(height: EmiSpacing.md),
                  TeacherListCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(mediaName ?? 'Media belum dipilih'),
                        const SizedBox(height: EmiSpacing.sm),
                        FilledButton.icon(
                          onPressed: saving ? null : _pick,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Pilih dan Unggah Media'),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: EmiSpacing.lg),
                TeacherSectionHeader('Urutan Tampil'),
                TextFormField(
                  controller: sort,
                  decoration: const InputDecoration(labelText: 'Urutan Tampil'),
                  keyboardType: TextInputType.number,
                  validator: (value) => (int.tryParse(value ?? '') ?? 0) < 1
                      ? 'Urutan minimal 1.'
                      : null,
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.all(EmiSpacing.md),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: saving ? null : _save,
                child: Text(saving ? 'Menyimpan...' : 'Simpan Materi'),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: type == 'image'
          ? const ['jpg', 'jpeg', 'png', 'webp']
          : type == 'audio'
          ? const ['mp3', 'wav', 'm4a']
          : const ['pdf'],
    );
    final file = result?.files.single;
    if (file?.path == null) return;
    setState(() => saving = true);
    try {
      final media = await ref
          .read(teacherRepositoryProvider)
          .uploadMedia(
            file!.path!,
            file.name,
            purpose: type == 'image'
                ? 'lesson_image'
                : type == 'audio'
                ? 'audio'
                : 'document',
          );
      if (mounted) {
        setState(() {
          mediaId = media.id;
          mediaName = media.name;
        });
      }
    } catch (error) {
      if (mounted) _notice(_error(error));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _save() async {
    if (!form.currentState!.validate()) return;
    if ({'image', 'audio', 'pdf'}.contains(type) && mediaId == null) {
      return _notice('Pilih media terlebih dahulu.');
    }
    setState(() => saving = true);
    try {
      await ref.read(teacherRepositoryProvider).createLesson(widget.moduleId, {
        'title': title.text.trim(),
        'description': description.text.trim(),
        'content_type': type,
        if (type == 'text') 'content_body': content.text.trim(),
        if (type == 'video' || type == 'link') 'external_url': url.text.trim(),
        if ({'image', 'audio', 'pdf'}.contains(type)) 'media_id': mediaId,
        'sort_order': int.parse(sort.text),
      });
      final _ = await ref.refresh(
        teacherModuleDetailProvider(widget.moduleId).future,
      );
      if (mounted) context.go('/teacher/modules/${widget.moduleId}/edit');
    } catch (error) {
      if (mounted) _notice(_error(error));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _notice(String value) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(value)));
}

class TeacherLessonEditScreen extends ConsumerStatefulWidget {
  const TeacherLessonEditScreen({
    super.key,
    required this.moduleId,
    required this.id,
  });
  final String moduleId;
  final String id;

  @override
  ConsumerState<TeacherLessonEditScreen> createState() =>
      _TeacherLessonEditScreenState();
}

class _TeacherLessonEditScreenState
    extends ConsumerState<TeacherLessonEditScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _content = TextEditingController();
  final _url = TextEditingController();
  final _sort = TextEditingController();
  bool _filled = false;
  bool _saving = false;
  String? _mediaId;
  String? _mediaName;
  String? _contentType;

  @override
  void dispose() {
    for (final controller in [_title, _description, _content, _url, _sort]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TeacherShell(
    title: 'Edit Materi',
    fallbackRoute: '/teacher/modules/${widget.moduleId}/edit',
    child: ref
        .watch(teacherLessonDetailProvider(widget.id))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => FriendlyState(
            icon: Icons.wifi_off_outlined,
            title: 'Materi belum bisa dimuat',
            message: 'Periksa koneksi internet, lalu coba lagi.',
            onRetry: () =>
                ref.invalidate(teacherLessonDetailProvider(widget.id)),
          ),
          data: _body,
        ),
  );

  Widget _body(TeacherLesson item) {
    if (!_filled) {
      _fill(item);
    }
    final dirty =
        _title.text.trim() != item.title ||
        _description.text.trim() != item.description ||
        _content.text.trim() != item.contentBody ||
        _url.text.trim() != (item.externalUrl ?? '') ||
        _sort.text != '${item.sortOrder}' ||
        _mediaId != item.mediaId ||
        _contentType != item.contentType;
    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop &&
            await _confirm(
                  context,
                  'Batalkan perubahan?',
                  'Perubahan yang belum disimpan akan hilang.',
                ) ==
                true &&
            mounted) {
          context.go('/teacher/modules/${widget.moduleId}/edit');
        }
      },
      child: ListView(
        padding: const EdgeInsets.all(EmiSpacing.md),
        children: [
          Wrap(
            spacing: EmiSpacing.xs,
            children: [
              TeacherStatusChip(label: _status(item.status)),
              TeacherStatusChip(
                label: _contentLabel(_contentType ?? item.contentType),
                color: TeacherStyle.tint,
              ),
            ],
          ),
          TeacherSectionHeader(
            'Identitas Materi',
            icon: Icons.article_outlined,
            leading: false,
          ),
          Form(
            key: _form,
            child: Column(
              children: [
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Judul Materi'),
                  onChanged: (_) => setState(() {}),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Judul wajib diisi.'
                      : null,
                ),
                const SizedBox(height: EmiSpacing.md),
                TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi Singkat',
                  ),
                  minLines: 2,
                  maxLines: 4,
                  onChanged: (_) => setState(() {}),
                ),
                if ((_contentType ?? item.contentType) == 'text') ...[
                  const SizedBox(height: EmiSpacing.md),
                  TextFormField(
                    controller: _content,
                    decoration: const InputDecoration(labelText: 'Isi Materi'),
                    minLines: 5,
                    maxLines: 12,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
                if ((_contentType ?? item.contentType) == 'video' ||
                    (_contentType ?? item.contentType) == 'link') ...[
                  const SizedBox(height: EmiSpacing.md),
                  TextFormField(
                    controller: _url,
                    decoration: const InputDecoration(
                      labelText: 'URL Eksternal',
                    ),
                    keyboardType: TextInputType.url,
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      final uri = Uri.tryParse(value ?? '');
                      return uri != null && uri.scheme == 'https'
                          ? null
                          : 'Masukkan URL HTTPS yang valid.';
                    },
                  ),
                ],
                const SizedBox(height: EmiSpacing.md),
                TextFormField(
                  controller: _sort,
                  decoration: const InputDecoration(labelText: 'Urutan Tampil'),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  validator: (value) => (int.tryParse(value ?? '') ?? 0) < 1
                      ? 'Urutan minimal 1.'
                      : null,
                ),
              ],
            ),
          ),
          TeacherSectionHeader('Media Lampiran', icon: Icons.attach_file),
          TeacherListCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _mediaId == null
                      ? 'Tidak ada media terlampir'
                      : (_mediaName ?? item.mediaType ?? 'Media terlampir'),
                ),
                const SizedBox(height: EmiSpacing.sm),
                FilledButton.icon(
                  onPressed: _saving ? null : () => _pick(item),
                  icon: const Icon(Icons.upload_file),
                  label: Text(
                    _mediaId == null ? 'Unggah Media' : 'Ganti Media',
                  ),
                ),
                if (_mediaId != null)
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => setState(() {
                            _mediaId = null;
                            _mediaName = null;
                          }),
                    child: const Text('Hapus Lampiran'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: EmiSpacing.lg),
          OutlinedButton.icon(
            onPressed: () =>
                context.push('/teacher/modules/${item.id}/preview'),
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Preview Modul'),
          ),
          const SizedBox(height: EmiSpacing.sm),
          FilledButton(
            onPressed: _saving ? null : () => _save(item),
            child: Text(_saving ? 'Menyimpan...' : 'Simpan Perubahan'),
          ),
          if (item.status != 'published') ...[
            const SizedBox(height: EmiSpacing.sm),
            OutlinedButton(
              onPressed: _saving ? null : () => _publish(item),
              child: const Text('Terbitkan Materi'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pick(TeacherLesson item) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'jpg',
        'jpeg',
        'png',
        'mp3',
        'wav',
        'm4a',
        'pdf',
      ],
    );
    final file = result?.files.single;
    if (file?.path == null) {
      return;
    }
    final contentType = _contentTypeForExtension(file!.extension);
    setState(() => _saving = true);
    try {
      final media = await ref
          .read(teacherRepositoryProvider)
          .uploadMedia(
            file.path!,
            file.name,
            purpose: _mediaPurpose(contentType),
          );
      if (mounted) {
        setState(() {
          _mediaId = media.id;
          _mediaName = media.name;
          _contentType = contentType;
        });
      }
    } catch (error) {
      if (mounted) _notice(_error(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save(TeacherLesson item) async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final contentType = _contentType ?? item.contentType;
      final updated = await ref
          .read(teacherRepositoryProvider)
          .updateLesson(item.id, {
            'title': _title.text.trim(),
            'description': _description.text.trim(),
            'content_type': contentType,
            if (contentType == 'text') 'content_body': _content.text.trim(),
            if (contentType == 'video' || contentType == 'link')
              'external_url': _url.text.trim(),
            'sort_order': int.parse(_sort.text),
            'media_id': _mediaId,
          });
      _fill(updated);
      final refreshedLesson = await ref.refresh(
        teacherLessonDetailProvider(item.id).future,
      );
      final module = await ref.refresh(
        teacherModuleDetailProvider(widget.moduleId).future,
      );
      if (module.classId != null) {
        ref.invalidate(teacherModulesProvider(module.classId!));
      }
      ref.invalidate(teacherDashboardProvider);
      _fill(refreshedLesson);
      if (mounted) {
        _notice('Materi berhasil disimpan.');
      }
    } catch (error) {
      if (mounted) _notice(_error(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _publish(TeacherLesson item) async {
    if (await _confirm(
          context,
          'Terbitkan materi?',
          'Materi dapat digunakan saat modul diterbitkan.',
        ) !=
        true) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(teacherRepositoryProvider).publishLesson(item.id);
      ref.invalidate(teacherLessonDetailProvider(item.id));
      ref.invalidate(teacherModuleDetailProvider(widget.moduleId));
      if (mounted) _notice('Materi berhasil diterbitkan.');
    } catch (error) {
      if (mounted) _notice(_error(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _fill(TeacherLesson item) {
    _title.text = item.title;
    _description.text = item.description;
    _content.text = item.contentBody;
    _url.text = item.externalUrl ?? '';
    _sort.text = '${item.sortOrder}';
    _mediaId = item.mediaId;
    _mediaName = item.mediaName;
    _contentType = item.contentType;
    _filled = true;
  }

  void _notice(String value) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(value)));

  String _contentTypeForExtension(String? extension) =>
      switch (extension?.toLowerCase()) {
        'pdf' => 'pdf',
        'jpg' || 'jpeg' || 'png' || 'webp' => 'image',
        'mp3' || 'wav' || 'm4a' => 'audio',
        _ => 'document',
      };

  String _mediaPurpose(String contentType) => switch (contentType) {
    'image' => 'lesson_image',
    'pdf' => 'document',
    'audio' => 'audio',
    _ => 'document',
  };
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const _State(
    icon: Icons.hourglass_empty,
    title: 'Memuat modul kelas',
    message: 'Mohon tunggu.',
  );
}

class _State extends StatelessWidget {
  const _State({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      SizedBox(
        height: 480,
        child: onRetry == null && icon == Icons.hourglass_empty
            ? const Center(child: CircularProgressIndicator())
            : FriendlyState(
                icon: icon,
                title: title,
                message: message,
                onRetry: onRetry,
              ),
      ),
    ],
  );
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
void _showReorderModulesDialog(
  BuildContext context,
  WidgetRef ref,
  String classId,
  List<TeacherModule> initialModules,
) {
  if (initialModules.length < 2) return;
  final ordered = List<TeacherModule>.from(initialModules);
  bool saving = false;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) {
        return Padding(
          padding: const EdgeInsets.all(EmiSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ubah Urutan Modul',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: EmiSpacing.xs),
              const Text('Tahan dan geser item untuk mengubah urutan pengerjaan modul.'),
              const SizedBox(height: EmiSpacing.md),
              SizedBox(
                height: 320,
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  itemCount: ordered.length,
                  onReorder: (oldIndex, newIndex) {
                    setModalState(() {
                      var targetIndex = newIndex;
                      if (oldIndex < targetIndex) targetIndex -= 1;
                      final item = ordered.removeAt(oldIndex);
                      ordered.insert(targetIndex, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    final module = ordered[index];
                    return ListTile(
                      key: ValueKey(module.id),
                      leading: CircleAvatar(
                        backgroundColor: TeacherStyle.tint,
                        foregroundColor: EmiColors.primary,
                        child: Text('${index + 1}'),
                      ),
                      title: Text(module.title),
                      trailing: const Icon(Icons.drag_handle),
                    );
                  },
                ),
              ),
              const SizedBox(height: EmiSpacing.md),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        setModalState(() => saving = true);
                        try {
                          await ref.read(teacherRepositoryProvider).reorderModules(
                                classId,
                                ordered.map((e) => e.id).toList(),
                              );
                          ref.invalidate(teacherModulesProvider(classId));
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          setModalState(() => saving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(_error(e))),
                            );
                          }
                        }
                      },
                child: Text(saving ? 'Menyimpan...' : 'Simpan Urutan Modul'),
              ),
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
            ],
          ),
        );
      },
    ),
  );
}

void _showReorderLessonsDialog(
  BuildContext context,
  WidgetRef ref,
  String moduleId,
  List<TeacherLesson> initialLessons,
) {
  if (initialLessons.length < 2) return;
  final ordered = List<TeacherLesson>.from(initialLessons);
  bool saving = false;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) {
        return Padding(
          padding: const EdgeInsets.all(EmiSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ubah Urutan Materi',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: EmiSpacing.xs),
              const Text('Tahan dan geser item untuk mengubah urutan alur materi.'),
              const SizedBox(height: EmiSpacing.md),
              SizedBox(
                height: 320,
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  itemCount: ordered.length,
                  onReorder: (oldIndex, newIndex) {
                    setModalState(() {
                      var targetIndex = newIndex;
                      if (oldIndex < targetIndex) targetIndex -= 1;
                      final item = ordered.removeAt(oldIndex);
                      ordered.insert(targetIndex, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    final lesson = ordered[index];
                    return ListTile(
                      key: ValueKey(lesson.id),
                      leading: CircleAvatar(
                        backgroundColor: TeacherStyle.tint,
                        foregroundColor: EmiColors.primary,
                        child: Text('${index + 1}'),
                      ),
                      title: Text(lesson.title),
                      subtitle: Text(_contentLabel(lesson.contentType)),
                      trailing: const Icon(Icons.drag_handle),
                    );
                  },
                ),
              ),
              const SizedBox(height: EmiSpacing.md),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        setModalState(() => saving = true);
                        try {
                          await ref.read(teacherRepositoryProvider).reorderLessons(
                                moduleId,
                                ordered.map((e) => e.id).toList(),
                              );
                          ref.invalidate(teacherModuleDetailProvider(moduleId));
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          setModalState(() => saving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(_error(e))),
                            );
                          }
                        }
                      },
                child: Text(saving ? 'Menyimpan...' : 'Simpan Urutan Materi'),
              ),
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
            ],
          ),
        );
      },
    ),
  );
}

String _error(Object error) => error is AppError
    ? error.message
    : 'Perubahan belum berhasil disimpan. Coba lagi.';
String _status(String value) => switch (value) {
  'published' => 'Terbit',
  'active' => 'Aktif',
  'archived' => 'Arsip',
  _ => 'Draft',
};
String _contentLabel(String value) => switch (value) {
  'image' => 'Gambar',
  'audio' => 'Audio',
  'pdf' => 'PDF',
  'video' => 'Video',
  'link' => 'Tautan',
  _ => 'Teks',
};
