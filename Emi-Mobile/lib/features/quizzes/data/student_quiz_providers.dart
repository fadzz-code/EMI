import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/dio_error_mapper.dart';
import '../../../core/network/dio_provider.dart';
import 'student_quiz.dart';
import 'student_quiz_repository.dart';

final studentQuizRepositoryProvider = Provider<StudentQuizRepository>(
  (ref) =>
      StudentQuizRepository(ref.watch(dioProvider), const DioErrorMapper()),
);

class StudentQuizQuery {
  const StudentQuizQuery({this.availability, this.page = 1});

  final String? availability;
  final int page;

  @override
  bool operator ==(Object other) {
    return other is StudentQuizQuery &&
        other.availability == availability &&
        other.page == page;
  }

  @override
  int get hashCode => Object.hash(availability, page);
}

final studentQuizListProvider = FutureProvider.autoDispose
    .family<StudentQuizPage, StudentQuizQuery>(
      (ref, query) => ref
          .watch(studentQuizRepositoryProvider)
          .list(availability: query.availability, page: query.page),
    );

final studentQuizAttemptsProvider = FutureProvider.autoDispose
    .family<QuizAttemptPage, ({String quizId, int page})>(
      (ref, query) => ref
          .watch(studentQuizRepositoryProvider)
          .attempts(query.quizId, page: query.page),
    );

final studentQuizDetailProvider = FutureProvider.autoDispose
    .family<StudentQuiz, String>(
      (ref, quizId) => ref.watch(studentQuizRepositoryProvider).detail(quizId),
    );

final quizAttemptProvider = FutureProvider.autoDispose
    .family<QuizAttempt, String>(
      (ref, attemptId) =>
          ref.watch(studentQuizRepositoryProvider).attempt(attemptId),
    );
