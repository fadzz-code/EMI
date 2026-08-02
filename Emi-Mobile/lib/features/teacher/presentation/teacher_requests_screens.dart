import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../data/teacher_providers.dart';
import 'teacher_shell.dart';
import 'teacher_widgets.dart';

class TeacherRequestsScreen extends ConsumerStatefulWidget {
  const TeacherRequestsScreen({super.key, required this.passwordReset});
  final bool passwordReset;

  @override
  ConsumerState<TeacherRequestsScreen> createState() =>
      _TeacherRequestsScreenState();
}

class _TeacherRequestsScreenState extends ConsumerState<TeacherRequestsScreen> {
  final search = TextEditingController();
  int page = 1;
  String status = 'pending';

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = (page: page, search: search.text, status: status);
    final provider = widget.passwordReset
        ? teacherPasswordResetRequestsProvider(query)
        : teacherRegistrationRequestsProvider(query);
    final data = ref.watch(provider);
    return TeacherShell(
      title: widget.passwordReset
          ? 'Reset Password Siswa'
          : 'Persetujuan Siswa',
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(provider.future),
        child: data.when(
          loading: () => const _RequestState(loading: true),
          error: (_, _) => const _RequestState(
            message: 'Data belum bisa dimuat. Tarik untuk mencoba lagi.',
          ),
          data: (result) => ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              TeacherSearchField(
                controller: search,
                label: 'Cari nama atau email',
                onSubmitted: (_) => setState(() => page = 1),
              ),
              const SizedBox(height: EmiSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Menunggu')),
                  DropdownMenuItem(value: 'approved', child: Text('Disetujui')),
                  DropdownMenuItem(value: 'rejected', child: Text('Ditolak')),
                ],
                onChanged: (value) => setState(() {
                  status = value ?? 'pending';
                  page = 1;
                }),
              ),
              const SizedBox(height: EmiSpacing.md),
              if (result.items.isEmpty)
                const SizedBox(
                  height: 240,
                  child: Center(child: Text('Belum ada permintaan.')),
                )
              else
                for (final item in result.items) ...[
                  TeacherListCard(
                    onTap: () => context.push(
                      widget.passwordReset
                          ? '/teacher/password-resets/${item.id}'
                          : '/teacher/approvals/${item.id}',
                    ),
                    child: ListTile(
                      title: Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${item.email}\n${requestStatus(item.status)}',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                  const SizedBox(height: EmiSpacing.sm),
                ],
              if (result.items.isNotEmpty)
                TeacherPaginationBar(
                  currentPage: result.currentPage,
                  lastPage: result.lastPage,
                  onPrevious: page > 1 ? () => setState(() => page--) : null,
                  onNext: page < result.lastPage
                      ? () => setState(() => page++)
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestState extends StatelessWidget {
  const _RequestState({this.loading = false, this.message});
  final bool loading;
  final String? message;

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      SizedBox(
        height: 360,
        child: Center(
          child: loading ? const CircularProgressIndicator() : Text(message!),
        ),
      ),
    ],
  );
}

class TeacherRequestDetailScreen extends ConsumerStatefulWidget {
  const TeacherRequestDetailScreen({
    super.key,
    required this.id,
    required this.passwordReset,
  });
  final String id;
  final bool passwordReset;

  @override
  ConsumerState<TeacherRequestDetailScreen> createState() =>
      _TeacherRequestDetailScreenState();
}

class _TeacherRequestDetailScreenState
    extends ConsumerState<TeacherRequestDetailScreen> {
  bool saving = false;

  @override
  Widget build(BuildContext context) {
    final provider = widget.passwordReset
        ? teacherPasswordResetRequestProvider(widget.id)
        : teacherRegistrationRequestProvider(widget.id);
    return TeacherShell(
      title: widget.passwordReset
          ? 'Detail Reset Password'
          : 'Detail Persetujuan',
      fallbackRoute: widget.passwordReset
          ? '/teacher/password-resets'
          : '/teacher/approvals',
      child: ref
          .watch(provider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) =>
                const Center(child: Text('Detail belum bisa dimuat.')),
            data: (item) => ListView(
              padding: const EdgeInsets.all(EmiSpacing.md),
              children: [
                TeacherPageHeader(
                  icon: widget.passwordReset
                      ? Icons.lock_reset
                      : Icons.how_to_reg,
                  title: item.name,
                  subtitle: item.email,
                ),
                const SizedBox(height: EmiSpacing.md),
                TeacherListCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: ${requestStatus(item.status)}'),
                      if (item.className != null)
                        Text('Kelas: ${item.className}'),
                      if (item.schoolName != null)
                        Text('Sekolah: ${item.schoolName}'),
                      if (item.reviewNote != null)
                        Text('Catatan: ${item.reviewNote}'),
                    ],
                  ),
                ),
                if (item.status == 'pending') ...[
                  const SizedBox(height: EmiSpacing.lg),
                  FilledButton(
                    onPressed: saving
                        ? null
                        : () => widget.passwordReset
                              ? _approvePassword()
                              : _approveRegistration(),
                    child: Text(saving ? 'Memproses...' : 'Setujui'),
                  ),
                  if (widget.passwordReset) ...[
                    const SizedBox(height: EmiSpacing.sm),
                    OutlinedButton(
                      onPressed: saving ? null : _rejectPassword,
                      child: const Text('Tolak'),
                    ),
                  ],
                ],
              ],
            ),
          ),
    );
  }

  Future<void> _approveRegistration() async {
    final note = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setujui siswa?'),
        content: TextField(
          controller: note,
          maxLength: 1000,
          decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, note.text.trim()),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );
    await WidgetsBinding.instance.endOfFrame;
    note.dispose();
    if (result == null) return;
    await _run(
      () => ref
          .read(teacherRepositoryProvider)
          .approveRegistrationRequest(widget.id, reviewNote: result),
    );
  }

  Future<void> _approvePassword() async {
    final password = TextEditingController();
    final confirmation = TextEditingController();
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset password siswa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password baru'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmation,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Konfirmasi password',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, [password.text, confirmation.text]),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );
    await WidgetsBinding.instance.endOfFrame;
    password.dispose();
    confirmation.dispose();
    if (result == null || result[0].length < 8 || result[0] != result[1]) {
      return _message('Password minimal 8 karakter dan konfirmasi harus sama.');
    }
    await _run(
      () => ref
          .read(teacherRepositoryProvider)
          .approvePasswordResetRequest(widget.id, result[0], result[1]),
    );
  }

  Future<void> _rejectPassword() async {
    final note = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tolak permintaan?'),
        content: TextField(
          controller: note,
          maxLength: 1000,
          decoration: const InputDecoration(labelText: 'Alasan penolakan'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, note.text.trim()),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
    await WidgetsBinding.instance.endOfFrame;
    note.dispose();
    if (result == null || result.isEmpty) return;
    await _run(
      () => ref
          .read(teacherRepositoryProvider)
          .rejectPasswordResetRequest(widget.id, result),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => saving = true);
    try {
      await action();
      if (!mounted) return;
      ref.invalidate(teacherRegistrationRequestsProvider);
      ref.invalidate(teacherPasswordResetRequestsProvider);
      ref.invalidate(
        widget.passwordReset
            ? teacherPasswordResetRequestProvider(widget.id)
            : teacherRegistrationRequestProvider(widget.id),
      );
      _message('Permintaan berhasil diproses.');
    } catch (error) {
      if (mounted) _message(error.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

String requestStatus(String status) => switch (status) {
  'approved' => 'Disetujui',
  'rejected' => 'Ditolak',
  _ => 'Menunggu',
};
