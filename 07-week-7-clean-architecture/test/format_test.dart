import 'package:campus_notify/core/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatDate returns day/month/year with padded day and month', () {
    expect(formatDate(DateTime(2026, 9, 7)), '07/09/2026');
  });

  group('routeFromMessage', () {
    const homeRoute = '/';
    const announcementSegment = 'pengumuman';

    String? parse(Map<String, dynamic> data) => routeFromMessage(
      data,
      homeRoute: homeRoute,
      announcementSegment: announcementSegment,
    );

    test('defaults empty route to home and normalizes valid route', () {
      expect(parse({}), homeRoute);
      expect(parse({'route': 'pengumuman/42'}), '/pengumuman/42');
    });

    test('rejects unknown and external routes', () {
      expect(parse({'route': '/unknown'}), isNull);
      expect(parse({'route': 'https://example.com'}), isNull);
      expect(parse({'route': '//example.com'}), isNull);
      expect(parse({'route': 42}), isNull);
    });
  });
}
