import 'dart:typed_data';

import 'package:campus_notify/data/api_client.dart';
import 'package:campus_notify/data/auth_repository.dart';
import 'package:campus_notify/data/token_store.dart';
import 'package:campus_notify/providers/auth_provider.dart';
import 'package:campus_notify/routes.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTokenStore extends TokenStore {
  String? access;
  String? refresh;

  @override
  Future<String?> readAccess() async => access;

  @override
  Future<String?> readRefresh() async => refresh;

  @override
  Future<void> save({required String access, required String refresh}) async {
    this.access = access;
    this.refresh = refresh;
  }

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }
}

class _ExpiredAuthRepository extends AuthRepository {
  @override
  Future<String> refresh(String refreshToken) async {
    throw StateError('Refresh token expired.');
  }
}

class _UnauthorizedAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"message":"unauthorized"}',
      401,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('routeFromMessage', () {
    test('handles empty route and routes without a leading slash', () {
      expect(routeFromMessage({}), '/');
      expect(routeFromMessage({'route': 'pengumuman/3'}), '/pengumuman/3');
      expect(routeFromMessage({'route': '/pengumuman/3'}), '/pengumuman/3');
    });

    test('announcement data includes its id', () {
      const data = {'route': '/pengumuman/3', 'id': '3'};

      expect(data['id'], '3');
      expect(routeFromMessage(data), '/pengumuman/3');
    });

    test('rejects unknown and external routes', () {
      expect(routeFromMessage({'route': '/settings'}), isNull);
      expect(routeFromMessage({'route': 'https://example.com'}), isNull);
      expect(routeFromMessage({'route': '//example.com'}), isNull);
    });
  });

  test('auth provider derives login status from stored access token', () async {
    final store = FakeTokenStore()..access = 'mock-access';
    final container = ProviderContainer(
      overrides: [tokenStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    expect(await container.read(authStateProvider.future), isTrue);

    await store.clear();
    container.invalidate(authStateProvider);
    expect(await container.read(authStateProvider.future), isFalse);
  });

  test('failed refresh clears stored session', () async {
    final store = FakeTokenStore()
      ..access = 'expired-access'
      ..refresh = 'expired-refresh';
    var sessionExpired = false;
    final dio = buildApiClient(
      store,
      _ExpiredAuthRepository(),
      baseUrl: 'https://unit.test',
      onSessionExpired: () async => sessionExpired = true,
    )..httpClientAdapter = _UnauthorizedAdapter();
    addTearDown(dio.close);

    await expectLater(dio.get<void>('/private'), throwsA(isA<DioException>()));

    expect(store.access, isNull);
    expect(store.refresh, isNull);
    expect(sessionExpired, isTrue);
  });
}
