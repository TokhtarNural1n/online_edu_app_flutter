import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'models/user_model.dart';
import 'view_models/auth_view_model.dart';
import 'screens/auth_view.dart';
import 'screens/main_screen.dart';
import 'screens/admin/admin_panel_screen.dart'; // <-- 1. Импортируем новый экран

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Этот StreamBuilder следит за состоянием входа/выхода пользователя
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        // Если пользователь вошел в систему...
        if (authSnapshot.hasData) {
          // ...то мы теперь загружаем его данные из Firestore, чтобы узнать роль
          return FutureBuilder<UserModel?>(
            future: Provider.of<AuthViewModel>(context, listen: false).getUserData(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (userSnapshot.hasError || !userSnapshot.hasData) {
                return const Scaffold(body: Center(child: Text("Не удалось загрузить данные пользователя.")));
              }
              
              final userModel = userSnapshot.data!;
              
              // --- ГЛАВНАЯ ЛОГИКА РАСПРЕДЕЛЕНИЯ ПО РОЛЯМ ---
              if (userModel.role == 'admin') {
                // Если роль 'admin', показываем админ-панель
                return const AdminPanelScreen();
              } else {
                // Иначе показываем обычный главный экран
                return const MainScreen();
              }
            },
          );
        }
        
        // Если пользователь не вошел, показываем экран аутентификации
        return const AuthView();
      },
    );
  }
}