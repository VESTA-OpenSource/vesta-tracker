import '../main.dart';
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

    debugPrint("DEBUG VESTA: Buscando hijo con pairingCode: $codigo");

    try {
      // Usamos collectionGroup para buscar en todos los documentos llamados 'hijos'
      final querySnapshot = await FirebaseFirestore.instance
          .collectionGroup('hijos')
          .where('pairingCode', isEqualTo: codigo)
          .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint("DEBUG VESTA: No se encontró ningún hijo con el código '$codigo'");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Código no válido")));
        }
        return;
      }

      // Tomamos el primer documento que coincida
      final doc = querySnapshot.docs.first;
      final childId = doc.id;
      // Obtenemos el tutorId del documento padre (la colección 'users')
      final tutorId = doc.reference.parent.parent!.id;

      debugPrint("DEBUG VESTA: Código encontrado. Vinculando Child: $childId con Tutor: $tutorId");

      // Actualizamos el status
      await doc.reference.update({'status': 'vinculado'});

      // Guardamos en preferencias
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('child_id', childId);
      await prefs.setString('tutor_id', tutorId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Vinculado con éxito!")));
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PermissionHandlerWrapper(childId: childId),
          ),    
        );
      }
    } catch (e) {
      debugPrint("DEBUG VESTA: Error de vinculación: $e");
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
            TextField(
              controller: _controller, 
              decoration: const InputDecoration(
                labelText: "Ingresa el código del Tutor",
                border: OutlineInputBorder(),
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