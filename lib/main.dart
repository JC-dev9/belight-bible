import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart'; // Import for FlutterQuillLocalizations

const supabaseUrl = 'https://dupoveauficvwgtrvxsx.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR1cG92ZWF1ZmljdndndHJ2eHN4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE0ODM2NTAsImV4cCI6MjA3NzA1OTY1MH0.9Gk_d6nj1cGSa6nbRHyuPmtiw7VU8Te7P8_qR5hRg8g';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Hive
  await Hive.initFlutter();
  await Hive.openBox('bibleBox'); // caixa para armazenar a Bíblia offline

  // Inicializa Supabase (para login, registro, etc.)
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bible App',
      // Adicionando suporte a localização para Flutter Quill
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
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.black)),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.yellow,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        dividerColor: Colors.grey.shade700,
        hintColor: Colors.grey.shade400,
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
      ),
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
      },
    );
  }
}
