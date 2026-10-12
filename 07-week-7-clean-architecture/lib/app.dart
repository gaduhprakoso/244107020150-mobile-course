import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'data/api_errors.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'pages/announcement_page.dart';
import 'pages/app_error_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'providers/push_provider.dart';
import 'routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.listen(authStateProvider, (previous, next) => refresh.refresh());

  final router = GoRouter(
    refreshListenable: refresh,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      if (authState.isLoading) return null;

      final loggedIn = authState.value ?? false;
      final isLoginRoute = state.matchedLocation == AppRoutes.login;
      if (!loggedIn && !isLoginRoute) {
        return Uri(
          path: AppRoutes.login,
          queryParameters: {'from': state.uri.toString()},
        ).toString();
      }

      if (loggedIn && isLoginRoute) {
        final destination = state.uri.queryParameters['from'];
        if (destination != null &&
            destination.startsWith('/') &&
            !destination.startsWith('//')) {
          return destination;
        }
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.announcementPattern,
        builder: (_, state) =>
            AnnouncementPage(id: state.pathParameters['id'] ?? ''),
      ),
    ],
    errorBuilder: (_, state) => AppErrorPage(
      message: apiFailureFrom(state.error).message,
    ),
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

class _RouterRefresh extends ChangeNotifier {
  void refresh() => notifyListeners();
}

class CampusNotificationApp extends ConsumerStatefulWidget {
  const CampusNotificationApp({super.key});

  @override
  ConsumerState<CampusNotificationApp> createState() =>
      _CampusNotificationAppState();
}

class _CampusNotificationAppState
    extends ConsumerState<CampusNotificationApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_initializePushService());
    });
  }

  Future<void> _initializePushService() async {
    try {
      final router = ref.read(routerProvider);
      await ref
          .read(pushServiceProvider)
          .initialize(
            onRoute: router.go,
            registerToken: _registerDeviceToken,
          );
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'campus notification startup',
          context: ErrorDescription('while initializing push notifications'),
        ),
      );
    }
  }

  Future<void> _registerDeviceToken(String token) async {
    if (token.isEmpty) {
      throw StateError('Firebase returned an empty registration token.');
    }

    // Configure the backend URL before replacing this documented endpoint
    // contract with apiClientProvider.post('/devices', data: {'token': token}).
    debugPrint('FCM token ready for backend registration: POST /devices');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Campus Notification',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
