import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../core/errors/app_error.dart';
import '../../../shared/widgets/emi_card.dart';
import '../../../shared/widgets/role_dashboard_widgets.dart';
import '../data/admin_crud_providers.dart';
import '../data/admin_crud_repository.dart';
import '../data/admin_providers.dart';
import 'admin_shell.dart';

class AdminApprovalsScreen extends ConsumerStatefulWidget {
  const AdminApprovalsScreen({super.key});

  @override
  ConsumerState<AdminApprovalsScreen> createState() =>
      _AdminApprovalsScreenState();
}

class _AdminApprovalsScreenState extends ConsumerState<AdminApprovalsScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  String? _searchValue;
  String _status = 'pending';
  String? _role;
  var _page = 1;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = AdminApprovalQuery(
      search: _searchValue,
      status: _status,
      role: _role,
      page: _page,
    );
    final data = ref.watch(adminApprovalsProvider(query));
    return AdminShell(
      title: 'Persetujuan Akun',
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminApprovalsProvider(query)),
        child: ListView(
          padding: const EdgeInsets.all(EmiSpacing.md),
          children: [
            TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Cari nama atau email',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Filter',
                  onPressed: () => _showFilter(context),
                  icon: Badge(
                    isLabelVisible: _role != null || _status != 'pending',
                    child: const Icon(Icons.tune),
                  ),
                ),
              ),
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 400), () {
                  setState(() {
                    _searchValue = value.trim().isEmpty ? null : value.trim();
                    _page = 1;
                  });
                });
              },
            ),
            const SizedBox(height: EmiSpacing.md),
            data.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => FriendlyState(
                icon: Icons.wifi_off_outlined,
                title: 'Data belum bisa dimuat',
                message: 'Periksa koneksi internet, lalu coba lagi.',
                onRetry: () => ref.invalidate(adminApprovalsProvider(query)),
              ),
              data: (page) {
                if (page.items.isEmpty) {
                  final filtered =
                      _search.text.trim().isNotEmpty ||
                      _role != null ||
                      _status != 'pending';
                  return FriendlyState(
                    icon: Icons.how_to_reg_outlined,
                    title: filtered
                        ? 'Pengajuan Tidak Ditemukan'
                        : 'Tidak Ada Permintaan Baru',
                    message: filtered
                        ? 'Coba gunakan nama atau filter yang berbeda.'
                        : 'Semua pengajuan akun sudah diperiksa.',
                  );
                }
                return Column(
                  children: [
                    for (final item in page.items) ...[
                      _ApprovalTile(item: item),
                      const SizedBox(height: EmiSpacing.sm),
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

  Future<void> _showFilter(BuildContext context) async {
    var status = _status;
    var role = _role;
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
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Semua')),
                  DropdownMenuItem(value: 'teacher', child: Text('Guru')),
                  DropdownMenuItem(value: 'student', child: Text('Siswa')),
                ],
                onChanged: (value) => setSheetState(() => role = value),
              ),
              const SizedBox(height: EmiSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(
                    value: 'pending',
                    child: Text('Menunggu Persetujuan'),
                  ),
                  DropdownMenuItem(value: 'approved', child: Text('Disetujui')),
                  DropdownMenuItem(value: 'rejected', child: Text('Ditolak')),
                  DropdownMenuItem(value: '', child: Text('Semua Pengajuan')),
                ],
                onChanged: (value) =>
                    setSheetState(() => status = value ?? 'pending'),
              ),
              const SizedBox(height: EmiSpacing.lg),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _role = role;
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
                    _role = null;
                    _status = 'pending';
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

class _ApprovalTile extends StatelessWidget {
  const _ApprovalTile({required this.item});

  final RegistrationApprovalAdmin item;

  @override
  Widget build(BuildContext context) => EmiCard(
    child: ListTile(
      leading: CircleAvatar(child: Icon(_roleIcon(item.requestedRole))),
      title: Text(item.userName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          '${_roleLabel(item.requestedRole)} • ${_statusLabel(item.status)}',
          item.userEmail,
          item.schoolName ?? 'Belum Memilih Sekolah',
          if (item.createdAt != null) 'Diajukan ${_dateLabel(item.createdAt!)}',
        ].join('\n'),
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/admin/approvals/${item.id}'),
    ),
  );
}

class AdminApprovalDetailScreen extends ConsumerStatefulWidget {
  const AdminApprovalDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<AdminApprovalDetailScreen> createState() =>
      _AdminApprovalDetailScreenState();
}

class _AdminApprovalDetailScreenState
    extends ConsumerState<AdminApprovalDetailScreen> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(adminApprovalDetailProvider(widget.id));
    return AdminShell(
      title: 'Detail Pemohon',
      fallbackRoute: '/admin/approvals',
      child: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => FriendlyState(
          icon: Icons.wifi_off_outlined,
          title: 'Data belum bisa dimuat',
          message: 'Periksa koneksi internet, lalu coba lagi.',
          onRetry: () => ref.invalidate(adminApprovalDetailProvider(widget.id)),
        ),
        data: (item) => ListView(
          padding: const EdgeInsets.all(EmiSpacing.md),
          children: [
            EmiCard(
              child: ListTile(
                leading: CircleAvatar(
                  child: Icon(_roleIcon(item.requestedRole)),
                ),
                title: Text(
                  item.userName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${_roleLabel(item.requestedRole)} • ${_statusLabel(item.status)}',
                ),
              ),
            ),
            const SizedBox(height: EmiSpacing.md),
            _InfoSection(
              title: 'Data Akun',
              rows: {
                'Nama': item.userName,
                'Email': item.userEmail,
                'Role': _roleLabel(item.requestedRole),
                'Status': _statusLabel(item.status),
              },
            ),
            const SizedBox(height: EmiSpacing.md),
            _InfoSection(
              title: 'Sekolah dan Kelas',
              rows: {
                'Sekolah': item.schoolName ?? 'Belum Memilih Sekolah',
                'Kelas': item.className ?? 'Belum Ditempatkan ke Kelas',
              },
            ),
            const SizedBox(height: EmiSpacing.md),
            _InfoSection(
              title: 'Informasi Pengajuan',
              rows: {
                'Tanggal Pengajuan': item.createdAt == null
                    ? 'Belum Diisi'
                    : _dateLabel(item.createdAt!),
                if (item.reviewNote?.isNotEmpty == true)
                  'Alasan Penolakan': item.reviewNote!,
              },
            ),
            if (item.status == 'pending') ...[
              const SizedBox(height: EmiSpacing.md),
              Text('Tindakan', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: EmiSpacing.sm),
              FilledButton(
                onPressed: _saving ? null : () => _confirmApprove(item),
                child: Text(_saving ? 'Memproses...' : 'Setujui Akun'),
              ),
              const SizedBox(height: EmiSpacing.sm),
              OutlinedButton(
                onPressed: _saving ? null : () => _confirmReject(item),
                child: const Text('Tolak Akun'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmApprove(RegistrationApprovalAdmin item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setujui akun ini?'),
        content: const Text(
          'Pengguna dapat masuk dan menggunakan EMI setelah akun disetujui.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );
    if (ok == true) await _submit('approve', null);
  }

  Future<void> _confirmReject(RegistrationApprovalAdmin item) async {
    final note = TextEditingController();
    String? validation;
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tolak akun ini?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pengguna belum dapat menggunakan EMI setelah pengajuan ditolak.',
              ),
              const SizedBox(height: EmiSpacing.md),
              TextField(
                controller: note,
                decoration: InputDecoration(
                  labelText: 'Alasan Penolakan',
                  hintText:
                      'Tuliskan alasan singkat agar pengguna memahami keputusan ini.',
                  errorText: validation,
                ),
                minLines: 2,
                maxLines: 4,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final value = note.text.trim();
                if (value.isEmpty) {
                  setDialogState(
                    () => validation = 'Alasan penolakan wajib diisi.',
                  );
                  return;
                }
                Navigator.pop(context, value);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    note.dispose();
    if (reason != null) await _submit('reject', reason);
  }

  Future<void> _submit(String action, String? note) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(adminCrudRepositoryProvider)
          .reviewApproval(widget.id, action, note);
      if (!mounted) return;
      ref.invalidate(adminApprovalsProvider);
      ref.invalidate(adminApprovalDetailProvider(widget.id));
      ref.invalidate(adminDashboardProvider);
      ref.invalidate(adminUsersProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'approve'
                ? 'Akun berhasil disetujui.'
                : 'Pengajuan akun telah ditolak.',
          ),
        ),
      );
      if (context.canPop()) {
        context.pop(true);
      } else {
        context.go('/admin/approvals');
      }
    } catch (e) {
      final message = _actionError(e);
      if (!mounted) return;
      setState(() => _saving = false);

      if (message.contains('sudah memiliki guru') ||
          message.contains('CLASS_ALREADY_HAS_TEACHER')) {
        await _showConflictDialog(
          'Akun Belum Bisa Disetujui',
          'Kelas yang dipilih sudah memiliki Guru aktif.\n\nPilih kelas lain atau ganti Guru kelas terlebih dahulu melalui menu Kelas.',
          true,
        );
        return;
      }
      if (message.contains('Guru sudah memiliki') ||
          message.contains('TEACHER_ALREADY_ASSIGNED')) {
        await _showConflictDialog(
          'Akun Belum Bisa Disetujui',
          'Guru ini sudah memiliki kelas aktif di tempat lain.',
          false,
        );
        return;
      }
      if (message.contains('Siswa sudah memiliki') ||
          message.contains('STUDENT_ALREADY_ASSIGNED')) {
        await _showConflictDialog(
          'Akun Belum Bisa Disetujui',
          'Siswa ini sudah memiliki kelas aktif di tempat lain.',
          false,
        );
        return;
      }
      if (message.contains('sedang tidak aktif')) {
        await _showConflictDialog('Akun Belum Bisa Disetujui', message, false);
        return;
      }
      if (message.contains('tidak sesuai dengan sekolah')) {
        await _showConflictDialog('Akun Belum Bisa Disetujui', message, false);
        return;
      }
      if (message.contains('Status akun sudah berubah')) {
        await _showConflictDialog(
          'Status Akun Sudah Berubah',
          'Pengajuan ini sudah diperiksa oleh Admin lain. Data terbaru telah dimuat.',
          false,
        );
        ref.invalidate(adminApprovalDetailProvider(widget.id));
        ref.invalidate(adminApprovalsProvider);
        ref.invalidate(adminDashboardProvider);
        return;
      }
      if (message.contains('Data belum lengkap')) {
        await _showConflictDialog(
          'Data Belum Lengkap',
          'Periksa kembali data pengajuan sebelum menyetujui akun.',
          false,
        );
        return;
      }
      if (message.contains('Persetujuan belum berhasil')) {
        await _showConflictDialog(
          'Persetujuan Belum Berhasil',
          'Periksa koneksi internet, lalu coba lagi.',
          false,
        );
        return;
      }
      if (message.contains('Anda tidak memiliki izin')) {
        await _showConflictDialog(
          'Akses Ditolak',
          'Anda tidak memiliki izin.',
          false,
        );
        return;
      }

      await _showConflictDialog(
        'Persetujuan Belum Berhasil',
        'Akun belum dapat disetujui saat ini. Silakan coba kembali.',
        false,
      );
    }
  }

  Future<void> _showConflictDialog(
    String title,
    String content,
    bool canOpenClass,
  ) async {
    final detail = ref.read(adminApprovalDetailProvider(widget.id)).valueOrNull;
    final classId = detail?.classId;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
          if (canOpenClass && classId != null && classId.isNotEmpty)
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/admin/classes/$classId');
              },
              child: const Text('Buka Kelas'),
            ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.rows});

  final String title;
  final Map<String, String> rows;

  @override
  Widget build(BuildContext context) => EmiCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: EmiSpacing.sm),
        for (final row in rows.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: EmiSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 132, child: Text(row.key)),
                Expanded(
                  child: Text(row.value.isEmpty ? 'Belum Diisi' : row.value),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

IconData _roleIcon(String value) => switch (value) {
  'teacher' => Icons.school_outlined,
  'student' => Icons.person_outline,
  _ => Icons.account_circle_outlined,
};

String _roleLabel(String value) => switch (value) {
  'teacher' => 'Guru',
  'student' => 'Siswa',
  _ => 'Belum Diisi',
};

String _statusLabel(String value) => switch (value) {
  'pending' => 'Menunggu Persetujuan',
  'approved' => 'Disetujui',
  'rejected' => 'Ditolak',
  'inactive' => 'Tidak Aktif',
  _ => 'Belum Diisi',
};

String _dateLabel(String value) =>
    value.length >= 10 ? value.substring(0, 10) : value;

String _actionError(Object error) {
  final message = error is AppError ? error.message : error.toString();

  if (message.contains('REGISTRATION_ALREADY_PROCESSED') ||
      message.contains('sudah diproses') ||
      message.contains('Status akun sudah berubah')) {
    return 'Status akun sudah berubah. Data terbaru telah dimuat.';
  }

  if (message.contains('TEACHER_ALREADY_ASSIGNED') ||
      message.contains('CLASS_ALREADY_HAS_TEACHER') ||
      message.contains('Guru sudah memiliki') ||
      message.contains('sudah memiliki guru')) {
    return message;
  }

  if (message.contains('STUDENT_ALREADY_ASSIGNED') ||
      message.contains('Siswa sudah memiliki')) {
    return message;
  }

  if (message.contains('TARGET_INACTIVE') ||
      message.contains('sudah tidak aktif')) {
    return 'Sekolah atau kelas yang dipilih sedang tidak aktif.';
  }

  if (message.contains('CLASS_MISMATCH') ||
      message.contains('tidak sesuai dengan sekolah')) {
    return 'Kelas tidak sesuai dengan sekolah yang dipilih.';
  }

  if (message.contains('VALIDATION_ERROR') || message.contains('wajib')) {
    return 'Data belum lengkap. Periksa kembali isian.';
  }

  if (message.contains('FORBIDDEN') || message.contains('izin')) {
    return 'Anda tidak memiliki izin.';
  }

  if (error is AppError && error.type == AppErrorType.timeout ||
      error is AppError && error.type == AppErrorType.networkUnavailable) {
    return 'Persetujuan belum berhasil. Periksa koneksi internet, lalu coba lagi.';
  }

  return 'Akun belum dapat disetujui saat ini. Silakan coba kembali.';
}
