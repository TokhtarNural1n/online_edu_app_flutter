
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/course_model.dart';
import '../../models/enrollment_detail_model.dart';
import '../../view_models/admin_view_model.dart';
import '../../view_models/course_view_model.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final UserModel user;
  const AdminUserDetailScreen({super.key, required this.user});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  int _refreshKey = 0;

  void _refreshData() {
    setState(() {
      _refreshKey++;
    });
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String content,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // --- НОВЫЙ ВСПОМОГАТЕЛЬНЫЙ МЕТОД ДЛЯ ЗАГРУЗКИ ДАННЫХ ---
  Future<List<Course>> _getAvailableCoursesForDialog() async {
    final courseViewModel = Provider.of<CourseViewModel>(context, listen: false);
    // Запускаем оба запроса параллельно для ускорения
    final results = await Future.wait([
      courseViewModel.fetchCourses(),
      courseViewModel.fetchMyCourses(userId: widget.user.uid),
    ]);
    final allCourses = results[0];
    final enrolledCourses = results[1];
    
    final enrolledCourseIds = enrolledCourses.map((c) => c.id).toSet();
    final availableToEnroll = allCourses.where((c) => !enrolledCourseIds.contains(c.id)).toList();
    return availableToEnroll;
  }


  // --- ОБНОВЛЕННЫЙ МЕТОД ДИАЛОГА ---
  void _showGrantAccessDialog() {
    // Теперь диалог открывается мгновенно
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Выдать доступ к курсу'),
          // Контент теперь FutureBuilder, который сам загрузит данные
          content: SizedBox(
            width: double.maxFinite,
            // Оборачиваем список в FutureBuilder
            child: FutureBuilder<List<Course>>(
              future: _getAvailableCoursesForDialog(),
              builder: (context, snapshot) {
                // Пока данные грузятся, показываем круговой индикатор
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Если ошибка или нет курсов для выдачи
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('Нет доступных для выдачи курсов.');
                }

                // Когда данные загружены, показываем список
                final availableToEnroll = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableToEnroll.length,
                  itemBuilder: (context, index) {
                    final course = availableToEnroll[index];
                    return InkWell(
                      onTap: () async {
                        final confirmed = await _showConfirmationDialog(
                          title: 'Подтвердите действие',
                          content: 'Вы уверены, что хотите дать пользователю ${widget.user.name} доступ к курсу "${course.title}"?',
                        );
                        if (confirmed && mounted) {
                          Navigator.of(dialogContext).pop();
                          final adminViewModel = Provider.of<AdminViewModel>(context, listen: false);
                          await adminViewModel.grantCourseAccess(userId: widget.user.uid, courseId: course.id);
                          _refreshData();
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Row(children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              course.imageUrl.isNotEmpty 
                                ? course.imageUrl 
                                : 'https://placehold.co/100x100/E0E0E0/BDBDBD?text=No+Img',
                              width: 56, height: 56, fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 56, height: 56, color: Colors.grey.shade200,
                                child: const Icon(Icons.school_outlined, color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(course.author, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                            ],
                          )),
                        ]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Закрыть'))],
        );
      },
    );
  }

  void _revokeAccess(String courseId, String courseTitle) async {
    final confirmed = await _showConfirmationDialog(
      title: 'Подтвердите удаление',
      content: 'Вы уверены, что хотите отнять у пользователя ${widget.user.name} доступ к курсу "${courseTitle}"?',
    );

    if (confirmed) {
      final adminViewModel = Provider.of<AdminViewModel>(context, listen: false);
      await adminViewModel.revokeCourseAccess(userId: widget.user.uid, courseId: courseId);
      _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = '${widget.user.name} ${widget.user.surname}'.trim();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(displayName.isEmpty ? widget.user.email : displayName),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text('Профиль пользователя', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Имя: ${widget.user.name}'),
          Text('Фамилия: ${widget.user.surname}'),
          Text('Email: ${widget.user.email}'),
          Text('Роль: ${widget.user.role}'),
          const Divider(height: 40),
          Text('Записан на курсы:', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          FutureBuilder<List<EnrollmentDetail>>(
            key: ValueKey(_refreshKey),
            future: Provider.of<AdminViewModel>(context, listen: false).fetchUserEnrollments(widget.user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Ошибка загрузки курсов: ${snapshot.error}'));
              }
              final enrollmentDetails = snapshot.data ?? [];
              if (enrollmentDetails.isEmpty) {
                return const Text('Пользователь не записан ни на один курс.');
              }
              return Column(
                children: enrollmentDetails.map((detail) {
                  String subtitleText;
                  Color subtitleColor = Colors.green.shade700;
                  if (detail.enrollment.grantMethod == 'admin') {
                    subtitleText = 'Доступ выдан администратором';
                  } else if (detail.enrollment.activatedWithCode != null) {
                    subtitleText = 'Промокод: ${detail.enrollment.activatedWithCode}';
                  } else {
                    subtitleText = 'Способ получения неизвестен';
                    subtitleColor = Colors.grey;
                  }
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(detail.course.title),
                      subtitle: Text(
                        subtitleText,
                        style: TextStyle(color: subtitleColor, fontWeight: FontWeight.w500),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _revokeAccess(detail.course.id, detail.course.title),
                        tooltip: 'Отозвать доступ',
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'user_detail_fab',
        onPressed: _showGrantAccessDialog,
        tooltip: 'Выдать доступ к курсу',
        child: const Icon(Icons.add),
      ),
    );
  }
}