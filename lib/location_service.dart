import 'dart:ui';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

class LocationService {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();
    
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        isForegroundMode: true,
        autoStart: true,
        notificationChannelId: 'vesta_tracker_channel',
        initialNotificationTitle: 'Vesta Tracker',
        initialNotificationContent: 'Rastreo activo en segundo plano',
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(autoStart: true),
    );
    
    // Solo iniciamos si no está corriendo ya para evitar conflictos
    if (!(await service.isRunning())) {
      await service.startService();
    }
  }

  @pragma('vm:entry-point')
  static Future<void> onStart(ServiceInstance service) async {
    // 1. Registro de plugins para el entorno de fondo (Isolate)
    DartPluginRegistrant.ensureInitialized();
    
    // 2. Inicialización de Firebase
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // 3. Obtener childId con un breve delay si es necesario
    final prefs = await SharedPreferences.getInstance();
    final childId = prefs.getString('child_id');
    
    if (childId == null) {
      service.stopSelf();
      return;
    }

    final DocumentReference telemetriaRef = FirebaseFirestore.instance
        .collection('telemetria')
        .doc(childId);

    // 4. Configuración de ubicación
    final positionStream = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        intervalDuration: const Duration(seconds: 10),
        forceLocationManager: true,
      ),
    );

    // 5. Suscripción a ubicación
    final positionSubscription = positionStream.listen((Position position) async {
      try {
        await telemetriaRef.set({
          'lat': position.latitude,
          'lng': position.longitude,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'activo', // Esto mantendrá el estado como activo en Firestore
        }, SetOptions(merge: true));
      } catch (e) {
        print("Error al actualizar Firestore: $e");
      }
    });

    // 6. Escuchar comandos externos (si el servicio es Android)
    if (service is AndroidServiceInstance) {
      service.on('stopService').listen((event) async {
        await positionSubscription.cancel();
        service.stopSelf();
      });
    }
    
    // Mantenemos el servicio vivo
    print("Servicio de rastreo iniciado correctamente para: $childId");
  }
}