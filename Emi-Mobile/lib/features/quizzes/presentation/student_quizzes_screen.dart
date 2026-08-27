import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../core/network/network_status_controller.dart';
import '../../../shared/widgets/emi_scaffold.dart';
import '../../../shared/widgets/student_connectivity_banner.dart';
import '../../../shared/widgets/student_style.dart';
import '../../../shared/widgets/student_widgets.dart';
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
  int _page = 1;

  @override
  Widget build(BuildContext context) {
    final query = StudentQuizQuery(availability: _availability, page: _page);
    final quizzes = ref.watch(studentQuizListProvider(query));
    final networkMode = ref.watch(networkStatusControllerProvider).mode;

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
              StudentPlaceholder(
                icon: Icons.cloud_off_outlined,
                title: 'Kuis Belum Bisa Dimuat',
                message: 'Periksa koneksi internetmu, lalu coba lagi.',
                onRetry: () => ref.invalidate(studentQuizListProvider(query)),
              ),
            ],
          ),
          data: (page) => ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              StudentConnectivityBanner(mode: networkMode),
              const StudentPageHeader(
                icon: Icons.quiz_outlined,
                title: 'Kuis & LKPD',
                subtitle: 'Lihat jadwal, status, dan hasil kuismu.',
              ),
              const SizedBox(height: EmiSpacing.md),
              _Filters(
                value: _availability,
                onChanged: (value) => setState(() {
                  _availability = value;
                  _page = 1;
                }),
              ),
              const SizedBox(height: EmiSpacing.md),
              _Summary(page: page),
              const StudentSectionHeader(
                'Daftar Kuis',
                icon: Icons.assignment_outlined,
              ),
              if (page.items.isEmpty)
                StudentPlaceholder(
                  icon: Icons.quiz_outlined,
                  title: 'Belum Ada Kuis',
                  message: 'Belum ada kuis untuk kelasmu saat ini.',
                )
              else
                ...page.items.map(
                  (quiz) => Padding(
                    padding: const EdgeInsets.only(bottom: EmiSpacing.md),
                    child: _QuizCard(quiz: quiz),
                  ),
                ),
              if (page.lastPage > 1) ...[
                const SizedBox(height: EmiSpacing.sm),
                StudentPaginationBar(
                  currentPage: page.currentPage,
                  lastPage: page.lastPage,
                  onPrevious: page.currentPage > 1
                      ? () => setState(() => _page--)
                      : null,
                  onNext: page.hasNextPage
                      ? () => setState(() => _page++)
                      : null,
                ),
              ],
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

  final StudentQuizPage page;

  @override
  Widget build(BuildContext context) {
    final finished = page.items
        .where((item) => item.availability == QuizAvailability.finished)
        .length;
    return Row(
      children: [
        Expanded(
          child: StudentStatChip(label: 'Total', value: '${page.total}'),
        ),
        const SizedBox(width: EmiSpacing.sm),
        Expanded(
          child: StudentStatChip(label: 'Selesai', value: '$finished'),
        ),
      ],
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({required this.quiz});

  final StudentQuiz quiz;

  @override
  Widget build(BuildContext context) {
    return StudentCard(
      onTap: () => context.push('/student/quizzes/${quiz.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  quiz.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: StudentStyle.ink),
                ),
              ),
              const SizedBox(width: EmiSpacing.sm),
              _StatusPill(quiz: quiz),
            ],
          ),
          if (quiz.description != null &&
              quiz.description!.trim().isNotEmpty) ...[
            const SizedBox(height: EmiSpacing.sm),
            Text(
              quiz.description!,
              style: const TextStyle(color: StudentStyle.inkMuted),
            ),
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
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.quiz});

  final StudentQuiz quiz;

  @override
  Widget build(BuildContext context) {
    final finished = quiz.availability == QuizAvailability.finished;
    return StudentStatusChip(
      label: quiz.statusLabel,
      status: finished ? 'done' : 'open',
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
      children: [
        Icon(icon, size: 18, color: StudentStyle.inkMuted),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: StudentStyle.inkMuted)),
      ],
    );
  }
}
