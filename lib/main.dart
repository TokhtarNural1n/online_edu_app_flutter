import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'view_models/course_view_model.dart'; 

// Импорты Firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Импорты наших файлов
import 'auth_wrapper.dart'; // Наш новый главный виджет-"переключатель"
import 'view_models/auth_view_model.dart';
import 'view_models/settings_view_model.dart';
import 'view_models/admin_view_model.dart';
import 'view_models/news_view_model.dart';


Future<void> main() async {
  // Убеждаемся, что все готово для асинхронных операций
  WidgetsFlutterBinding.ensureInitialized();
  // Инициализируем Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    // Предоставляем наши ViewModel-ы всему приложению
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(create: (_) => CourseViewModel()),
        ChangeNotifierProvider(create: (_) => AdminViewModel()),
        ChangeNotifierProvider(create: (_) => NewsViewModel()), 
      ],
      child: const EducationApp(),
    ),
  );
}

// Корневой виджет нашего приложения~
class EducationApp extends StatelessWidget {
  const EducationApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsViewModel = Provider.of<SettingsViewModel>(context);

    // Определяем наш основной синий цвет
    const Color primaryBlue = Colors.blue;

    return MaterialApp(
      title: 'Education App', 
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: settingsViewModel.appLocale,

      // --- ОБНОВЛЕННАЯ СВЕТЛАЯ ТЕМА ---
      theme: ThemeData(
        useMaterial3: true, // Включаем современный дизайн Material 3
        fontFamily: 'Inter',
        // Создаем всю цветовую схему на основе нашего синего цвета
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          brightness: Brightness.light,
          // Можно дополнительно настроить фон
          background: const Color(0xFFF5F7FA), 
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent, // Убирает оттенок на AppBar при прокрутке
          elevation: 1,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white, 
          type: BottomNavigationBarType.fixed,
        ), 
      ),

      // --- ОБНОВЛЕННАЯ ТЕМНАЯ ТЕМА ---
      darkTheme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme( 
          elevation: 1,
        ), 
      ),

      themeMode: settingsViewModel.themeMode,
      debugShowCheckedModeBanner: false, 
      home: const AuthWrapper(), 
    );
  }
}