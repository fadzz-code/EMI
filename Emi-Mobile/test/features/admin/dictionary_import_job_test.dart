import 'package:emi_mobile/features/admin/data/admin_crud_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final status in const ['completed_with_errors', 'completed', 'failed']) {
    test('dictionary import $status is terminal', () {
      final job = DictionaryImportJobAdmin.fromJson({
        'id': 'job-1',
        'status': status,
      });

      expect(job.isTerminal, isTrue);
    });
  }

  test('parses authoritative sheet, audio, and error fields', () {
    final job = DictionaryImportJobAdmin.fromJson({
      'id': 'job-1',
      'status': 'preview_ready',
      'summary': {
        'vocabulary': {
          'total_rows': 8,
          'valid_rows': 5,
          'invalid_rows': 1,
          'duplicate_rows': 2,
        },
        'audio': {'matched': 3, 'missing': 1, 'ambiguous': 2, 'unused': 4},
      },
    });
    final error = DictionaryImportErrorAdmin.fromJson({
      'id': 'error-1',
      'sheet': 'Kosakata',
      'raw_data': {'kata': 'mowali'},
      'created_at': '2026-08-24T00:00:00Z',
    });

    expect(job.sheets['Kosakata']?.duplicate, 2);
    expect(job.vocabUpdated, 0);
    expect(job.audioAttached, 3);
    expect(job.audioNotFound, 1);
    expect(job.audioAmbiguous, 2);
    expect(job.audioUnused, 4);
    expect(error.sheet, 'Kosakata');
    expect(error.rawData, {'kata': 'mowali'});
    expect(error.createdAt, '2026-08-24T00:00:00Z');
  });

  test('does not invent omitted audio counts', () {
    final job = DictionaryImportJobAdmin.fromJson({
      'id': 'job-1',
      'status': 'preview_ready',
    });

    expect(job.audioAttached, isNull);
    expect(job.audioNotFound, isNull);
    expect(job.audioAmbiguous, isNull);
    expect(job.audioUnused, isNull);
  });
}
