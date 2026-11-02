import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';

// Uygulama genelinde tema durumunu en sade şekilde yöneten global ValueNotifier
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

const String _themePrefKey = 'is_dark_mode';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Uygulama açılışında kullanıcının son kaydettiği tema tercihini hafızadan oku
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool(_themePrefKey) ?? false;
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  runApp(const MobilabEventApp());
}

// Tema tercihini hem anlık değiştiren hem de kalıcı olarak kaydeden yardımcı fonksiyon
Future<void> toggleTheme() async {
  final isCurrentlyDark = themeNotifier.value == ThemeMode.dark;
  final newMode = isCurrentlyDark ? ThemeMode.light : ThemeMode.dark;

  // Arayüzü anında güncelle
  themeNotifier.value = newMode;

  // Tercihi telefon hafızasına kaydet
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_themePrefKey, newMode == ThemeMode.dark);
}

class MobilabEventApp extends StatelessWidget {
  const MobilabEventApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder ile sadece tema değiştiğinde MaterialApp yeniden çizilir
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'Etkinlik Keşif',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          // Açık Tema Ayarları
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              centerTitle: false,
              elevation: 0,
            ),
          ),
          // Koyu Tema Ayarları
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              centerTitle: false,
              elevation: 0,
            ),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}
