// lib/main_student.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:online_edu_app_flutter/l10n/app_localizations.dart';
import 'package:online_edu_app_flutter/view_models/course_view_model.dart';
import 'package:online_edu_app_flutter/view_models/admin_view_model.dart';

// --- ИСПРАВЛЕНИЕ: Добавляем недостающий импорт ---
import 'package:cloud_firestore/cloud_firestore.dart';

// Импорты Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:online_edu_app_flutter/firebase_options.dart';

// Импорты наших файлов
import 'package:online_edu_app_flutter/auth_wrapper.dart';
import 'package:online_edu_app_flutter/view_models/auth_view_model.dart';
import 'package:online_edu_app_flutter/view_models/settings_view_model.dart';
import 'package:online_edu_app_flutter/view_models/news_view_model.dart';
import 'package:online_edu_app_flutter/utils/app_constants.dart';
import 'package:online_edu_app_flutter/utils/navigator_key.dart';

// Здесь мы УСЛОВНО импортируем заглушку AdminPanelScreen
import 'package:online_edu_app_flutter/screens/admin/admin_panel_stub_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Устанавливаем лимит кэша, как мы обсуждали для оптимизации
  FirebaseFirestore.instance.settings = const Settings(
    cacheSizeBytes: 50 * 1024 * 1024, // 50 МБ
  );
  
  runZonedGuarded(() {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthViewModel()),
          ChangeNotifierProvider(create: (_) => SettingsViewModel()),
          ChangeNotifierProvider(create: (_) => CourseViewModel()),
          ChangeNotifierProvider(create: (_) => NewsViewModel()), 
          ChangeNotifierProvider(create: (_) => AdminViewModel()),
        ],
        child: EducationApp(
          appType: AppType.student,
          adminPanelBuilder: () => const AdminPanelStubScreen(),
        ),
      ),
    );
  }, (error, stack) {
    print("Неперехваченная ошибка: $error\n$stack");
  });
}

class EducationApp extends StatelessWidget {
  final AppType appType;
  final Widget Function() adminPanelBuilder;

  const EducationApp({
    super.key,
    required this.appType,
    required this.adminPanelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final settingsViewModel = Provider.of<SettingsViewModel>(context);
    const Color primaryBlue = Color.fromARGB(255, 35, 52, 67);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Online Edu App (Student)',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: settingsViewModel.appLocale,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          brightness: Brightness.light,
          background: const Color(0xFFF5F7FA), 
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
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
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
        ),
      ),
      darkTheme: ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      brightness: Brightness.dark, // Явно указываем, что это темная тема
      scaffoldBackgroundColor: const Color(0xFF121212), // Классический темный фон
      cardColor: const Color(0xFF1E1E1E), // Карточки чуть светлее фона
      
      // Создаем цветовую схему на основе вашего синего цвета
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark, // Важно указать здесь
      ),
      
      // Настраиваем AppBar для темной темы
      appBarTheme: const AppBarTheme( 
        elevation: 0, // Убираем тень
        backgroundColor: Color(0xFF1E1E1E), // Такой же, как у карточек
      ),
      
      // Настраиваем нижнюю навигацию
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
      ), 
    ),
      themeMode: settingsViewModel.themeMode,
      debugShowCheckedModeBanner: false, 
      home: AuthWrapper(appType: appType, adminPanelBuilder: adminPanelBuilder),
    );
  }
}