// lib/screens/courses_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/subject_model.dart'; // <-- Наша новая модель
import '../view_models/course_view_model.dart';
import 'courses_by_subject_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  late Future<List<Subject>> _subjectsFuture;
  int _selectedChipIndex = 0;

  @override
  void initState() {
    super.initState();
    // Загружаем список предметов при открытии экрана
    _subjectsFuture = Provider.of<CourseViewModel>(context, listen: false).fetchSubjects();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> filterChips = ['Курсы', 'Кітаптар', 'Набор'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Курсы'),
      ),
      body: Column(
        children: [
          // --- Блок с фильтрами-чипами ---
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              itemCount: filterChips.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(filterChips[index]),
                    selected: _selectedChipIndex == index,
                    onSelected: (selected) {
                      setState(() {
                        _selectedChipIndex = selected ? index : 0;
                      });
                    },
                    selectedColor: Theme.of(context).primaryColor,
                    labelStyle: TextStyle(
                      color: _selectedChipIndex == index ? Colors.white : Colors.black,
                    ),
                    backgroundColor: Colors.grey.shade200,
                    shape: StadiumBorder(side: BorderSide(color: Colors.grey.shade300)),
                  ),
                );
              },
            ),
          ),

          // --- Сетка с предметами ---
          Expanded(
            child: FutureBuilder<List<Subject>>(
              future: _subjectsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Ошибка загрузки: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Предметы не найдены."));
                }

                final subjects = snapshot.data!;
                return GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,       // Две колонки
                    crossAxisSpacing: 16,    // Отступ по горизонтали
                    mainAxisSpacing: 16,     // Отступ по вертикали
                    childAspectRatio: 0.8,   // Соотношение сторон карточки
                  ),
                  itemCount: subjects.length,
                  itemBuilder: (context, index) {
                    return _buildSubjectCard(context, subjects[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Вспомогательный виджет для создания карточки предмета
   Widget _buildSubjectCard(BuildContext context, Subject subject) {
    // --- ИЗМЕНЕНИЕ ЗДЕСЬ ---
    // Собираем полный путь к локальному изображению
    final String assetPath = 'assets/images/${subject.imageUrl}';

    return GestureDetector(
      onTap: () {
        // --- ИЗМЕНЕНИЕ ЗДЕСЬ: Переходим на новый экран ---
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CoursesBySubjectScreen(subject: subject),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                // Заменяем CachedNetworkImage на Image.asset
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.cover,
                  // Добавляем обработчик ошибок на случай, если файл не найден
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Icon(Icons.image_not_supported, color: Colors.grey));
                  },
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Text(
                subject.name,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}