import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/content_item_model.dart';
import '../models/course_model.dart';
import '../models/lesson_model.dart';
import '../models/module_model.dart';
import '../view_models/course_view_model.dart';
import 'lesson_player_screen.dart';
import 'material_detail_screen.dart';
import 'test_welcome_screen.dart';

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
  // Переключатель удален
  // bool _hideCompleted = false; 
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

  NextItemInfo? _findNextContentItem(Course course, Set<String> completedIds) {
    for (final module in course.modules) {
      // Ищем следующий не пройденный урок или тест, игнорируя материалы
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
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, widget.course),
          FutureBuilder(
            future: Future.wait([_courseDetailsFuture, _progressFuture]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasError) {
                return SliverToBoxAdapter(child: _buildNoAccessContent(context));
              }
              if (!snapshot.hasData) {
                return const SliverFillRemaining(child: Center(child: Text("Нет данных о курсе.")));
              }

              final detailedCourse = snapshot.data![0] as Course;
              final completedIds = snapshot.data![1] as Set<String>;

              // Логика фильтрации удалена
              final visibleModules = detailedCourse.modules;

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == 0) {
                      return _buildCourseInfo(context, detailedCourse);
                    }
                    final module = visibleModules[index - 1];
                    return _buildModuleTile(context, detailedCourse, module, completedIds);
                  },
                  childCount: visibleModules.length + 1,
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: FutureBuilder(
        future: Future.wait([_courseDetailsFuture, _progressFuture]),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.hasError) return const SizedBox.shrink();
          final detailedCourse = snapshot.data![0] as Course;
          final completedIds = snapshot.data![1] as Set<String>;
          final nextItemInfo = _findNextContentItem(detailedCourse, completedIds);
          return _buildBottomButton(context, nextItemInfo, detailedCourse);
        },
      ),
    );
  }

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
          // --- Переключатель "Скрыть пройденные" удален ---
        ],
      ),
    );
  }

  Widget _buildModuleTile(BuildContext context, Course course, Module module, Set<String> completedIds) {
    // --- ИЗМЕНЕНИЕ: Считаем прогресс только по лекциям и тестам ---
    final trackableItems = module.contentItems.where((item) => item.type != ContentType.material).toList();
    final lectureCount = trackableItems.where((item) => item.type == ContentType.lesson).length;
    final testCount = trackableItems.where((item) => item.type == ContentType.test).length;
    final fileCount = module.contentItems.where((item) => item.type == ContentType.material).length; // Файлы просто считаем для отображения

    final totalTrackableItems = trackableItems.length;
    final completedItems = trackableItems.where((item) => completedIds.contains(item.id)).length;
    final double progress = (totalTrackableItems > 0) ? (completedItems / totalTrackableItems) : 0.0;
    final progressPercentage = (progress * 100).toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ExpansionTile(
          // ... стили ExpansionTile
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
            // ... иконка "play"
          ]),
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

    if (isCompleted) {
      iconData = Icons.check_circle;
      iconColor = Colors.green;
    } else {
      switch (item.type) {
        case ContentType.lesson: iconData = Icons.play_circle_outline; break;
        case ContentType.test: iconData = Icons.list_alt_outlined; break;
        case ContentType.material: iconData = Icons.description_outlined; break;
        default: iconData = Icons.help_outline; break;
      }
      iconColor = Theme.of(context).primaryColor;
    }

    return Material(
      color: Theme.of(context).primaryColor.withOpacity(0.05),
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
          } else if (item.type == ContentType.material) {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => MaterialDetailScreen(materialItem: item)));
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

  Widget _buildBottomButton(BuildContext context, NextItemInfo? nextItemInfo, Course course) {
    final bool isCourseCompleted = nextItemInfo == null;
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: ElevatedButton(
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
        child: Text(isCourseCompleted ? 'Курс пройден' : 'Продолжить урок', style: const TextStyle(fontSize: 16)),
      ),
    );
  }

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
}