import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../location_service.dart';

class TrackerActiveScreen extends StatefulWidget {
  final String childId;
  const TrackerActiveScreen({super.key, required this.childId});

  @override
  State<TrackerActiveScreen> createState() => _TrackerActiveScreenState();
}

class _TrackerActiveScreenState extends State<TrackerActiveScreen> {
  bool _isLoading = true;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    try {
      // Solo inicializamos si el servicio no está corriendo
      final service = FlutterBackgroundService();
      if (!(await service.isRunning())) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse || 
            permission == LocationPermission.always) {
          await LocationService.initializeService();
        }
      }
    } catch (e) {
      debugPrint("Error al inicializar: $e");
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleUnlink() async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);

    try {
      final service = FlutterBackgroundService();
      service.invoke("stopService");
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('child_id');
      
      if (mounted) context.go('/setup');
    } catch (e) {
      debugPrint("Error durante la desvinculación: $e");
      if (mounted) setState(() => _isNavigating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('telemetria').doc(widget.childId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;
        
        // Lógica de desvinculación mejorada
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          if (!_isNavigating) _handleUnlink();
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Si está inactivo, mostramos un aviso antes de expulsar (evita el rebote)
        if (data?['status'] == 'inactivo') {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("El dispositivo está marcado como inactivo.", textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _handleUnlink(), 
                    child: const Text("Volver a configurar")
                  )
                ],
              ),
            ),
          );
        }

        // Pantalla principal de rastreo
        return Scaffold(
          appBar: AppBar(title: const Text("Vesta Tracker")),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.my_location, size: 80, color: Colors.blue),
                const SizedBox(height: 20),
                const Text("Rastreo activo", style: TextStyle(fontSize: 18)),
                const SizedBox(height: 10),
                Text(
                  "Última señal: ${data?['timestamp']?.toDate()?.toString() ?? 'Recibiendo...'}",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}