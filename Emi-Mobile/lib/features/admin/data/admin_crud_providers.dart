import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/dio_error_mapper.dart';
import '../../../core/network/dio_provider.dart';
import 'admin_crud_repository.dart';

final adminCrudRepositoryProvider = Provider<AdminCrudRepository>(
  (ref) => AdminCrudRepository(ref.watch(dioProvider), const DioErrorMapper()),
);

final dictionaryCategoriesProvider = FutureProvider(
  (ref) => ref.watch(adminCrudRepositoryProvider).categories(),
);

final adminDictionaryProvider =
    FutureProvider.family<
      AdminCrudPage<DictionaryEntryAdmin>,
      AdminSearchQuery
    >(
      (ref, query) => ref
          .watch(adminCrudRepositoryProvider)
          .dictionary(search: query.search, page: query.page),
    );

final adminDictionaryDetailProvider =
    FutureProvider.family<DictionaryEntryAdmin, String>(
      (ref, id) => ref.watch(adminCrudRepositoryProvider).dictionaryDetail(id),
    );

final adminQuizProvider =
    FutureProvider.family<AdminCrudPage<QuizTemplateAdmin>, AdminSearchQuery>(
      (ref, query) => ref
          .watch(adminCrudRepositoryProvider)
          .quizzes(search: query.search, page: query.page),
    );

final adminQuizDetailProvider =
    FutureProvider.family<QuizTemplateAdmin, String>(
      (ref, id) => ref.watch(adminCrudRepositoryProvider).quizDetail(id),
    );

final adminQuizQuestionsProvider =
    FutureProvider.family<List<QuizQuestionAdmin>, String>(
      (ref, quizId) => ref.watch(adminCrudRepositoryProvider).questions(quizId),
    );

final adminQuestionDetailProvider =
    FutureProvider.family<QuizQuestionAdmin, String>(
      (ref, id) => ref.watch(adminCrudRepositoryProvider).questionDetail(id),
    );

final adminReportProvider = FutureProvider.family<ReportPage, AdminReportQuery>(
  (ref, query) => ref
      .watch(adminCrudRepositoryProvider)
      .report(query.kind, page: query.page),
);

final adminApprovalsProvider =
    FutureProvider.family<
      AdminCrudPage<RegistrationApprovalAdmin>,
      AdminApprovalQuery
    >(
      (ref, query) => ref
          .watch(adminCrudRepositoryProvider)
          .approvals(
            search: query.search,
            status: query.status,
            role: query.role,
            page: query.page,
          ),
    );

final adminApprovalDetailProvider =
    FutureProvider.family<RegistrationApprovalAdmin, String>(
      (ref, id) => ref.watch(adminCrudRepositoryProvider).approvalDetail(id),
    );

class AdminSearchQuery {
  const AdminSearchQuery({this.search, this.page = 1});
  final String? search;
  final int page;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminSearchQuery && other.search == search && other.page == page;
  @override
  int get hashCode => Object.hash(search, page);
}

class AdminApprovalQuery {
  const AdminApprovalQuery({
    this.search,
    this.status = 'pending',
    this.role,
    this.page = 1,
  });
  final String? search;
  final String status;
  final String? role;
  final int page;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminApprovalQuery &&
          other.search == search &&
          other.status == status &&
          other.role == role &&
          other.page == page;
  @override
  int get hashCode => Object.hash(search, status, role, page);
}

class AdminReportQuery {
  const AdminReportQuery({required this.kind, this.page = 1});
  final String kind;
  final int page;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminReportQuery && other.kind == kind && other.page == page;
  @override
  int get hashCode => Object.hash(kind, page);
}
