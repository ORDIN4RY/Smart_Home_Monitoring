import 'package:flutter_test/flutter_test.dart';
import 'package:smart_home_monitoring/main.dart';

void main() {
  testWidgets('App renders login screen initially', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartHomeApp());

    // Verify Login Screen widgets
    expect(find.text('Smart Home System'), findsOneWidget);
    expect(find.text('Masuk ke Dashboard'), findsOneWidget);
    expect(find.text('Demo Login Cepat'), findsOneWidget);
  });
}
