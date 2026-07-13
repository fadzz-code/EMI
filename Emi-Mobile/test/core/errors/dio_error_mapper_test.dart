import 'package:dio/dio.dart';
import 'package:emi_mobile/core/errors/app_error.dart';
import 'package:emi_mobile/core/errors/dio_error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = DioErrorMapper();

  test('maps timeout', () {
    final error = mapper.map(
      DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.connectionTimeout,
      ),
    );
    expect(error.type, AppErrorType.timeout);
  });

  test('maps validation errors', () {
    final error = mapper.map(
      DioException(
        requestOptions: RequestOptions(),
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: 422,
          data: {
            'message': 'Data yang diberikan tidak valid.',
            'errors': {
              'email': ['Email wajib diisi.'],
            },
          },
        ),
      ),
    );

    expect(error.type, AppErrorType.validation);
    expect(error.fieldErrors['email']?.first, 'Email wajib diisi.');
  });
}
