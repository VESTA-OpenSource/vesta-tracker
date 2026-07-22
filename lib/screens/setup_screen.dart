import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../location_service.dart';
import 'package:permission_handler/permission_handler.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  Future<bool> _solicitarPermisos() async {
    var status = await Permission.location.request();
    if (!status.isGranted) return false;

    Map<Permission, PermissionStatus> statuses = await [
      Permission.locationAlways,
      Permission.notification,
    ].request();
    return statuses[Permission.locationAlways]!.isGranted;
  }

  Future<void> _vincular() async {
    final String codigo = _controller.text.trim().toUpperCase();
    if (codigo.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      bool permisosConcedidos = await _solicitarPermisos();
      if (!permisosConcedidos) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Es necesario permitir la ubicación 'Siempre' para el rastreo en segundo plano."),
              action: SnackBarAction(label: "Configuración", onPressed: openAppSettings),
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final querySnapshot = await FirebaseFirestore.instance
          .collectionGroup('hijos')
          .where('pairingCode', isEqualTo: codigo)
          .where('status', isEqualTo: 'esperando_vinculacion')
          .get();

      if (querySnapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Código no válido o ya vinculado")),
          );
        }
        return;
      }

      final doc = querySnapshot.docs.first;
      final childId = doc.id;
      final tutorId = doc.reference.parent.parent!.id;

      await doc.reference.update({
        'status': 'vinculado',
        'linkedAt': FieldValue.serverTimestamp(),
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('child_id', childId);
      await prefs.setString('parent_id', tutorId);
      
      final service = FlutterBackgroundService();
      service.invoke('stopService');
      await Future.delayed(const Duration(milliseconds: 500));
      await LocationService.initializeService();
      
      if (mounted) {
        context.go('/success/$childId');
      }
    } catch (e) {
      debugPrint("Error de vinculación: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al conectar: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Configuración inicial")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: "Código del Tutor",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code),
              ),
            ),
            const SizedBox(height: 20),
            _isLoading 
              ? const CircularProgressIndicator() 
              : ElevatedButton(
                  onPressed: _vincular, 
                  child: const Text("VINCULAR DISPOSITIVO"),
                ),
          ],
        ),
      ),
    );
  }
}