import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/course_model.dart';
import '../../view_models/admin_view_model.dart';
import '../../view_models/course_view_model.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final UserModel user;

  const AdminUserDetailScreen({super.key, required this.user});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  // 1. Убираем Future из состояния. Вместо него используем простой счетчик для ключа.
  int _refreshKey = 0;

  // Этот метод теперь просто меняет ключ, заставляя FutureBuilder обновиться
  void _refreshData() {
    setState(() {
      _refreshKey++;
    });
  }

  void _showGrantAccessDialog() async {
    final courseViewModel = Provider.of<CourseViewModel>(context, listen: false);
    final adminViewModel = Provider.of<AdminViewModel>(context, listen: false);

    // Загружаем все курсы
    final allCourses = await courseViewModel.fetchCourses();
    // Загружаем курсы, на которые пользователь уже записан
    final enrolledCourses = await courseViewModel.fetchMyCourses(userId: widget.user.uid);

    final enrolledCourseIds = enrolledCourses.map((c) => c.id).toSet();
    final availableToEnroll = allCourses.where((c) => !enrolledCourseIds.contains(c.id)).toList();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Выдать доступ к курсу'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableToEnroll.length,
              itemBuilder: (context, index) {
                final course = availableToEnroll[index];
                return ListTile(
                  title: Text(course.title),
                  onTap: () async {
                    await adminViewModel.grantCourseAccess(userId: widget.user.uid, courseId: course.id);
                    if (mounted) {
                      Navigator.of(context).pop();
                      _refreshData(); // 2. Вызываем простой метод обновления
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Отмена')),
          ],
        );
      },
    );
  }

  void _revokeAccess(String courseId) async {
    final adminViewModel = Provider.of<AdminViewModel>(context, listen: false);
    await adminViewModel.revokeCourseAccess(userId: widget.user.uid, courseId: courseId);
    _refreshData(); // 3. Вызываем простой метод обновления
  }

  @override
  Widget build(BuildContext context) {
    final displayName = '${widget.user.name} ${widget.user.surname}'.trim();
    final courseViewModel = Provider.of<CourseViewModel>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(displayName.isEmpty ? widget.user.email : displayName),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // ... (Блок с информацией о пользователе без изменений) ...
          Text('Профиль пользователя', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Имя: ${widget.user.name}'),
          Text('Фамилия: ${widget.user.surname}'),
          Text('Email: ${widget.user.email}'),
          Text('Роль: ${widget.user.role}'),
          const Divider(height: 40),

          Text('Записан на курсы:', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          
          FutureBuilder<List<Course>>(
            // 4. Добавляем наш новый ключ
            key: ValueKey(_refreshKey),
            // 5. Запрос к базе данных теперь находится прямо здесь
            future: courseViewModel.fetchMyCourses(userId: widget.user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Ошибка загрузки курсов: ${snapshot.error}'));
              }
              final enrolledCourses = snapshot.data ?? [];

              if (enrolledCourses.isEmpty) {
                return const Text('Пользователь не записан ни на один курс.');
              }

              return Column(
                children: enrolledCourses.map((course) => ListTile(
                      title: Text(course.title),
                      subtitle: Text(course.author),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _revokeAccess(course.id),
                        tooltip: 'Отозвать доступ',
                      ),
                    )).toList(),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showGrantAccessDialog,
        tooltip: 'Выдать доступ к курсу',
        child: const Icon(Icons.add),
      ),
    );
  }
}