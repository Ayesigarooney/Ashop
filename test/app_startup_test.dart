import 'package:flutter_test/flutter_test.dart';
import 'package:ashop/core/di/locator.dart' as di;
import 'package:ashop/features/settings/data/settings_repository.dart';
import 'package:ashop/main.dart' as app;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    di.locator.reset();
  });

  test('setupLocator is safe to call more than once', () {
    expect(() => di.setupLocator(), returnsNormally);
    expect(() => di.setupLocator(), returnsNormally);
  });

  test('initializeApp registers required services before app startup', () async {
    await app.initializeApp(
      initializePlatform: false,
      initializeHive: false,
    );

    expect(di.locator.isRegistered<SettingsRepository>(), isTrue);
  });
}
