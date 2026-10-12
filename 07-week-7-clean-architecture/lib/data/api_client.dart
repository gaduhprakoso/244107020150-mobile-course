import 'package:dio/dio.dart';

import 'token_store.dart';
import '../features/auth/domain/repositories/auth_repository.dart';

const _retryAfterRefreshKey = 'retriedAfterTokenRefresh';

Dio buildApiClient(
  TokenStore store,
  AuthRepository auth, {
  String baseUrl = 'https://example-campus-api.test',
  Future<void> Function()? onSessionExpired,
}) {
  final dio = Dio(BaseOptions(baseUrl: baseUrl));

  Future<void> expireSession() async {
    await store.clear();
    await onSessionExpired?.call();
  }

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final access = await store.readAccess();
        if (access != null) {
          options.headers['Authorization'] = 'Bearer $access';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode != 401) {
          handler.next(error);
          return;
        }

        if (error.requestOptions.extra[_retryAfterRefreshKey] == true) {
          await expireSession();
          handler.next(error);
          return;
        }

        final refreshToken = await store.readRefresh();
        if (refreshToken == null || refreshToken.isEmpty) {
          await expireSession();
          handler.next(error);
          return;
        }

        late final String renewedAccess;
        try {
          renewedAccess = await auth.refresh(refreshToken);
          await store.save(access: renewedAccess, refresh: refreshToken);
        } catch (refreshError, stackTrace) {
          await expireSession();
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: refreshError,
              stackTrace: stackTrace,
              message: 'Session refresh failed; user was logged out.',
            ),
          );
          return;
        }

        final retryOptions = error.requestOptions
          ..extra[_retryAfterRefreshKey] = true
          ..headers['Authorization'] = 'Bearer $renewedAccess';

        try {
          handler.resolve(await dio.fetch<dynamic>(retryOptions));
        } on DioException catch (retryError) {
          handler.reject(retryError);
        } catch (retryError, stackTrace) {
          handler.reject(
            DioException(
              requestOptions: retryOptions,
              error: retryError,
              stackTrace: stackTrace,
            ),
          );
        }
      },
    ),
  );

  return dio;
}
