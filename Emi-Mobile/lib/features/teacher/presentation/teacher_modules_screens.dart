import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../core/errors/app_error.dart';
import '../../../shared/widgets/emi_card.dart';
import '../../../shared/widgets/role_dashboard_widgets.dart';
import '../data/teacher_providers.dart';
import '../data/teacher_repository.dart';
import 'teacher_shell.dart';

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
                    return EmiCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          child: Icon(Icons.menu_book_outlined),
                        ),
                        title: Text(item.title),
                        subtitle: Text(
                          '${_status(item.status)} • Urutan ${item.sortOrder}\n${item.lessons.length} materi',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            context.push('/teacher/modules/${item.id}/edit'),
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
    child: ListView(
      padding: const EdgeInsets.all(EmiSpacing.md),
      children: [
        Form(
          key: _form,
          child: Column(
            children: [
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
                decoration: const InputDecoration(labelText: 'Deskripsi Modul'),
                minLines: 3,
                maxLines: 6,
              ),
              const SizedBox(height: EmiSpacing.md),
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
        const SizedBox(height: EmiSpacing.lg),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Menyimpan...' : 'Simpan Modul'),
        ),
      ],
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
          Text(
            'Status: ${_status(item.status)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: EmiSpacing.md),
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
            TextButton(
              onPressed: _saving ? null : () => _delete(item),
              child: const Text('Hapus Draft'),
            ),
          const SizedBox(height: EmiSpacing.lg),
          Text('Daftar Materi', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: EmiSpacing.sm),
          if (item.lessons.isEmpty)
            const Text('Modul ini belum memiliki materi.')
          else
            for (final lesson in item.lessons)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(lesson.title),
                subtitle: Text(
                  '${_contentLabel(lesson.contentType)} • ${_status(lesson.status)} • Urutan ${lesson.sortOrder}',
                ),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => context.push(
                  '/teacher/modules/${item.id}/lessons/${lesson.id}/edit',
                ),
              ),
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
          Text(
            'Status: ${_status(item.status)} • ${_contentLabel(_contentType ?? item.contentType)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: EmiSpacing.md),
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
          const SizedBox(height: EmiSpacing.lg),
          EmiCard(
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
          FilledButton(
            onPressed: _saving ? null : () => _save(item),
            child: Text(_saving ? 'Menyimpan...' : 'Simpan Perubahan'),
          ),
          if (item.status != 'published')
            OutlinedButton(
              onPressed: _saving ? null : () => _publish(item),
              child: const Text('Terbitkan Materi'),
            ),
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
