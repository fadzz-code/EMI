import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../core/errors/app_error.dart';
import '../../../shared/widgets/emi_card.dart';
import '../data/admin_crud_providers.dart';
import '../data/admin_crud_repository.dart';
import 'admin_shell.dart';

class AdminQuizScreen extends ConsumerStatefulWidget {
  const AdminQuizScreen({super.key});
  @override
  ConsumerState<AdminQuizScreen> createState() => _AdminQuizScreenState();
}

class _AdminQuizScreenState extends ConsumerState<AdminQuizScreen> {
  String? _search;
  int _page = 1;
  @override
  Widget build(BuildContext context) {
    final q = AdminSearchQuery(search: _search, page: _page);
    final data = ref.watch(adminQuizProvider(q));
    return AdminShell(
      title: 'Kuis Template',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(EmiSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(hintText: 'Search'),
                    onChanged: (v) => setState(() {
                      _search = v;
                      _page = 1;
                    }),
                  ),
                ),
                IconButton.filled(
                  onPressed: () => context.go('/admin/quizzes/new'),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          Expanded(
            child: data.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _Error(
                message: e.toString(),
                onRetry: () => ref.invalidate(adminQuizProvider(q)),
              ),
              data: (page) => ListView(
                padding: const EdgeInsets.all(EmiSpacing.md),
                children: page.items.isEmpty
                    ? const [EmiCard(child: Text('Kuis belum tersedia.'))]
                    : [
                        for (final item in page.items)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: EmiSpacing.md,
                            ),
                            child: EmiCard(
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(item.title),
                                subtitle: Text(
                                  '${item.durationMinutes} menit • ${item.maxAttempts} attempt',
                                ),
                                trailing: Text(item.status ?? ''),
                                onTap: () =>
                                    context.go('/admin/quizzes/${item.id}'),
                              ),
                            ),
                          ),
                        if (page.hasMore)
                          OutlinedButton(
                            onPressed: () => setState(() => _page++),
                            child: const Text('Muat lagi'),
                          ),
                      ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminQuizFormScreen extends ConsumerStatefulWidget {
  const AdminQuizFormScreen({super.key, this.id});
  final String? id;
  @override
  ConsumerState<AdminQuizFormScreen> createState() =>
      _AdminQuizFormScreenState();
}

class _AdminQuizFormScreenState extends ConsumerState<AdminQuizFormScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _instructions = TextEditingController();
  final _duration = TextEditingController(text: '30');
  final _attempts = TextEditingController(text: '1');
  bool _showResult = true;
  bool _saving = false;
  bool _hydrated = false;
  AppError? _error;
  bool get _editing => widget.id != null && widget.id != 'new';
  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _instructions.dispose();
    _duration.dispose();
    _attempts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = _editing
        ? ref.watch(adminQuizDetailProvider(widget.id!))
        : null;
    if (detail?.hasValue == true && !_hydrated) {
      final item = detail!.value!;
      _title.text = item.title;
      _description.text = item.description ?? '';
      _instructions.text = item.instructions ?? '';
      _duration.text = '${item.durationMinutes}';
      _attempts.text = '${item.maxAttempts}';
      _showResult = item.showResult;
      _hydrated = true;
    }
    return AdminShell(
      title: _editing ? 'Edit Kuis' : 'Tambah Kuis',
      child: detail?.isLoading == true
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(EmiSpacing.md),
                children: [
                  if (_error != null) _Validation(error: _error!),
                  EmiCard(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _title,
                          decoration: const InputDecoration(labelText: 'Judul'),
                          validator: _req,
                        ),
                        TextFormField(
                          controller: _description,
                          decoration: const InputDecoration(
                            labelText: 'Deskripsi',
                          ),
                        ),
                        TextFormField(
                          controller: _instructions,
                          decoration: const InputDecoration(
                            labelText: 'Instruksi',
                          ),
                        ),
                        TextFormField(
                          controller: _duration,
                          decoration: const InputDecoration(
                            labelText: 'Durasi menit',
                          ),
                          keyboardType: TextInputType.number,
                          validator: _num,
                        ),
                        TextFormField(
                          controller: _attempts,
                          decoration: const InputDecoration(
                            labelText: 'Max attempts',
                          ),
                          keyboardType: TextInputType.number,
                          validator: _num,
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Tampilkan hasil'),
                          value: _showResult,
                          onChanged: _saving
                              ? null
                              : (v) => setState(() => _showResult = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: EmiSpacing.md),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Menyimpan...' : 'Simpan'),
                  ),
                  if (_editing) ...[
                    OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => context.go(
                              '/admin/quizzes/${widget.id}/questions',
                            ),
                      child: const Text('Kelola Soal'),
                    ),
                    Wrap(
                      spacing: EmiSpacing.sm,
                      children: [
                        TextButton(
                          onPressed: _saving ? null : () => _status('publish'),
                          child: const Text('Publish'),
                        ),
                        TextButton(
                          onPressed: _saving ? null : () => _status('archive'),
                          child: const Text('Archive'),
                        ),
                        TextButton(
                          onPressed: _saving ? null : _delete,
                          child: const Text('Hapus'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  String? _req(String? v) =>
      v == null || v.trim().isEmpty ? 'Wajib diisi.' : null;
  String? _num(String? v) =>
      (int.tryParse(v ?? '') ?? 0) < 1 ? 'Minimal 1.' : null;
  Map<String, dynamic> _payload() => {
    'title': _title.text.trim(),
    'description': _description.text.trim().isEmpty
        ? null
        : _description.text.trim(),
    'instructions': _instructions.text.trim().isEmpty
        ? null
        : _instructions.text.trim(),
    'duration_minutes': int.parse(_duration.text),
    'max_attempts': int.parse(_attempts.text),
    'show_result': _showResult,
    if (!_editing) 'status': 'draft',
  };
  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await ref
          .read(adminCrudRepositoryProvider)
          .saveQuiz(id: _editing ? widget.id : null, data: _payload());
      ref.invalidate(adminQuizProvider);
      if (mounted) context.go('/admin/quizzes/${saved.id}');
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is AppError
              ? e
              : AppError(type: AppErrorType.unknown, message: e.toString()),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _status(String action) async {
    if (await _confirm(context, '$action kuis?') != true) return;
    await ref.read(adminCrudRepositoryProvider).quizStatus(widget.id!, action);
    ref.invalidate(adminQuizDetailProvider(widget.id!));
  }

  Future<void> _delete() async {
    if (await _confirm(context, 'Hapus kuis?') != true) return;
    await ref.read(adminCrudRepositoryProvider).deleteQuiz(widget.id!);
    ref.invalidate(adminQuizProvider);
    if (mounted) context.go('/admin/quizzes');
  }
}

class AdminQuestionListScreen extends ConsumerWidget {
  const AdminQuestionListScreen({super.key, required this.quizId});
  final String quizId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(adminQuizQuestionsProvider(quizId));
    return AdminShell(
      title: 'Soal Kuis',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(EmiSpacing.md),
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () =>
                    context.go('/admin/quizzes/$quizId/questions/new'),
                icon: const Icon(Icons.add),
                label: const Text('Tambah Soal'),
              ),
            ),
          ),
          Expanded(
            child: data.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _Error(
                message: e.toString(),
                onRetry: () =>
                    ref.invalidate(adminQuizQuestionsProvider(quizId)),
              ),
              data: (items) => ListView(
                padding: const EdgeInsets.all(EmiSpacing.md),
                children: items.isEmpty
                    ? const [EmiCard(child: Text('Soal belum tersedia.'))]
                    : [
                        for (final item in items)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: EmiSpacing.md,
                            ),
                            child: EmiCard(
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(item.text),
                                subtitle: Text(
                                  '${item.type} • ${item.points} poin',
                                ),
                                onTap: () => context.go(
                                  '/admin/quizzes/$quizId/questions/${item.id}',
                                ),
                              ),
                            ),
                          ),
                      ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminQuestionFormScreen extends ConsumerStatefulWidget {
  const AdminQuestionFormScreen({super.key, required this.quizId, this.id});
  final String quizId;
  final String? id;
  @override
  ConsumerState<AdminQuestionFormScreen> createState() =>
      _AdminQuestionFormScreenState();
}

class _AdminQuestionFormScreenState
    extends ConsumerState<AdminQuestionFormScreen> {
  final _form = GlobalKey<FormState>();
  final _text = TextEditingController();
  final _points = TextEditingController(text: '1');
  final _order = TextEditingController(text: '1');
  final _correct = TextEditingController();
  final _explanation = TextEditingController();
  String _type = 'multiple_choice';
  final _options = [TextEditingController(), TextEditingController()];
  int _correctOption = 0;
  bool _saving = false;
  bool _hydrated = false;
  AppError? _error;
  bool get _editing => widget.id != null && widget.id != 'new';
  @override
  void dispose() {
    _text.dispose();
    _points.dispose();
    _order.dispose();
    _correct.dispose();
    _explanation.dispose();
    for (final c in _options) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = _editing
        ? ref.watch(adminQuestionDetailProvider(widget.id!))
        : null;
    if (detail?.hasValue == true && !_hydrated) {
      final q = detail!.value!;
      _text.text = q.text;
      _points.text = '${q.points}';
      _order.text = '${q.orderNumber}';
      _correct.text = q.correctAnswerText ?? '';
      _explanation.text = q.explanation ?? '';
      _type = q.type;
      if (q.options.isNotEmpty) {
        _options.clear();
        for (final o in q.options) {
          _options.add(TextEditingController(text: o.text));
          if (o.isCorrect) _correctOption = q.options.indexOf(o);
        }
      }
      _hydrated = true;
    }
    return AdminShell(
      title: _editing ? 'Edit Soal' : 'Tambah Soal',
      child: detail?.isLoading == true
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(EmiSpacing.md),
                children: [
                  if (_error != null) _Validation(error: _error!),
                  EmiCard(
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _type,
                          decoration: const InputDecoration(labelText: 'Tipe'),
                          items: const [
                            DropdownMenuItem(
                              value: 'multiple_choice',
                              child: Text('Pilihan ganda'),
                            ),
                            DropdownMenuItem(
                              value: 'short_answer',
                              child: Text('Isian'),
                            ),
                          ],
                          onChanged: _saving
                              ? null
                              : (v) => setState(
                                  () => _type = v ?? 'multiple_choice',
                                ),
                        ),
                        TextFormField(
                          controller: _text,
                          decoration: const InputDecoration(
                            labelText: 'Pertanyaan',
                          ),
                          validator: _req,
                          minLines: 2,
                          maxLines: 5,
                        ),
                        TextFormField(
                          controller: _points,
                          decoration: const InputDecoration(labelText: 'Poin'),
                          keyboardType: TextInputType.number,
                          validator: _num,
                        ),
                        TextFormField(
                          controller: _order,
                          decoration: const InputDecoration(
                            labelText: 'Urutan',
                          ),
                          keyboardType: TextInputType.number,
                          validator: _num,
                        ),
                        if (_type == 'short_answer')
                          TextFormField(
                            controller: _correct,
                            decoration: const InputDecoration(
                              labelText: 'Jawaban benar',
                            ),
                          )
                        else ...[
                          for (var i = 0; i < _options.length; i++)
                            Row(
                              children: [
                                Checkbox(
                                  value: _correctOption == i,
                                  onChanged: (_) =>
                                      setState(() => _correctOption = i),
                                ),
                                Expanded(
                                  child: TextFormField(
                                    controller: _options[i],
                                    decoration: InputDecoration(
                                      labelText: 'Pilihan ${i + 1}',
                                    ),
                                    validator: _req,
                                  ),
                                ),
                              ],
                            ),
                          OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () => setState(
                                    () => _options.add(TextEditingController()),
                                  ),
                            child: const Text('Tambah pilihan'),
                          ),
                        ],
                        TextFormField(
                          controller: _explanation,
                          decoration: const InputDecoration(
                            labelText: 'Penjelasan',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: EmiSpacing.md),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Menyimpan...' : 'Simpan'),
                  ),
                  if (_editing)
                    TextButton(
                      onPressed: _saving ? null : _delete,
                      child: const Text('Hapus soal'),
                    ),
                ],
              ),
            ),
    );
  }

  String? _req(String? v) =>
      v == null || v.trim().isEmpty ? 'Wajib diisi.' : null;
  String? _num(String? v) =>
      (int.tryParse(v ?? '') ?? 0) < 1 ? 'Minimal 1.' : null;
  Map<String, dynamic> _payload() => {
    'question_type': _type,
    'question_text': _text.text.trim(),
    'points': int.parse(_points.text),
    'order_number': int.parse(_order.text),
    'explanation': _explanation.text.trim().isEmpty
        ? null
        : _explanation.text.trim(),
    if (_type == 'short_answer')
      'correct_answer_text': _correct.text.trim().isEmpty
          ? null
          : _correct.text.trim(),
    if (_type == 'multiple_choice')
      'options': [
        for (var i = 0; i < _options.length; i++)
          QuizOptionAdmin(
            text: _options[i].text.trim(),
            isCorrect: i == _correctOption,
            orderNumber: i + 1,
          ).toJson(),
      ],
  };
  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(adminCrudRepositoryProvider)
          .saveQuestion(
            quizId: widget.quizId,
            id: _editing ? widget.id : null,
            data: _payload(),
          );
      ref.invalidate(adminQuizQuestionsProvider(widget.quizId));
      if (mounted) context.go('/admin/quizzes/${widget.quizId}/questions');
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is AppError
              ? e
              : AppError(type: AppErrorType.unknown, message: e.toString()),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (await _confirm(context, 'Hapus soal?') != true) return;
    await ref.read(adminCrudRepositoryProvider).deleteQuestion(widget.id!);
    ref.invalidate(adminQuizQuestionsProvider(widget.quizId));
    if (mounted) context.go('/admin/quizzes/${widget.quizId}/questions');
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(EmiSpacing.md),
    children: [
      EmiCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            OutlinedButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    ],
  );
}

class _Validation extends StatelessWidget {
  const _Validation({required this.error});
  final AppError error;
  @override
  Widget build(BuildContext context) => EmiCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(error.message),
        for (final entry in error.fieldErrors.entries)
          Text('${entry.key}: ${entry.value.join(', ')}'),
      ],
    ),
  );
}

Future<bool?> _confirm(BuildContext context, String text) => showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    content: Text(text),
    actions: [
      TextButton(
        onPressed: () => context.pop(false),
        child: const Text('Batal'),
      ),
      FilledButton(onPressed: () => context.pop(true), child: const Text('Ya')),
    ],
  ),
);
