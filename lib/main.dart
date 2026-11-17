import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

import 'providers/auth_provider.dart';
import 'providers/wishlist_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop SQLite initialization (Windows / Linux / macOS)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    try {
      ffi.sqfliteFfiInit();
      databaseFactory = ffi.databaseFactoryFfi;
    } catch (e) {
      debugPrint('Desktop SQLite init error: $e');
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
      ],
      child: const ShoppingHubApp(),
    ),
  );
}

class ShoppingHubApp extends StatelessWidget {
  const ShoppingHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShoppingHub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          // If auth state is checking SharedPreferences, show quick indicator
          if (!authProvider.isInitialized) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // When logged in -> MainScreen
          if (authProvider.isLoggedIn) {
            return const MainScreen();
          }

          // Otherwise -> LoginScreen
          return const LoginScreen();
        },
      ),
    );
  }
}
