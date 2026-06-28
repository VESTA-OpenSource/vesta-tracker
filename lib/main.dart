import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart'; // Asegúrate de tener esta importación
import 'location_service.dart'; 
import 'screens/setup_screen.dart';
import 'screens/tracker_active_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  try {
    await FirebaseAuth.instance.signInAnonymously();
    print("Autenticación anónima exitosa");
  } catch (e) {
    print("Error de autenticación: $e");
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
        'vesta_tracker_channel',
        'Vesta Tracker',
        description: 'Canal de seguridad',
        importance: Importance.high,
      ));

  final prefs = await SharedPreferences.getInstance();
  final String? childIdSaved = prefs.getString('child_id');

  runApp(VestaTrackerApp(initialChildId: childIdSaved));
}

class VestaTrackerApp extends StatelessWidget {
  final String? initialChildId;
  const VestaTrackerApp({super.key, this.initialChildId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: initialChildId == null 
          ? const SetupScreen() 
          : TrackerActiveScreen(childId: initialChildId!),
    );
  }
}

class PermissionHandlerWrapper extends StatefulWidget {
  final String childId;
  const PermissionHandlerWrapper({super.key, required this.childId});

  @override
  State<PermissionHandlerWrapper> createState() => _PermissionHandlerWrapperState();
}

class _PermissionHandlerWrapperState extends State<PermissionHandlerWrapper> {
  @override
  void initState() {
    super.initState();
    _requestLocationAndStartService();
  }

  Future<void> _requestLocationAndStartService() async {
    LocationPermission permission = await Geolocator.requestPermission();
    
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      await LocationService.initializeService();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TrackerActiveScreen(childId: widget.childId);
  }
}