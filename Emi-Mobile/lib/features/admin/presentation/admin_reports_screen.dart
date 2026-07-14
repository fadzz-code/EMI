import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_card.dart';
import '../data/admin_crud_providers.dart';
import 'admin_shell.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});
  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  String _kind = 'students';
  int _page = 1;
  @override
  Widget build(BuildContext context) {
    final query = AdminReportQuery(kind: _kind, page: _page);
    final data = ref.watch(adminReportProvider(query));
    return AdminShell(
      title: 'Laporan',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(EmiSpacing.md),
            child: DropdownButtonFormField<String>(
              initialValue: _kind,
              decoration: const InputDecoration(labelText: 'Jenis laporan'),
              items: const [
                DropdownMenuItem(
                  value: 'students',
                  child: Text('Progress siswa'),
                ),
                DropdownMenuItem(
                  value: 'classes',
                  child: Text('Progress kelas'),
                ),
                DropdownMenuItem(
                  value: 'schools',
                  child: Text('Progress sekolah'),
                ),
                DropdownMenuItem(value: 'quiz', child: Text('Hasil kuis')),
              ],
              onChanged: (v) => setState(() {
                _kind = v ?? 'students';
                _page = 1;
              }),
            ),
          ),
          Expanded(
            child: data.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ListView(
                padding: const EdgeInsets.all(EmiSpacing.md),
                children: [
                  EmiCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.toString()),
                        OutlinedButton(
                          onPressed: () =>
                              ref.invalidate(adminReportProvider(query)),
                          child: const Text('Coba lagi'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              data: (report) => ListView(
                padding: const EdgeInsets.all(EmiSpacing.md),
                children: [
                  if (report.summary.isNotEmpty)
                    EmiCard(
                      child: Wrap(
                        spacing: EmiSpacing.md,
                        runSpacing: EmiSpacing.sm,
                        children: [
                          for (final entry in report.summary.entries)
                            Chip(label: Text('${entry.key}: ${entry.value}')),
                        ],
                      ),
                    ),
                  const SizedBox(height: EmiSpacing.md),
                  if (report.rows.isEmpty)
                    const EmiCard(child: Text('Laporan belum tersedia.')),
                  for (final row in report.rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: EmiSpacing.md),
                      child: EmiCard(child: Text(_rowTitle(row))),
                    ),
                  if (report.hasMore)
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

  String _rowTitle(Map<String, dynamic> row) {
    final student = row['student'];
    final quiz = row['quiz'];
    if (student is Map && quiz is Map) {
      return '${student['full_name'] ?? '-'} • ${quiz['title'] ?? '-'}';
    }
    return (row['full_name'] ??
            row['class_name'] ??
            row['school_name'] ??
            row.toString())
        .toString();
  }
}
