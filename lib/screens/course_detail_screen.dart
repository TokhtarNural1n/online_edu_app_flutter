// lib/screens/course_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/content_item_model.dart';
import '../models/course_model.dart';
import '../models/lesson_model.dart';
import '../models/module_model.dart';
import '../view_models/course_view_model.dart';
import 'lesson_player_screen.dart';
import 'material_detail_screen.dart';
import 'test_welcome_screen.dart';
import 'subscription_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;
  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class NextItemInfo {
  final ContentItem item;
  final Module module;
  NextItemInfo(this.item, this.module);
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final courseViewModel = Provider.of<CourseViewModel>(context, listen: false);
    // Используем вашу новую функцию для загрузки всех данных, включая статус подписки
    setState(() {
      _dataFuture = _fetchAllData(courseViewModel);
    });
  }

  // --- НОВАЯ, УЛУЧШЕННАЯ ЛОГИКА ОПРЕДЕЛЕНИЯ ЗАБЛОКИРОВАННЫХ УРОКОВ ---
  Set<String> _getLockedItemIds(Course course, Set<String> completedIds) {
    final lockedIds = <String>{};
    bool lockEngaged = false;

    // Проходим по всем урокам всех модулей один раз
    for (final module in course.modules) {
      for (final item in module.contentItems) {
        // Если блокировка уже включена, добавляем ID урока в список заблокированных
        if (lockEngaged) {
          lockedIds.add(item.id);
          continue;
        }

        // Проверяем, нужно ли включить блокировку
        // Условие: (глобальная настройка включена ИЛИ это индивидуальный стоп-урок) И (урок не пройден)
        final bool isStopCondition = (course.areLessonsSequential || item.isStopLesson) && !completedIds.contains(item.id);

        // Блокируем, только если это не простой материал (их можно смотреть всегда)
        if (isStopCondition && item.type != ContentType.material) {
          lockEngaged = true;
        }
      }
    }
    return lockedIds;
  }

  NextItemInfo? _findNextContentItem(Course course, Set<String> completedIds) {
    for (final module in course.modules) {
      for (final item in module.contentItems) {
        if (item.type != ContentType.material && !completedIds.contains(item.id)) {
          return NextItemInfo(item, module);
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return CustomScrollView(slivers: [
              _buildSliverAppBar(context, widget.course),
              SliverToBoxAdapter(child: _buildNoAccessContent(context))
            ]);
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("Нет данных о курсе."));
          }

          final detailedCourse = snapshot.data!['course'] as Course;
          final completedIds = snapshot.data!['progress'] as Set<String>;
          final isEnrolled = snapshot.data!['isEnrolled'] as bool;
          // Вычисляем список заблокированных уроков
          final lockedItemIds = _getLockedItemIds(detailedCourse, completedIds);
          final nextItemInfo = _findNextContentItem(detailedCourse, completedIds);

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, detailedCourse),
              SliverToBoxAdapter(child: _buildCourseInfo(context, detailedCourse)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final module = detailedCourse.modules[index];
                    // ---> ИЗМЕНЕНИЕ: Передаем isEnrolled в виджет модуля
                    return _buildModuleTile(context, detailedCourse, module, completedIds, lockedItemIds, isEnrolled);
                  },
                  childCount: detailedCourse.modules.length,
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: FutureBuilder<Map<String, dynamic>>(
         future: _dataFuture,
         builder: (context, snapshot) {
           if (!snapshot.hasData || snapshot.hasError) return const SizedBox.shrink();
            final detailedCourse = snapshot.data!['course'] as Course;
            final completedIds = snapshot.data!['progress'] as Set<String>;
            // ---> НОВОЕ: Получаем статус подписки
            final isEnrolled = snapshot.data!['isEnrolled'] as bool;
            final nextItemInfo = _findNextContentItem(detailedCourse, completedIds);
           // ---> ИЗМЕНЕНИЕ: Передаем isEnrolled в кнопку
           return _buildBottomButton(context, nextItemInfo, detailedCourse, completedIds, isEnrolled);
         }
      ),
    );
  }

  // (Метод _buildSliverAppBar остается без изменений)
  SliverAppBar _buildSliverAppBar(BuildContext context, Course course) {
    return SliverAppBar(
      expandedHeight: 220.0, pinned: true, stretch: true,
      backgroundColor: Colors.grey.shade800,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        background: Image.network(course.imageUrl, fit: BoxFit.cover, color: Colors.black.withOpacity(0.5), colorBlendMode: BlendMode.darken),
      ),
    );
  }


  Widget _buildCourseInfo(BuildContext context, Course course) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(course.category.toUpperCase(), style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(course.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text('${course.totalDurationMinutes} мин.'),
            const SizedBox(width: 16),
            const Icon(Icons.star, size: 16, color: Colors.orange),
            const SizedBox(width: 4),
            Text('${course.rating} (${course.reviewCount} отзывов)'),
          ]),
          const Divider(height: 32),
          const Text('Программа курса', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildModuleTile(BuildContext context, Course course, Module module, Set<String> completedIds, Set<String> lockedIds, bool isEnrolled) {
    // (Логика подсчета прогресса остается без изменений)
    final trackableItems = module.contentItems.where((item) => item.type != ContentType.material).toList();
    final lectureCount = trackableItems.where((item) => item.type == ContentType.lesson).length;
    final testCount = trackableItems.where((item) => item.type == ContentType.test).length;
    final fileCount = module.contentItems.where((item) => item.type == ContentType.material).length;

    final totalTrackableItems = trackableItems.length;
    final completedItems = trackableItems.where((item) => completedIds.contains(item.id)).length;
    final double progress = (totalTrackableItems > 0) ? (completedItems / totalTrackableItems) : 0.0;
    final progressPercentage = (progress * 100).toInt();

    // Проверяем, заблокирован ли весь модуль (заблокирован первый элемент в нем)
    final isModuleLocked = !isEnrolled ? false : module.contentItems.isNotEmpty && lockedIds.contains(module.contentItems.first.id);

    return Opacity(
      opacity: isModuleLocked ? 0.5 : 1.0, // Делаем весь модуль полупрозрачным, если он заблокирован
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ExpansionTile(
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.04),
            collapsedBackgroundColor: Theme.of(context).cardColor,
            trailing: isModuleLocked ? const Icon(Icons.lock) : null,
            title: Row(children: [
               Expanded(child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(module.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                   const SizedBox(height: 4),
                   Text('$lectureCount лекция • $fileCount файла • $testCount тест', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                   const SizedBox(height: 8),
                   if (totalTrackableItems > 0)
                     Row(children: [
                       Expanded(child: LinearProgressIndicator(value: progress, backgroundColor: Colors.grey.shade300, minHeight: 6, borderRadius: BorderRadius.circular(3))),
                       const SizedBox(width: 8),
                       Text('$progressPercentage%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                     ])
                 ],
               )),
            ]),
            children: List.generate(module.contentItems.length, (index) {
              final item = module.contentItems[index];
              final isCompleted = completedIds.contains(item.id);
              final isLocked = lockedIds.contains(item.id); // Проверяем, заблокирован ли конкретный урок
              return _buildLessonTile(context, course, module, item, isCompleted, index + 1, isLocked, isEnrolled);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildLessonTile(BuildContext context, Course course, Module module, ContentItem item, bool isCompleted, int lessonNumber, bool isLocked, bool isEnrolled) {
    IconData iconData;
    Color iconColor;
    Color tileColor = Theme.of(context).primaryColor.withOpacity(0.05);

    final bool isContentLocked = !isEnrolled || isLocked;

    if (!isEnrolled) {
      // Состояние для НЕ ПОДПИСАННОГО пользователя
      iconData = Icons.lock_outline;
      iconColor = Colors.grey.shade500;
      tileColor = Colors.grey.withOpacity(0.08);
    } else if (isLocked) {
      // Состояние для ПОДПИСАННОГО, но урок заблокирован последовательностью
      iconData = Icons.lock_outline;
      iconColor = Colors.grey.shade500;
      tileColor = Colors.grey.withOpacity(0.08);
    } else if (isCompleted) {
      // Урок пройден
      iconData = Icons.check_circle;
      iconColor = Colors.green;
    } else {
      // Урок доступен
      switch (item.type) {
        case ContentType.lesson: iconData = Icons.play_circle_outline; break;
        case ContentType.test: iconData = Icons.list_alt_outlined; break;
        case ContentType.material: iconData = Icons.description_outlined; break;
        default: iconData = Icons.help_outline; break;
      }
      iconColor = Theme.of(context).primaryColor;
    }

    return Material(
      color: tileColor,
      child: InkWell(
        onTap: () {
          if (!isEnrolled) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Чтобы получить доступ, приобретите курс.')),
            );
            return; // Выходим, если не подписан
          }
          
          if (isLocked) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Сначала пройдите предыдущие уроки.')),
            );
            return; // Выходим, если урок заблокирован последовательностью
          }
          
          // Логика перехода на экран урока/теста/материала
          _navigateToContent(item, course, module);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(children: [
            Icon(iconData, color: iconColor),
            const SizedBox(width: 16),
            Expanded(child: Text(
              '${lessonNumber}. ${item.title}',
              style: TextStyle(color: isContentLocked ? Colors.grey.shade600 : null),
            )),
            if (item.duration != null)
              Text(
                item.duration!,
                style: TextStyle(color: isContentLocked ? Colors.grey.shade600 : Colors.grey)
              ),
          ]),
        ),
      ),
    );
  }

  void _navigateToContent(ContentItem item, Course course, Module module) async {
  if (item.type == ContentType.lesson) {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => LessonPlayerScreen(lesson: Lesson.fromContentItem(item), courseId: course.id)));
  } else if (item.type == ContentType.test) {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => TestWelcomeScreen(courseId: course.id, moduleId: module.id, testItem: item)));
  } else if (item.type == ContentType.material) {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => MaterialDetailScreen(materialItem: item)));
  }
  _loadData(); // Обновляем данные после возврата с любого экрана
}

  Widget _buildBottomButton(BuildContext context, NextItemInfo? nextItemInfo, Course course, Set<String> completedIds, bool isEnrolled) {
    // ---> НОВОЕ: Логика для НЕ ПОДПИСАННОГО пользователя
    if (!isEnrolled) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton(
          onPressed: () {
            // Переходим на новый экран подписки и передаем туда информацию о курсе
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SubscriptionScreen(course: widget.course),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          // ---> Текст для не подписанных
          child: const Text('Курсқа тіркелу', style: TextStyle(fontSize: 16)),
        ),
      );
    }

    // --- Старая логика для ПОДПИСАННЫХ пользователей остается ниже ---

    if (nextItemInfo == null) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.green),
          child: const Text('Курс пройден', style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
      );
    }

    final lockedIds = _getLockedItemIds(course, completedIds);
    final isNextItemLocked = lockedIds.contains(nextItemInfo.item.id);

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: ElevatedButton(
        onPressed: isNextItemLocked ? null : () {
          // Используем новый вспомогательный метод для навигации
          _navigateToContent(nextItemInfo.item, course, nextItemInfo.module);
        },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        child: Text(isNextItemLocked ? 'Сначала пройдите стоп-урок' : 'Продолжить урок', style: const TextStyle(fontSize: 16)),
      ),
    );
  }


  // (Метод _buildNoAccessContent остается без изменений)
    Widget _buildNoAccessContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 64.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.lock_outline_rounded, size: 90, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          Text('Доступ к материалам курса закрыт', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text('Чтобы просматривать уроки и проходить тесты, вам необходимо приобрести этот курс.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey.shade700, height: 1.5)),
          const SizedBox(height: 48),
          ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('Приобрести курс')),
        ],
      ),
    );
  }
  Future<Map<String, dynamic>> _fetchAllData(CourseViewModel viewModel) async {
    final courseId = widget.course.id;
    // Загружаем все 3 типа данных параллельно
    final results = await Future.wait([
      viewModel.fetchCourseDetails(courseId),
      viewModel.fetchCompletedContentIds(courseId),
      viewModel.isEnrolledInCourse(courseId), // <-- Добавлена загрузка статуса подписки
    ]);
    
    // Возвращаем результат в виде карты (словаря)
    return {
      'course': results[0] as Course,
      'progress': results[1] as Set<String>,
      'isEnrolled': results[2] as bool, // <-- Добавлен результат в карту
    };
  }
}