import 'package:dio/dio.dart';

String apiErrorMessage(Object? error) {
  if (error is! DioException) {
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }

  if (error.response?.statusCode == 401) {
    return 'Sesi Anda berakhir. Silakan masuk kembali.';
  }

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return 'Koneksi terlalu lama. Periksa jaringan lalu coba lagi.';
    case DioExceptionType.connectionError:
      return 'Tidak dapat terhubung. Periksa koneksi internet Anda.';
    case DioExceptionType.badCertificate:
    case DioExceptionType.badResponse:
    case DioExceptionType.cancel:
    case DioExceptionType.unknown:
      return 'Layanan sedang bermasalah. Silakan coba lagi.';
  }
}
