import 'package:flutter_test/flutter_test.dart';
import 'package:smart_home_monitoring/data/services/server_connection_manager.dart';
import 'package:smart_home_monitoring/data/services/sync_manager.dart';
import 'package:smart_home_monitoring/main.dart';

void main() {
  tearDown(() {
    SyncManager.dispose();
    ServerConnectionManager.dispose();
  });

  testWidgets('App renders splash screen initially', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartHomeApp());

    // Verify Splash Screen widgets
    expect(find.text('Smart Home'), findsOneWidget);
    expect(find.text('Monitoring & IoT System'), findsOneWidget);

    // Let the splash sequence and timers finish
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    SyncManager.dispose();
    ServerConnectionManager.dispose();
  });
}
