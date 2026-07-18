import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_card.dart';
import '../../../shared/widgets/emi_scaffold.dart';
import '../data/student_quiz.dart';
import '../data/student_quiz_providers.dart';

class StudentQuizzesScreen extends ConsumerStatefulWidget {
  const StudentQuizzesScreen({super.key});

  @override
  ConsumerState<StudentQuizzesScreen> createState() =>
      _StudentQuizzesScreenState();
}

class _StudentQuizzesScreenState extends ConsumerState<StudentQuizzesScreen> {
  String? _availability;

  @override
  Widget build(BuildContext context) {
    final query = StudentQuizQuery(availability: _availability);
    final quizzes = ref.watch(studentQuizListProvider(query));

    return EmiScaffold(
      title: 'Kuis & LKPD',
      currentIndex: 3,
      onNavTap: (index) => _go(context, index),
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(studentQuizListProvider(query).future),
        child: quizzes.when(
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
                          ref.invalidate(studentQuizListProvider(query)),
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
              Text(
                'Daftar Kuis',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: EmiSpacing.xs),
              const Text('Lihat jadwal, status, dan hasil kuis yang tersedia.'),
              const SizedBox(height: EmiSpacing.lg),
              _Filters(
                value: _availability,
                onChanged: (value) => setState(() => _availability = value),
              ),
              const SizedBox(height: EmiSpacing.lg),
              _Summary(page: page),
              const SizedBox(height: EmiSpacing.lg),
              if (page.items.isEmpty)
                const EmiCard(child: Text('Belum ada kuis tersedia.'))
              else
                ...page.items.map(
                  (quiz) => Padding(
                    padding: const EdgeInsets.only(bottom: EmiSpacing.lg),
                    child: _QuizCard(quiz: quiz),
                  ),
                ),
              if (page.hasNextPage)
                OutlinedButton(
                  onPressed: null,
                  child: Text(
                    'Halaman ${page.currentPage} dari ${page.lastPage}',
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
      'open': 'Tersedia',
      'not_open': 'Terkunci',
      'closed': 'Ditutup',
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

  final StudentQuizPage page;

  @override
  Widget build(BuildContext context) {
    final finished = page.items
        .where((item) => item.availability == QuizAvailability.finished)
        .length;
    return Row(
      children: [
        Expanded(
          child: _SmallStat(label: 'Total', value: '${page.total}'),
        ),
        const SizedBox(width: EmiSpacing.sm),
        Expanded(
          child: _SmallStat(
            label: 'Selesai',
            value: '$finished',
            color: EmiColors.success,
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
        color: color ?? EmiColors.secondary,
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

class _QuizCard extends StatelessWidget {
  const _QuizCard({required this.quiz});

  final StudentQuiz quiz;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/student/quizzes/${quiz.id}'),
      child: EmiCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    quiz.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                _StatusPill(quiz: quiz),
              ],
            ),
            if (quiz.description != null &&
                quiz.description!.trim().isNotEmpty) ...[
              const SizedBox(height: EmiSpacing.sm),
              Text(quiz.description!),
            ],
            const SizedBox(height: EmiSpacing.md),
            Wrap(
              spacing: EmiSpacing.sm,
              runSpacing: EmiSpacing.sm,
              children: [
                _Meta(
                  icon: Icons.help_outline,
                  text: '${quiz.questionsCount} soal',
                ),
                if (quiz.durationMinutes != null)
                  _Meta(
                    icon: Icons.timer_outlined,
                    text: '${quiz.durationMinutes} menit',
                  ),
                if (quiz.bestScorePercent != null)
                  _Meta(
                    icon: Icons.star_outline,
                    text: 'Terbaik ${quiz.bestScorePercent!.round()}%',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.quiz});

  final StudentQuiz quiz;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EmiSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: quiz.availability == QuizAvailability.finished
            ? EmiColors.success
            : EmiColors.secondary,
        border: Border.all(color: EmiColors.border, width: 2),
        borderRadius: BorderRadius.circular(EmiRadii.pill),
      ),
      child: Text(
        quiz.statusLabel,
        style: Theme.of(context).textTheme.labelLarge,
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 18), const SizedBox(width: 4), Text(text)],
    );
  }
}
