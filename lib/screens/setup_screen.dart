import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      // 1. Búsqueda directa y eficiente en 'pairing_codes'
      final doc = await FirebaseFirestore.instance.collection('pairing_codes').doc(codigo).get();

      if (!doc.exists) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Código no válido")));
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      final String childId = data['childId'];
      final String tutorId = data['tutorId'];

      // 2. Actualizar el estado a 'vinculado' en la ruta correcta
      await FirebaseFirestore.instance
          .collection('users')
          .doc(tutorId)
          .collection('hijos')
          .doc(childId)
          .update({'status': 'vinculado'});

      // 3. Limpieza: borrar el código para que no se reutilice
      await doc.reference.delete();

      // 4. Guardar localmente
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('child_id', childId);
      await prefs.setString('tutor_id', tutorId);
      
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Vinculado con éxito!")));

    } catch (e) {
      debugPrint("Error de vinculación: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: _controller, decoration: const InputDecoration(labelText: "Ingresa el código del Tutor")),
            const SizedBox(height: 20),
            _isLoading 
              ? const CircularProgressIndicator() 
              : ElevatedButton(onPressed: _vincular, child: const Text("VINCULAR DISPOSITIVO")),
          ],
        ),
      ),
    );
  }
}