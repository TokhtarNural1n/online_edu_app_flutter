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

    return MaterialApp(
      title: 'Education App',
      // Подключение локализации
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: settingsViewModel.appLocale,
      
      // Светлая тема
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF0F4F8),
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Color(0xFF007BFF),
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
        ),
        cardColor: Colors.white,
      ),
      
      // Темная тема
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFF121212),
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 1,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Color(0xFF4A90E2),
          unselectedItemColor: Colors.grey,
          backgroundColor: Color(0xFF1E1E1E),
          type: BottomNavigationBarType.fixed,
        ),
        cardColor: const Color(0xFF1E1E1E),
      ),
      
      // Управление темой
      themeMode: settingsViewModel.themeMode,
      
      debugShowCheckedModeBanner: false,
      
      // ГЛАВНОЕ ИЗМЕНЕНИЕ: теперь домашний экран - это AuthWrapper
      home: const AuthWrapper(),
    );
  }
}