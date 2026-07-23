import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/dio_error_mapper.dart';
import '../../../core/network/dio_provider.dart';
import 'speaking_models.dart';
import 'speaking_repository.dart';

final speakingRepositoryProvider = Provider<SpeakingRepository>(
  (ref) => SpeakingRepository(ref.watch(dioProvider), const DioErrorMapper()),
);

final speakingExercisesProvider =
    FutureProvider.autoDispose<List<SpeakingExercise>>(
      (ref) => ref.watch(speakingRepositoryProvider).listExercises(),
    );

final speakingExerciseProvider = FutureProvider.autoDispose
    .family<SpeakingExercise, String>((ref, id) {
      return ref.watch(speakingRepositoryProvider).getExercise(id);
    });

final speakingAttemptsProvider = FutureProvider.autoDispose
    .family<SpeakingAttemptPage, int>((ref, page) {
      return ref.watch(speakingRepositoryProvider).listAttempts(page: page);
    });

final speakingAttemptProvider = FutureProvider.autoDispose
    .family<SpeakingAttempt, String>((ref, id) {
      return ref.watch(speakingRepositoryProvider).getAttempt(id);
    });
