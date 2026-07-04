import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_tank_controller/main.dart';
import 'package:water_tank_controller/models/app_user.dart';
import 'package:water_tank_controller/models/auth_state.dart';
import 'package:water_tank_controller/models/connection_info.dart';
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
          authControllerProvider.overrideWith(FakeAuthController.new),
          controllerControllerProvider.overrideWith(
            FakeControllerController.new,
          ),
        ],
        child: const WaterTankApp(),
      ),
    );

    await tester.pump();
    expect(find.text('Water\nTank Control'), findsOneWidget);
    expect(find.text('Administrator - Local Connection'), findsOneWidget);
  });
}

class FakeAuthController extends AuthController {
  @override
  AuthState build() {
    const user = AppUser(
      id: 'admin',
      name: 'Administrator',
      role: UserRole.administrator,
      active: true,
    );
    return const AuthState(
      loading: false,
      users: [user],
      session: AuthSession(user: user),
    );
  }
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
      connection: ConnectionInfo(
        mode: ConnectionMode.local,
        qualityPercent: 96,
        endpoint: 'http://192.168.1.13',
        switchedAt: DateTime(2026),
      ),
    );
  }
}
