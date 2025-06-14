// lib/screens/course_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../models/content_item_model.dart';
import '../models/course_model.dart';
import '../models/lesson_model.dart';
import '../models/module_model.dart';
import '../view_models/course_view_model.dart';
import 'lesson_player_screen.dart';
import 'test_welcome_screen.dart';

// Вспомогательный класс для хранения информации о следующем уроке
class NextItemInfo {
  final ContentItem item;
  final Module module;
  NextItemInfo(this.item, this.module);
}

class CourseDetailScreen extends StatefulWidget {
  final Course course;
  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  bool _hideCompleted = false;
  late Future<Course> _courseDetailsFuture;
  late Future<Set<String>> _progressFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  void _loadData() {
    final courseViewModel = Provider.of<CourseViewModel>(context, listen: false);
    _courseDetailsFuture = courseViewModel.fetchCourseDetails(widget.course.id);
    _progressFuture = courseViewModel.fetchCompletedContentIds(widget.course.id);
  }

  // --- НОВЫЙ МЕТОД: Поиск следующего не пройденного элемента ---
  NextItemInfo? _findNextContentItem(Course course, Set<String> completedIds) {
    for (final module in course.modules) {
      for (final item in module.contentItems) {
        if (!completedIds.contains(item.id)) {
          // Найден первый не пройденный элемент
          return NextItemInfo(item, module);
        }
      }
    }
    // Если все пройдено, возвращаем null
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: Future.wait([_courseDetailsFuture, _progressFuture]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _buildErrorView();
          }

          final detailedCourse = snapshot.data![0] as Course;
          final completedIds = snapshot.data![1] as Set<String>;

          // --- НОВЫЙ КОД: Определяем следующий урок ---
          final nextItemInfo = _findNextContentItem(detailedCourse, completedIds);

          final visibleModules = _hideCompleted
            ? detailedCourse.modules.where((module) {
                final contentIds = module.contentItems.map((item) => item.id).toSet();
                return !completedIds.containsAll(contentIds);
              }).toList()
            : detailedCourse.modules;

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, detailedCourse),
              SliverToBoxAdapter(
                child: _buildCourseInfo(context, detailedCourse),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final module = visibleModules[index];
                    return _buildModuleTile(context, detailedCourse, module, completedIds);
                  },
                  childCount: visibleModules.length,
                ),
              ),
            ],
          );
        },
      ),
      // --- ИЗМЕНЕНИЕ: Передаем информацию о следующем уроке в кнопку ---
      bottomNavigationBar: FutureBuilder(
        future: Future.wait([_courseDetailsFuture, _progressFuture]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink(); // Не показывать кнопку, пока данные грузятся
          final detailedCourse = snapshot.data![0] as Course;
          final completedIds = snapshot.data![1] as Set<String>;
          final nextItemInfo = _findNextContentItem(detailedCourse, completedIds);
          return _buildBottomButton(context, nextItemInfo, detailedCourse);
        },
      )
    );
  }
  
  // --- Виджеты ниже (SliverAppBar, _buildCourseInfo и т.д.) остаются почти без изменений ---
  // ... (весь остальной код виджетов остается как в предыдущем ответе) ...
  // ... (Просто убедитесь, что вы скопировали все методы от _buildSliverAppBar до _buildErrorView)

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

  Widget _buildModuleTile(BuildContext context, Course course, Module module, Set<String> completedIds) {
    // --- НАЧАЛО ИЗМЕНЕНИЙ: Считаем количество элементов прямо здесь ---
    final lectureCount = module.contentItems.where((item) => item.type == ContentType.lesson).length;
    final testCount = module.contentItems.where((item) => item.type == ContentType.test).length;
    final fileCount = module.contentItems.where((item) => item.type == ContentType.material).length;
    // --- КОНЕЦ ИЗМЕНЕНИЙ ---

    final totalItems = module.contentItems.length;
    final completedItems = module.contentItems.where((item) => completedIds.contains(item.id)).length;
    final double progress = (totalItems > 0) ? (completedItems / totalItems) : 0.0;
    final progressPercentage = (progress * 100).toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          backgroundColor: Colors.blue.withOpacity(0.05),
          collapsedBackgroundColor: Colors.grey.shade100,
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(module.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    // --- ИЗМЕНЕНИЕ: Используем наши новые переменные для счетчиков ---
                    Text(
                      '$lectureCount лекция • $fileCount файла • $testCount тест',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    if (totalItems > 0)
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey.shade300,
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('$progressPercentage%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      )
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.play_arrow, color: Theme.of(context).primaryColor),
              ),
            ],
          ),
          trailing: const SizedBox.shrink(),
          children: List.generate(module.contentItems.length, (index) {
            final item = module.contentItems[index];
            final bool isCompleted = completedIds.contains(item.id);
            return _buildLessonTile(context, course, module, item, isCompleted, index + 1);
          }),
        ),
      ),
    );
  }
  
  Widget _buildLessonTile(BuildContext context, Course course, Module module, ContentItem item, bool isCompleted, int lessonNumber) {
    IconData iconData;
    Color iconColor;
    if(isCompleted) {
      iconData = Icons.check_circle;
      iconColor = Colors.green;
    } else {
      iconData = item.type == ContentType.lesson ? Icons.play_circle_outline : Icons.list_alt_outlined;
      iconColor = Theme.of(context).primaryColor;
    }
    return Material(
      color: Colors.blue.withOpacity(0.05),
      child: InkWell(
        onTap: () async {
          if (item.type == ContentType.lesson) {
            final videoId = YoutubePlayer.convertUrlToId(item.videoUrl ?? '');
            if (videoId != null && videoId.isNotEmpty) {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => LessonPlayerScreen(lesson: Lesson.fromContentItem(item), courseId: course.id)));
              setState(() { _loadData(); });
            }
          } else if (item.type == ContentType.test) {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => TestWelcomeScreen(courseId: course.id, moduleId: module.id, testItem: item)));
            setState(() { _loadData(); });
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(children: [
            Icon(iconData, color: iconColor),
            const SizedBox(width: 16),
            Expanded(child: Text('${lessonNumber}. ${item.title}')),
            if (item.duration != null) Text(item.duration!, style: const TextStyle(color: Colors.grey)),
          ]),
        ),
      ),
    );
  }

  Widget _buildErrorView() => const Center(child: Text("Ошибка: Не удалось загрузить данные курса."));

  // --- ИЗМЕНЕННЫЙ МЕТОД ДЛЯ НИЖНЕЙ КНОПКИ ---
  Widget _buildBottomButton(BuildContext context, NextItemInfo? nextItemInfo, Course course) {
    final bool isCourseCompleted = nextItemInfo == null;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: ElevatedButton(
        // Кнопка неактивна, если курс пройден
        onPressed: isCourseCompleted ? null : () async {
          final item = nextItemInfo.item;
          final module = nextItemInfo.module;
          
          if (item.type == ContentType.lesson) {
            final videoId = YoutubePlayer.convertUrlToId(item.videoUrl ?? '');
            if (videoId != null && videoId.isNotEmpty) {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => LessonPlayerScreen(lesson: Lesson.fromContentItem(item), courseId: course.id)));
              setState(() { _loadData(); });
            }
          } else if (item.type == ContentType.test) {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => TestWelcomeScreen(courseId: course.id, moduleId: module.id, testItem: item)));
            setState(() { _loadData(); });
          }
        },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        // Текст на кнопке меняется, если курс пройден
        child: Text(
          isCourseCompleted ? 'Курс пройден' : 'Продолжить урок', 
          style: const TextStyle(fontSize: 16)
        ),
      ),
    );
  }
}