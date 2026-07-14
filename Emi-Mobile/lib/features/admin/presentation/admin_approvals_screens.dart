import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../core/errors/app_error.dart';
import '../../../shared/widgets/emi_card.dart';
import '../data/admin_crud_providers.dart';
import 'admin_shell.dart';

class AdminApprovalsScreen extends ConsumerStatefulWidget {
  const AdminApprovalsScreen({super.key});

  @override
  ConsumerState<AdminApprovalsScreen> createState() =>
      _AdminApprovalsScreenState();
}

class _AdminApprovalsScreenState extends ConsumerState<AdminApprovalsScreen> {
  String? _search;
  String _status = 'pending';
  var _page = 1;

  @override
  Widget build(BuildContext context) {
    final query = AdminApprovalQuery(
      search: _search,
      status: _status,
      page: _page,
    );
    final data = ref.watch(adminApprovalsProvider(query));
    return AdminShell(
      title: 'Persetujuan',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(EmiSpacing.md),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Cari nama atau email',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() {
                    _search = v;
                    _page = 1;
                  }),
                ),
                const SizedBox(height: EmiSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('pending')),
                    DropdownMenuItem(
                      value: 'approved',
                      child: Text('approved'),
                    ),
                    DropdownMenuItem(
                      value: 'rejected',
                      child: Text('rejected'),
                    ),
                  ],
                  onChanged: (v) => setState(() {
                    _status = v ?? 'pending';
                    _page = 1;
                  }),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(adminApprovalsProvider),
              child: data.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _Message(
                  text: e.toString(),
                  action: TextButton(
                    onPressed: () =>
                        ref.invalidate(adminApprovalsProvider(query)),
                    child: const Text('Coba lagi'),
                  ),
                ),
                data: (page) => ListView(
                  padding: const EdgeInsets.all(EmiSpacing.md),
                  children: [
                    if (page.items.isEmpty)
                      const _Message(text: 'Permintaan pendaftaran kosong.'),
                    for (final item in page.items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: EmiSpacing.sm),
                        child: EmiCard(
                          child: ListTile(
                            title: Text(item.userName),
                            subtitle: Text(
                              '${item.userEmail}\n${item.requestedRole} • ${item.schoolName ?? '-'} • ${item.className ?? '-'}',
                            ),
                            isThreeLine: true,
                            trailing: Text(item.status),
                            onTap: () =>
                                context.go('/admin/approvals/${item.id}'),
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
          ),
        ],
      ),
    );
  }
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
  final _note = TextEditingController();
  bool _saving = false;
  AppError? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(adminApprovalDetailProvider(widget.id));
    return AdminShell(
      title: 'Detail Persetujuan',
      child: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Message(
          text: e.toString(),
          action: TextButton(
            onPressed: () =>
                ref.invalidate(adminApprovalDetailProvider(widget.id)),
            child: const Text('Coba lagi'),
          ),
        ),
        data: (item) => ListView(
          padding: const EdgeInsets.all(EmiSpacing.md),
          children: [
            if (_error != null) _Message(text: _error!.message),
            EmiCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.userName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(item.userEmail),
                  const Divider(),
                  _Row(label: 'Role', value: item.requestedRole),
                  _Row(label: 'Status', value: item.status),
                  _Row(label: 'Sekolah', value: item.schoolName ?? '-'),
                  _Row(label: 'Kelas', value: item.className ?? '-'),
                  if (item.reviewNote?.isNotEmpty == true)
                    _Row(label: 'Catatan', value: item.reviewNote!),
                ],
              ),
            ),
            if (item.status == 'pending') ...[
              const SizedBox(height: EmiSpacing.md),
              TextField(
                controller: _note,
                decoration: const InputDecoration(labelText: 'Catatan review'),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: EmiSpacing.md),
              FilledButton(
                onPressed: _saving ? null : () => _submit('approve'),
                child: Text(_saving ? 'Memproses...' : 'Setujui'),
              ),
              TextButton(
                onPressed: _saving ? null : () => _submit('reject'),
                child: const Text('Tolak'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submit(String action) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(adminCrudRepositoryProvider)
          .reviewApproval(
            widget.id,
            action,
            _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      ref.invalidate(adminApprovalsProvider);
      ref.invalidate(adminApprovalDetailProvider(widget.id));
      if (mounted) context.go('/admin/approvals');
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
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: EmiSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 96, child: Text(label)),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(EmiSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, textAlign: TextAlign.center),
          ?action,
        ],
      ),
    ),
  );
}
