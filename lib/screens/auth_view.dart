import 'package:flutter/material.dart';
import 'login_view.dart';
import 'registration_view.dart';
import 'forgot_password_view.dart';

// Используем enum для более чистого управления состоянием
enum AuthScreen { login, register, forgotPassword }

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  AuthScreen _currentScreen = AuthScreen.login;

  void _navigateTo(AuthScreen screen) {
    setState(() {
      _currentScreen = screen;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentScreen) {
      case AuthScreen.login:
        return LoginView(
          onNavigateToRegister: () => _navigateTo(AuthScreen.register),
          onNavigateToForgotPassword: () => _navigateTo(AuthScreen.forgotPassword),
        );
      case AuthScreen.register:
        return RegistrationView(
          onNavigateToLogin: () => _navigateTo(AuthScreen.login),
        );
      case AuthScreen.forgotPassword:
        return ForgotPasswordView(
          onNavigateBackToLogin: () => _navigateTo(AuthScreen.login),
        );
    }
  }
}