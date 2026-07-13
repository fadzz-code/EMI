import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/dio_error_mapper.dart';
import '../../../core/network/dio_provider.dart';
import 'admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(ref.watch(dioProvider), const DioErrorMapper()),
);

final adminDashboardProvider = FutureProvider<AdminSummary>(
  (ref) => ref.watch(adminRepositoryProvider).dashboard(),
);

final adminListProvider =
    FutureProvider.family<AdminListPage, AdminFeatureQuery>(
      (ref, query) => ref
          .watch(adminRepositoryProvider)
          .list(query.feature.endpoint, query.query),
    );

final adminDetailProvider =
    FutureProvider.family<AdminRecord, AdminDetailQuery>(
      (ref, query) => ref
          .watch(adminRepositoryProvider)
          .detail(query.feature.endpoint, query.id),
    );

class AdminFeatureQuery {
  const AdminFeatureQuery({
    required this.feature,
    this.query = const AdminListQuery(),
  });

  final AdminFeature feature;
  final AdminListQuery query;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminFeatureQuery &&
          other.feature == feature &&
          other.query == query;

  @override
  int get hashCode => Object.hash(feature, query);
}

class AdminDetailQuery {
  const AdminDetailQuery({required this.feature, required this.id});

  final AdminFeature feature;
  final String id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminDetailQuery && other.feature == feature && other.id == id;

  @override
  int get hashCode => Object.hash(feature, id);
}

enum AdminFeature {
  users('Pengguna', '/users', '/admin/users'),
  classes('Kelas', '/classes', '/admin/classes'),
  modules('Modul', '/admin/module-templates', '/admin/modules'),
  dictionary('Kamus', '/admin/dictionary/entries', '/admin/dictionary'),
  quizzes('Kuis', '/admin/quiz-templates', '/admin/quizzes'),
  culture('Budaya', '/admin/culture/items', '/admin/culture'),
  speaking('Speaking', '/admin/speaking/exercises', '/admin/speaking'),
  reports('Laporan', '/admin/reports/progress/students', '/admin/reports'),
  settings('Pengaturan', '/admin/settings', '/admin/settings');

  const AdminFeature(this.label, this.endpoint, this.route);

  final String label;
  final String endpoint;
  final String route;
}
