import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:online_edu_app_flutter/models/user_model.dart'; //
import 'package:online_edu_app_flutter/view_models/auth_view_model.dart'; //
import 'package:online_edu_app_flutter/screens/auth_view.dart'; //
import 'package:online_edu_app_flutter/screens/main_screen.dart'; //
import 'package:online_edu_app_flutter/utils/app_constants.dart'; //

class AuthWrapper extends StatelessWidget {
  final AppType appType;
  // Добавляем функцию, которая возвращает виджет AdminPanelScreen или его заглушку
  final Widget Function() adminPanelBuilder;

  const AuthWrapper({
    super.key,
    required this.appType,
    required this.adminPanelBuilder, // Теперь это обязательный параметр
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (authSnapshot.hasData) {
          // Пользователь вошел в систему. Теперь получаем его данные для определения роли.
          return FutureBuilder<UserModel?>(
            future: Provider.of<AuthViewModel>(context, listen: false).getUserData(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (userSnapshot.hasError || !userSnapshot.hasData) {
                // Если данные пользователя не загружены (например, ошибка сети), можно показать ошибку.
                return const Scaffold(body: Center(child: Text("Не удалось загрузить данные пользователя.")));
              }

              final userModel = userSnapshot.data!;

              // Логика маршрутизации в зависимости от типа приложения (student/admin)
              if (appType == AppType.admin) {
                // Если это АДМИН-приложение
                if (userModel.role == 'admin') {
                  // Если пользователь - администратор, показываем админ-панель (ту, которую передали)
                  return adminPanelBuilder();
                } else {
                  // Если пользователь НЕ администратор, но пытается войти в админ-приложение
                  return Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.security, size: 80, color: Colors.red),
                          const SizedBox(height: 20),
                          const Text(
                            'У вас нет прав доступа к этой панели.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () async {
                              await Provider.of<AuthViewModel>(context, listen: false).logout();
                            },
                            child: const Text('Выйти'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              } else {
                // Если это СТУДЕНЧЕСКОЕ приложение (AppType.student)
                // ВСЕГДА показываем MainScreen, независимо от роли пользователя.
                // Это гарантирует, что админский функционал недоступен в этой сборке.
                return const MainScreen();
              }
            },
          );
        }

        // Если пользователь не вошел в систему, показываем экран аутентификации.
        return const AuthView();
      },
    );
  }
}