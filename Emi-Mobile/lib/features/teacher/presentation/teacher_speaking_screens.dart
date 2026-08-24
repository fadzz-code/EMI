import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../core/errors/app_error.dart';
import '../../../shared/widgets/role_dashboard_widgets.dart';
import '../data/teacher_providers.dart';
import '../data/teacher_repository.dart';
import 'teacher_shell.dart';
import 'teacher_style.dart';
import 'teacher_widgets.dart';

class TeacherSpeakingScreen extends StatefulWidget {
  const TeacherSpeakingScreen({super.key, this.attempts = false});
  final bool attempts;
  @override
  State<TeacherSpeakingScreen> createState() => _TeacherSpeakingScreenState();
}

class _TeacherSpeakingScreenState extends State<TeacherSpeakingScreen> {
  @override
  Widget build(BuildContext context) => TeacherShell(
    title: 'Speaking',
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(EmiSpacing.md),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Latihan')),
              ButtonSegment(value: true, label: Text('Hasil Siswa')),
            ],
            selected: {widget.attempts},
            onSelectionChanged: (v) => context.go(
              v.first
                  ? '/teacher/speaking/attempts'
                  : '/teacher/speaking/exercises',
            ),
          ),
        ),
        Expanded(
          child: widget.attempts ? const _Attempts() : const _Exercises(),
        ),
      ],
    ),
  );
}

class _Exercises extends ConsumerStatefulWidget {
  const _Exercises();
  @override
  ConsumerState<_Exercises> createState() => _ExercisesState();
}

class _ExercisesState extends ConsumerState<_Exercises> {
  String classroom = '', status = '';
  final deletedIds = <String>{};
  @override
  Widget build(BuildContext context) {
    final classes = ref.watch(teacherClassesProvider((page: 1, search: '')));
    final data = ref.watch(
      teacherSpeakingExercisesProvider((
        classroomId: classroom,
        status: status,
      )),
    );
    return ListView(
      padding: const EdgeInsets.all(EmiSpacing.md),
      children: [
        const TeacherPageHeader(
          icon: Icons.record_voice_over_outlined,
          title: 'Latihan Speaking',
          subtitle: 'Kelola latihan pengucapan untuk kelas Anda.',
        ),
        const SizedBox(height: 12),
        classes.maybeWhen(
          data: (p) => DropdownButtonFormField(
            isExpanded: true,
            initialValue: classroom,
            decoration: const InputDecoration(labelText: 'Kelas'),
            items: [
              const DropdownMenuItem(value: '', child: Text('Semua kelas')),
              ...p.items.map(
                (e) => DropdownMenuItem(value: e.id, child: Text(e.name)),
              ),
            ],
            onChanged: (v) => setState(() => classroom = v ?? ''),
          ),
          orElse: () => const SizedBox.shrink(),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField(
          isExpanded: true,
          initialValue: status,
          decoration: const InputDecoration(labelText: 'Status'),
          items: const [
            DropdownMenuItem(value: '', child: Text('Semua status')),
            DropdownMenuItem(value: 'draft', child: Text('Draft')),
            DropdownMenuItem(value: 'published', child: Text('Terbit')),
            DropdownMenuItem(value: 'archived', child: Text('Arsip')),
          ],
          onChanged: (v) => setState(() => status = v ?? ''),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => context.push('/teacher/speaking/create'),
          icon: const Icon(Icons.add),
          label: const Text('Tambah Latihan'),
        ),
        const SizedBox(height: 12),
        data.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => SizedBox(
            height: 260,
            child: _error(
              'Speaking Belum Bisa Dimuat',
              'Periksa koneksi internet Anda, lalu coba lagi.',
              () => ref.refresh(
                teacherSpeakingExercisesProvider((
                  classroomId: classroom,
                  status: status,
                )),
              ),
            ),
          ),
          data: (items) {
            final visible = items
                .where((e) => !deletedIds.contains(e.id))
                .toList();
            return visible.isEmpty
                ? const SizedBox(
                    height: 260,
                    child: FriendlyState(
                      icon: Icons.mic_none,
                      title: 'Belum Ada Latihan Speaking',
                      message:
                          'Tambahkan latihan untuk membantu siswa berlatih pengucapan.',
                    ),
                  )
                : Column(
                    children: visible
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: TeacherListCard(
                              padding: EdgeInsets.zero,
                              onTap: () => context.push(
                                '/teacher/speaking/exercises/${e.id}',
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: TeacherStyle.tint,
                                  foregroundColor: EmiColors.primary,
                                  child: const Icon(
                                    Icons.record_voice_over_outlined,
                                  ),
                                ),
                                title: Text(
                                  e.title,
                                  style: const TextStyle(
                                    color: TeacherStyle.ink,
                                  ),
                                ),
                                subtitle: Text(
                                  [
                                    if (e.classroomName != null)
                                      e.classroomName!,
                                    if (e.attemptsCount != null)
                                      '${e.attemptsCount} hasil',
                                  ].join(' · '),
                                  style: const TextStyle(
                                    color: TeacherStyle.inkMuted,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TeacherStatusChip(label: _status(e.status)),
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          context.push(
                                            '/teacher/speaking/exercises/${e.id}/edit',
                                          );
                                        } else if (value == 'delete') {
                                          _delete(e);
                                        }
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Edit'),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text(
                                            'Hapus Latihan',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
          },
        ),
      ],
    );
  }

  Future<void> _delete(TeacherSpeakingExercise exercise) async {
    if (!await _confirmDelete(context, ref, exercise.id)) return;
    setState(() => deletedIds.add(exercise.id));
    ref.invalidate(teacherSpeakingExerciseProvider(exercise.id));
    ref.invalidate(teacherSpeakingExercisesProvider);
    if (mounted) _snack(context, 'Latihan speaking berhasil dihapus.');
  }
}

class TeacherSpeakingExerciseDetailScreen extends ConsumerWidget {
  const TeacherSpeakingExerciseDetailScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => TeacherShell(
    title: 'Detail Latihan Speaking',
    fallbackRoute: '/teacher/speaking',
    child: ref
        .watch(teacherSpeakingExerciseProvider(id))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _error(
            'Latihan Belum Bisa Dimuat',
            'Detail latihan belum bisa dimuat. Silakan coba lagi.',
            () => ref.invalidate(teacherSpeakingExerciseProvider(id)),
          ),
          data: (e) => ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              TeacherPageHeader(
                icon: Icons.record_voice_over_outlined,
                title: e.title,
                subtitle: e.classroomName ?? 'Kelas Anda',
              ),
              const SizedBox(height: EmiSpacing.md),
              TeacherListCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _field('Teks target', e.targetText),
                    if (e.targetTranslation != null)
                      _field('Terjemahan', e.targetTranslation!),
                    if (e.promptText != null) _field('Petunjuk', e.promptText!),
                    if (e.difficulty != null)
                      _field('Kesulitan', _difficulty(e.difficulty!)),
                    _field('Status', _status(e.status)),
                    if (e.updatedAt != null)
                      _field('Diperbarui', _date(e.updatedAt)),
                    if (e.attemptsCount != null)
                      _field('Jumlah hasil', '${e.attemptsCount}'),
                  ],
                ),
              ),
              const SizedBox(height: EmiSpacing.lg),
              FilledButton(
                onPressed: () =>
                    context.push('/teacher/speaking/exercises/$id/edit'),
                child: const Text('Edit Latihan'),
              ),
              const SizedBox(height: EmiSpacing.sm),
              OutlinedButton(
                onPressed: () => _archive(context, ref, e),
                child: const Text('Arsipkan'),
              ),
              const SizedBox(height: EmiSpacing.sm),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: EmiColors.error,
                  side: const BorderSide(color: EmiColors.error),
                ),
                onPressed: () => _delete(context, ref, e),
                child: const Text('Hapus Latihan'),
              ),
            ],
          ),
        ),
  );
  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    TeacherSpeakingExercise exercise,
  ) async {
    if (!await _confirmDelete(context, ref, exercise.id)) return;
    ref.invalidate(teacherSpeakingExerciseProvider(exercise.id));
    ref.invalidate(teacherSpeakingExercisesProvider);
    if (context.mounted) {
      context.go('/teacher/speaking');
      _snack(context, 'Latihan speaking berhasil dihapus.');
    }
  }

  Future<void> _archive(
    BuildContext context,
    WidgetRef ref,
    TeacherSpeakingExercise e,
  ) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Arsipkan Latihan?'),
        content: const Text('Latihan akan disembunyikan dari siswa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Arsipkan'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await ref.read(teacherRepositoryProvider).archiveSpeakingExercise(e.id);
      ref.invalidate(teacherSpeakingExercisesProvider);
      if (context.mounted) context.go('/teacher/speaking');
    } catch (error) {
      if (context.mounted) {
        _snack(
          context,
          error is AppError
              ? error.message
              : 'Latihan belum bisa diarsipkan. Silakan coba lagi.',
        );
      }
    }
  }
}

class TeacherSpeakingExerciseFormScreen extends ConsumerStatefulWidget {
  const TeacherSpeakingExerciseFormScreen({super.key, this.id});
  final String? id;
  @override
  ConsumerState<TeacherSpeakingExerciseFormScreen> createState() =>
      _ExerciseFormState();
}

class _ExerciseFormState
    extends ConsumerState<TeacherSpeakingExerciseFormScreen> {
  final key = GlobalKey<FormState>();
  final title = TextEditingController(),
      target = TextEditingController(),
      translation = TextEditingController(),
      prompt = TextEditingController();
  String? classroom, template, audioPath, audioName, referenceAudioId;
  String difficulty = '', status = 'draft';
  bool loaded = false, dirty = false, saving = false;
  @override
  void dispose() {
    for (final c in [title, target, translation, prompt]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.id == null
        ? null
        : ref.watch(teacherSpeakingExerciseProvider(widget.id!));
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_back());
      },
      child: TeacherShell(
        title: widget.id == null
            ? 'Tambah Latihan Speaking'
            : 'Edit Latihan Speaking',
        fallbackRoute: '/teacher/speaking',
        onBack: _back,
        child: detail == null
            ? _body(null)
            : detail.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => _error(
                  'Speaking Belum Bisa Dimuat',
                  'Periksa koneksi internet Anda, lalu coba lagi.',
                  () => ref.invalidate(
                    teacherSpeakingExerciseProvider(widget.id!),
                  ),
                ),
                data: _body,
              ),
      ),
    );
  }

  Widget _body(TeacherSpeakingExercise? e) {
    if (e != null && !loaded) {
      title.text = e.title;
      target.text = e.targetText;
      translation.text = e.targetTranslation ?? '';
      prompt.text = e.promptText ?? '';
      classroom = e.classroomId;
      difficulty = _formDifficulty(e.difficulty);
      status = e.status;
      referenceAudioId = e.referenceAudioMediaId;
      audioName = e.referenceAudio?.fileName;
      loaded = true;
    }
    final classes = ref.watch(teacherClassesProvider((page: 1, search: '')));
    final templates = ref.watch(teacherSpeakingTemplatesProvider);
    return Form(
      key: key,
      onChanged: () => dirty = true,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(EmiSpacing.md),
              children: [
                if (widget.id == null)
                  templates.maybeWhen(
                    data: (v) => DropdownButtonFormField<String>(
                      initialValue: template,
                      decoration: const InputDecoration(
                        labelText: 'Template (opsional)',
                      ),
                      items: v
                          .map(
                            (t) => DropdownMenuItem(
                              value: t.id,
                              child: Text(t.title),
                            ),
                          )
                          .toList(),
                      onChanged: (id) {
                        final t = v.firstWhere((x) => x.id == id);
                        setState(() {
                          template = id;
                          title.text = t.title;
                          target.text = t.targetText;
                          translation.text = t.targetTranslation ?? '';
                          prompt.text = t.promptText ?? '';
                          difficulty = _formDifficulty(t.difficulty);
                          referenceAudioId = t.referenceAudioMediaId;
                          audioName = t.referenceAudio?.fileName;
                          audioPath = null;
                          dirty = true;
                        });
                      },
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                const SizedBox(height: 12),
                classes.maybeWhen(
                  data: (v) => DropdownButtonFormField<String>(
                    initialValue: classroom,
                    decoration: const InputDecoration(labelText: 'Kelas'),
                    items: v.items
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    validator: (v) => v == null ? 'Pilih kelas.' : null,
                    onChanged: (v) => setState(() => classroom = v),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: saving ? null : _pickAudio,
                  icon: const Icon(Icons.audio_file_outlined),
                  label: Text(
                    audioName == null
                        ? 'Pilih Audio Penutur Asli'
                        : 'Ganti Audio: $audioName',
                  ),
                ),
                if (e?.referenceAudio?.url != null && audioPath == null) ...[
                  const SizedBox(height: 8),
                  _ReferenceAudioPlayer(source: e!.referenceAudio!.url!),
                ],
                ...[
                  _input(title, 'Judul', required: true),
                  _input(target, 'Teks target', required: true),
                  _input(translation, 'Terjemahan target'),
                  _input(prompt, 'Petunjuk', lines: 3),
                ],
                DropdownButtonFormField(
                  initialValue: difficulty,
                  decoration: const InputDecoration(labelText: 'Kesulitan'),
                  items: const [
                    DropdownMenuItem(
                      value: '',
                      child: Text('Tidak ditentukan'),
                    ),
                    DropdownMenuItem(value: 'beginner', child: Text('Pemula')),
                    DropdownMenuItem(
                      value: 'intermediate',
                      child: Text('Menengah'),
                    ),
                    DropdownMenuItem(value: 'advanced', child: Text('Mahir')),
                  ],
                  onChanged: (v) => difficulty = v ?? '',
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'draft', child: Text('Draft')),
                    DropdownMenuItem(value: 'published', child: Text('Terbit')),
                  ],
                  onChanged: (v) => status = v ?? 'draft',
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

  Widget _input(
    TextEditingController c,
    String label, {
    bool required = false,
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: TextFormField(
      controller: c,
      minLines: lines,
      maxLines: lines,
      decoration: InputDecoration(labelText: label),
      validator: (v) => required && v!.trim().isEmpty ? 'Wajib diisi.' : null,
    ),
  );
  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    final file = result?.files.single;
    if (file?.path == null) return;
    setState(() {
      audioPath = file!.path;
      audioName = file.name;
      dirty = true;
    });
  }

  Future<void> _save() async {
    if (saving || !key.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      if (audioPath != null) {
        referenceAudioId =
            (await ref
                    .read(teacherRepositoryProvider)
                    .uploadMedia(
                      audioPath!,
                      audioName ?? 'audio',
                      purpose: 'speaking_reference_audio',
                    ))
                .id;
      }
      final saved = await ref
          .read(teacherRepositoryProvider)
          .saveSpeakingExercise(
            id: widget.id,
            data: {
              'classroom_id': classroom,
              'template_exercise_id': widget.id == null ? template : null,
              'title': title.text.trim(),
              'target_text': target.text.trim(),
              'target_translation': translation.text.trim().isEmpty
                  ? null
                  : translation.text.trim(),
              'prompt_text': prompt.text.trim().isEmpty
                  ? null
                  : prompt.text.trim(),
              'reference_audio_media_id': referenceAudioId,
              'difficulty': difficulty.isEmpty ? null : difficulty,
              'language_code': 'mekongga',
              'status': status,
            },
          );
      dirty = false;
      final refreshedDetail = await ref.refresh(
        teacherSpeakingExerciseProvider(saved.id).future,
      );
      ref.invalidate(teacherSpeakingExercisesProvider);
      if (refreshedDetail.id.isEmpty) return;
      if (mounted) context.go('/teacher/speaking/exercises/${saved.id}');
    } catch (e) {
      if (mounted) {
        _snack(
          context,
          e is AppError
              ? e.message
              : 'Latihan belum bisa disimpan. Silakan coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _back() async {
    if (dirty) {
      final leave =
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
      if (!leave) return;
    }
    dirty = false;
    if (mounted) {
      context.canPop() ? context.pop() : context.go('/teacher/speaking');
    }
  }
}

class _ReferenceAudioPlayer extends StatefulWidget {
  const _ReferenceAudioPlayer({required this.source});
  final String source;
  @override
  State<_ReferenceAudioPlayer> createState() => _ReferenceAudioPlayerState();
}

class _ReferenceAudioPlayerState extends State<_ReferenceAudioPlayer> {
  final player = AudioPlayer();
  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    try {
      if (player.playing) {
        await player.pause();
      } else {
        if (player.audioSource == null) {
          final uri = Uri.parse(widget.source);
          final mobileUri = (uri.host == 'localhost' || uri.host == '127.0.0.1')
              ? uri.replace(host: '10.0.2.2')
              : uri;
          await player.setUrl(mobileUri.toString());
        }
        await player.play();
      }
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio belum bisa diputar. Silakan coba lagi.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: _toggle,
    icon: Icon(player.playing ? Icons.pause : Icons.play_arrow),
    label: Text(
      player.playing ? 'Jeda Audio Penutur Asli' : 'Putar Audio Penutur Asli',
    ),
  );
}

class _Attempts extends ConsumerStatefulWidget {
  const _Attempts();
  @override
  ConsumerState<_Attempts> createState() => _AttemptsState();
}

class _AttemptsState extends ConsumerState<_Attempts> {
  final searchController = TextEditingController();
  String search = '', review = '';
  int page = 1;

  ({int page, String search, String reviewStatus}) get query => (
    page: page,
    search: search,
    reviewStatus: review == 'done' ? 'reviewed' : review,
  );

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteAttempt(TeacherSpeakingAttempt attempt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Hasil Speaking?'),
        content: const Text('Hasil yang belum dinilai akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(teacherRepositoryProvider)
          .deleteSpeakingAttempt(attempt.id);
      ref.invalidate(teacherSpeakingAttemptsProvider);
    } catch (error) {
      if (mounted) {
        _snack(
          context,
          error is AppError
              ? error.message
              : 'Hasil speaking belum bisa dihapus. Silakan coba lagi.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(EmiSpacing.md),
    children: [
      const TeacherPageHeader(
        icon: Icons.record_voice_over_outlined,
        title: 'Hasil Speaking Siswa',
        subtitle: 'Dengarkan hasil dan berikan penilaian.',
      ),
      const SizedBox(height: EmiSpacing.md),
      TeacherSearchField(
        controller: searchController,
        label: 'Cari siswa atau latihan',
        onChanged: (v) => setState(() {
          search = v.toLowerCase();
          page = 1;
        }),
      ),
      const SizedBox(height: EmiSpacing.sm),
      DropdownButtonFormField(
        initialValue: review,
        decoration: const InputDecoration(labelText: 'Status penilaian'),
        items: const [
          DropdownMenuItem(value: '', child: Text('Semua')),
          DropdownMenuItem(value: 'pending', child: Text('Belum dinilai')),
          DropdownMenuItem(value: 'done', child: Text('Sudah dinilai')),
        ],
        onChanged: (v) => setState(() {
          review = v ?? '';
          page = 1;
        }),
      ),
      const SizedBox(height: EmiSpacing.md),
      ref
          .watch(teacherSpeakingAttemptsProvider(query))
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => SizedBox(
              height: 320,
              child: _error(
                'Hasil Speaking Belum Bisa Dimuat',
                'Hasil speaking siswa belum bisa dimuat. Silakan coba lagi.',
                () => ref.refresh(teacherSpeakingAttemptsProvider(query)),
              ),
            ),
            data: (result) {
              final items = result.items;
              if (items.isEmpty && page > result.lastPage) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && page > result.lastPage) {
                    setState(() => page = result.lastPage);
                  }
                });
              }
              return Column(
                children: [
                  Wrap(
                    spacing: EmiSpacing.sm,
                    runSpacing: EmiSpacing.sm,
                    children: [
                      TeacherStatusChip(label: 'Total ${result.total}'),
                      TeacherStatusChip(
                        label: 'Menunggu ${result.pendingCount}',
                      ),
                      TeacherStatusChip(
                        label: 'Dinilai ${result.reviewedCount}',
                      ),
                      TeacherStatusChip(label: 'Gagal ${result.failedCount}'),
                    ],
                  ),
                  const SizedBox(height: EmiSpacing.md),
                  if (items.isEmpty)
                    const SizedBox(
                      height: 240,
                      child: FriendlyState(
                        icon: Icons.record_voice_over_outlined,
                        title: 'Belum Ada Hasil Speaking',
                        message:
                            'Hasil speaking siswa akan muncul setelah mereka mengirim rekaman.',
                      ),
                    ),
                  ...items.map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TeacherListCard(
                        padding: EdgeInsets.zero,
                        onTap: () =>
                            context.push('/teacher/speaking/attempts/${a.id}'),
                        child: ListTile(
                          title: Text(
                            a.studentName,
                            style: const TextStyle(color: TeacherStyle.ink),
                          ),
                          subtitle: Text(
                            [
                              a.exerciseTitle,
                              if (a.classroomName != null) a.classroomName!,
                              if (a.aiScore != null)
                                'Skor AI ${a.aiScore!.toStringAsFixed(0)}',
                              a.teacherScore == null
                                  ? 'Belum dinilai'
                                  : 'Sudah dinilai',
                              _date(a.submittedAt ?? a.createdAt),
                            ].join(' · '),
                            style: const TextStyle(
                              color: TeacherStyle.inkMuted,
                            ),
                          ),
                          isThreeLine: true,
                          trailing: a.canDelete
                              ? IconButton(
                                  tooltip: 'Hapus hasil',
                                  onPressed: () => _deleteAttempt(a),
                                  icon: const Icon(Icons.delete_outline),
                                )
                              : const TeacherStatusChip(label: 'Sudah dinilai'),
                        ),
                      ),
                    ),
                  ),
                  if (result.lastPage > 1)
                    TeacherPaginationBar(
                      currentPage: result.currentPage,
                      lastPage: result.lastPage,
                      onPrevious: result.currentPage > 1
                          ? () => setState(() => page--)
                          : null,
                      onNext: result.currentPage < result.lastPage
                          ? () => setState(() => page++)
                          : null,
                    ),
                ],
              );
            },
          ),
    ],
  );
}

class TeacherSpeakingAttemptDetailScreen extends ConsumerStatefulWidget {
  const TeacherSpeakingAttemptDetailScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<TeacherSpeakingAttemptDetailScreen> createState() =>
      _AttemptDetailState();
}

class _AttemptDetailState
    extends ConsumerState<TeacherSpeakingAttemptDetailScreen> {
  final score = TextEditingController(), feedback = TextEditingController();
  final player = AudioPlayer();
  bool loaded = false, saving = false, audioLoading = false;
  String? audioError;
  TeacherSpeakingAttempt? savedAttempt;
  @override
  void dispose() {
    score.dispose();
    feedback.dispose();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TeacherShell(
    title: 'Detail Hasil Speaking',
    fallbackRoute: '/teacher/speaking/attempts',
    child: ref
        .watch(teacherSpeakingAttemptProvider(widget.id))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _error(
            'Hasil Speaking Belum Bisa Dimuat',
            'Detail hasil speaking belum bisa dimuat. Silakan coba lagi.',
            () => ref.invalidate(teacherSpeakingAttemptProvider(widget.id)),
          ),
          data: (serverAttempt) {
            final a = savedAttempt ?? serverAttempt;
            if (!loaded) {
              score.text = a.teacherScore?.toStringAsFixed(0) ?? '';
              feedback.text = a.teacherFeedback ?? '';
              loaded = true;
            }
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(EmiSpacing.md),
                    children: [
                      TeacherPageHeader(
                        icon: Icons.person_outline,
                        title: a.studentName,
                        subtitle: a.exerciseTitle,
                      ),
                      const SizedBox(height: EmiSpacing.md),
                      TeacherListCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (a.classroomName != null)
                              _field('Kelas', a.classroomName!),
                            _field('Tanggal', _date(a.createdAt)),
                            _field(
                              'Status',
                              a.teacherScore == null
                                  ? 'Belum dinilai'
                                  : 'Sudah dinilai',
                            ),
                            if (a.targetText != null)
                              _field('Teks target', a.targetText!),
                            if (a.transcription != null)
                              _field('Transkripsi AI', a.transcription!),
                            if (a.aiError != null)
                              _field('AI gagal menganalisis', a.aiError!),
                            if (a.aiScore != null)
                              _field('Skor AI', a.aiScore!.toStringAsFixed(0)),
                            if (a.status != null)
                              _field('Status analisis', _analysis(a.status!)),
                            if (a.captureSource != null)
                              _field(
                                'Sumber rekaman',
                                _source(a.captureSource!),
                              ),
                          ],
                        ),
                      ),
                      if (a.referenceAudio?.url != null) ...[
                        const SizedBox(height: EmiSpacing.md),
                        _ReferenceAudioPlayer(source: a.referenceAudio!.url!),
                      ],
                      const SizedBox(height: EmiSpacing.sm),
                      FilledButton.icon(
                        onPressed: audioLoading || a.audioMediaId == null
                            ? null
                            : () => _audio(a.audioMediaId!),
                        icon: Icon(
                          player.playing ? Icons.pause : Icons.play_arrow,
                        ),
                        label: Text(
                          audioLoading
                              ? 'Memuat audio...'
                              : player.playing
                              ? 'Jeda Audio'
                              : 'Putar Audio',
                        ),
                      ),
                      if (audioError != null)
                        Text(
                          audioError!,
                          style: const TextStyle(color: EmiColors.error),
                        ),
                      if (_alignment(a.aiAlignment).isNotEmpty) ...[
                        const SizedBox(height: EmiSpacing.md),
                        TeacherSectionHeader(
                          'Perbandingan ucapan',
                          icon: Icons.compare_arrows,
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _alignment(a.aiAlignment)
                              .map(
                                (row) =>
                                    Chip(label: Text('${row.$1}: ${row.$2}%')),
                              )
                              .toList(),
                        ),
                      ],
                      TeacherSectionHeader(
                        'Penilaian Guru',
                        icon: Icons.rate_review_outlined,
                      ),
                      TextFormField(
                        controller: score,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Nilai (0–100)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: feedback,
                        maxLength: 5000,
                        minLines: 3,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Feedback (opsional)',
                        ),
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
                      child: Text(
                        saving
                            ? 'Menyimpan...'
                            : a.isReviewed
                            ? 'Perbarui Penilaian'
                            : 'Simpan Penilaian',
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
  );
  Future<void> _audio(String id) async {
    if (player.playing) {
      await player.pause();
      if (mounted) setState(() {});
      return;
    }
    setState(() {
      audioLoading = true;
      audioError = null;
    });
    try {
      final url = await ref
          .read(teacherRepositoryProvider)
          .speakingTemporaryUrl(id);
      await player.setUrl(url);
      await player.play();
    } catch (_) {
      audioError = 'Audio belum bisa diputar. Silakan coba lagi.';
    } finally {
      if (mounted) setState(() => audioLoading = false);
    }
  }

  Future<void> _save() async {
    final value = num.tryParse(score.text);
    if (value == null || value < 0 || value > 100) {
      _snack(context, 'Masukkan nilai antara 0 dan 100.');
      return;
    }
    if (feedback.text.length > 5000) return;
    if (saving) return;
    setState(() => saving = true);
    try {
      final saved = await ref
          .read(teacherRepositoryProvider)
          .saveSpeakingFeedback(
            widget.id,
            teacherScore: value,
            teacherFeedback: feedback.text.trim().isEmpty
                ? null
                : feedback.text.trim(),
          );
      savedAttempt = saved;
      loaded = true;
      ref.invalidate(teacherSpeakingAttemptsProvider);
      ref.invalidate(teacherSpeakingAttemptProvider(widget.id));
      if (saved.id.isEmpty) return;
      final refreshed = await ref.refresh(
        teacherSpeakingAttemptProvider(widget.id).future,
      );
      if (!mounted) return;
      setState(() => savedAttempt = refreshed);
      _snack(context, 'Penilaian berhasil disimpan.');
    } catch (e) {
      if (mounted) {
        _snack(
          context,
          e is AppError
              ? e.message
              : 'Penilaian belum bisa disimpan. Silakan coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}

Future<bool> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  String id,
) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        var deleting = false;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Hapus Latihan?'),
            content: const SingleChildScrollView(
              child: Text(
                'Latihan ini akan dihapus dari kelas. Tindakan ini tidak dapat dibatalkan.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: deleting
                    ? null
                    : () => Navigator.pop(dialogContext, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: deleting
                    ? null
                    : () async {
                        setState(() => deleting = true);
                        try {
                          await ref
                              .read(teacherRepositoryProvider)
                              .deleteSpeakingExercise(id);
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext, true);
                          }
                        } catch (error) {
                          if (!dialogContext.mounted) return;
                          setState(() => deleting = false);
                          if (error is AppError &&
                              error.type == AppErrorType.validation) {
                            await showDialog<void>(
                              context: dialogContext,
                              builder: (context) => AlertDialog(
                                title: const Text(
                                  'Latihan Tidak Dapat Dihapus',
                                ),
                                content: const SingleChildScrollView(
                                  child: Text(
                                    'Latihan ini sudah memiliki hasil siswa. Arsipkan latihan agar tidak lagi tampil kepada siswa.',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Tutup'),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            _snack(
                              dialogContext,
                              error is AppError
                                  ? error.message
                                  : 'Latihan belum bisa dihapus. Silakan coba lagi.',
                            );
                          }
                        }
                      },
                child: deleting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Hapus'),
              ),
            ],
          ),
        );
      },
    ) ??
    false;

Widget _field(String label, String value) => Padding(
  padding: const EdgeInsets.only(top: 10),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: TeacherStyle.inkMuted,
        ),
      ),
      Text(value, style: const TextStyle(color: TeacherStyle.ink)),
    ],
  ),
);
Widget _error(String title, String message, VoidCallback retry) =>
    FriendlyState(
      icon: Icons.error_outline,
      title: title,
      message: message,
      onRetry: retry,
    );
void _snack(BuildContext c, String text) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(text)));
String _status(String v) => v == 'published'
    ? 'Terbit'
    : v == 'archived'
    ? 'Arsip'
    : 'Draft';
String _formDifficulty(String? value) => switch (value?.toLowerCase()) {
  'beginner' || 'easy' || 'mudah' || 'demo' => 'beginner',
  'intermediate' || 'medium' || 'sedang' => 'intermediate',
  'advanced' || 'hard' || 'sulit' => 'advanced',
  _ => '',
};
String _difficulty(String v) => switch (_formDifficulty(v)) {
  'beginner' => 'Pemula',
  'advanced' => 'Mahir',
  'intermediate' => 'Menengah',
  _ => 'Tidak ditentukan',
};
String _analysis(String v) => v == 'completed'
    ? 'Analisis selesai'
    : v == 'failed'
    ? 'Analisis gagal'
    : v == 'processing'
    ? 'Sedang dianalisis'
    : v == 'reviewed'
    ? 'Sudah dinilai'
    : 'Menunggu analisis';
List<(String, int)> _alignment(Object? value) {
  if (value is! Map) return const [];
  return value.entries
      .where(
        (entry) =>
            entry.key is String &&
            RegExp(r'^\d+_').hasMatch(entry.key as String) &&
            entry.value is num,
      )
      .take(8)
      .map(
        (entry) => (
          (entry.key as String).replaceFirst(RegExp(r'^\d+_'), ''),
          (entry.value as num).round(),
        ),
      )
      .toList();
}

String _source(String v) => switch (v) {
  'web_microphone' => 'Mikrofon web',
  'web_esp32_serial' => 'ESP32 web',
  'mobile_microphone' => 'Mikrofon ponsel',
  'mobile_esp32_bluetooth' => 'ESP32 Bluetooth',
  _ => 'Tidak diketahui',
};
String _date(DateTime? d) => d == null
    ? 'Tanggal belum tersedia'
    : '${d.toLocal().day.toString().padLeft(2, '0')}/${d.toLocal().month.toString().padLeft(2, '0')}/${d.toLocal().year}';
