import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/api_client.dart';
import '../../../../data/api_errors.dart';
import '../../../../data/token_store.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(),
);

final loginProvider = Provider<Login>(
  (ref) => Login(ref.watch(authRepositoryProvider)),
);

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, bool>(AuthNotifier.new);

final apiClientProvider = Provider<Dio>((ref) {
  return buildApiClient(
    ref.watch(tokenStoreProvider),
    ref.watch(authRepositoryProvider),
    onSessionExpired: () => ref.read(authStateProvider.notifier).logout(),
  );
});

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    try {
      final token = await ref.watch(tokenStoreProvider).readAccess();
      return token != null;
    } catch (error) {
      throw apiFailureFrom(error);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final session = await ref.read(loginProvider).call(
            email: email,
            password: password,
          );
      await ref
          .read(tokenStoreProvider)
          .save(access: session.access, refresh: session.refresh);
      state = const AsyncData(true);
    } catch (error, stackTrace) {
      state = AsyncError(apiFailureFrom(error), stackTrace);
    }
  }

  Future<void> logout() async {
    try {
      await ref.read(tokenStoreProvider).clear();
      ref.invalidateSelf();
    } catch (error, stackTrace) {
      state = AsyncError(apiFailureFrom(error), stackTrace);
    }
  }
}
