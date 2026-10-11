import 'package:campus_notify/data/api_errors.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps unauthorized responses to a sign-in message', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/private'),
      response: Response(
        requestOptions: RequestOptions(path: '/private'),
        statusCode: 401,
      ),
    );

    expect(apiErrorMessage(error), contains('Sesi Anda berakhir'));
  });

  test('maps connection timeouts to a friendly message', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/'),
      type: DioExceptionType.connectionTimeout,
    );

    expect(apiErrorMessage(error), contains('Koneksi terlalu lama'));
  });

  test('maps connection errors to an offline message', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/'),
      type: DioExceptionType.connectionError,
    );

    expect(apiErrorMessage(error), contains('koneksi internet'));
  });
}
