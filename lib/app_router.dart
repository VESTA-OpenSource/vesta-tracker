import 'package:go_router/go_router.dart';
import 'screens/setup_screen.dart';
import 'screens/tracker_active_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GoRouter appRouter = GoRouter(
  redirect: (context, state) async {
    final prefs = await SharedPreferences.getInstance();
    final String? childId = prefs.getString('child_id');

    if (childId == null && state.matchedLocation != '/setup') {
      return '/setup';
    }
    if (childId != null && state.matchedLocation == '/setup') {
      return '/tracker/$childId';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/setup',
      builder: (context, state) => const SetupScreen(),
    ),
    GoRoute(
      path: '/tracker/:childId',
      builder: (context, state) {
        final childId = state.pathParameters['childId']!;
        return TrackerActiveScreen(childId: childId);
      },
    ),
  ],
);