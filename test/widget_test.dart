import 'package:flutter_test/flutter_test.dart';
import 'package:vesta_tracker/main.dart'; // Asegúrate que aquí esté VestaTrackerApp
import 'package:vesta_tracker/screens/setup_screen.dart';

void main() {
  testWidgets('La App carga la pantalla de SetupScreen al iniciar', (WidgetTester tester) async {
    // Ya no pasamos initialChildId, ya que MaterialApp.router usa el GoRouter
    await tester.pumpWidget(const VestaTrackerApp());
    
    // pumpAndSettle espera a que las animaciones y el router terminen de cargar
    await tester.pumpAndSettle();
    
    // Verificamos que el botón de vinculación esté presente
    expect(find.text('VINCULAR DISPOSITIVO'), findsOneWidget);
    
    // Verificamos que estamos en la pantalla de Setup
    expect(find.byType(SetupScreen), findsOneWidget);
  });
}