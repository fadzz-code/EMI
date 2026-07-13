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
  const StudentQuizQuery({this.availability});

  final String? availability;

  @override
  bool operator ==(Object other) {
    return other is StudentQuizQuery && other.availability == availability;
  }

  @override
  int get hashCode => availability.hashCode;
}

final studentQuizListProvider = FutureProvider.autoDispose
    .family<StudentQuizPage, StudentQuizQuery>(
      (ref, query) => ref
          .watch(studentQuizRepositoryProvider)
          .list(availability: query.availability),
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
