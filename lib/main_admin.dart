import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:online_edu_app_flutter/l10n/app_localizations.dart';
import 'package:online_edu_app_flutter/view_models/course_view_model.dart';

// Импорты Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:online_edu_app_flutter/firebase_options.dart';

// Импорты наших файлов
import 'package:online_edu_app_flutter/auth_wrapper.dart';
import 'package:online_edu_app_flutter/view_models/auth_view_model.dart';
import 'package:online_edu_app_flutter/view_models/settings_view_model.dart';
import 'package:online_edu_app_flutter/view_models/admin_view_model.dart';
import 'package:online_edu_app_flutter/view_models/news_view_model.dart';
import 'package:online_edu_app_flutter/utils/app_constants.dart'; // КОРРЕКТНЫЙ ИМПОРТ AppType

// Здесь импортируем РЕАЛЬНУЮ AdminPanelScreen
import 'package:online_edu_app_flutter/screens/admin/admin_panel_screen.dart' as AdminPanelScreenAlias;


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(create: (_) => CourseViewModel()),
        ChangeNotifierProvider(create: (_) => AdminViewModel()),
        ChangeNotifierProvider(create: (_) => NewsViewModel()), 
      ],
      // Здесь мы передаем РЕАЛЬНУЮ админ-панель
      child: EducationApp( // <<< УБРАЛИ 'const' ЗДЕСЬ
        appType: AppType.admin,
        adminPanelBuilder: () => AdminPanelScreenAlias.AdminPanelScreen(), // <<< УБРАЛИ 'const' ЗДЕСЬ
      ),
    ),
  );
}

class EducationApp extends StatelessWidget {
  final AppType appType;
  final Widget Function() adminPanelBuilder;

  // Конструктор EducationApp теперь НЕ const, потому что adminPanelBuilder может быть не const
  const EducationApp({
    super.key,
    required this.appType,
    required this.adminPanelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final settingsViewModel = Provider.of<SettingsViewModel>(context);
    const Color primaryBlue = Colors.blue;

    return MaterialApp(
      title: 'Online Edu App (Admin)',
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
          type: BottomNavigationBarType.fixed,
        ), 
      ),
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
      home: AuthWrapper(appType: appType, adminPanelBuilder: adminPanelBuilder),
    );
  }
}