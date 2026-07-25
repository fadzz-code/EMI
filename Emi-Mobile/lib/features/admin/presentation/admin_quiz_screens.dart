import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../core/errors/app_error.dart';
import '../../../shared/widgets/emi_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../data/admin_crud_providers.dart';
import '../data/admin_providers.dart';
import '../data/admin_repository.dart';
import '../data/admin_crud_repository.dart';
import 'admin_shell.dart';
import 'admin_widgets.dart';

class AdminQuizScreen extends ConsumerStatefulWidget {
  const AdminQuizScreen({super.key});
  @override
  ConsumerState<AdminQuizScreen> createState() => _AdminQuizScreenState();
}

class _AdminQuizScreenState extends ConsumerState<AdminQuizScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String? _search;
  String? _status;
  int _page = 1;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = AdminSearchQuery(search: _search, status: _status, page: _page);
    final data = ref.watch(adminQuizProvider(q));
    return AdminShell(
      title: 'Template Kuis',
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminQuizProvider(q)),
        child: ListView(
          padding: const EdgeInsets.all(EmiSpacing.md),
          children: [
            const Text(
              'Kelola kumpulan soal yang dapat digunakan dalam kegiatan pembelajaran.',
            ),
            const SizedBox(height: EmiSpacing.md),
            FilledButton.icon(
              key: const Key('adminAdd-quizzes'),
              onPressed: () => context.push('/admin/quizzes/create'),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Template Kuis'),
            ),
            const SizedBox(height: EmiSpacing.md),
            TextField(
              key: const Key('adminSearch-quizzes'),
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari judul Template Kuis',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Filter',
                  onPressed: _showFilter,
                  icon: Badge(
                    isLabelVisible: _status != null,
                    child: const Icon(Icons.tune),
                  ),
                ),
              ),
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 400), () {
                  setState(() {
                    _search = value;
                    _page = 1;
                  });
                });
              },
            ),
            if (_status != null) ...[
              const SizedBox(height: EmiSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(label: Text(_statusLabel(_status!))),
              ),
            ],
            const SizedBox(height: EmiSpacing.md),
            data.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => _Error(
                message:
                    'Data Kuis Belum Bisa Dimuat\nPeriksa koneksi internet, lalu coba lagi.',
                onRetry: () => ref.invalidate(adminQuizProvider(q)),
              ),
              data: (page) {
                if (page.items.isEmpty) {
                  final searching =
                      (_search?.trim().isNotEmpty ?? false) || _status != null;
                  return KeyedSubtree(
                    key: const Key('adminEmpty-quizzes'),
                    child: _Empty(
                      title: searching
                          ? 'Template Kuis Tidak Ditemukan'
                          : 'Belum Ada Template Kuis',
                      message: searching
                          ? 'Coba gunakan judul atau filter yang berbeda.'
                          : 'Tambahkan Template Kuis untuk menyiapkan latihan atau penilaian pembelajaran.',
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final item in page.items) ...[
                      _QuizTile(item: item),
                      const SizedBox(height: 12),
                    ],
                    if (page.hasMore)
                      FilledButton(
                        onPressed: () => setState(() => _page++),
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

  Future<void> _showFilter() async {
    String? status = _status;
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
                  setState(() {
                    _status = status;
                    _page = 1;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Terapkan'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _status = null;
                    _page = 1;
                  });
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

class _QuizTile extends StatelessWidget {
  const _QuizTile({required this.item});

  final QuizTemplateAdmin item;

  @override
  Widget build(BuildContext context) => AdminCard(
    onTap: () => context.push('/admin/quizzes/${item.id}'),
    child: Row(
      children: [
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
              const SizedBox(height: EmiSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.questionsCount} Pertanyaan',
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
                '${item.durationMinutes} menit · ${item.maxAttempts} percobaan · Diubah ${_shortDate(item.updatedAt)}',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'view') context.push('/admin/quizzes/${item.id}');
            if (value == 'edit') context.push('/admin/quizzes/${item.id}');
            if (value == 'questions') {
              context.push('/admin/quizzes/${item.id}/questions');
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'view', child: Text('Lihat')),
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'questions', child: Text('Pertanyaan')),
          ],
        ),
      ],
    ),
  );
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
  String _status = 'draft';
  bool _saving = false;
  bool _hydrated = false;
  AppError? _error;
  bool get _editing => widget.id != null;
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
      _status = item.status ?? 'draft';
      _hydrated = true;
    }
    return AdminShell(
      title: _editing ? 'Edit Template Kuis' : 'Tambah Template Kuis',
      fallbackRoute: '/admin/quizzes',
      child: detail?.isLoading == true
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(EmiSpacing.md),
                children: [
                  if (_error != null) ...[
                    _Validation(error: _error!),
                    const SizedBox(height: EmiSpacing.md),
                  ],
                  _SectionTitle(
                    'Identitas Template',
                    'Judul dan deskripsi singkat membantu Admin dan Guru mengenali kuis ini.',
                  ),
                  TextFormField(
                    controller: _title,
                    decoration: const InputDecoration(labelText: 'Judul'),
                    validator: _req,
                  ),
                  const SizedBox(height: EmiSpacing.md),
                  TextFormField(
                    controller: _description,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Deskripsi'),
                  ),
                  const SizedBox(height: EmiSpacing.md),
                  TextFormField(
                    controller: _instructions,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Instruksi'),
                  ),
                  const SizedBox(height: EmiSpacing.lg),
                  _SectionTitle(
                    'Pengaturan Pengerjaan',
                    'Atur durasi, jumlah percobaan, dan apakah siswa langsung melihat hasil.',
                  ),
                  TextFormField(
                    controller: _duration,
                    decoration: const InputDecoration(
                      labelText: 'Durasi menit',
                    ),
                    keyboardType: TextInputType.number,
                    validator: _num,
                  ),
                  const SizedBox(height: EmiSpacing.md),
                  TextFormField(
                    controller: _attempts,
                    decoration: const InputDecoration(
                      labelText: 'Maksimal percobaan',
                    ),
                    keyboardType: TextInputType.number,
                    validator: _num,
                  ),
                  const SizedBox(height: EmiSpacing.md),
                  EmiCard(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Tampilkan hasil'),
                      subtitle: const Text(
                        'Siswa langsung melihat skor setelah selesai mengerjakan.',
                      ),
                      value: _showResult,
                      onChanged: _saving
                          ? null
                          : (v) => setState(() => _showResult = v),
                    ),
                  ),
                  const SizedBox(height: EmiSpacing.lg),
                  _SectionTitle(
                    'Status',
                    'Draft belum digunakan. Terbit membutuhkan pertanyaan lengkap. Arsip tetap tersimpan.',
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'draft', child: Text('Draft')),
                      DropdownMenuItem(
                        value: 'published',
                        child: Text('Terbit'),
                      ),
                      DropdownMenuItem(value: 'archived', child: Text('Arsip')),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _status = value ?? 'draft'),
                  ),
                  const SizedBox(height: EmiSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () => _editing
                                    ? context.go('/admin/quizzes/${widget.id}')
                                    : context.go('/admin/quizzes'),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: EmiSpacing.sm),
                      Expanded(
                        child: FilledButton(
                          key: const Key('adminSave-quizzes'),
                          onPressed: _saving ? null : _save,
                          child: Text(_saving ? 'Menyimpan...' : 'Simpan'),
                        ),
                      ),
                    ],
                  ),
                  if (_editing) ...[
                    const SizedBox(height: EmiSpacing.xl),
                    _SectionTitle(
                      'Kelola Isi Kuis',
                      'Tambah atau ubah pertanyaan yang termasuk dalam template ini.',
                    ),
                    OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => context.go(
                              '/admin/quizzes/${widget.id}/questions',
                            ),
                      child: const Text('Kelola Pertanyaan'),
                    ),
                    const SizedBox(height: EmiSpacing.lg),
                    _SectionTitle(
                      'Aksi Lainnya',
                      'Terbitkan agar dapat digunakan, atau arsipkan bila belum diperlukan.',
                    ),
                    Wrap(
                      spacing: EmiSpacing.sm,
                      runSpacing: EmiSpacing.sm,
                      children: [
                        OutlinedButton(
                          key: const Key('adminPublish-quizzes'),
                          onPressed: _saving
                              ? null
                              : () => _statusAction('publish'),
                          child: const Text('Terbitkan'),
                        ),
                        OutlinedButton(
                          key: const Key('adminArchive-quizzes'),
                          onPressed: _saving
                              ? null
                              : () => _statusAction('archive'),
                          child: const Text('Arsipkan'),
                        ),
                        OutlinedButton(
                          onPressed: _saving ? null : _showApply,
                          child: const Text('Terapkan ke Kelas'),
                        ),
                        OutlinedButton(
                          key: const Key('adminDelete-quizzes'),
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
    'status': _editing ? _status : 'draft',
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
              : const AppError(
                  type: AppErrorType.unknown,
                  message: 'Template Kuis gagal diproses. Silakan coba lagi.',
                ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _statusAction(String action) async {
    final title = action == 'publish'
        ? 'Terbitkan Template Kuis ini?'
        : 'Arsipkan Template Kuis ini?';
    if (await _confirm(context, title) != true) return;
    try {
      await ref
          .read(adminCrudRepositoryProvider)
          .quizStatus(widget.id!, action);
      ref.invalidate(adminQuizDetailProvider(widget.id!));
      ref.invalidate(adminQuizProvider);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is AppError
              ? e
              : const AppError(
                  type: AppErrorType.unknown,
                  message: 'Template Kuis gagal diproses. Silakan coba lagi.',
                ),
        );
      }
    }
  }

  Future<void> _showApply() async {
    final classes = await ref
        .read(adminRepositoryProvider)
        .classes(const AdminListQuery(status: 'active'));
    if (!mounted) return;
    final selected = <String>{};
    final ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(EmiSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Terapkan ke Kelas',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: EmiSpacing.md),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final item in classes.items)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.name),
                        subtitle: Text(item.schoolName ?? '-'),
                        value: selected.contains(item.id),
                        onChanged: (value) => setSheetState(() {
                          if (value == true) {
                            selected.add(item.id);
                          } else {
                            selected.remove(item.id);
                          }
                        }),
                      ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: selected.isEmpty
                    ? null
                    : () => Navigator.pop(context, true),
                child: const Text('Terapkan'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || selected.isEmpty) return;
    try {
      await ref
          .read(adminCrudRepositoryProvider)
          .applyQuiz(widget.id!, selected.toList());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template Kuis diterapkan ke kelas.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is AppError
              ? e
              : const AppError(
                  type: AppErrorType.unknown,
                  message: 'Template Kuis gagal diproses. Silakan coba lagi.',
                ),
        );
      }
    }
  }

  Future<void> _delete() async {
    if (await _confirm(context, 'Hapus Template Kuis ini?') != true) return;
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
      title: 'Pertanyaan Kuis',
      fallbackRoute: '/admin/quizzes/$quizId',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(EmiSpacing.md),
            child: Wrap(
              spacing: EmiSpacing.sm,
              runSpacing: EmiSpacing.sm,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _showQuestionReorder(context, ref, quizId),
                  child: const Text('Atur Urutan Pertanyaan'),
                ),
                FilledButton.icon(
                  onPressed: () =>
                      context.push('/admin/quizzes/$quizId/questions/create'),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Pertanyaan'),
                ),
              ],
            ),
          ),
          Expanded(
            child: data.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _Error(
                message: e is AppError
                    ? e.message
                    : 'Pertanyaan belum bisa dimuat. Silakan coba lagi.',
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
                                title: Text(
                                  item.text,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '${_questionTypeLabel(item.type)} · ${item.points} poin',
                                ),
                                leading: Text('${item.orderNumber}'),
                                onTap: () => context.push(
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
  final _correct = TextEditingController();
  final _explanation = TextEditingController();
  final _fuzzyThreshold = TextEditingController(text: '80');
  String _type = 'multiple_choice';
  bool _useFuzzy = false;
  String? _imageMediaId;
  String? _imagePath;
  String? _imageName;
  final _options = [TextEditingController(), TextEditingController()];
  int _correctOption = 0;
  bool _saving = false;
  bool _hydrated = false;
  AppError? _error;
  bool get _editing => widget.id != null;
  @override
  void dispose() {
    _text.dispose();
    _points.dispose();
    _correct.dispose();
    _explanation.dispose();
    _fuzzyThreshold.dispose();
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
      _correct.text = q.correctAnswerText ?? '';
      _explanation.text = q.explanation ?? '';
      _fuzzyThreshold.text = '${q.fuzzyThreshold ?? 80}';
      _useFuzzy = q.useFuzzyMatching;
      _imageMediaId = q.imageMediaId;
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
      title: _editing ? 'Edit Pertanyaan' : 'Tambah Pertanyaan',
      fallbackRoute: '/admin/quizzes/${widget.quizId}/questions',
      child: detail?.isLoading == true
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(EmiSpacing.md),
                children: [
                  Text(
                    _editing
                        ? 'Perbarui isi pertanyaan dan jawaban yang benar.'
                        : 'Buat pertanyaan yang jelas dan mudah dipahami siswa.',
                  ),
                  const SizedBox(height: EmiSpacing.xl),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: EmiSpacing.md),
                      child: Text(
                        _error!.message,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),

                  Text(
                    'Pertanyaan',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Divider(),
                  const SizedBox(height: EmiSpacing.md),

                  DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration: const InputDecoration(
                      labelText: 'Jenis Pertanyaan',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'multiple_choice',
                        child: Text('Pilihan Ganda'),
                      ),
                      DropdownMenuItem(
                        value: 'short_answer',
                        child: Text('Jawaban Singkat'),
                      ),
                    ],
                    onChanged: _saving
                        ? null
                        : (v) => setState(() => _type = v ?? 'multiple_choice'),
                  ),
                  const SizedBox(height: EmiSpacing.md),
                  TextFormField(
                    controller: _text,
                    decoration: const InputDecoration(
                      labelText: 'Isi Pertanyaan',
                    ),
                    validator: _req,
                    minLines: 3,
                    maxLines: 7,
                  ),
                  const SizedBox(height: EmiSpacing.xl),

                  if (_type == 'short_answer') ...[
                    Text(
                      'Jawaban Benar',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Divider(),
                    const SizedBox(height: EmiSpacing.md),
                    TextFormField(
                      controller: _correct,
                      decoration: const InputDecoration(
                        labelText: 'Jawaban yang Diterima',
                      ),
                      validator: _req,
                    ),
                    const SizedBox(height: EmiSpacing.md),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Terima Jawaban yang Mirip'),
                      value: _useFuzzy,
                      onChanged: _saving
                          ? null
                          : (value) => setState(() => _useFuzzy = value),
                    ),
                    if (_useFuzzy) ...[
                      const SizedBox(height: EmiSpacing.sm),
                      TextFormField(
                        controller: _fuzzyThreshold,
                        decoration: const InputDecoration(
                          labelText: 'Tingkat Kemiripan',
                          helperText:
                              'Angka 1-100. Semakin kecil semakin mentoleransi typo.',
                        ),
                        keyboardType: TextInputType.number,
                        validator: _num,
                      ),
                    ],
                  ] else ...[
                    Text(
                      'Pilihan Jawaban',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Divider(),
                    const SizedBox(height: EmiSpacing.md),
                    RadioGroup<int>(
                      groupValue: _correctOption,
                      onChanged: _saving
                          ? (_) {}
                          : (value) {
                              if (value != null) {
                                setState(() => _correctOption = value);
                              }
                            },
                      child: Column(
                        children: [
                          for (var i = 0; i < _options.length; i++) ...[
                            Row(
                              children: [
                                Radio<int>(value: i),
                                Expanded(
                                  child: TextFormField(
                                    controller: _options[i],
                                    decoration: InputDecoration(
                                      labelText:
                                          'Pilihan ${String.fromCharCode(65 + i)}',
                                    ),
                                    validator: _req,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Hapus pilihan',
                                  onPressed: _saving || _options.length <= 2
                                      ? null
                                      : () => setState(() {
                                          final removed = _options.removeAt(i);
                                          removed.dispose();
                                          if (_correctOption >=
                                                  _options.length ||
                                              _correctOption == i) {
                                            _correctOption = 0;
                                          }
                                        }),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                            const SizedBox(height: EmiSpacing.md),
                          ],
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: _saving
                            ? null
                            : () => setState(
                                () => _options.add(TextEditingController()),
                              ),
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Pilihan'),
                      ),
                    ),
                  ],
                  const SizedBox(height: EmiSpacing.xl),

                  Text(
                    'Pengaturan Pertanyaan',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Divider(),
                  const SizedBox(height: EmiSpacing.md),
                  TextFormField(
                    controller: _points,
                    decoration: const InputDecoration(labelText: 'Poin'),
                    keyboardType: TextInputType.number,
                    validator: _num,
                  ),
                  const SizedBox(height: EmiSpacing.md),
                  TextFormField(
                    controller: _explanation,
                    decoration: const InputDecoration(
                      labelText: 'Pembahasan Jawaban',
                    ),
                    minLines: 2,
                    maxLines: 5,
                  ),
                  const SizedBox(height: EmiSpacing.xl),

                  Text(
                    'Gambar Pertanyaan',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Divider(),
                  const SizedBox(height: EmiSpacing.md),
                  _QuestionImagePicker(
                    imagePath: _imagePath,
                    imageName: _imageName,
                    hasExisting: _imagePath == null && _imageMediaId != null,
                    onPick: _pickImage,
                    onClear: () => setState(() {
                      _imagePath = null;
                      _imageName = null;
                      _imageMediaId = null;
                    }),
                  ),

                  const SizedBox(height: EmiSpacing.xl),
                  SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton(
                          onPressed: _saving ? null : _save,
                          child: Text(
                            _saving ? 'Menyimpan...' : 'Simpan Pertanyaan',
                          ),
                        ),
                        const SizedBox(height: EmiSpacing.sm),
                        OutlinedButton(
                          onPressed: _saving ? null : () => context.pop(),
                          child: const Text('Batal'),
                        ),
                        if (_editing) ...[
                          const SizedBox(height: EmiSpacing.sm),
                          TextButton(
                            onPressed: _saving ? null : _delete,
                            child: const Text(
                              'Hapus soal',
                              style: TextStyle(color: EmiColors.error),
                            ),
                          ),
                        ],
                      ],
                    ),
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
  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: false,
    );
    if (!mounted || result == null || result.files.single.path == null) return;
    final file = result.files.single;
    if (file.size > 5 * 1024 * 1024) {
      setState(
        () => _error = const AppError(
          type: AppErrorType.validation,
          message: 'Ukuran file terlalu besar.',
        ),
      );
      return;
    }
    setState(() {
      _imagePath = file.path;
      _imageName = file.name;
    });
  }

  Map<String, dynamic> _payload() => {
    'question_type': _type,
    'question_text': _text.text.trim(),
    'points': int.parse(_points.text),
    'explanation': _explanation.text.trim().isEmpty
        ? null
        : _explanation.text.trim(),
    'image_media_id': _imageMediaId,
    if (_type == 'short_answer') ...{
      'correct_answer_text': _correct.text.trim().isEmpty
          ? null
          : _correct.text.trim(),
      'use_fuzzy_matching': _useFuzzy,
      'fuzzy_threshold': _useFuzzy ? int.parse(_fuzzyThreshold.text) : null,
    },
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
      if (_imagePath != null) {
        _imageMediaId = await ref
            .read(adminCrudRepositoryProvider)
            .uploadQuestionImage(_imagePath!, _imageName ?? 'question.png');
      }
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
        var msg = 'Pertanyaan belum berhasil disimpan. Silakan coba lagi.';
        if (e is AppError) {
          if (e.message.contains('QUIZ_QUESTION_ORDER_ALREADY_USED') ||
              e.message.contains('urutan')) {
            msg =
                'Urutan pertanyaan sudah digunakan.\nSilakan atur urutan dari menu Atur Urutan Pertanyaan.';
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(msg)));
            setState(() => _saving = false);
            return;
          } else {
            msg = e.message;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pertanyaan belum berhasil disimpan. Silakan coba lagi.',
            ),
          ),
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

Future<void> _showQuestionReorder(
  BuildContext context,
  WidgetRef ref,
  String quizId,
) async {
  final questions = ref.read(adminQuizQuestionsProvider(quizId)).valueOrNull;
  if (questions == null || questions.length < 2) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Minimal dua pertanyaan dibutuhkan.')),
    );
    return;
  }
  final original = [...questions]
    ..sort((a, b) => a.orderNumber.compareTo(b.orderNumber));
  final ordered = [...original];
  var saving = false;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(EmiSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Atur Urutan Pertanyaan',
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
                      leading: Text('${index + 1}'),
                      title: Text(
                        item.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(_questionTypeLabel(item.type)),
                      trailing: Wrap(
                        children: [
                          IconButton(
                            onPressed: saving || index == 0
                                ? null
                                : () => setSheetState(() {
                                    final current = ordered.removeAt(index);
                                    ordered.insert(index - 1, current);
                                  }),
                            icon: const Icon(Icons.arrow_upward),
                          ),
                          IconButton(
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
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        setSheetState(() => saving = true);
                        try {
                          await ref
                              .read(adminCrudRepositoryProvider)
                              .reorderQuestions(
                                quizId,
                                ordered.map((item) => item.id).toList(),
                              );
                          ref.invalidate(adminQuizQuestionsProvider(quizId));
                          if (context.mounted) Navigator.pop(context);
                        } catch (_) {
                          ordered
                            ..clear()
                            ..addAll(original);
                          setSheetState(() => saving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Urutan pertanyaan belum berhasil disimpan.',
                                ),
                              ),
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

class _QuestionImagePicker extends StatelessWidget {
  const _QuestionImagePicker({
    required this.imagePath,
    required this.imageName,
    required this.hasExisting,
    required this.onPick,
    required this.onClear,
  });

  final String? imagePath;
  final String? imageName;
  final bool hasExisting;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(EmiSpacing.sm),
    decoration: BoxDecoration(
      border: Border.all(color: EmiColors.border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(hasExisting ? 'Gambar Saat Ini' : 'Gambar Pertanyaan'),
        if (imageName != null) Text(imageName!),
        if (hasExisting)
          const Text('Gambar lama dipertahankan jika tidak diganti.'),
        if (imagePath != null) ...[
          const SizedBox(height: EmiSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(File(imagePath!), height: 140, fit: BoxFit.cover),
          ),
        ],
        const SizedBox(height: EmiSpacing.sm),
        OutlinedButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.image_outlined),
          label: Text(
            imagePath == null && !hasExisting ? 'Pilih Gambar' : 'Ganti',
          ),
        ),
        if (imagePath != null)
          TextButton(onPressed: onClear, child: const Text('Hapus Pilihan')),
      ],
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: EmiSpacing.xl),
    child: Column(
      children: [
        const Icon(Icons.quiz_outlined, size: 56),
        const SizedBox(height: EmiSpacing.sm),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: EmiSpacing.xs),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, this.helper);

  final String title;
  final String helper;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: EmiSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: EmiSpacing.xl),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: EmiSpacing.xs),
        Text(helper, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

String _statusLabel(String? status) => switch (status) {
  'published' => 'Terbit',
  'archived' => 'Arsip',
  _ => 'Draft',
};

String _questionTypeLabel(String type) => switch (type) {
  'short_answer' => 'Jawaban Singkat',
  _ => 'Pilihan Ganda',
};

String _shortDate(String? value) {
  if (value == null || value.isEmpty) return '-';
  final parsed = DateTime.tryParse(value)?.toLocal();
  if (parsed == null) return '-';
  return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
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
