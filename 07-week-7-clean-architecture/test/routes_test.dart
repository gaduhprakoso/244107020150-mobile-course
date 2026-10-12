import 'package:campus_notify/core/format.dart';
import 'package:campus_notify/routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('routeFromMessage', () {
    test('accepts the home route', () {
      expect(_parseRoute({'route': AppRoutes.home}), AppRoutes.home);
    });

    test('accepts an announcement route', () {
      final route = AppRoutes.announcement('123');
      expect(_parseRoute({'route': route}), route);
    });

    test('rejects unknown or external routes', () {
      expect(_parseRoute({'route': '/admin'}), isNull);
      expect(_parseRoute({'route': 'https://example.com'}), isNull);
      expect(_parseRoute({'route': '//example.com'}), isNull);
      expect(_parseRoute({'route': 123}), isNull);
      expect(_parseRoute({}), AppRoutes.home);
    });
  });
}

String? _parseRoute(Map<String, dynamic> data) => routeFromMessage(
  data,
  homeRoute: AppRoutes.home,
  announcementSegment: AppRoutes.announcementSegment,
);
