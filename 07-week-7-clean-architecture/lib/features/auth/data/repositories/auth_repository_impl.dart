import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return AuthSession(
      access: 'mock-access-for-$email',
      refresh: 'mock-refresh-for-$email',
    );
  }

  @override
  Future<String> refresh(String refreshToken) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return 'mock-access-renewed-${DateTime.now().millisecondsSinceEpoch}';
  }
}
