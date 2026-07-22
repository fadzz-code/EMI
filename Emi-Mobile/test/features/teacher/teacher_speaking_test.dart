import 'dart:async';

import 'package:dio/dio.dart';
import 'package:emi_mobile/core/errors/app_error.dart';
import 'package:emi_mobile/core/errors/dio_error_mapper.dart';
import 'package:emi_mobile/features/auth/domain/auth_repository.dart';
import 'package:emi_mobile/features/auth/presentation/auth_controller.dart';
import 'package:emi_mobile/features/auth/presentation/auth_state.dart';
import 'package:emi_mobile/features/teacher/data/teacher_providers.dart';
import 'package:emi_mobile/features/teacher/data/teacher_repository.dart';
import 'package:emi_mobile/features/teacher/presentation/teacher_dashboard_screen.dart';
import 'package:emi_mobile/features/teacher/presentation/teacher_speaking_screens.dart';
import 'package:emi_mobile/shared/widgets/emi_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _Auth extends AuthController {
  _Auth() : super(_MockAuthRepository()) {
    state = const AuthState(status: AuthStatus.authenticatedTeacher);
  }
}

class _AudioErrorRepository extends TeacherRepository {
  const _AudioErrorRepository(super.dio, super.mapper);

  @override
  Future<String> speakingTemporaryUrl(String mediaId) async =>
      throw Exception('audio');
}

class _DeleteRepository extends TeacherRepository {
  _DeleteRepository({this.error, this.pending = false})
    : super(
        Dio(BaseOptions(baseUrl: 'https://example.test')),
        const DioErrorMapper(),
      );

  final Object? error;
  final bool pending;
  final completer = Completer<void>();
  int calls = 0;

  @override
  Future<void> deleteSpeakingExercise(String id) async {
    calls++;
    if (error != null) throw error!;
    if (pending) await completer.future;
  }
}

TeacherSpeakingExercise _exercise({
  String status = 'published',
  String difficulty = 'beginner',
}) => TeacherSpeakingExercise.fromJson({
  'id': 'exercise-1',
  'classroom_id': 'class-1',
  'classroom': {'id': 'class-1', 'name': 'Kelas 7A'},
  'title': 'Salam Tolaki',
  'target_text': 'Tabe',
  'target_translation': 'Permisi',
  'prompt_text': 'Ucapkan dengan jelas',
  'difficulty': difficulty,
  'status': status,
  'attempts_count': 4,
  'updated_at': '2026-07-18T09:00:00Z',
});

TeacherSpeakingAttempt _attempt({double? teacherScore}) =>
    TeacherSpeakingAttempt.fromJson({
      'id': 'attempt-1',
      'student': {'full_name': 'Nina'},
      'exercise': {
        'title': 'Salam Tolaki',
        'classroom': {'name': 'Kelas 7A'},
      },
      'audio_media_id': 'media-secret',
      'ai_transcription': 'Tabe',
      'ai_score': 87,
      'teacher_score': teacherScore,
      'teacher_feedback': teacherScore == null ? null : 'Bagus sekali',
      'status': 'completed',
      'capture_source': 'mobile_microphone',
      'created_at': '2026-07-18T09:00:00Z',
    });

TeacherClassPage get _classes => TeacherClassPage.fromJson({
  'data': [
    {
      'id': 'class-1',
      'name': 'Kelas 7A',
      'status': 'active',
      'active_students_count': 20,
    },
  ],
  'meta': {'current_page': 1, 'last_page': 1, 'total': 1},
});

TeacherDashboardSummary get _summary => TeacherDashboardSummary.fromJson({
  'class': {'id': 'class-1', 'name': 'Kelas 7A'},
  'students': {},
  'learning': {},
  'recent_activity': [],
});

Future<GoRouter> _pump(
  WidgetTester tester, {
  required String location,
  List<Override> overrides = const [],
  double textScale = 1,
}) async {
  await tester.pumpWidget(const SizedBox());
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: '/teacher/dashboard',
        builder: (_, _) => const TeacherDashboardScreen(),
      ),
      GoRoute(
        path: '/teacher/speaking',
        redirect: (_, _) => '/teacher/speaking/exercises',
      ),
      GoRoute(
        path: '/teacher/speaking/exercises',
        builder: (_, _) => const TeacherSpeakingScreen(),
      ),
      GoRoute(
        path: '/teacher/speaking/attempts',
        builder: (_, _) => const TeacherSpeakingScreen(attempts: true),
      ),
      GoRoute(
        path: '/teacher/speaking/create',
        builder: (_, _) => const TeacherSpeakingExerciseFormScreen(),
      ),
      GoRoute(
        path: '/teacher/speaking/exercises/:id/edit',
        builder: (_, s) =>
            TeacherSpeakingExerciseFormScreen(id: s.pathParameters['id']),
      ),
      GoRoute(
        path: '/teacher/speaking/exercises/:id',
        builder: (_, s) =>
            TeacherSpeakingExerciseDetailScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/teacher/speaking/attempts/:id',
        builder: (_, s) =>
            TeacherSpeakingAttemptDetailScreen(id: s.pathParameters['id']!),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith((_) => _Auth()),
        teacherDashboardProvider.overrideWith((_) async => _summary),
        teacherClassesProvider.overrideWith((_, _) async => _classes),
        teacherSpeakingTemplatesProvider.overrideWith((_) async => const []),
        ...overrides,
      ],
      child: MaterialApp.router(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        routerConfig: router,
      ),
    ),
  );
  return router;
}

Future<void> _bounded(WidgetTester tester, [int count = 15]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
}

void main() {
  late List<RequestOptions> requests;
  late TeacherRepository repository;

  setUp(() {
    requests = [];
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          final exercise = {
            'id': 'exercise-1',
            'classroom_id': 'class-1',
            'classroom': {'name': 'Kelas 7A'},
            'title': 'Salam Tolaki',
            'target_text': 'Tabe',
            'status': options.path.endsWith('/archive') ? 'archived' : 'draft',
          };
          final attempt = {
            'id': 'attempt-1',
            'student': {'full_name': 'Nina'},
            'exercise': {'title': 'Salam Tolaki'},
            'audio_media_id': 'media-secret',
            'ai_score': 87,
            'teacher_score': options.path.endsWith('/feedback') ? 90 : null,
            'teacher_feedback': options.path.endsWith('/feedback')
                ? 'Bagus sekali'
                : null,
          };
          final data = options.path.endsWith('/temporary-url')
              ? {'url': 'https://example.test/audio'}
              : options.path.contains('/attempts')
              ? attempt
              : exercise;
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              data: {
                'data':
                    options.method == 'GET' &&
                        (options.path.endsWith('/templates') ||
                            options.path.endsWith('/exercises') ||
                            options.path.endsWith('/attempts'))
                    ? [data]
                    : data,
              },
            ),
          );
        },
      ),
    );
    repository = TeacherRepository(dio, const DioErrorMapper());
  });

  test(
    'repository lists templates exercises attempts with supported queries',
    () async {
      await repository.speakingTemplates();
      await repository.speakingExercises(
        classroomId: 'class-1',
        status: 'published',
      );
      await repository.speakingAttempts();
      expect(requests.map((r) => r.path), [
        '/teacher/speaking/templates',
        '/teacher/speaking/exercises',
        '/teacher/speaking/attempts',
      ]);
      expect(requests[1].queryParameters, {
        'per_page': 100,
        'classroom_id': 'class-1',
        'status': 'published',
      });
    },
  );

  test(
    'repository mutations and temporary URL preserve exact payloads',
    () async {
      final payload = {
        'classroom_id': 'class-1',
        'title': 'Salam Tolaki',
        'target_text': 'Tabe',
        'language_code': 'mekongga',
        'status': 'draft',
      };
      await repository.saveSpeakingExercise(data: payload);
      await repository.saveSpeakingExercise(id: 'exercise-1', data: payload);
      await repository.archiveSpeakingExercise('exercise-1');
      final saved = await repository.saveSpeakingFeedback(
        'attempt-1',
        teacherScore: 90,
        teacherFeedback: 'Bagus sekali',
      );
      expect(
        await repository.speakingTemporaryUrl('media-secret'),
        'https://example.test/audio',
      );
      expect(saved.teacherFeedback, 'Bagus sekali');
      expect(requests.map((r) => '${r.method} ${r.path}'), [
        'POST /teacher/speaking/exercises',
        'PATCH /teacher/speaking/exercises/exercise-1',
        'PATCH /teacher/speaking/exercises/exercise-1/archive',
        'PATCH /teacher/speaking/attempts/attempt-1/feedback',
        'POST /media/media-secret/temporary-url',
      ]);
      expect(requests[3].data, {
        'teacher_score': 90,
        'teacher_feedback': 'Bagus sekali',
      });
      expect(requests[4].data, {
        'expires_in_minutes': 15,
        'disposition': 'inline',
      });
    },
  );

  testWidgets('drawer orders Speaking after Budaya and navigates', (
    tester,
  ) async {
    final router = await _pump(tester, location: '/teacher/dashboard');
    await _bounded(tester);
    await tester.tap(find.byKey(const Key('teacherMenuButton')));
    await _bounded(tester);
    final culture = find.text('Budaya Mekongga');
    final speaking = find.text('Speaking');
    expect(
      tester.getTopLeft(speaking).dy,
      greaterThan(tester.getTopLeft(culture).dy),
    );
    await tester.tap(speaking);
    await _bounded(tester);
    expect(
      router.routeInformationProvider.value.uri.path,
      '/teacher/speaking/exercises',
    );
  });

  testWidgets('dashboard Hasil Speaking quick action opens attempts', (
    tester,
  ) async {
    final router = await _pump(tester, location: '/teacher/dashboard');
    await _bounded(tester);
    await tester.drag(find.byType(ListView).first, const Offset(0, -900));
    await tester.pump();
    await tester.tap(find.text('Hasil Speaking').last);
    await _bounded(tester);
    expect(
      router.routeInformationProvider.value.uri.path,
      '/teacher/speaking/attempts',
    );
  });

  testWidgets('segmented Latihan and Hasil Siswa switch routes', (
    tester,
  ) async {
    final router = await _pump(
      tester,
      location: '/teacher/speaking/exercises',
      overrides: [
        teacherSpeakingExercisesProvider.overrideWith((_, _) async => []),
      ],
    );
    await _bounded(tester);
    expect(find.text('Latihan'), findsOneWidget);
    expect(find.text('Hasil Siswa'), findsOneWidget);
    await tester.tap(find.text('Hasil Siswa'));
    await _bounded(tester);
    expect(
      router.routeInformationProvider.value.uri.path,
      '/teacher/speaking/attempts',
    );
  });

  testWidgets('exercise loading empty error exact copy and retry', (
    tester,
  ) async {
    final pending = Completer<List<TeacherSpeakingExercise>>();
    await _pump(
      tester,
      location: '/teacher/speaking/exercises',
      overrides: [
        teacherSpeakingExercisesProvider.overrideWith((_, _) => pending.future),
      ],
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await _pump(
      tester,
      location: '/teacher/speaking/exercises',
      overrides: [
        teacherSpeakingExercisesProvider.overrideWith((_, _) async => []),
      ],
    );
    await _bounded(tester);
    expect(find.text('Belum Ada Latihan Speaking'), findsOneWidget);
    expect(
      find.text('Tambahkan latihan untuk membantu siswa berlatih pengucapan.'),
      findsOneWidget,
    );
    var calls = 0;
    await _pump(
      tester,
      location: '/teacher/speaking/exercises',
      overrides: [
        teacherSpeakingExercisesProvider.overrideWith((_, _) async {
          calls++;
          throw Exception('network');
        }),
      ],
    );
    await _bounded(tester);
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pump();
    expect(find.text('Speaking Belum Bisa Dimuat'), findsOneWidget);
    expect(
      find.text('Periksa koneksi internet Anda, lalu coba lagi.'),
      findsOneWidget,
    );
    final retry = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Coba Lagi'),
    );
    retry.onPressed!();
    await tester.pump();
    expect(calls, greaterThan(1));
  });

  testWidgets('exercise compact EmiCard shows friendly status', (tester) async {
    await _pump(
      tester,
      location: '/teacher/speaking/exercises',
      textScale: 1.2,
      overrides: [
        teacherSpeakingExercisesProvider.overrideWith(
          (_, _) async => [_exercise()],
        ),
      ],
    );
    await _bounded(tester);
    expect(
      find.ancestor(
        of: find.text('Salam Tolaki'),
        matching: find.byType(EmiCard),
      ),
      findsOneWidget,
    );
    expect(find.text('Kelas 7A · 4 hasil'), findsOneWidget);
    expect(find.text('Terbit'), findsOneWidget);
    for (final raw in ['exercise-1', 'class-1', 'published', 'null']) {
      expect(find.textContaining(raw), findsNothing);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('exercise detail maps fields without IDs', (tester) async {
    await _pump(
      tester,
      location: '/teacher/speaking/exercises/exercise-1',
      overrides: [
        teacherSpeakingExerciseProvider.overrideWith(
          (_, _) async => _exercise(),
        ),
      ],
    );
    await _bounded(tester);
    for (final text in [
      'Salam Tolaki',
      'Kelas 7A',
      'Tabe',
      'Permisi',
      'Ucapkan dengan jelas',
      'Pemula',
      'Terbit',
      '4',
    ]) {
      expect(find.text(text), findsWidgets);
    }
    expect(find.textContaining('exercise-1'), findsNothing);
    expect(find.textContaining('class-1'), findsNothing);
  });

  testWidgets('create template selection populates form and exposes status', (
    tester,
  ) async {
    final template = TeacherSpeakingTemplate.fromJson({
      'id': 'template-1',
      'title': 'Sapaan Template',
      'target_text': 'Tabe meambo',
      'target_translation': 'Selamat pagi',
      'difficulty': 'beginner',
    });
    await _pump(
      tester,
      location: '/teacher/speaking/create',
      overrides: [
        teacherSpeakingTemplatesProvider.overrideWith((_) async => [template]),
      ],
    );
    await _bounded(tester);
    await tester.tap(find.text('Template (opsional)'));
    await _bounded(tester);
    await tester.tap(find.text('Sapaan Template').last);
    await _bounded(tester);
    expect(
      find.widgetWithText(TextFormField, 'Sapaan Template'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextFormField, 'Tabe meambo'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -700));
    await tester.pump();
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Draft'), findsOneWidget);
  });

  testWidgets('legacy template difficulties normalize to Pemula', (
    tester,
  ) async {
    for (final difficulty in ['demo', 'easy']) {
      final template = TeacherSpeakingTemplate.fromJson({
        'id': 'template-$difficulty',
        'title': 'Template $difficulty',
        'target_text': 'Tabe',
        'difficulty': difficulty,
      });
      await _pump(
        tester,
        location: '/teacher/speaking/create',
        overrides: [
          teacherSpeakingTemplatesProvider.overrideWith(
            (_) async => [template],
          ),
        ],
      );
      await _bounded(tester);
      await tester.tap(find.text('Template (opsional)'));
      await _bounded(tester);
      await tester.tap(find.text('Template $difficulty').last);
      await _bounded(tester);
      await tester.drag(find.byType(ListView).last, const Offset(0, -500));
      await tester.pump();
      expect(find.text('Pemula'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('legacy exercise difficulties render edit form', (tester) async {
    for (final difficulty in ['easy', 'demo']) {
      await _pump(
        tester,
        location: '/teacher/speaking/exercises/exercise-1/edit',
        overrides: [
          teacherSpeakingExerciseProvider.overrideWith(
            (_, _) async => _exercise(difficulty: difficulty),
          ),
        ],
      );
      await _bounded(tester);
      expect(find.text('Pemula'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('edit is populated and archive calls mutation', (tester) async {
    await _pump(
      tester,
      location: '/teacher/speaking/exercises/exercise-1/edit',
      overrides: [
        teacherSpeakingExerciseProvider.overrideWith(
          (_, _) async => _exercise(status: 'draft'),
        ),
      ],
    );
    await _bounded(tester);
    expect(find.text('Edit Latihan Speaking'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Salam Tolaki'), findsOneWidget);
    await _pump(
      tester,
      location: '/teacher/speaking/exercises/exercise-1',
      overrides: [
        teacherRepositoryProvider.overrideWith((_) => repository),
        teacherSpeakingExerciseProvider.overrideWith(
          (_, _) async => _exercise(),
        ),
        teacherSpeakingExercisesProvider.overrideWith((_, _) async => []),
      ],
    );
    await _bounded(tester);
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pump();
    await tester.tap(find.text('Arsipkan'));
    await _bounded(tester);
    await tester.tap(find.text('Arsipkan').last);
    await _bounded(tester);
    expect(
      requests.single.path,
      '/teacher/speaking/exercises/exercise-1/archive',
    );
  });

  test('repository deletes speaking exercise once at exact endpoint', () async {
    await repository.deleteSpeakingExercise('exercise-1');
    expect(requests.map((r) => '${r.method} ${r.path}'), [
      'DELETE /teacher/speaking/exercises/exercise-1',
    ]);
  });

  testWidgets('list delete cancel loading double click and removal', (
    tester,
  ) async {
    final delete = _DeleteRepository(pending: true);
    await _pump(
      tester,
      location: '/teacher/speaking/exercises',
      overrides: [
        teacherRepositoryProvider.overrideWith((_) => delete),
        teacherSpeakingExercisesProvider.overrideWith(
          (_, _) async => [_exercise()],
        ),
      ],
    );
    await _bounded(tester);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus Latihan'));
    await tester.pumpAndSettle();
    expect(find.text('Hapus Latihan?'), findsOneWidget);
    expect(
      find.text(
        'Latihan ini akan dihapus dari kelas. Tindakan ini tidak dapat dibatalkan.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(delete.calls, 0);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus Latihan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(FilledButton).last);
    expect(delete.calls, 1);
    delete.completer.complete();
    await tester.pumpAndSettle();
    expect(find.text('Salam Tolaki'), findsNothing);
    expect(find.text('Latihan speaking berhasil dihapus.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('detail delete navigates and 422 shows exact friendly dialog', (
    tester,
  ) async {
    final delete = _DeleteRepository();
    final router = await _pump(
      tester,
      location: '/teacher/speaking/exercises/exercise-1',
      overrides: [
        teacherRepositoryProvider.overrideWith((_) => delete),
        teacherSpeakingExerciseProvider.overrideWith(
          (_, _) async => _exercise(),
        ),
        teacherSpeakingExercisesProvider.overrideWith((_, _) async => []),
      ],
    );
    await _bounded(tester);
    await tester.scrollUntilVisible(find.text('Hapus Latihan'), 200);
    await tester.tap(find.text('Hapus Latihan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    expect(delete.calls, 1);
    expect(
      router.routeInformationProvider.value.uri.path,
      '/teacher/speaking/exercises',
    );

    final validation = _DeleteRepository(
      error: const AppError(
        type: AppErrorType.validation,
        message: 'validation',
      ),
    );
    await _pump(
      tester,
      location: '/teacher/speaking/exercises/exercise-1',
      textScale: 1.4,
      overrides: [
        teacherRepositoryProvider.overrideWith((_) => validation),
        teacherSpeakingExerciseProvider.overrideWith(
          (_, _) async => _exercise(),
        ),
      ],
    );
    await _bounded(tester);
    await tester.scrollUntilVisible(find.text('Hapus Latihan'), 200);
    await tester.tap(find.text('Hapus Latihan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    expect(find.text('Latihan Tidak Dapat Dihapus'), findsOneWidget);
    expect(
      find.text(
        'Latihan ini sudah memiliki hasil siswa. Arsipkan latihan agar tidak lagi tampil kepada siswa.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('delete 403 shows friendly AppError', (tester) async {
    final forbidden = _DeleteRepository(
      error: const AppError(
        type: AppErrorType.forbidden,
        message: 'Anda tidak memiliki izin menghapus latihan ini.',
      ),
    );
    await _pump(
      tester,
      location: '/teacher/speaking/exercises/exercise-1',
      overrides: [
        teacherRepositoryProvider.overrideWith((_) => forbidden),
        teacherSpeakingExerciseProvider.overrideWith(
          (_, _) async => _exercise(),
        ),
      ],
    );
    await _bounded(tester);
    await tester.scrollUntilVisible(find.text('Hapus Latihan'), 200);
    await tester.tap(find.text('Hapus Latihan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    expect(
      find.text('Anda tidak memiliki izin menghapus latihan ini.'),
      findsOneWidget,
    );
    expect(forbidden.calls, 1);
  });

  testWidgets('attempt loading empty error exact copy and retry', (
    tester,
  ) async {
    final pending = Completer<List<TeacherSpeakingAttempt>>();
    await _pump(
      tester,
      location: '/teacher/speaking/attempts',
      overrides: [
        teacherSpeakingAttemptsProvider.overrideWith((_) => pending.future),
      ],
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await _pump(
      tester,
      location: '/teacher/speaking/attempts',
      overrides: [
        teacherSpeakingAttemptsProvider.overrideWith((_) async => []),
      ],
    );
    await _bounded(tester);
    expect(find.text('Belum Ada Hasil Speaking'), findsOneWidget);
    expect(
      find.text(
        'Hasil speaking siswa akan muncul setelah mereka mengirim rekaman.',
      ),
      findsOneWidget,
    );
    var calls = 0;
    await _pump(
      tester,
      location: '/teacher/speaking/attempts',
      overrides: [
        teacherSpeakingAttemptsProvider.overrideWith((_) async {
          calls++;
          throw Exception('network');
        }),
      ],
    );
    await _bounded(tester);
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pump();
    expect(find.text('Hasil Speaking Belum Bisa Dimuat'), findsOneWidget);
    final retry = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Coba Lagi'),
    );
    retry.onPressed!();
    await tester.pump();
    expect(calls, greaterThan(1));
  });

  testWidgets('attempt EmiCard shows AI and review status', (tester) async {
    await _pump(
      tester,
      location: '/teacher/speaking/attempts',
      overrides: [
        teacherSpeakingAttemptsProvider.overrideWith((_) async => [_attempt()]),
      ],
    );
    await _bounded(tester);
    expect(
      find.ancestor(of: find.text('Nina'), matching: find.byType(EmiCard)),
      findsOneWidget,
    );
    expect(find.textContaining('Skor AI 87'), findsOneWidget);
    expect(find.textContaining('Belum dinilai'), findsOneWidget);
    expect(find.textContaining('attempt-1'), findsNothing);
    expect(find.textContaining('media-secret'), findsNothing);
  });

  testWidgets('attempt detail maps AI audio control and hides raw values', (
    tester,
  ) async {
    await _pump(
      tester,
      location: '/teacher/speaking/attempts/attempt-1',
      overrides: [
        teacherSpeakingAttemptProvider.overrideWith((_, _) async => _attempt()),
      ],
    );
    await _bounded(tester);
    for (final text in [
      'Nina',
      'Salam Tolaki',
      'Kelas 7A',
      'Tabe',
      '87',
      'Analisis selesai',
      'Mikrofon ponsel',
    ]) {
      expect(find.text(text), findsWidgets);
    }
    await tester.scrollUntilVisible(find.text('Putar Audio'), 200);
    expect(find.text('Putar Audio'), findsOneWidget);
    for (final raw in [
      'attempt-1',
      'media-secret',
      'completed',
      'mobile_microphone',
      'null',
    ]) {
      expect(find.textContaining(raw), findsNothing);
    }
  });

  testWidgets('audio failure shows friendly widget error', (tester) async {
    await _pump(
      tester,
      location: '/teacher/speaking/attempts/attempt-1',
      overrides: [
        teacherRepositoryProvider.overrideWith(
          (_) => _AudioErrorRepository(
            Dio(BaseOptions(baseUrl: 'https://example.test')),
            const DioErrorMapper(),
          ),
        ),
        teacherSpeakingAttemptProvider.overrideWith((_, _) async => _attempt()),
      ],
    );
    await _bounded(tester);
    await tester.scrollUntilVisible(find.text('Putar Audio'), 200);
    await tester.tap(find.text('Putar Audio'));
    await _bounded(tester, 30);
    expect(
      find.text('Audio belum bisa diputar. Silakan coba lagi.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'feedback validates score sends payload and updates immediately',
    (tester) async {
      await _pump(
        tester,
        location: '/teacher/speaking/attempts/attempt-1',
        overrides: [
          teacherRepositoryProvider.overrideWith((_) => repository),
          teacherSpeakingAttemptProvider.overrideWith(
            (_, _) async => _attempt(),
          ),
          teacherSpeakingAttemptsProvider.overrideWith(
            (_) async => [_attempt(teacherScore: 90)],
          ),
        ],
      );
      await _bounded(tester);
      await tester.scrollUntilVisible(
        find.widgetWithText(TextFormField, 'Nilai (0–100)'),
        200,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nilai (0–100)'),
        '101',
      );
      await tester.tap(find.text('Simpan Penilaian'));
      await tester.pump();
      expect(find.text('Masukkan nilai antara 0 dan 100.'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nilai (0–100)'),
        '90',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Feedback (opsional)'),
        'Bagus sekali',
      );
      await tester.tap(find.text('Simpan Penilaian'));
      await _bounded(tester);
      expect(requests.single.data, {
        'teacher_score': 90,
        'teacher_feedback': 'Bagus sekali',
      });
      expect(find.text('Sudah dinilai'), findsOneWidget);
      expect(find.text('Bagus sekali'), findsOneWidget);
    },
  );

  testWidgets('dirty AppBar system back direct fallback and responsive save', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await _pump(tester, location: '/teacher/speaking/create', textScale: 1.2);
    await _bounded(tester);
    await tester.enterText(find.widgetWithText(TextFormField, 'Judul'), 'Baru');
    await tester.tap(find.byKey(const Key('teacherBackButton')));
    await _bounded(tester);
    expect(find.text('Buang perubahan?'), findsOneWidget);
    await tester.tap(find.text('Tetap di sini'));
    await _bounded(tester);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Buang perubahan?'), findsWidgets);
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    await tester.pump();
    expect(find.text('Simpan'), findsOneWidget);
    expect(
      tester.getBottomLeft(find.text('Simpan')).dy,
      lessThanOrEqualTo(240),
    );
    expect(tester.takeException(), isNull);
    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pump();
    await tester.tap(find.text('Buang').last);
    await _bounded(tester, 5);
  });

  testWidgets('direct exercise detail back falls back to speaking list', (
    tester,
  ) async {
    final router = await _pump(
      tester,
      location: '/teacher/speaking/exercises/exercise-1',
      overrides: [
        teacherSpeakingExerciseProvider.overrideWith(
          (_, _) async => _exercise(),
        ),
      ],
    );
    await _bounded(tester);
    await tester.tap(find.byKey(const Key('teacherBackButton')));
    await _bounded(tester, 5);
    expect(
      router.routeInformationProvider.value.uri.path,
      '/teacher/speaking/exercises',
    );
  });
}
