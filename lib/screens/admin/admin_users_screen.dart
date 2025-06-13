import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../view_models/admin_view_model.dart';
import 'admin_user_detail_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  late Future<List<UserModel>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    // Загружаем пользователей один раз при открытии экрана
    _usersFuture = Provider.of<AdminViewModel>(context, listen: false).fetchAllUsers();
  }

  // Метод для принудительного обновления списка после редактирования
  void _refreshUsersList() {
    setState(() {
      _loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Пользователи'),
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Пользователи не найдены.'));
          }

          final users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final displayName = '${user.name} ${user.surname}'.trim();

              return ListTile(
                leading: CircleAvatar(
                  child: Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : '?'),
                ),
                title: Text(displayName.isEmpty ? user.email : displayName),
                subtitle: Text(user.email),
                trailing: Chip(
                  label: Text(user.role),
                  backgroundColor: user.role == 'admin' 
                    ? Colors.orangeAccent 
                    : Colors.grey.shade300,
                ),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AdminUserDetailScreen(user: user)),
                  );
                  // Если с детального экрана вернулся сигнал, обновляем список
                  if (result == true) {
                    _refreshUsersList();
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
