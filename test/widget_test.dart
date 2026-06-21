import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_tank_controller/main.dart';
import 'package:water_tank_controller/models/controller_snapshot.dart';
import 'package:water_tank_controller/models/controller_status.dart';
import 'package:water_tank_controller/providers/app_providers.dart';
import 'package:water_tank_controller/services/notification_service.dart';

void main() {
  testWidgets('App shell renders dashboard', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          notificationServiceProvider.overrideWithValue(NotificationService()),
          controllerControllerProvider.overrideWith(
            FakeControllerController.new,
          ),
        ],
        child: const WaterTankApp(),
      ),
    );

    await tester.pump();
    expect(find.text('Water Tank Controller'), findsOneWidget);
    expect(find.text('192.168.1.13'), findsOneWidget);
  });
}

class FakeControllerController extends ControllerController {
  @override
  ControllerSnapshot build() {
    return ControllerSnapshot(
      status: ControllerStatus(
        pumpRunning: false,
        tankFull: false,
        lockout: false,
        currentRuntimeSeconds: 0,
        totalRuntimeSeconds: 0,
        wifiConnected: true,
        receivedAt: DateTime(2026),
      ),
      online: true,
      syncing: false,
    );
  }
}
