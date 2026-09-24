import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splytwise/data/db/app_database.dart';
import 'package:splytwise/features/settings/settings_page.dart';
import 'package:splytwise/main.dart';
import 'package:splytwise/providers/app_providers.dart';
import 'package:splytwise/router/app_router.dart';
import 'package:splytwise/services/pin_service.dart';
import 'package:splytwise/theme/app_theme.dart';
import 'package:splytwise/theme/tokens.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('app widget type is wired', () {
    expect(SplytwiseApp, isNotNull);
  });

  test('theme follows the approved Splytwise palette', () {
    final theme = AppTheme.light();

    expect(theme.colorScheme.primary, SplytPalette.gold);
    expect(theme.filledButtonTheme.style?.foregroundColor?.resolve({}), Colors.black);
    expect(theme.scaffoldBackgroundColor, SplytPalette.lightBg);
  });

  test('hashPin exists and hashes a 4-digit pin', () {
    final hashed = hashPin('1234');

    expect(hashed, isNotEmpty);
    expect(hashed, isNot('1234'));
  });

  test('settings row is created when the database starts empty', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    final settings = await db.settings();

    expect(settings, isNotNull);
    expect(settings.themeMode, 'light');
    expect(settings.id, isA<int>());
  });

  test('watchSettings emits a seeded settings row from an empty database', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final settings = await db.watchSettings().first;

    expect(settings, isNotNull);
    expect(settings.themeMode, 'light');
    expect(settings.id, isA<int>());
  });

  testWidgets('settings screen renders its content', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final settings = await db.settings();
    await db.ensureSeeded();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWith((ref) => db),
          settingsProvider.overrideWith((ref) => Stream.value(settings)),
          userProvider.overrideWith((ref) => Stream.value(User(
            id: 1,
            name: 'Test User',
            currency: 'GHS',
            profileImagePath: null,
            createdAt: DateTime.now(),
          ))),
          categoriesProvider.overrideWith((ref) async* {
            yield await db.watchSpendCategories().first;
          }),
        ],
        child: const MaterialApp(home: SettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsAtLeastNWidgets(1));
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Lock & alerts'), findsOneWidget);
  });

  testWidgets('router keeps settings accessible when PIN lock is on', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final settings = AppSetting(
      id: 1,
      pinEnabled: true,
      pinHash: hashPin('1234'),
      notificationsEnabled: true,
      reminderDays: 7,
      freeMoneyWarnPesewas: 5000,
      onboardingComplete: true,
      themeMode: 'light',
    );

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWith((ref) => db),
        settingsProvider.overrideWith((ref) => Stream.value(settings)),
        userProvider.overrideWith((ref) => Stream.value(User(
          id: 1,
          name: 'Test User',
          currency: 'GHS',
          profileImagePath: null,
          createdAt: DateTime.now(),
        ))),
        categoriesProvider.overrideWith((ref) => Stream.value(const [])),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    router.go('/settings');
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.toString(), '/settings');
  });

  testWidgets('router keeps settings accessible when PIN lock is off', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final settings = AppSetting(
      id: 1,
      pinEnabled: false,
      pinHash: null,
      notificationsEnabled: true,
      reminderDays: 7,
      freeMoneyWarnPesewas: 5000,
      onboardingComplete: true,
      themeMode: 'light',
    );

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWith((ref) => db),
        settingsProvider.overrideWith((ref) => Stream.value(settings)),
        userProvider.overrideWith((ref) => Stream.value(User(
          id: 1,
          name: 'Test User',
          currency: 'GHS',
          profileImagePath: null,
          createdAt: DateTime.now(),
        ))),
        categoriesProvider.overrideWith((ref) => Stream.value(const [])),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    router.go('/settings');
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.toString(), '/settings');
  });
}
