String formatDate(DateTime date) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');

  return '${twoDigits(date.day)}/${twoDigits(date.month)}/${date.year}';
}

String? routeFromMessage(
  Map<String, dynamic> data, {
  required String homeRoute,
  required String announcementSegment,
}) {
  final rawRoute = data['route'];
  if (rawRoute == null || rawRoute == '') return homeRoute;
  if (rawRoute is! String) return null;

  final route = rawRoute.startsWith('/') ? rawRoute : '/$rawRoute';
  if (route.startsWith('//')) return null;
  final uri = Uri.tryParse(route);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return null;

  if (uri.path == homeRoute) return route;

  final segments = uri.pathSegments;
  if (segments.length == 2 &&
      segments.first == announcementSegment &&
      segments.last.isNotEmpty) {
    return route;
  }

  return null;
}
