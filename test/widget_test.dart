import 'package:flutter_test/flutter_test.dart';
import 'package:vesta_tracker/main.dart';
import 'package:vesta_tracker/screens/setup_screen.dart';

void main() {
  testWidgets('La App carga la pantalla de SetupScreen al iniciar', (WidgetTester tester) async {
    await tester.pumpWidget(const VestaTrackerApp(initialChildId: null));
    await tester.pumpAndSettle();
    expect(find.text('VINCULAR DISPOSITIVO'), findsOneWidget);
    expect(find.byType(SetupScreen), findsOneWidget);
  });
}