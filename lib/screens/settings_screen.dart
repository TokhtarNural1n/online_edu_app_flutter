// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/settings_view_model.dart'; // <-- Добавляем импорт
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Убираем локальные состояния, теперь все будет управляться через ViewModel
  // bool _isFaceIdEnabled = true;
  // bool _isPushEnabled = true;

  @override
  Widget build(BuildContext context) {
    // Используем context.watch, чтобы экран перестраивался при смене темы
    final settingsViewModel = context.watch<SettingsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          children: [
            // ... (Блок с аватаром и кнопками изменения фото)
            
            const SizedBox(height: 32),

            // --- Пункты меню ---
            _buildSettingsItem(
              context,
              title: 'Редактировать профиль',
              icon: Icons.edit_outlined,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
              },
            ),
            _buildSettingsItem(
              context,
              title: 'Изменить пароль',
              icon: Icons.password_outlined,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordScreen()));
              },
            ),
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            
            // --- НОВЫЙ ПЕРЕКЛЮЧАТЕЛЬ ТЕМЫ ---
            _buildSwitchItem(
              context,
              title: 'Ночной режим',
              icon: Icons.dark_mode_outlined,
              value: settingsViewModel.themeMode == ThemeMode.dark,
              onChanged: (newValue) {
                // Вызываем метод из ViewModel для смены темы
                final viewModel = context.read<SettingsViewModel>();
                viewModel.setTheme(newValue ? ThemeMode.dark : ThemeMode.light);
              },
            ),
            
            _buildSwitchItem(
              context,
              title: 'Push-уведомления',
              icon: Icons.notifications_active_outlined,
              value: true, // TODO: Привязать к реальному состоянию
              onChanged: (newValue) { /* TODO: Implement logic */ }
            ),

            const SizedBox(height: 32),
            
            // --- Кнопка выхода ---
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text('Выйти', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
              onTap: () {
                Provider.of<AuthViewModel>(context, listen: false).logout();
                // Возвращаемся на самый первый экран после выхода
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Theme.of(context).cardColor,
            ),
          ],
        ),
      ),
    );
  }

  // Вспомогательные виджеты для построения UI
  Widget _buildSettingsItem(BuildContext context, {required String title, required IconData icon, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).textTheme.bodyLarge?.color),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
        tileColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSwitchItem(BuildContext context, {required String title, required IconData icon, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: SwitchListTile(
        title: Text(title),
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon, color: Theme.of(context).textTheme.bodyLarge?.color),
        activeColor: Theme.of(context).primaryColor,
        tileColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}