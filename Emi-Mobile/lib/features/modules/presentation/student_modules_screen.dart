import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_card.dart';
import '../../../shared/widgets/emi_scaffold.dart';
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
              EmiCard(
                child: Column(
                  children: [
                    Text(error.toString()),
                    const SizedBox(height: EmiSpacing.md),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(studentModuleListProvider),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          data: (page) => ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              _Filters(
                value: _status,
                onChanged: (value) => setState(() => _status = value),
              ),
              const SizedBox(height: EmiSpacing.md),
              _Summary(page: page),
              const SizedBox(height: EmiSpacing.lg),
              Text(
                'Daftar Modul',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: EmiSpacing.md),
              if (page.items.isEmpty)
                const EmiCard(child: Text('Belum ada modul tersedia.'))
              else
                ...page.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: EmiSpacing.lg),
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
            child: ChoiceChip(
              selected: active,
              label: Text(entry.value),
              onSelected: (_) => onChanged(entry.key),
              selectedColor: EmiColors.primary,
              backgroundColor: EmiColors.background,
              side: const BorderSide(color: EmiColors.border, width: 2),
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
          child: _SmallStat(label: 'Total', value: '${page.total}'),
        ),
        const SizedBox(width: EmiSpacing.sm),
        Expanded(
          child: _SmallStat(
            label: 'Berjalan',
            value: '$inProgress',
            color: EmiColors.success,
          ),
        ),
        const SizedBox(width: EmiSpacing.sm),
        Expanded(
          child: _SmallStat(
            label: 'Selesai',
            value: '$completed',
            color: EmiColors.secondary,
          ),
        ),
      ],
    );
  }
}

class _SmallStat extends StatelessWidget {
  const _SmallStat({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(EmiSpacing.sm),
      decoration: BoxDecoration(
        color: color ?? EmiColors.background,
        border: Border.all(color: EmiColors.border, width: 2),
        borderRadius: BorderRadius.circular(EmiRadii.card),
        boxShadow: const [EmiShadows.hard],
      ),
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.titleMedium),
          Text(label),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module});

  final StudentModule module;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/student/modules/${module.id}'),
      child: EmiCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 128,
              decoration: const BoxDecoration(
                color: Color(0xFF81D4FA),
                border: Border(
                  bottom: BorderSide(color: EmiColors.border, width: 2),
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.menu_book_outlined, size: 40),
            ),
            Padding(
              padding: const EdgeInsets.all(EmiSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (module.description != null) ...[
                    const SizedBox(height: EmiSpacing.xs),
                    Text(
                      module.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: EmiSpacing.md),
                  LinearProgressIndicator(
                    value: module.progress.progressPercent / 100,
                  ),
                  const SizedBox(height: EmiSpacing.xs),
                  Text('${module.progress.progressPercent}% selesai'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
