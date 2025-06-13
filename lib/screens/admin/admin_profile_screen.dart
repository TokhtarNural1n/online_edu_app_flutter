import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../view_models/auth_view_model.dart';
import '../settings_screen.dart'; // Переиспользуем экран настроек

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Получаем ViewModel для доступа к его методам
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль Администратора'),
      ),
      // Используем FutureBuilder, чтобы асинхронно получить данные админа
      body: FutureBuilder<UserModel?>(
        future: authViewModel.getUserData(),
        builder: (context, snapshot) {
          // Пока данные грузятся, показываем индикатор
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Если ошибка или нет данных
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Не удалось загрузить данные профиля."));
          }

          // Если все успешно, строим наш интерфейс
          final adminUserModel = snapshot.data!;
          return _buildAdminProfileView(context, adminUserModel);
        },
      ),
    );
  }

  // Основной виджет для отображения профиля админа
  Widget _buildAdminProfileView(BuildContext context, UserModel admin) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final String displayName = '${admin.name} ${admin.surname}'.trim();
    final String firstLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A';

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // --- Блок с информацией об админе ---
        GestureDetector(
          onTap: () {
            // Переходим на тот же экран настроек, что и обычный пользователь
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.orange.withOpacity(0.2),
                  child: Text(
                    firstLetter,
                    style: const TextStyle(fontSize: 24, color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              displayName.isEmpty ? admin.email : displayName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Значок админа
                          if (admin.role == 'admin')
                            const Chip(
                              label: Text('Admin'),
                              backgroundColor: Colors.orangeAccent,
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                              labelStyle: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Настройки аккаунта',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 32),
        
        // --- Кнопка выхода ---
        ListTile(
          leading: const Icon(Icons.exit_to_app, color: Colors.red),
          title: const Text(
            'Выйти из аккаунта',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
          ),
          onTap: () {
            authViewModel.logout();
          },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          tileColor: Theme.of(context).cardColor,
        ),
      ],
    );
  }
}
