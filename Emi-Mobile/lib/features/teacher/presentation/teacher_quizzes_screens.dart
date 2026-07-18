import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../core/errors/app_error.dart';
import '../../../shared/widgets/emi_card.dart';
import '../data/teacher_providers.dart';
import '../data/teacher_quiz_models.dart';
import 'teacher_shell.dart';

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
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(EmiSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Kelola kuis untuk kelas Anda.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: EmiSpacing.sm),
                TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    labelText: 'Cari kuis',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (_) => setState(() => page = 1),
                ),
                const SizedBox(height: EmiSpacing.sm),
                Wrap(
                  spacing: EmiSpacing.sm,
                  runSpacing: EmiSpacing.sm,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    FilledButton.icon(
                      onPressed: () => context.push('/teacher/quizzes/create'),
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Kuis'),
                    ),
                    DropdownButton<String>(
                      value: status,
                      items: const [
                        DropdownMenuItem(value: '', child: Text('Semua')),
                        DropdownMenuItem(value: 'draft', child: Text('Draf')),
                        DropdownMenuItem(
                          value: 'published',
                          child: Text('Terbit'),
                        ),
                        DropdownMenuItem(
                          value: 'archived',
                          child: Text('Diarsipkan'),
                        ),
                      ],
                      onChanged: (v) => setState(() {
                        status = v ?? '';
                        page = 1;
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: value.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => _State(
                title: 'Gagal memuat kuis',
                message:
                    'Kuis kelas belum bisa dimuat. Periksa koneksi internet, lalu coba lagi.',
                retry: () => ref.invalidate(teacherQuizzesProvider(filter)),
              ),
              data: (data) => data.items.isEmpty
                  ? const _State(
                      title: 'Kuis belum tersedia',
                      message: 'Belum ada kuis kelas yang bisa dikelola.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: EmiSpacing.md,
                      ),
                      itemCount: data.items.length + 1,
                      itemBuilder: (context, index) {
                        if (index == data.items.length) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: page > 1
                                    ? () => setState(() => page--)
                                    : null,
                                icon: const Icon(Icons.chevron_left),
                              ),
                              Text(
                                'Halaman ${data.page} dari ${data.lastPage}',
                              ),
                              IconButton(
                                onPressed: page < data.lastPage
                                    ? () => setState(() => page++)
                                    : null,
                                icon: const Icon(Icons.chevron_right),
                              ),
                            ],
                          );
                        }
                        final quiz = data.items[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: EmiSpacing.sm),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(EmiRadii.card),
                            onTap: () =>
                                context.push('/teacher/quizzes/${quiz.id}'),
                            child: EmiCard(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.quiz_outlined, size: 28),
                                  const SizedBox(width: EmiSpacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          quiz.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleLarge,
                                        ),
                                        Text(
                                          quiz.className ?? 'Kelas aktif',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${quiz.questionsCount} pertanyaan • ${quiz.attemptsCount} siswa mengerjakan',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: EmiSpacing.xs),
                                        _StatusBadge(status: quiz.status),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) => value == 'result'
                                        ? context.push(
                                            '/teacher/quizzes/${quiz.id}/results',
                                          )
                                        : context.push(
                                            '/teacher/quizzes/${quiz.id}/edit',
                                          ),
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Edit Kuis'),
                                      ),
                                      PopupMenuItem(
                                        value: 'result',
                                        child: Text('Lihat Hasil'),
                                      ),
                                    ],
                                  ),
                                ],
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

class TeacherQuizDetailScreen extends ConsumerWidget {
  const TeacherQuizDetailScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => TeacherShell(
    title: 'Detail Kuis',
    fallbackRoute: '/teacher/quizzes',
    child: ref
        .watch(teacherQuizDetailProvider(id))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _State(
            title: 'Detail kuis belum bisa dimuat',
            message: 'Periksa koneksi internet, lalu coba lagi.',
            retry: () => ref.invalidate(teacherQuizDetailProvider(id)),
          ),
          data: (quiz) => ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              Text(
                quiz.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                '${quiz.className ?? 'Kelas aktif'} • ${_status(quiz.status)}',
              ),
              const SizedBox(height: EmiSpacing.md),
              Text(
                quiz.description.isEmpty
                    ? 'Tanpa deskripsi.'
                    : quiz.description,
              ),
              Text('Durasi: ${quiz.durationMinutes} menit'),
              Text('Maksimal percobaan: ${quiz.maxAttempts}'),
              Text('Jumlah soal: ${quiz.questionsCount}'),
              Text('Jumlah attempt: ${quiz.attemptsCount}'),
              Text('Terakhir diperbarui: ${_date(quiz.updatedAt)}'),
              if (quiz.openAt != null)
                Text('Dibuka: ${quiz.openAt!.toLocal()}'),
              if (quiz.closeAt != null)
                Text('Ditutup: ${quiz.closeAt!.toLocal()}'),
              const SizedBox(height: EmiSpacing.md),
              FilledButton(
                onPressed: () => context.push('/teacher/quizzes/$id/edit'),
                child: const Text('Edit Kuis'),
              ),
              OutlinedButton(
                onPressed: () => context.push('/teacher/quizzes/$id/results'),
                child: const Text('Lihat Hasil'),
              ),
              if (quiz.status == 'draft')
                OutlinedButton(
                  onPressed: () => _action(context, ref, quiz, true),
                  child: const Text('Terbitkan Kuis'),
                ),
              if (quiz.status == 'published')
                OutlinedButton(
                  onPressed: () => _action(context, ref, quiz, false),
                  child: const Text('Arsipkan Kuis'),
                ),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Daftar Soal',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: quiz.status == 'draft'
                        ? () => context.push(
                            '/teacher/quizzes/$id/questions/create',
                          )
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              if (quiz.questions.isEmpty)
                const Text('Belum ada soal.')
              else
                for (final question in quiz.questions)
                  ListTile(
                    title: Text(question.text),
                    subtitle: Text(
                      '${question.points} poin • ${question.type == 'multiple_choice' ? 'Pilihan ganda' : 'Jawaban singkat'}',
                    ),
                    onTap: quiz.status == 'draft'
                        ? () => context.push(
                            '/teacher/quizzes/$id/questions/${question.id}/edit',
                          )
                        : null,
                  ),
            ],
          ),
        ),
  );

  Future<void> _action(
    BuildContext context,
    WidgetRef ref,
    TeacherQuiz quiz,
    bool publish,
  ) async {
    if (publish && quiz.questionsCount < 1) {
      _notice(context, 'Tambahkan minimal satu soal sebelum menerbitkan kuis.');
      return;
    }
    if (await _confirm(
          context,
          publish ? 'Terbitkan kuis?' : 'Arsipkan kuis?',
        ) !=
        true) {
      return;
    }
    try {
      publish
          ? await ref.read(teacherQuizRepositoryProvider).publish(quiz.id)
          : await ref.read(teacherQuizRepositoryProvider).archive(quiz.id);
      final _ = await ref.refresh(teacherQuizDetailProvider(quiz.id).future);
      ref.invalidate(teacherQuizzesProvider);
    } catch (error) {
      if (context.mounted) _notice(context, _error(error));
    }
  }
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
              open.text = quiz.openAt?.toIso8601String() ?? '';
              close.text = quiz.closeAt?.toIso8601String() ?? '';
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
      child: ListView(
        padding: const EdgeInsets.all(EmiSpacing.md),
        children: [
          _field(title, 'Judul Kuis', required: true),
          _field(description, 'Deskripsi', lines: 3),
          _field(instructions, 'Petunjuk', lines: 3),
          _field(duration, 'Durasi (menit)', number: true, positive: true),
          _field(attempts, 'Maksimal Percobaan', number: true, positive: true),
          _field(open, 'Buka pada (ISO 8601, opsional)', date: true),
          _field(close, 'Tutup pada (ISO 8601, opsional)', date: true),
          SwitchListTile(
            value: showResult,
            title: const Text('Tampilkan hasil ke siswa'),
            onChanged: (v) => setState(() {
              showResult = v;
              dirty = true;
            }),
          ),
          FilledButton(
            onPressed: saving ? null : () => _save(quiz),
            child: Text(saving ? 'Menyimpan...' : 'Simpan'),
          ),
        ],
      ),
    ),
  );

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
  Future<void> _save(TeacherQuiz? quiz) async {
    if (!form.currentState!.validate()) return;
    final dashboard = await ref.read(teacherDashboardProvider.future);
    if (!mounted) return;
    if (dashboard.classId == null) {
      _notice(context, 'Belum ada kelas aktif.');
      return;
    }
    if (open.text.isNotEmpty &&
        close.text.isNotEmpty &&
        !DateTime.parse(close.text).isAfter(DateTime.parse(open.text))) {
      _notice(context, 'Waktu tutup harus setelah waktu buka.');
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
        'open_at': open.text.isEmpty ? null : open.text,
        'close_at': close.text.isEmpty ? null : close.text,
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
      child: ListView(
        padding: const EdgeInsets.all(EmiSpacing.md),
        children: [
          DropdownButtonFormField(
            initialValue: type,
            decoration: const InputDecoration(labelText: 'Jenis Soal'),
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
          _input(text, 'Pertanyaan', true),
          _input(points, 'Poin', true, number: true),
          if (type == 'short_answer') _input(answer, 'Jawaban Benar', true),
          if (type == 'multiple_choice')
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
                  Expanded(child: _input(options[i], 'Pilihan ${i + 1}', true)),
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
          if (type == 'multiple_choice')
            TextButton.icon(
              onPressed: () => setState(() {
                options.add(TextEditingController());
                dirty = true;
              }),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Pilihan'),
            ),
          _input(explanation, 'Penjelasan', false),
          FilledButton(
            onPressed: saving ? null : _save,
            child: Text(saving ? 'Menyimpan...' : 'Simpan Soal'),
          ),
          if (q != null)
            TextButton(
              onPressed: saving ? null : _delete,
              child: const Text('Hapus Soal'),
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
  Future<void> _save() async {
    if (!form.currentState!.validate()) return;
    setState(() => saving = true);
    final data = {
      'question_type': type,
      'question_text': text.text.trim(),
      'points': int.parse(points.text),
      if (widget.id != null) 'order_number': existingOrder,
      'explanation': explanation.text.trim(),
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
    if (await _confirm(context, 'Hapus soal ini?') != true) return;
    try {
      await ref.read(teacherQuizRepositoryProvider).deleteQuestion(widget.id!);
      ref.invalidate(teacherQuizDetailProvider(widget.quizId));
      if (mounted) context.go('/teacher/quizzes/${widget.quizId}');
    } catch (e) {
      if (mounted) _notice(context, _error(e));
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
  @override
  Widget build(BuildContext context) {
    final filter = (quizId: widget.quizId, page: page, status: status);
    final attempts = ref.watch(teacherQuizAttemptsProvider(filter));
    return TeacherShell(
      title: 'Hasil Kuis',
      fallbackRoute: '/teacher/quizzes/${widget.quizId}',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(EmiSpacing.md),
            child: DropdownButton<String>(
              value: status,
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
                      itemCount: data.items.length + 1,
                      itemBuilder: (context, index) {
                        if (index == data.items.length) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: page > 1
                                    ? () => setState(() => page--)
                                    : null,
                                icon: const Icon(Icons.chevron_left),
                              ),
                              Text(
                                'Halaman ${data.page} dari ${data.lastPage}',
                              ),
                              IconButton(
                                onPressed: page < data.lastPage
                                    ? () => setState(() => page++)
                                    : null,
                                icon: const Icon(Icons.chevron_right),
                              ),
                            ],
                          );
                        }
                        final item = data.items[index];
                        return ListTile(
                          title: Text(item.studentName),
                          subtitle: Text(
                            '${_attemptStatus(item.status)} • Attempt #${item.number} • Skor ${item.scorePercent ?? '-'}%',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push(
                            '/teacher/quizzes/${widget.quizId}/results/${item.id}',
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
              Text(
                item.studentName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text('${_attemptStatus(item.status)} • Attempt #${item.number}'),
              Text(
                'Skor: ${item.scorePercent ?? '-'}% (${item.scorePoints ?? '-'} / ${item.maxPoints ?? '-'})',
              ),
              Text('Mulai: ${_date(item.startedAt)}'),
              Text('Dikumpulkan: ${_date(item.submittedAt)}'),
              const Divider(),
              Text('Jawaban', style: Theme.of(context).textTheme.titleMedium),
              if (item.answers.isEmpty)
                const Text('Detail jawaban kosong.')
              else
                for (final answer in item.answers)
                  Card(
                    child: ListTile(
                      title: Text(answer.answerText),
                      subtitle: Text(
                        'Poin: ${answer.awardedPoints ?? '-'} / ${answer.maxPoints ?? '-'}',
                      ),
                      trailing: answer.correct == null
                          ? null
                          : Icon(
                              answer.correct!
                                  ? Icons.check_circle_outline
                                  : Icons.cancel_outlined,
                            ),
                    ),
                  ),
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
          ? EmiColors.surfaceSoft
          : EmiColors.warning,
      border: Border.all(color: EmiColors.border, width: 2),
      borderRadius: BorderRadius.circular(EmiRadii.pill),
    ),
    child: Text(_status(status), style: Theme.of(context).textTheme.labelLarge),
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
          const Icon(Icons.quiz_outlined, size: 48),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          Text(message, textAlign: TextAlign.center),
          if (retry != null)
            TextButton(onPressed: retry, child: const Text('Coba Lagi')),
        ],
      ),
    ),
  );
}

String _date(DateTime? value) => value?.toLocal().toString() ?? '-';
String _attemptStatus(String value) => switch (value) {
  'submitted' => 'Dikumpulkan',
  'expired' => 'Berakhir',
  'in_progress' => 'Sedang dikerjakan',
  _ => value,
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
