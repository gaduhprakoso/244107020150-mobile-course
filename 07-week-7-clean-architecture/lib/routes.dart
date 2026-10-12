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
