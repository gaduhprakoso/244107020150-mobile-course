import 'package:campus_notify/routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('routeFromMessage', () {
    test('accepts the home route', () {
      expect(routeFromMessage({'route': AppRoutes.home}), AppRoutes.home);
    });

    test('accepts an announcement route', () {
      final route = AppRoutes.announcement('123');
      expect(routeFromMessage({'route': route}), route);
    });

    test('rejects unknown or external routes', () {
      expect(routeFromMessage({'route': '/admin'}), isNull);
      expect(routeFromMessage({'route': 'https://example.com'}), isNull);
      expect(routeFromMessage({'route': '//example.com'}), isNull);
      expect(routeFromMessage({'route': 123}), isNull);
      expect(routeFromMessage({}), AppRoutes.home);
    });
  });
}
