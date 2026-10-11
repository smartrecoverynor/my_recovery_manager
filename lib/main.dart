import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/router.dart';
import 'core/services/notification_service.dart';
import 'core/services/onboarding_service.dart';
import 'core/services/risky_place_alert_service.dart';
import 'core/services/risky_place_region_service.dart';
import 'core/theme/theme_controller.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Avgjør startside før oppstartstjenester eventuelt oppretter databasen.
  final initialLocation = await OnboardingService.resolveInitialLocation();

  await NotificationService.instance.initialize();
  await NotificationService.instance.requestPermissions();
  await RiskyPlaceRegionService.instance.syncAllPlaces();

  final themeController = ThemeController();
  await themeController.load();

  final router = createAppRouter(initialLocation: initialLocation);

  runApp(
    ThemeScope(
      controller: themeController,
      child: MyApp(router: router),
    ),
  );
}

class MyApp extends StatefulWidget {
  final RouterConfig<Object> router;

  const MyApp({super.key, required this.router});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _checkingNotificationTap = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForTappedRiskyPlace();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkForTappedRiskyPlace();
      });
    }
  }

  Future<void> _checkForTappedRiskyPlace() async {
    if (_checkingNotificationTap) {
      return;
    }

    _checkingNotificationTap = true;

    try {
      String? placeId;

      for (var attempt = 0; attempt < 8; attempt++) {
        placeId = await RiskyPlaceRegionService.instance
            .consumeTappedRiskyPlace();

        if (placeId != null) {
          break;
        }

        await Future<void>.delayed(const Duration(milliseconds: 250));
      }

      if (placeId == null) {
        return;
      }

      await RiskyPlaceAlertService.instance.loadPendingRegion(placeId);

      if (!mounted) {
        return;
      }

      await RiskyPlaceAlertService.instance.showPendingAlert();
    } finally {
      _checkingNotificationTap = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeScope.of(context);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      locale: const Locale('nb', 'NO'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('nb', 'NO')],
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeController.themeMode,
      routerConfig: widget.router,
    );
  }
}
