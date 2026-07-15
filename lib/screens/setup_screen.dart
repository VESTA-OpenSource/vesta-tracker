import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  Future<void> _vincular() async {
    final String codigo = _controller.text.trim().toUpperCase();
    if (codigo.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // 1. Buscamos en todas las subcolecciones 'hijos'
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
      
      // 2. Obtenemos el tutorId de la jerarquía: doc -> hijos (col) -> users (doc)
      final tutorId = doc.reference.parent.parent!.id;

      // 3. Actualizamos el estado a 'vinculado'
      await doc.reference.update({
        'status': 'vinculado',
        'linkedAt': FieldValue.serverTimestamp(),
      });

      // 4. Persistencia para el servicio de fondo
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('child_id', childId);
      await prefs.setString('parent_id', tutorId);
      
      // 5. Navegación hacia la pantalla de éxito antes de ir al rastreador
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