import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:charging_monitoring/main.dart';
import 'package:charging_monitoring/services/settings_service.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = await SettingsService.create();

    await tester.pumpWidget(MyApp(settings: settings));

    expect(find.text('充电桩离线检测'), findsOneWidget);
    expect(find.text('监测'), findsOneWidget);
    expect(find.text('日志'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
  });
}