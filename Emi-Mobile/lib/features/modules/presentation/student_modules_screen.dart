import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_scaffold.dart';
import '../../../shared/widgets/student_style.dart';
import '../../../shared/widgets/student_widgets.dart';
import '../data/student_module.dart';
import '../data/student_module_providers.dart';

class StudentModulesScreen extends ConsumerStatefulWidget {
  const StudentModulesScreen({super.key});

  @override
  ConsumerState<StudentModulesScreen> createState() =>
      _StudentModulesScreenState();
}

class _StudentModulesScreenState extends ConsumerState<StudentModulesScreen> {
  String? _status;

  @override
  Widget build(BuildContext context) {
    final query = StudentModuleQuery(status: _status);
    final modules = ref.watch(studentModuleListProvider(query));

    return EmiScaffold(
      title: 'Modul Belajar',
      currentIndex: 1,
      onNavTap: (index) => _go(context, index),
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(studentModuleListProvider(query).future),
        child: modules.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              StudentPlaceholder(
                icon: Icons.cloud_off_outlined,
                title: 'Modul Belum Bisa Dimuat',
                message: 'Periksa koneksi internetmu, lalu coba lagi.',
                onRetry: () => ref.invalidate(studentModuleListProvider),
              ),
            ],
          ),
          data: (page) => ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              const StudentPageHeader(
                icon: Icons.menu_book_outlined,
                title: 'Modul Belajar',
                subtitle: 'Pilih modul dan lanjutkan progress belajarmu.',
              ),
              const SizedBox(height: EmiSpacing.md),
              _Filters(
                value: _status,
                onChanged: (value) => setState(() => _status = value),
              ),
              const SizedBox(height: EmiSpacing.md),
              _Summary(page: page),
              const StudentSectionHeader(
                'Daftar Modul',
                icon: Icons.collections_bookmark_outlined,
              ),
              if (page.items.isEmpty)
                StudentPlaceholder(
                  icon: Icons.menu_book_outlined,
                  title: 'Belum Ada Modul',
                  message: 'Modul untuk kelasmu belum tersedia.',
                )
              else
                ...page.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: EmiSpacing.md),
                    child: _ModuleCard(module: item),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _go(BuildContext context, int index) {
    if (index == 0) context.go('/student/dashboard');
    if (index == 1) context.go('/student/modules');
    if (index == 2) context.go('/student/dictionary');
    if (index == 3) context.go('/student/quizzes');
    if (index == 4) context.go('/student/profile');
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    const filters = <String?, String>{
      null: 'Semua',
      'not_started': 'Belum',
      'in_progress': 'Berjalan',
      'completed': 'Selesai',
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.entries.map((entry) {
          final active = entry.key == value;
          return Padding(
            padding: const EdgeInsets.only(right: EmiSpacing.sm),
            child: GestureDetector(
              onTap: () => onChanged(entry.key),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: EmiSpacing.md,
                  vertical: EmiSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: active ? EmiColors.primary : StudentStyle.tint,
                  borderRadius: BorderRadius.circular(EmiRadii.pill),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    color: active ? Colors.white : StudentStyle.inkMuted,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.page});

  final StudentModulePage page;

  @override
  Widget build(BuildContext context) {
    final completed = page.items
        .where((item) => item.progress.status == 'completed')
        .length;
    final inProgress = page.items
        .where((item) => item.progress.status == 'in_progress')
        .length;
    return Row(
      children: [
        Expanded(
          child: StudentStatChip(label: 'Total', value: '${page.total}'),
        ),
        const SizedBox(width: EmiSpacing.sm),
        Expanded(
          child: StudentStatChip(label: 'Berjalan', value: '$inProgress'),
        ),
        const SizedBox(width: EmiSpacing.sm),
        Expanded(
          child: StudentStatChip(label: 'Selesai', value: '$completed'),
        ),
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module});

  final StudentModule module;

  @override
  Widget build(BuildContext context) {
    return StudentCard(
      padding: EdgeInsets.zero,
      clip: true,
      onTap: () => context.push('/student/modules/${module.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 110,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF7FB2F0), Color(0xFF5B8FE0)],
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.menu_book_outlined,
              size: 40,
              color: Colors.white,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(EmiSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  module.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: StudentStyle.ink),
                ),
                if (module.description != null) ...[
                  const SizedBox(height: EmiSpacing.xs),
                  Text(
                    module.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: StudentStyle.inkMuted),
                  ),
                ],
                const SizedBox(height: EmiSpacing.md),
                StudentProgressBar(
                  value: module.progress.progressPercent / 100,
                  caption: '${module.progress.progressPercent}% selesai',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
