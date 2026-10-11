class AppRoutes {
  AppRoutes._();

  static const home = '/';
  static const login = '/login';
  static const announcementSegment = 'pengumuman';
  static const announcementPrefix = '/$announcementSegment/';
  static const announcementPattern = '$announcementPrefix:id';

  static String announcement(String id) =>
      '$announcementPrefix${Uri.encodeComponent(id)}';
}

String? routeFromMessage(Map<String, dynamic> data) {
  final rawRoute = data['route'];
  if (rawRoute == null || rawRoute == '') return AppRoutes.home;
  if (rawRoute is! String) return null;

  final route = rawRoute.startsWith('/') ? rawRoute : '/$rawRoute';
  if (route.startsWith('//')) return null;
  final uri = Uri.tryParse(route);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return null;

  if (uri.path == AppRoutes.home) return route;

  final segments = uri.pathSegments;
  if (segments.length == 2 &&
      segments.first == AppRoutes.announcementSegment &&
      segments.last.isNotEmpty) {
    return route;
  }

  return null;
}
