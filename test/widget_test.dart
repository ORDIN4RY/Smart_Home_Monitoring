import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_home_monitoring/data/services/server_connection_manager.dart';
import 'package:smart_home_monitoring/data/services/sync_manager.dart';
import 'package:smart_home_monitoring/main.dart';
import 'package:smart_home_monitoring/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:smart_home_monitoring/presentation/screens/main_navigation.dart';

void main() {
  tearDown(() {
    SyncManager.currentSensors.value = null;
    SyncManager.currentDeviceStatus.value = null;
    SyncManager.dispose();
    ServerConnectionManager.dispose();
  });

  testWidgets('App renders Homatix splash screen initially', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartHomeApp());

    expect(find.text('Homatix'), findsOneWidget);
    expect(find.text('Smart Home & IoT System'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('Dashboard shows Tidak Terdeteksi when sensor & device status are null',
      (WidgetTester tester) async {
    SyncManager.currentSensors.value = null;
    SyncManager.currentDeviceStatus.value = null;

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DashboardScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Suhu Ruang: Tidak Terdeteksi'), findsOneWidget);
    expect(find.text('Tidak Terdeteksi'), findsWidgets);
    // Pastikan angka dummy lama (24.0 / 28.4 / 95 PPM) tidak muncul
    expect(find.textContaining('28.4'), findsNothing);
    expect(find.textContaining('95 PPM'), findsNothing);
  });

  testWidgets('MainNavigation renders Homatix header and liquid bubble navbar transitions cleanly',
      (WidgetTester tester) async {
    SyncManager.syncStatus.value = SyncStatus.offline;
    SyncManager.currentSensors.value = null;
    SyncManager.currentDeviceStatus.value = null;

    await tester.pumpWidget(const MaterialApp(home: MainNavigation()));
    await tester.pump();

    expect(find.text('Homatix Smart Home'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.tune_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Kendali Perangkat'), findsOneWidget);
    expect(find.text('Kontrol'), findsOneWidget);
  });

  test('LiquidBubbleNavGeometry produces valid bounded metaball paths across all transitions', () {
    const labelWidths = [62.0, 44.0, 60.0, 42.0];
    for (final totalWidth in [290.0, 328.0, 376.0]) {
      for (int step = 0; step <= 60; step++) {
        final pos = (step / 60.0) * 3.0;
        final slots = LiquidBubbleNavGeometry.computeSlots(
          totalWidth: totalWidth,
          pos: pos,
          labelWidths: labelWidths,
        );
        final sumWidth = slots.fold<double>(0.0, (acc, s) => acc + s.width);
        expect(sumWidth, closeTo(totalWidth, 0.01));

        final path = LiquidBubbleNavGeometry.buildBubblePath(
          totalWidth: totalWidth,
          barHeight: 46.0,
          pos: pos,
          slots: slots,
        );
        final bounds = path.getBounds();
        expect(bounds.isEmpty, isFalse);
        expect(bounds.left.isFinite, isTrue);
        expect(bounds.right.isFinite, isTrue);
        expect(bounds.top.isFinite, isTrue);
        expect(bounds.bottom.isFinite, isTrue);
        expect(bounds.left, greaterThanOrEqualTo(0.0));
        expect(bounds.right, lessThanOrEqualTo(totalWidth + 0.5));
      }
    }
  });
}
