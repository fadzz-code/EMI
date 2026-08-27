import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../core/errors/app_error.dart';
import '../data/teacher_providers.dart';
import '../data/teacher_quiz_models.dart';
import 'teacher_shell.dart';
import 'teacher_style.dart';
import 'teacher_widgets.dart';

bool teacherQuizCanDelete(TeacherQuiz quiz) =>
    quiz.status != 'published' && quiz.attemptsCount == 0;

bool teacherQuizCanEditQuestions(TeacherQuiz quiz) =>
    quiz.status != 'published' && quiz.attemptsCount == 0;

class TeacherQuizzesScreen extends ConsumerStatefulWidget {
  const TeacherQuizzesScreen({super.key});
  @override
  ConsumerState<TeacherQuizzesScreen> createState() =>
      _TeacherQuizzesScreenState();
}

class _TeacherQuizzesScreenState extends ConsumerState<TeacherQuizzesScreen> {
  final _search = TextEditingController();
  int page = 1;
  String status = '';
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = (page: page, search: _search.text, status: status);
    final value = ref.watch(teacherQuizzesProvider(filter));
    return TeacherShell(
      title: 'Kuis Kelas',
      fallbackRoute: null,
      child: value.when(
        loading: () => const _QuizSkeleton(),
        error: (_, _) => _State(
          title: 'Kuis Belum Bisa Dimuat',
          message: 'Periksa koneksi internet, lalu coba lagi.',
          retry: () => ref.invalidate(teacherQuizzesProvider(filter)),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.all(EmiSpacing.md),
          children: [
            const TeacherPageHeader(
              icon: Icons.quiz_outlined,
              title: 'Kuis Kelas',
              subtitle: 'Kelola kuis dan pantau pemahaman siswa.',
            ),
            const SizedBox(height: EmiSpacing.md),
            FilledButton.icon(
              onPressed: () => context.push('/teacher/quizzes/create'),
              icon: const Icon(Icons.add, size: 24),
              label: const Text('Tambah Kuis'),
            ),
            const SizedBox(height: EmiSpacing.lg),
            _QuizMetrics(items: data.items, paginated: data.lastPage > 1),
            const SizedBox(height: EmiSpacing.lg),
            TeacherSearchField(
              controller: _search,
              label: 'Cari kuis',
              onSubmitted: (_) => setState(() => page = 1),
            ),
            const SizedBox(height: EmiSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: '', child: Text('Semua')),
                DropdownMenuItem(value: 'draft', child: Text('Draf')),
                DropdownMenuItem(value: 'published', child: Text('Terbit')),
                DropdownMenuItem(value: 'archived', child: Text('Diarsipkan')),
              ],
              onChanged: (v) => setState(() {
                status = v ?? '';
                page = 1;
              }),
            ),
            const SizedBox(height: EmiSpacing.lg),
            if (data.items.isEmpty)
              const _State(
                title: 'Belum Ada Kuis',
                message:
                    'Buat kuis pertama untuk mulai menilai pemahaman siswa.',
              )
            else
              for (final quiz in data.items) ...[
                _QuizItem(quiz: quiz),
                const SizedBox(height: EmiSpacing.sm),
              ],
            if (data.items.isNotEmpty) ...[
              const SizedBox(height: EmiSpacing.xs),
              TeacherPaginationBar(
                currentPage: data.page,
                lastPage: data.lastPage,
                onPrevious: page > 1 ? () => setState(() => page--) : null,
                onNext: page < data.lastPage
                    ? () => setState(() => page++)
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuizMetrics extends StatelessWidget {
  const _QuizMetrics({required this.items, required this.paginated});
  final List<TeacherQuiz> items;
  final bool paginated;
  @override
  Widget build(BuildContext context) {
    final metrics = [
      (
        Icons.quiz_outlined,
        '${items.length}',
        paginated ? 'Kuis di halaman ini' : 'Total kuis',
      ),
      (
        Icons.public,
        '${items.where((q) => q.status == 'published').length}',
        paginated ? 'Terbit di halaman ini' : 'Terbit',
      ),
      (
        Icons.edit_note,
        '${items.where((q) => q.status == 'draft').length}',
        paginated ? 'Draf di halaman ini' : 'Draf',
      ),
      (
        Icons.groups_outlined,
        '${items.fold<int>(0, (sum, q) => sum + q.attemptsCount)}',
        paginated ? 'Pengerjaan di halaman ini' : 'Siswa mengerjakan',
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 688 ? 4 : 2;
        final width =
            (constraints.maxWidth - EmiSpacing.sm * (columns - 1)) / columns;
        return Wrap(
          spacing: EmiSpacing.sm,
          runSpacing: EmiSpacing.sm,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: width,
                child: TeacherListCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: TeacherStyle.tint,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          metric.$1,
                          size: 18,
                          color: EmiColors.primary,
                        ),
                      ),
                      const SizedBox(height: EmiSpacing.sm),
                      Text(
                        metric.$2,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: TeacherStyle.ink,
                        ),
                      ),
                      Text(
                        metric.$3,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: TeacherStyle.inkMuted),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _QuizItem extends StatelessWidget {
  const _QuizItem({required this.quiz});
  final TeacherQuiz quiz;
  @override
  Widget build(BuildContext context) => TeacherListCard(
    onTap: () => context.push('/teacher/quizzes/${quiz.id}'),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: TeacherStyle.tint,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.quiz_outlined, color: EmiColors.primary),
        ),
        const SizedBox(width: EmiSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quiz.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: TeacherStyle.ink),
              ),
              Text(
                '${quiz.className ?? 'Kelas aktif'} • ${quiz.questionsCount} pertanyaan • ${quiz.attemptsCount} mengerjakan',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: TeacherStyle.inkMuted),
              ),
              const SizedBox(height: EmiSpacing.sm),
              Row(
                children: [
                  Flexible(child: _StatusBadge(status: quiz.status)),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      'Diperbarui ${_date(quiz.updatedAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: TeacherStyle.inkMuted),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (value) => context.push(
            value == 'result'
                ? '/teacher/quizzes/${quiz.id}/results'
                : '/teacher/quizzes/${quiz.id}/edit',
          ),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit Kuis')),
            PopupMenuItem(value: 'result', child: Text('Lihat Hasil')),
          ],
        ),
      ],
    ),
  );
}

class _QuizSkeleton extends StatelessWidget {
  const _QuizSkeleton();
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(EmiSpacing.md),
    children: [
      for (var i = 0; i < 4; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: EmiSpacing.sm),
          child: Container(
            height: 88,
            decoration: BoxDecoration(
              color: TeacherStyle.tint,
              borderRadius: BorderRadius.circular(TeacherStyle.cardRadius),
            ),
          ),
        ),
    ],
  );
}

class TeacherQuizDetailScreen extends ConsumerStatefulWidget {
  const TeacherQuizDetailScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<TeacherQuizDetailScreen> createState() =>
      _TeacherQuizDetailScreenState();
}

class _TeacherQuizDetailScreenState
    extends ConsumerState<TeacherQuizDetailScreen> {
  bool mutating = false;
  @override
  Widget build(BuildContext context) => TeacherShell(
    title: 'Detail Kuis',
    fallbackRoute: '/teacher/quizzes',
    child: ref
        .watch(teacherQuizDetailProvider(widget.id))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _State(
            title: 'Detail kuis belum bisa dimuat',
            message: 'Periksa koneksi internet, lalu coba lagi.',
            retry: () => ref.invalidate(teacherQuizDetailProvider(widget.id)),
          ),
          data: (quiz) => ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              TeacherPageHeader(
                icon: Icons.quiz_outlined,
                title: quiz.title,
                subtitle: quiz.className ?? 'Kelas aktif',
                trailing: PopupMenuButton<String>(
                  enabled: !mutating,
                  onSelected: (value) => value == 'result'
                      ? context.push('/teacher/quizzes/${widget.id}/results')
                      : _action(context, quiz, value),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'result',
                      child: Text('Lihat Hasil'),
                    ),
                    if (quiz.status == 'draft' || quiz.status == 'archived')
                      const PopupMenuItem(
                        value: 'publish',
                        child: Text('Terbitkan Kuis'),
                      ),
                    if (quiz.status == 'published')
                      const PopupMenuItem(
                        value: 'archive',
                        child: Text('Arsipkan Kuis'),
                      ),
                    if (teacherQuizCanDelete(quiz))
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Hapus Kuis'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: EmiSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: _StatusBadge(status: quiz.status),
              ),
              const SizedBox(height: EmiSpacing.sm),
              if (quiz.status == 'published')
                const TeacherStatusChip(label: 'Terkunci')
              else if (quiz.attemptsCount > 0)
                const TeacherStatusChip(label: 'Sudah ada pengerjaan'),
              if (quiz.attemptsCount > 0) ...[
                const SizedBox(height: EmiSpacing.sm),
                const Text(
                  'Kuis sudah memiliki pengerjaan siswa. Kuis tidak dapat dihapus dan pertanyaan tidak dapat diubah.',
                ),
              ],
              const SizedBox(height: EmiSpacing.lg),
              FilledButton.icon(
                onPressed: quiz.status == 'published'
                    ? null
                    : () => context.push('/teacher/quizzes/${widget.id}/edit'),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Kuis'),
              ),
              const SizedBox(height: EmiSpacing.sm),
              OutlinedButton.icon(
                onPressed: () =>
                    context.push('/teacher/quizzes/${widget.id}/preview'),
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Preview Kuis'),
              ),
              const SizedBox(height: EmiSpacing.lg),
              _DetailMetrics(quiz: quiz),
              if (quiz.description.isNotEmpty) ...[
                TeacherSectionHeader('Deskripsi'),
                Text(quiz.description),
              ],
              TeacherSectionHeader(
                'Pertanyaan',
                icon: Icons.help_outline,
                trailing: Wrap(
                  spacing: EmiSpacing.xs,
                  children: [
                    if (quiz.questions.length > 1 &&
                        teacherQuizCanEditQuestions(quiz))
                      IconButton(
                        tooltip: 'Ubah Urutan Soal',
                        onPressed: () => _showReorderQuestionsDialog(
                          context,
                          ref,
                          quiz.id,
                          quiz.questions,
                        ),
                        icon: const Icon(Icons.swap_vert),
                      ),
                    FilledButton.icon(
                      onPressed: teacherQuizCanEditQuestions(quiz)
                          ? () => context.push(
                              '/teacher/quizzes/${widget.id}/questions/create',
                            )
                          : null,
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah'),
                    ),
                  ],
                ),
              ),
              if (quiz.questions.isEmpty)
                const _State(
                  title: 'Belum Ada Pertanyaan',
                  message:
                      'Tambahkan pertanyaan pertama untuk melengkapi kuis ini.',
                )
              else
                for (var index = 0; index < quiz.questions.length; index++) ...[
                  TeacherListCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${index + 1}'.padLeft(2, '0'),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: EmiColors.primary),
                        ),
                        const SizedBox(width: EmiSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                quiz.questions[index].text,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: TeacherStyle.ink),
                              ),
                              if (quiz.questions[index].imageUrl != null) ...[
                                const SizedBox(height: EmiSpacing.sm),
                                Image.network(
                                  quiz.questions[index].imageUrl!,
                                  height: 120,
                                  fit: BoxFit.contain,
                                ),
                              ],
                              const SizedBox(height: EmiSpacing.xs),
                              Text(
                                '${quiz.questions[index].type == 'multiple_choice' ? 'Pilihan ganda' : 'Jawaban singkat'} • ${quiz.questions[index].points} poin',
                                style: const TextStyle(
                                  color: TeacherStyle.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (teacherQuizCanEditQuestions(quiz))
                          PopupMenuButton<String>(
                            enabled: !mutating,
                            onSelected: (value) => value == 'edit'
                                ? context.push(
                                    '/teacher/quizzes/${widget.id}/questions/${quiz.questions[index].id}/edit',
                                  )
                                : _deleteQuestion(
                                    context,
                                    quiz.questions[index].id,
                                  ),
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit Pertanyaan'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Hapus Pertanyaan'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: EmiSpacing.sm),
                ],
            ],
          ),
        ),
  );

  Future<void> _deleteQuestion(BuildContext context, String questionId) async {
    if (mutating || await _confirm(context, 'Hapus pertanyaan ini?') != true) {
      return;
    }
    setState(() => mutating = true);
    try {
      await ref.read(teacherQuizRepositoryProvider).deleteQuestion(questionId);
      ref.invalidate(teacherQuizDetailProvider(widget.id));
      if (context.mounted) _notice(context, 'Pertanyaan berhasil dihapus.');
    } catch (error) {
      if (context.mounted) _notice(context, _error(error));
    } finally {
      if (mounted) setState(() => mutating = false);
    }
  }

  Future<void> _action(
    BuildContext context,
    TeacherQuiz quiz,
    String action,
  ) async {
    if (mutating) return;
    final publish = action == 'publish';
    final delete = action == 'delete';
    if (publish && quiz.questionsCount < 1) {
      _notice(context, 'Tambahkan minimal satu soal sebelum menerbitkan kuis.');
      return;
    }
    if (await _confirm(
          context,
          publish
              ? 'Terbitkan kuis?'
              : delete
              ? 'Hapus kuis permanen?'
              : 'Arsipkan kuis?',
        ) !=
        true) {
      return;
    }
    setState(() => mutating = true);
    try {
      if (delete) {
        await ref.read(teacherQuizRepositoryProvider).deleteQuiz(quiz.id);
        ref.invalidate(teacherQuizzesProvider);
        if (context.mounted) context.go('/teacher/quizzes');
        return;
      }
      publish
          ? await ref.read(teacherQuizRepositoryProvider).publish(quiz.id)
          : await ref.read(teacherQuizRepositoryProvider).archive(quiz.id);
      final _ = await ref.refresh(teacherQuizDetailProvider(quiz.id).future);
      ref.invalidate(teacherQuizzesProvider);
    } catch (error) {
      if (context.mounted) _notice(context, _error(error));
    } finally {
      if (mounted) setState(() => mutating = false);
    }
  }
}

class _DetailMetrics extends StatelessWidget {
  const _DetailMetrics({required this.quiz});
  final TeacherQuiz quiz;
  @override
  Widget build(BuildContext context) {
    final metrics = [
      (Icons.help_outline, '${quiz.questionsCount}', 'Pertanyaan'),
      (Icons.replay, '${quiz.maxAttempts}', 'Batas Percobaan'),
      (Icons.timer_outlined, '${quiz.durationMinutes} menit', 'Durasi'),
      (Icons.groups_outlined, '${quiz.attemptsCount}', 'Pengerjaan'),
      if (quiz.openAt != null || quiz.closeAt != null)
        (
          Icons.calendar_today_outlined,
          '${_date(quiz.openAt)} – ${_date(quiz.closeAt)}',
          'Jadwal',
        ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - EmiSpacing.sm) / 2;
        return Wrap(
          spacing: EmiSpacing.sm,
          runSpacing: EmiSpacing.sm,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: width,
                child: TeacherListCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: TeacherStyle.tint,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          metric.$1,
                          size: 18,
                          color: EmiColors.primary,
                        ),
                      ),
                      const SizedBox(height: EmiSpacing.sm),
                      Text(
                        metric.$2,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: TeacherStyle.ink,
                        ),
                      ),
                      Text(
                        metric.$3,
                        style: const TextStyle(color: TeacherStyle.inkMuted),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class TeacherQuizPreviewScreen extends ConsumerWidget {
  const TeacherQuizPreviewScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) => TeacherShell(
    title: 'Preview Kuis',
    fallbackRoute: '/teacher/quizzes/$id',
    child: ref
        .watch(teacherQuizDetailProvider(id))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              const Center(child: Text('Preview belum bisa dimuat.')),
          data: (quiz) => ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              TeacherPageHeader(
                icon: Icons.visibility_outlined,
                title: quiz.title,
                subtitle: quiz.instructions.isEmpty
                    ? 'Tampilan kuis untuk siswa'
                    : quiz.instructions,
              ),
              const SizedBox(height: EmiSpacing.md),
              _DetailMetrics(quiz: quiz),
              if (quiz.description.isNotEmpty) ...[
                TeacherSectionHeader('Deskripsi'),
                Text(quiz.description),
              ],
              const SizedBox(height: EmiSpacing.md),
              for (var index = 0; index < quiz.questions.length; index++) ...[
                TeacherListCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${index + 1}. ${quiz.questions[index].text}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (quiz.questions[index].imageUrl != null) ...[
                        const SizedBox(height: EmiSpacing.sm),
                        Image.network(
                          quiz.questions[index].imageUrl!,
                          height: 180,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Text(
                            'Gambar soal tidak dapat ditampilkan.',
                          ),
                        ),
                      ],
                      const SizedBox(height: EmiSpacing.sm),
                      if (quiz.questions[index].type == 'multiple_choice')
                        for (final option in quiz.questions[index].options)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: EmiSpacing.xs,
                            ),
                            child: Text(
                              '${option.correct ? '✓' : '○'} ${option.text}${option.correct ? ' (Jawaban benar)' : ''}',
                            ),
                          )
                      else
                        Text(
                          quiz.questions[index].correctAnswer.isEmpty
                              ? 'Siswa mengisi jawaban singkat.'
                              : 'Jawaban benar: ${quiz.questions[index].correctAnswer}',
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: EmiSpacing.sm),
              ],
            ],
          ),
        ),
  );
}

class TeacherQuizFormScreen extends ConsumerStatefulWidget {
  const TeacherQuizFormScreen({super.key, this.id});
  final String? id;
  @override
  ConsumerState<TeacherQuizFormScreen> createState() =>
      _TeacherQuizFormScreenState();
}

class _TeacherQuizFormScreenState extends ConsumerState<TeacherQuizFormScreen> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController(),
      description = TextEditingController(),
      instructions = TextEditingController(),
      duration = TextEditingController(text: '30'),
      attempts = TextEditingController(text: '1'),
      open = TextEditingController(),
      close = TextEditingController();
  bool showResult = true, filled = false, saving = false, dirty = false;
  DateTime? openAt, closeAt;
  @override
  void dispose() {
    for (final c in [
      title,
      description,
      instructions,
      duration,
      attempts,
      open,
      close,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.id == null) return _shell(null);
    return ref
        .watch(teacherQuizDetailProvider(widget.id!))
        .when(
          loading: () => const TeacherShell(
            title: 'Edit Kuis',
            fallbackRoute: '/teacher/quizzes',
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => TeacherShell(
            title: 'Edit Kuis',
            fallbackRoute: '/teacher/quizzes',
            child: _State(
              title: 'Kuis belum bisa dimuat',
              message: 'Coba lagi.',
              retry: () =>
                  ref.invalidate(teacherQuizDetailProvider(widget.id!)),
            ),
          ),
          data: (quiz) {
            if (!filled) {
              title.text = quiz.title;
              description.text = quiz.description;
              instructions.text = quiz.instructions;
              duration.text = '${quiz.durationMinutes}';
              attempts.text = '${quiz.maxAttempts}';
              openAt = quiz.openAt?.toLocal();
              closeAt = quiz.closeAt?.toLocal();
              open.text = _dateTime(openAt);
              close.text = _dateTime(closeAt);
              showResult = quiz.showResult;
              filled = true;
            }
            return _shell(quiz);
          },
        );
  }

  Widget _shell(TeacherQuiz? quiz) => TeacherShell(
    title: quiz == null ? 'Buat Kuis' : 'Edit Kuis',
    fallbackRoute: quiz == null
        ? '/teacher/quizzes'
        : '/teacher/quizzes/${quiz.id}',
    onBack: () => _leave(quiz),
    child: Form(
      key: form,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(EmiSpacing.md),
              children: [
                _section(
                  context,
                  'Informasi Kuis',
                  Icons.info_outline,
                  leading: false,
                ),
                _field(title, 'Judul Kuis', required: true),
                _field(description, 'Deskripsi', lines: 3),
                _field(instructions, 'Petunjuk', lines: 3),
                const SizedBox(height: EmiSpacing.sm),
                _section(context, 'Aturan Pengerjaan', Icons.rule_outlined),
                _field(
                  duration,
                  'Durasi (menit)',
                  number: true,
                  positive: true,
                ),
                _field(
                  attempts,
                  'Maksimal Percobaan',
                  number: true,
                  positive: true,
                ),
                _section(context, 'Jadwal', Icons.calendar_today_outlined),
                _scheduleField(open, 'Buka pada', openAt, (value) {
                  openAt = value;
                  open.text = _dateTime(value);
                }),
                _scheduleField(close, 'Tutup pada', closeAt, (value) {
                  closeAt = value;
                  close.text = _dateTime(value);
                }),
                _section(context, 'Status', Icons.visibility_outlined),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: showResult,
                  title: const Text('Tampilkan hasil ke siswa'),
                  onChanged: (v) => setState(() {
                    showResult = v;
                    dirty = true;
                  }),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(
              EmiSpacing.md,
              EmiSpacing.sm,
              EmiSpacing.md,
              EmiSpacing.md,
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: saving ? null : () => _save(quiz),
                child: Text(saving ? 'Menyimpan...' : 'Simpan'),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _section(
    BuildContext context,
    String title,
    IconData icon, {
    bool leading = true,
  }) => TeacherSectionHeader(title, icon: icon, leading: leading);

  Future<void> _leave(TeacherQuiz? quiz) async {
    if (dirty && await _confirm(context, 'Batalkan perubahan?') != true) return;
    if (!mounted) return;
    final fallback = quiz == null
        ? '/teacher/quizzes'
        : '/teacher/quizzes/${quiz.id}';
    context.canPop() ? context.pop() : context.go(fallback);
  }

  Widget _field(
    TextEditingController c,
    String label, {
    bool required = false,
    bool number = false,
    bool positive = false,
    bool date = false,
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: EmiSpacing.md),
    child: TextFormField(
      controller: c,
      maxLines: lines,
      keyboardType: number ? TextInputType.number : null,
      decoration: InputDecoration(labelText: label),
      onChanged: (_) => setState(() => dirty = true),
      validator: (v) {
        if (required && (v?.trim().isEmpty ?? true)) {
          return '$label wajib diisi.';
        }
        if (positive && (int.tryParse(v ?? '') ?? 0) < 1) {
          return 'Nilai minimal 1.';
        }
        if (date && v!.isNotEmpty && DateTime.tryParse(v) == null) {
          return 'Gunakan tanggal ISO 8601 yang valid.';
        }
        return null;
      },
    ),
  );
  Widget _scheduleField(
    TextEditingController controller,
    String label,
    DateTime? value,
    ValueChanged<DateTime?> update,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: EmiSpacing.md),
    child: TextFormField(
      key: ValueKey(label),
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: '$label (opsional)',
        suffixIcon: value == null
            ? const Icon(Icons.calendar_today_outlined)
            : IconButton(
                tooltip: 'Hapus $label',
                onPressed: () => setState(() {
                  update(null);
                  dirty = true;
                }),
                icon: const Icon(Icons.clear),
              ),
      ),
      onTap: () async {
        final initial = value ?? DateTime.now();
        final date = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (date == null || !mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(initial),
        );
        if (time == null) return;
        setState(() {
          update(
            DateTime(date.year, date.month, date.day, time.hour, time.minute),
          );
          dirty = true;
        });
      },
    ),
  );

  Future<void> _save(TeacherQuiz? quiz) async {
    if (!form.currentState!.validate()) return;
    final dashboard = await ref.read(teacherDashboardProvider.future);
    if (!mounted) return;
    if (dashboard.classId == null) {
      _notice(context, 'Belum ada kelas aktif.');
      return;
    }
    final scheduleError = teacherQuizScheduleError(openAt, closeAt);
    if (scheduleError != null) {
      _notice(context, scheduleError);
      return;
    }
    setState(() => saving = true);
    try {
      final data = {
        'class_id': dashboard.classId,
        'title': title.text.trim(),
        'description': description.text.trim(),
        'instructions': instructions.text.trim(),
        'duration_minutes': int.parse(duration.text),
        'max_attempts': int.parse(attempts.text),
        'show_result': showResult,
        ...teacherQuizSchedulePayload(openAt, closeAt),
      };
      final repository = ref.read(teacherQuizRepositoryProvider);
      final saved = quiz == null
          ? await repository.create(data)
          : await repository.update(quiz.id, data);
      ref.invalidate(teacherQuizDetailProvider(saved.id));
      await repository.list();
      ref.invalidate(teacherQuizzesProvider);
      if (mounted) context.go('/teacher/quizzes/${saved.id}');
    } catch (error) {
      if (mounted) _notice(context, _error(error));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}

class TeacherQuestionFormScreen extends ConsumerStatefulWidget {
  const TeacherQuestionFormScreen({super.key, required this.quizId, this.id});
  final String quizId;
  final String? id;
  @override
  ConsumerState<TeacherQuestionFormScreen> createState() =>
      _TeacherQuestionFormScreenState();
}

class _TeacherQuestionFormScreenState
    extends ConsumerState<TeacherQuestionFormScreen> {
  final form = GlobalKey<FormState>(),
      text = TextEditingController(),
      answer = TextEditingController(),
      points = TextEditingController(text: '1'),
      explanation = TextEditingController();
  final options = List.generate(4, (_) => TextEditingController());
  int correct = 0, existingOrder = 1;
  String type = 'multiple_choice';
  String? imageMediaId, imageUrl, imagePath, imageName;
  bool filled = false, dirty = false, saving = false;
  @override
  void dispose() {
    for (final c in [text, answer, points, explanation, ...options]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.id == null) return _body(null);
    return ref
        .watch(teacherQuizQuestionProvider(widget.id!))
        .when(
          loading: () => const TeacherShell(
            title: 'Edit Soal',
            fallbackRoute: '/teacher/quizzes',
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => TeacherShell(
            title: 'Edit Soal',
            fallbackRoute: '/teacher/quizzes/${widget.quizId}',
            child: _State(
              title: 'Soal belum bisa dimuat',
              message: 'Coba lagi.',
              retry: () =>
                  ref.invalidate(teacherQuizQuestionProvider(widget.id!)),
            ),
          ),
          data: (q) {
            if (!filled) {
              type = q.type;
              text.text = q.text;
              answer.text = q.correctAnswer;
              points.text = '${q.points}';
              existingOrder = q.order;
              explanation.text = q.explanation;
              imageMediaId = q.imageMediaId;
              imageUrl = q.imageUrl;
              imageName = q.imageName;
              while (options.length < q.options.length) {
                options.add(TextEditingController());
              }
              for (var i = 0; i < q.options.length; i++) {
                options[i].text = q.options[i].text;
                if (q.options[i].correct) correct = i;
              }
              filled = true;
            }
            return _body(q);
          },
        );
  }

  Widget _body(TeacherQuizQuestion? q) => TeacherShell(
    title: q == null ? 'Buat Soal' : 'Edit Soal',
    fallbackRoute: '/teacher/quizzes/${widget.quizId}',
    onBack: _leave,
    child: Form(
      key: form,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(EmiSpacing.md),
              children: [
                TeacherSectionHeader(
                  'Pertanyaan',
                  icon: Icons.help_outline,
                  leading: false,
                ),
                _input(text, 'Pertanyaan', true),
                TeacherSectionHeader('Tipe Soal'),
                DropdownButtonFormField(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Tipe Soal'),
                  items: const [
                    DropdownMenuItem(
                      value: 'multiple_choice',
                      child: Text('Pilihan ganda'),
                    ),
                    DropdownMenuItem(
                      value: 'short_answer',
                      child: Text('Jawaban singkat'),
                    ),
                  ],
                  onChanged: (v) => setState(() {
                    type = v!;
                    dirty = true;
                  }),
                ),
                TeacherSectionHeader('Poin'),
                _input(points, 'Poin', true, number: true),
                if (type == 'short_answer') ...[
                  TeacherSectionHeader('Jawaban Benar'),
                  _input(answer, 'Jawaban Benar', true),
                ],
                if (type == 'multiple_choice') ...[
                  TeacherSectionHeader('Pilihan Jawaban'),
                  for (var i = 0; i < options.length; i++)
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Jadikan pilihan ${i + 1} jawaban benar',
                          onPressed: () => setState(() {
                            correct = i;
                            dirty = true;
                          }),
                          icon: Icon(
                            correct == i
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                          ),
                        ),
                        Expanded(
                          child: _input(options[i], 'Pilihan ${i + 1}', true),
                        ),
                        if (options.length > 2)
                          IconButton(
                            tooltip: 'Hapus pilihan ${i + 1}',
                            onPressed: () => setState(() {
                              options.removeAt(i).dispose();
                              if (correct == i) correct = 0;
                              if (correct > i) correct--;
                              dirty = true;
                            }),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                      ],
                    ),
                  TextButton.icon(
                    onPressed: () => setState(() {
                      options.add(TextEditingController());
                      dirty = true;
                    }),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Pilihan'),
                  ),
                  const SizedBox(height: EmiSpacing.xs),
                  Text(
                    'Pilih tombol radio pada jawaban yang benar.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: EmiColors.textSecondary,
                    ),
                  ),
                ],
                TeacherSectionHeader('Penjelasan'),
                _input(explanation, 'Penjelasan', false),
                TeacherSectionHeader('Gambar Soal', icon: Icons.image_outlined),
                if (imagePath != null)
                  Image.file(File(imagePath!), height: 160, fit: BoxFit.contain)
                else if (imageUrl != null)
                  Image.network(imageUrl!, height: 160, fit: BoxFit.contain)
                else if (imageMediaId != null)
                  Text(imageName ?? 'Gambar soal terhubung.'),
                const SizedBox(height: EmiSpacing.sm),
                Wrap(
                  spacing: EmiSpacing.sm,
                  children: [
                    OutlinedButton.icon(
                      onPressed: saving ? null : _pickImage,
                      icon: const Icon(Icons.image_outlined),
                      label: Text(
                        imageMediaId == null ? 'Pilih Gambar' : 'Ganti Gambar',
                      ),
                    ),
                    if (imageMediaId != null || imagePath != null)
                      OutlinedButton(
                        onPressed: saving
                            ? null
                            : () => setState(() {
                                imageMediaId = imageUrl = imagePath =
                                    imageName = null;
                                dirty = true;
                              }),
                        child: const Text('Lepas Gambar'),
                      ),
                  ],
                ),
                if (q != null) ...[
                  const SizedBox(height: EmiSpacing.md),
                  OutlinedButton(
                    onPressed: saving ? null : _delete,
                    child: const Text('Hapus Soal'),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(
              EmiSpacing.md,
              EmiSpacing.sm,
              EmiSpacing.md,
              EmiSpacing.md,
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: saving ? null : _save,
                child: Text(saving ? 'Menyimpan...' : 'Simpan Soal'),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _leave() async {
    if (dirty && await _confirm(context, 'Batalkan perubahan?') != true) return;
    if (!mounted) return;
    final fallback = '/teacher/quizzes/${widget.quizId}';
    context.canPop() ? context.pop() : context.go(fallback);
  }

  Widget _input(
    TextEditingController c,
    String label,
    bool required, {
    bool number = false,
  }) => TextFormField(
    controller: c,
    keyboardType: number ? TextInputType.number : null,
    decoration: InputDecoration(labelText: label),
    onChanged: (_) => setState(() => dirty = true),
    validator: (v) => (required && (v?.trim().isEmpty ?? true))
        ? '$label wajib diisi.'
        : number && (int.tryParse(v ?? '') ?? 0) < 1
        ? 'Nilai minimal 1.'
        : null,
  );
  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (!mounted || result == null || result.files.single.path == null) return;
    final file = result.files.single;
    if (file.size > 5 * 1024 * 1024) {
      _notice(context, 'Ukuran gambar maksimal 5 MB.');
      return;
    }
    setState(() {
      imagePath = file.path;
      imageName = file.name;
      dirty = true;
    });
  }

  Future<void> _save() async {
    if (!form.currentState!.validate()) return;
    setState(() => saving = true);
    final repository = ref.read(teacherQuizRepositoryProvider);
    try {
      if (imagePath != null) {
        imageMediaId = await repository.uploadQuestionImage(
          imagePath!,
          imageName ?? 'question.png',
        );
      }
    } catch (e) {
      if (mounted) _notice(context, _error(e));
      if (mounted) setState(() => saving = false);
      return;
    }
    final data = {
      'question_type': type,
      'question_text': text.text.trim(),
      'points': int.parse(points.text),
      if (widget.id != null) 'order_number': existingOrder,
      'explanation': explanation.text.trim(),
      'image_media_id': imageMediaId,
      if (type == 'short_answer') 'correct_answer_text': answer.text.trim(),
      if (type == 'multiple_choice')
        'options': [
          for (var i = 0; i < options.length; i++)
            {
              'option_text': options[i].text.trim(),
              'is_correct': i == correct,
              'order_number': i + 1,
            },
        ],
    };
    try {
      widget.id == null
          ? await ref
                .read(teacherQuizRepositoryProvider)
                .createQuestion(widget.quizId, data)
          : await ref
                .read(teacherQuizRepositoryProvider)
                .updateQuestion(widget.id!, data);
      ref.invalidate(teacherQuizDetailProvider(widget.quizId));
      if (mounted) context.go('/teacher/quizzes/${widget.quizId}');
    } catch (e) {
      if (mounted) _notice(context, _error(e));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _delete() async {
    if (saving) return;
    setState(() => saving = true);
    if (await _confirm(context, 'Hapus soal ini?') != true) {
      if (mounted) setState(() => saving = false);
      return;
    }
    try {
      await ref.read(teacherQuizRepositoryProvider).deleteQuestion(widget.id!);
      ref.invalidate(teacherQuizDetailProvider(widget.quizId));
      if (mounted) context.go('/teacher/quizzes/${widget.quizId}');
    } catch (e) {
      if (mounted) _notice(context, _error(e));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}

class TeacherQuizResultsScreen extends ConsumerStatefulWidget {
  const TeacherQuizResultsScreen({super.key, required this.quizId});
  final String quizId;
  @override
  ConsumerState<TeacherQuizResultsScreen> createState() =>
      _TeacherQuizResultsScreenState();
}

class _TeacherQuizResultsScreenState
    extends ConsumerState<TeacherQuizResultsScreen> {
  int page = 1;
  String status = '';

  Future<void> _exportCsv() async {
    try {
      final bytes = await ref
          .read(teacherQuizRepositoryProvider)
          .reportCsv(quizId: widget.quizId, status: status);
      final file = File(
        '${(await getTemporaryDirectory()).path}/hasil-kuis.csv',
      );
      await file.writeAsBytes(bytes, flush: true);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: 'Hasil Kuis CSV'),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengekspor hasil kuis CSV.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = (quizId: widget.quizId, page: page, status: status);
    final attempts = ref.watch(teacherQuizAttemptsProvider(filter));
    final reportFilter = (page: page, quizId: widget.quizId, status: status);
    final report = ref.watch(teacherQuizReportProvider(reportFilter));
    final classQuizReport = ref.watch(
      teacherClassQuizReportProvider(widget.quizId),
    );
    return TeacherShell(
      title: 'Hasil Kuis',
      fallbackRoute: '/teacher/quizzes/${widget.quizId}',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              EmiSpacing.md,
              EmiSpacing.md,
              EmiSpacing.md,
              0,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _exportCsv,
                icon: const Icon(Icons.share, size: 20),
                label: const Text('Export CSV Hasil Kuis'),
              ),
            ),
          ),
          classQuizReport.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (summary) => Padding(
              padding: const EdgeInsets.fromLTRB(
                EmiSpacing.md,
                EmiSpacing.sm,
                EmiSpacing.md,
                0,
              ),
              child: TeacherListCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.analytics_outlined,
                          color: EmiColors.primary,
                        ),
                        const SizedBox(width: EmiSpacing.xs),
                        Text(
                          'Statistik Kuis Kelas',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: TeacherStyle.ink,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: EmiSpacing.xs),
                    Wrap(
                      spacing: EmiSpacing.md,
                      runSpacing: EmiSpacing.xs,
                      children: [
                        Text(
                          'Siswa: ${summary.studentCount}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'Total Attempt: ${summary.attemptsCount}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'Selesai: ${summary.submittedCount}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (summary.averageScorePercent != null)
                          Text(
                            'Rata-rata: ${summary.averageScorePercent}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: EmiColors.primary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          report.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const SizedBox.shrink(),
            data: (data) => Padding(
              padding: const EdgeInsets.fromLTRB(
                EmiSpacing.md,
                EmiSpacing.md,
                EmiSpacing.md,
                0,
              ),
              child: Wrap(
                spacing: EmiSpacing.sm,
                runSpacing: EmiSpacing.sm,
                children: [
                  _ResultMetric('Rata-rata', data.average, percent: true),
                  _ResultMetric('Tertinggi', data.highest, percent: true),
                  _ResultMetric('Terendah', data.lowest, percent: true),
                  _ResultMetric('Siswa berhak', data.eligibleStudents),
                  _ResultMetric('Berpartisipasi', data.participatingStudents),
                  _ResultMetric('Hasil final', data.finalizedStudents),
                  _ResultMetric('Belum mencoba', data.notAttemptedStudents),
                  _ResultMetric('Attempt dikumpulkan', data.submittedAttempts),
                  _ResultMetric('Attempt berakhir', data.expiredAttempts),
                  _ResultMetric('Sedang dikerjakan', data.inProgressAttempts),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(EmiSpacing.md),
            child: DropdownButtonFormField<String>(
              initialValue: status,
              decoration: const InputDecoration(labelText: 'Status attempt'),
              items: const [
                DropdownMenuItem(value: '', child: Text('Semua status')),
                DropdownMenuItem(
                  value: 'in_progress',
                  child: Text('Sedang dikerjakan'),
                ),
                DropdownMenuItem(
                  value: 'submitted',
                  child: Text('Dikumpulkan'),
                ),
                DropdownMenuItem(value: 'expired', child: Text('Berakhir')),
              ],
              onChanged: (value) => setState(() {
                status = value ?? '';
                page = 1;
              }),
            ),
          ),
          Expanded(
            child: attempts.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => _State(
                title: 'Gagal memuat attempt',
                message: 'Hasil kuis belum bisa dimuat. Coba lagi.',
                retry: () =>
                    ref.invalidate(teacherQuizAttemptsProvider(filter)),
              ),
              data: (data) => data.items.isEmpty
                  ? const _State(
                      title: 'Attempt kosong',
                      message: 'Belum ada attempt siswa untuk kuis ini.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        EmiSpacing.md,
                        0,
                        EmiSpacing.md,
                        EmiSpacing.md,
                      ),
                      itemCount: data.items.length + 1,
                      itemBuilder: (context, index) {
                        if (index == data.items.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: EmiSpacing.xs),
                            child: TeacherPaginationBar(
                              currentPage: data.page,
                              lastPage: data.lastPage,
                              onPrevious: page > 1
                                  ? () => setState(() => page--)
                                  : null,
                              onNext: page < data.lastPage
                                  ? () => setState(() => page++)
                                  : null,
                            ),
                          );
                        }
                        final item = data.items[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: EmiSpacing.sm),
                          child: TeacherListCard(
                            padding: EdgeInsets.zero,
                            onTap: () => context.push(
                              '/teacher/quizzes/${widget.quizId}/results/${item.id}',
                            ),
                            child: ListTile(
                              title: Text(
                                item.studentName,
                                style: const TextStyle(color: TeacherStyle.ink),
                              ),
                              subtitle: Text(
                                '${_attemptStatus(item.status)} • Attempt #${item.number} • Skor ${item.scorePercent ?? '-'}%',
                                style: const TextStyle(
                                  color: TeacherStyle.inkMuted,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: TeacherStyle.inkMuted,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultMetric extends StatelessWidget {
  const _ResultMetric(this.label, this.value, {this.percent = false});
  final String label;
  final num? value;
  final bool percent;
  @override
  Widget build(BuildContext context) => TeacherStatChip(
    label: label,
    value: value == null
        ? 'Belum tersedia'
        : percent
        ? '${value!.toStringAsFixed(1)}%'
        : '$value',
  );
}

class TeacherQuizAttemptScreen extends ConsumerWidget {
  const TeacherQuizAttemptScreen({
    super.key,
    required this.quizId,
    required this.attemptId,
  });
  final String quizId;
  final String attemptId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => TeacherShell(
    title: 'Detail Attempt',
    fallbackRoute: '/teacher/quizzes/$quizId/results',
    child: ref
        .watch(teacherQuizAttemptProvider(attemptId))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _State(
            title: 'Gagal memuat detail attempt',
            message: 'Detail attempt belum bisa dimuat. Coba lagi.',
            retry: () => ref.invalidate(teacherQuizAttemptProvider(attemptId)),
          ),
          data: (item) => ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              TeacherPageHeader(
                icon: Icons.person_outline,
                title: item.studentName,
                subtitle:
                    '${_attemptStatus(item.status)} • Attempt #${item.number}',
              ),
              const SizedBox(height: EmiSpacing.md),
              Wrap(
                spacing: EmiSpacing.sm,
                runSpacing: EmiSpacing.sm,
                children: [
                  TeacherStatChip(
                    label: 'Skor',
                    value:
                        '${item.scorePercent ?? '-'}% (${item.scorePoints ?? '-'}/${item.maxPoints ?? '-'})',
                  ),
                  TeacherStatChip(label: 'Mulai', value: _date(item.startedAt)),
                  TeacherStatChip(
                    label: 'Dikumpulkan',
                    value: _date(item.submittedAt),
                  ),
                ],
              ),
              TeacherSectionHeader('Jawaban', icon: Icons.checklist_outlined),
              if (item.answers.isEmpty)
                TeacherListCard(
                  child: Text(
                    'Detail jawaban kosong.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: EmiColors.textSecondary,
                    ),
                  ),
                )
              else
                for (final answer in item.answers) ...[
                  TeacherListCard(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      title: Text(
                        answer.answerText,
                        style: const TextStyle(color: TeacherStyle.ink),
                      ),
                      subtitle: Text(
                        'Poin: ${answer.awardedPoints ?? '-'} / ${answer.maxPoints ?? '-'}',
                        style: const TextStyle(color: TeacherStyle.inkMuted),
                      ),
                      trailing: answer.correct == null
                          ? null
                          : Icon(
                              answer.correct!
                                  ? Icons.check_circle_outline
                                  : Icons.cancel_outlined,
                              color: answer.correct!
                                  ? EmiColors.success
                                  : EmiColors.error,
                            ),
                    ),
                  ),
                  const SizedBox(height: EmiSpacing.sm),
                ],
            ],
          ),
        ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: EmiSpacing.sm,
      vertical: EmiSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: status == 'published'
          ? EmiColors.success
          : status == 'archived'
          ? TeacherStyle.tintStrong
          : EmiColors.warning,
      borderRadius: BorderRadius.circular(EmiRadii.pill),
    ),
    child: Text(
      _status(status),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: status == 'archived' ? TeacherStyle.ink : Colors.white,
      ),
    ),
  );
}

class _State extends StatelessWidget {
  const _State({required this.title, required this.message, this.retry});
  final String title, message;
  final VoidCallback? retry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.quiz_outlined,
            size: 48,
            color: TeacherStyle.inkMuted,
          ),
          const SizedBox(height: EmiSpacing.sm),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: TeacherStyle.ink),
          ),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: TeacherStyle.inkMuted),
          ),
          if (retry != null)
            TextButton(onPressed: retry, child: const Text('Coba Lagi')),
        ],
      ),
    ),
  );
}

void _showReorderQuestionsDialog(
  BuildContext context,
  WidgetRef ref,
  String quizId,
  List<TeacherQuizQuestion> initialQuestions,
) {
  if (initialQuestions.length < 2) return;
  final ordered = List<TeacherQuizQuestion>.from(initialQuestions);
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
                'Ubah Urutan Soal',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: EmiSpacing.xs),
              const Text(
                'Tahan dan geser item untuk mengubah nomor urut soal.',
              ),
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
                    final question = ordered[index];
                    return ListTile(
                      key: ValueKey(question.id),
                      leading: CircleAvatar(
                        backgroundColor: TeacherStyle.tint,
                        foregroundColor: EmiColors.primary,
                        child: Text('${index + 1}'),
                      ),
                      title: Text(
                        question.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                          await ref
                              .read(teacherQuizRepositoryProvider)
                              .reorderQuestions(
                                quizId,
                                ordered.map((e) => e.id).toList(),
                              );
                          ref.invalidate(teacherQuizDetailProvider(quizId));
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          setModalState(() => saving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(_error(e))));
                          }
                        }
                      },
                child: Text(saving ? 'Menyimpan...' : 'Simpan Urutan Soal'),
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

String? teacherQuizScheduleError(DateTime? openAt, DateTime? closeAt) =>
    openAt != null && closeAt != null && !closeAt.isAfter(openAt)
    ? 'Waktu tutup harus setelah waktu buka.'
    : null;
Map<String, String?> teacherQuizSchedulePayload(
  DateTime? openAt,
  DateTime? closeAt,
) => {
  'open_at': openAt?.toUtc().toIso8601String(),
  'close_at': closeAt?.toUtc().toIso8601String(),
};

String _date(DateTime? value) =>
    value == null ? 'Belum tersedia' : _dateTime(value.toLocal());
String _dateTime(DateTime? value) => value == null
    ? ''
    : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
String _attemptStatus(String value) => switch (value) {
  'submitted' => 'Dikumpulkan',
  'expired' => 'Berakhir',
  'in_progress' => 'Sedang dikerjakan',
  _ => 'Status tidak diketahui',
};
String _status(String v) => switch (v) {
  'published' => 'Terbit',
  'archived' => 'Diarsipkan',
  _ => 'Draf',
};
String _error(Object e) =>
    e is AppError ? e.message : 'Tindakan belum berhasil. Coba lagi.';
void _notice(BuildContext c, String value) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(value)));
Future<bool?> _confirm(BuildContext c, String title) => showDialog<bool>(
  context: c,
  builder: (c) => AlertDialog(
    title: Text(title),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(c, false),
        child: const Text('Batal'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(c, true),
        child: const Text('Lanjut'),
      ),
    ],
  ),
);
