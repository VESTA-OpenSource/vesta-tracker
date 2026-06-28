import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import '../location_service.dart';

class TrackerActiveScreen extends StatefulWidget {
  final String childId;
  const TrackerActiveScreen({super.key, required this.childId});

  @override
  State<TrackerActiveScreen> createState() => _TrackerActiveScreenState();
}

class _TrackerActiveScreenState extends State<TrackerActiveScreen> {
  bool _isServiceRunning = false;

  @override
  void initState() {
    super.initState();
    _startTrackingProcess();
  }

  Future<void> _startTrackingProcess() async {
    LocationPermission permission = await Geolocator.requestPermission();
    
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      await LocationService.initializeService();
      FlutterBackgroundService().startService();
      
      setState(() {
        _isServiceRunning = true;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Necesitamos permisos de ubicación para rastrear.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vesta Tracker Activo")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isServiceRunning ? Icons.location_on : Icons.location_off,
              size: 100,
              color: _isServiceRunning ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              _isServiceRunning 
                ? "Rastreo activo para: ${widget.childId}" 
                : "Esperando permisos...",
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}