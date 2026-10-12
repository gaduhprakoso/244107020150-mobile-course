import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/auth/domain/entities/auth_session.dart';
import 'package:campus_notify/features/auth/domain/repositories/auth_repository.dart';
import 'package:campus_notify/features/auth/domain/usecases/login.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository implements AuthRepository {
  AuthSession? session;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    session = AuthSession(access: 'access', refresh: 'refresh');
    return session!;
  }

  @override
  Future<String> refresh(String refreshToken) async => 'renewed';
}

void main() {
  test('Login sends valid credentials to the repository', () async {
    final repository = _FakeAuthRepository();

    final result = await Login(repository)
        .call(email: 'student@example.edu', password: 'secret1');

    expect(result.access, 'access');
    expect(repository.session, isNotNull);
  });

  test('Login returns a validation failure for invalid credentials', () {
    final repository = _FakeAuthRepository();

    expect(
      () => Login(repository).call(email: 'invalid', password: '123'),
      throwsA(isA<ValidationFailure>()),
    );
    expect(repository.session, isNull);
  });
}
