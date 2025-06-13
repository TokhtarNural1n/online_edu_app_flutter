import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/auth_view_model.dart';
import '../models/user_model.dart';
import 'settings_screen.dart';
import 'language_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мой профиль'),
        elevation: 0,
      ),
      body: FutureBuilder<UserModel?>(
        future: authViewModel.getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text("Не удалось загрузить данные профиля."),
            );
          }
          
          final userModel = snapshot.data!;
          return _buildProfileView(context, userModel);
        },
      ),
    );
  }

  Widget _buildProfileView(BuildContext context, UserModel userModel) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildUserProfile(context, userModel),
        const SizedBox(height: 24),
        _buildMenuItem(context, icon: Icons.video_library_outlined, title: 'Мои курсы', onTap: () {}),
        _buildMenuItem(context, icon: Icons.run_circle_outlined, title: 'Мои марафоны', onTap: () {}),
        _buildMenuItem(context, icon: Icons.note_alt_outlined, title: 'Мои тесты', onTap: () {}),
        _buildMenuItem(
          context,
          icon: Icons.language_outlined,
          title: 'Язык',
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const LanguageScreen()));
          },
        ),
      ],
    );
  }

  // В этом виджете мы вносим исправление
  Widget _buildUserProfile(BuildContext context, UserModel userModel) {
    final String displayName = '${userModel.name} ${userModel.surname}'.trim();
    final String firstLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : (userModel.email.isNotEmpty ? userModel.email[0].toUpperCase() : 'U');

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
              child: Text(
                firstLetter,
                style: const TextStyle(fontSize: 24, color: Colors.blueAccent, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // --- НАШЕ ИСПРАВЛЕНИЕ ЗДЕСЬ ---
                      // 1. Оборачиваем Text в Expanded
                      Expanded(
                        child: Text(
                          displayName.isEmpty ? userModel.email : displayName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          // 2. Добавляем свойства для обрезки текста
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      // ---------------------------------
                      const SizedBox(width: 8),
                      if (userModel.role == 'admin')
                        Chip(
                          label: const Text('Админ'),
                          backgroundColor: Colors.orangeAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                          labelStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Настройки',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  // Вспомогательный виджет для создания пункта меню
  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: Theme.of(context).cardColor,
      ),
    );
  }
}