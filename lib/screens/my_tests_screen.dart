// lib/screens/my_tests_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mock_test_model.dart';
import '../view_models/course_view_model.dart';
import '../widgets/test_card.dart';
import 'mock_test_player_screen.dart';
import 'test_history_screen.dart';

class MyTestsScreen extends StatefulWidget {
  const MyTestsScreen({super.key});

  @override
  State<MyTestsScreen> createState() => _MyTestsScreenState();
}

class _MyTestsScreenState extends State<MyTestsScreen> {
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  // Загружает все необходимые данные
  void _loadAllData() {
    final courseViewModel = Provider.of<CourseViewModel>(context, listen: false);
    _dataFuture = Future.wait([
      courseViewModel.fetchMockTests(),
      courseViewModel.fetchAttemptedMockTestIds(),
    ]).then((responses) => {
      'allTests': responses[0],
      'attemptedIds': responses[1],
    });
  }

  // Обрабатывает нажатие на карточку теста
  void _handleTestTap(MockTest test, bool isCompleted) async {
    if (isCompleted) {
      // Если тест пройден, показываем историю
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TestHistoryScreen(test: test),
        ),
      );
    } else {
      // Если тест новый, запускаем его прохождение
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MockTestPlayerScreen(mockTest: test),
        ),
      );
      // После возвращения с экрана теста, обновляем список
      setState(() {
        _loadAllData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Пробные тесты'),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Новые'),
              Tab(text: 'Завершенные'),
            ],
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
          ),
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Произошла ошибка: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: Text('Тестов пока нет.'));
            }

            final allTests = snapshot.data!['allTests'] as List<MockTest>;
            final attemptedTestIds = snapshot.data!['attemptedIds'] as Set<String>;

            final newTests = allTests.where((test) => !attemptedTestIds.contains(test.id)).toList();
            final completedTests = allTests.where((test) => attemptedTestIds.contains(test.id)).toList();

            return TabBarView(
              children: [
                _buildTestsList(
                  tests: newTests,
                  attemptedIds: attemptedTestIds,
                  emptyMessage: 'Новых тестов нет. Вы молодец!',
                ),
                _buildTestsList(
                  tests: completedTests,
                  attemptedIds: attemptedTestIds,
                  emptyMessage: 'Вы еще не завершили ни одного теста.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- ВОТ НЕДОСТАЮЩИЙ МЕТОД ---
  Widget _buildTestsList({
    required List<MockTest> tests,
    required Set<String> attemptedIds,
    String? emptyMessage,
  }) {
    if (tests.isEmpty) {
      return Center(child: Text(emptyMessage ?? 'Нет тестов в этой категории.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: tests.length,
      itemBuilder: (context, index) {
        final test = tests[index];
        final bool isCompleted = attemptedIds.contains(test.id);
        return TestCard(
          title: test.title,
          subject: test.subject,
          language: test.language,
          questionCount: test.questionCount,
          studentCount: 0, 
          isPassed: isCompleted,
          onTap: () => _handleTestTap(test, isCompleted),
        );
      },
    );
  }
}