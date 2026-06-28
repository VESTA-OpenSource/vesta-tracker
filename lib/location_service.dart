import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        isForegroundMode: true,
        notificationChannelId: 'vesta_tracker_channel',
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(autoStart: true),
    );
  }

  @pragma('vm:entry-point')
  static Future<void> onStart(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    final prefs = await SharedPreferences.getInstance();
    final childId = prefs.getString('child_id');
    
    if (childId == null) {
      service.stopSelf();
      return;
    }
    Geolocator.getPositionStream().listen((Position position) {
      FirebaseFirestore.instance.collection('telemetria').doc(childId).set({
        'lat': position.latitude,
        'lng': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'childId': childId, // Incluimos esto para validar en las reglas
      }, SetOptions(merge: true));
    });
  }
}