import 'dart:ui';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

class LocationService {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        isForegroundMode: true, // Esto ya indica que el servicio debe ser foreground
        autoStart: true,
        notificationChannelId: 'vesta_tracker_channel',
        initialNotificationTitle: 'Vesta Tracker',
        initialNotificationContent: 'Rastreo activo',
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
      ),
    );

    await service.startService();
  }

  @pragma('vm:entry-point')
  static Future<void> onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    // ELIMINAMOS service.setForegroundMode(true); 
    // porque no es necesario y causaba el error de compilación.

    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    final prefs = await SharedPreferences.getInstance();
    final childId = prefs.getString('child_id');

    if (childId == null) {
      service.stopSelf();
      return;
    }

    final db = FirebaseFirestore.instance;

    // Configuración para mantener el GPS vivo en Android
    final androidSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
      intervalDuration: const Duration(seconds: 10),
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationText: "Rastreo activo para Vesta",
        notificationTitle: "Vesta Tracker",
        enableWakeLock: true,
      ),
    );

    Geolocator.getPositionStream(
      locationSettings: androidSettings,
    ).listen((Position position) async {
      try {
        await db.collection('telemetria').doc(childId).set({
          'lat': position.latitude,
          'lng': position.longitude,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'activo',
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint("Error al enviar ubicación: $e");
      }
    });

    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }
}