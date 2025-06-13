import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/auth_view_model.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isFaceIdEnabled = true;
  bool _isPushEnabled = true;

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          children: [
            // ... (Блок с аватаром без изменений) ...
            const CircleAvatar(radius: 50, backgroundColor: Color(0xFFE0E0E0), child: Icon(Icons.person, color: Colors.grey, size: 50)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(onPressed: () {}, child: const Text('Удалить фото')),
                const SizedBox(width: 16),
                ElevatedButton(onPressed: () {}, child: const Text('Изменить фото'), style: ElevatedButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.blueAccent)),
              ],
            ),
            const SizedBox(height: 32),

            // --- Пункты меню для навигации ---
            _buildSettingsItem(
              context,
              title: 'Редактировать профиль',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
              },
            ),
            _buildSettingsItem(
              context,
              title: 'Изменить пароль',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordScreen()));
              },
            ),
            // ПУНКТ ДЛЯ ПИН-КОДА УДАЛЕН
            const SizedBox(height: 16),

            // ... (Переключатели и кнопка Выйти без изменений) ...
             _buildSwitchItem(context, title: 'Вход с Face ID', value: _isFaceIdEnabled, onChanged: (newValue) => setState(() => _isFaceIdEnabled = newValue)),
             _buildSwitchItem(context, title: 'Push-уведомления', value: _isPushEnabled, onChanged: (newValue) => setState(() => _isPushEnabled = newValue)),
            const SizedBox(height: 32),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text('Выйти', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
              onTap: () {
                authViewModel.logout();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Theme.of(context).cardColor,
            ),
            const SizedBox(height: 40),
            const Text('Версия приложения: 1.0.0 (1)', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // Вспомогательный виджет для пунктов меню
  Widget _buildSettingsItem(BuildContext context, {required String title, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
        tileColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Вспомогательный виджет для переключателей
  Widget _buildSwitchItem(BuildContext context, {required String title, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: SwitchListTile(
        title: Text(title),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.teal,
        tileColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}