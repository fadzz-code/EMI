import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_card.dart';
import '../../../shared/widgets/emi_scaffold.dart';
import '../data/speaking_models.dart';
import '../data/speaking_providers.dart';

class StudentSpeakingListScreen extends ConsumerWidget {
  const StudentSpeakingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(speakingExercisesProvider);
    final attempts = ref.watch(speakingAttemptsProvider);

    return EmiScaffold(
      title: 'Speaking',
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(speakingExercisesProvider);
          ref.invalidate(speakingAttemptsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(EmiSpacing.md),
          children: [
            exercises.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorCard(
                message: error.toString(),
                onRetry: () => ref.invalidate(speakingExercisesProvider),
              ),
              data: (items) => _ExerciseList(items: items),
            ),
            const SizedBox(height: EmiSpacing.lg),
            Text(
              'Riwayat Attempt',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: EmiSpacing.sm),
            attempts.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorCard(
                message: error.toString(),
                onRetry: () => ref.invalidate(speakingAttemptsProvider),
              ),
              data: (items) => _AttemptList(items: items),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseList extends StatelessWidget {
  const _ExerciseList({required this.items});

  final List<SpeakingExercise> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmiCard(child: Text('Belum ada latihan speaking.'));
    }
    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: EmiSpacing.md),
              child: InkWell(
                onTap: () => context.go('/student/speaking/${item.id}'),
                child: EmiCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: EmiSpacing.sm),
                      Text(
                        item.promptText ??
                            item.targetText ??
                            'Buka untuk detail latihan.',
                      ),
                      const SizedBox(height: EmiSpacing.sm),
                      Wrap(
                        spacing: EmiSpacing.sm,
                        children: [
                          _Chip(item.difficulty ?? 'Speaking'),
                          if (item.hasReferenceAudio) const _Chip('Suara Asli'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _AttemptList extends StatelessWidget {
  const _AttemptList({required this.items});

  final List<SpeakingAttempt> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const EmiCard(child: Text('Belum ada riwayat.'));
    return Column(
      children: items.take(10).map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: EmiSpacing.sm),
          child: EmiCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.exercise?.title ??
                            item.targetText ??
                            'Attempt speaking',
                      ),
                      Text('Status: ${item.status}'),
                    ],
                  ),
                ),
                if (item.aiScore != null) Text('${item.aiScore}'),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label), backgroundColor: EmiColors.secondary);
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return EmiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          const SizedBox(height: EmiSpacing.sm),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}
