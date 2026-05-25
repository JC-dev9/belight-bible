import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'config/app_env.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/notification_service.dart';

/// Notificador global de tema para a aplicação.
/// Permite mudar o ThemeMode (light, dark, system) de qualquer lugar.
final ValueNotifier<ThemeMode> appThemeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

/// Constantes para chaves do Hive
class HiveKeys {
  static const String settingsBox = 'settingsBox';
  static const String rememberMe = 'rememberMe';
  static const String themeMode = 'themeMode';
  static const String bibleTheme = 'bibleTheme';
  static const String onboardingCompleted = 'onboardingCompleted';
  static const String dailyVerseEnabled = 'dailyVerseEnabled';
  static const String dailyVerseHour = 'dailyVerseHour';
  static const String dailyVerseMinute = 'dailyVerseMinute';
}

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = kReleaseMode && AppEnv.sentryDsn.isNotEmpty
          ? AppEnv.sentryDsn
          : null;
      options.tracesSampleRate = 0.2;
    },
    appRunner: () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Inicializa Hive
      await Hive.initFlutter();
      await Hive.openBox('bibleBox');
      await Hive.openBox(HiveKeys.settingsBox);

      // Valida configuração em modo debug
      AppEnv.assertConfigured();

      // Inicializa Supabase
      await Supabase.initialize(
        url: AppEnv.supabaseUrl,
        anonKey: AppEnv.supabaseAnonKey,
      );

      // Carregar ThemeMode persistido
      final settingsBox = Hive.box(HiveKeys.settingsBox);
      final savedTheme = settingsBox.get(HiveKeys.themeMode, defaultValue: 'system');
      appThemeNotifier.value = _parseThemeMode(savedTheme);

      // Verificar "Lembrar-me" — se não está ativado, fazer sign out
      final rememberMe = settingsBox.get(HiveKeys.rememberMe, defaultValue: true);
      if (rememberMe == false) {
        await Supabase.instance.client.auth.signOut();
      }

      // Re-agendar a notificação diária, se activa, sem bloquear o cold start.
      // O init() do NotificationService corre lazy dentro de scheduleDailyVerse,
      // evitando carregar timezone (~700KB) para quem não usa notificações.
      final dailyEnabled =
          settingsBox.get(HiveKeys.dailyVerseEnabled, defaultValue: false) == true;
      if (dailyEnabled) {
        final hour = settingsBox.get(HiveKeys.dailyVerseHour, defaultValue: 8) as int;
        final minute =
            settingsBox.get(HiveKeys.dailyVerseMinute, defaultValue: 0) as int;
        unawaited(NotificationService.instance
            .scheduleDailyVerse(hour: hour, minute: minute));
      }

      runApp(const ProviderScope(child: MyApp()));
    },
  );
}

ThemeMode _parseThemeMode(String value) {
  switch (value) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Verifica se existe uma sessão ativa
    final hasSession = Supabase.instance.client.auth.currentSession != null;

    // Onboarding visto?
    final settingsBox = Hive.box(HiveKeys.settingsBox);
    final onboardingDone =
        settingsBox.get(HiveKeys.onboardingCompleted, defaultValue: false) == true;
    final Widget initialScreen = !onboardingDone
        ? const OnboardingScreen()
        : (hasSession ? const HomeScreen() : const LoginScreen());

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'BeLight Bible',
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('pt', 'BR'),
          ],
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.yellow,
            scaffoldBackgroundColor: Colors.white,
            cardColor: Colors.white,
            dividerColor: Colors.grey.shade300,
            hintColor: Colors.grey.shade600,
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Colors.black),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.yellow,
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            dividerColor: Colors.grey.shade700,
            hintColor: Colors.grey.shade400,
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Colors.white),
            ),
          ),
          themeMode: themeMode,
          home: initialScreen,
          routes: {
            '/home': (context) => const HomeScreen(),
            '/register': (context) => const RegisterScreen(),
            '/forgot-password': (context) => const ForgotPasswordScreen(),
            '/onboarding': (context) => const OnboardingScreen(),
          },
        );
      },
    );
  }
}
