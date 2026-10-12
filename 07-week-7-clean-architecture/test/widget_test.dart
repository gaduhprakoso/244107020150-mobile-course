import 'package:campus_notify/data/token_store.dart';
import 'package:campus_notify/pages/login_page.dart';
import 'package:campus_notify/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryTokenStore extends TokenStore {
  @override
  Future<String?> readAccess() async => null;

  @override
  Future<void> save({required String access, required String refresh}) async {}

  @override
  Future<void> clear() async {}
}

void main() {
  testWidgets('login screen renders validation and controls', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tokenStoreProvider.overrideWithValue(_MemoryTokenStore())],
        child: const MaterialApp(home: LoginPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Masuk'), findsNWidgets(2));
    expect(find.byType(TextFormField), findsNWidgets(2));

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('Masukkan email yang valid.'), findsOneWidget);
  });
}
