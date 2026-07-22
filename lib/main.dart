import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'location_service.dart';
import 'screens/setup_screen.dart';
import 'screens/tracker_active_screen.dart';
import 'screens/success_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  try {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  } catch (e) {
    debugPrint("Error de autenticación: $e");
  }
  await LocationService.initializeService();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
        'vesta_tracker_channel',
        'Vesta Tracker',
        description: 'Canal de seguridad para rastreo en tiempo real',
        importance: Importance.high,
      ));
  final prefs = await SharedPreferences.getInstance();
  final String? childIdSaved = prefs.getString('child_id');

  runApp(VestaTrackerApp(initialChildId: childIdSaved));
}
class VestaTrackerApp extends StatefulWidget {
  final String? initialChildId;
  const VestaTrackerApp({super.key, this.initialChildId});

  @override
  State<VestaTrackerApp> createState() => _VestaTrackerAppState();
}
class _VestaTrackerAppState extends State<VestaTrackerApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: widget.initialChildId == null ? '/setup' : '/tracker/${widget.initialChildId}',
      routes: [
        GoRoute(
          path: '/setup',
          builder: (context, state) => const SetupScreen(),
        ),
        GoRoute(
          path: '/success/:childId',
          builder: (context, state) => SuccessScreen(childId: state.pathParameters['childId']!),
        ),
        GoRoute(
          path: '/tracker/:childId',
          builder: (context, state) => TrackerActiveScreen(childId: state.pathParameters['childId']!),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}