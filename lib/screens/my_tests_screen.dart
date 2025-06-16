import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/mock_test_model.dart';
import '../models/mock_test_attempt_model.dart';
import '../view_models/course_view_model.dart';
import '../widgets/test_card.dart';
import 'mock_test_player_screen.dart';
import 'ubt_welcome_screen.dart';
import 'ubt_result_detail_screen.dart';
import 'mock_detailed_results_screen.dart';

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

  // --- ВОТ НЕДОСТАЮЩИЕ МЕТОДЫ ---

  // Загружает все необходимые данные
  void _loadAllData() {
    final courseViewModel = Provider.of<CourseViewModel>(context, listen: false);
    // Оборачиваем в setState, чтобы FutureBuilder перестроился при обновлении
    setState(() {
      _dataFuture = Future.wait([
        courseViewModel.fetchMockTests(),
        courseViewModel.fetchAllMockTestAttempts(),
      ]).then((responses) => {
        'allTests': responses[0] as List<MockTest>,
        'allAttempts': responses[1] as List<MockTestAttempt>,
      });
    });
  }

  // Метод для обновления "потянув вниз"
  Future<void> _refresh() async {
    _loadAllData();
    // Ждем завершения нового Future, чтобы индикатор обновления исчез
    await _dataFuture;
  }

  // Обрабатывает нажатие на карточку из общего списка тестов
  void _handleTestTap(MockTest test) async {
    if (test.testType == MockTestType.ubt) {
      await Navigator.push(context, MaterialPageRoute(
        builder: (context) => UbtWelcomeScreen(ubtTest: test),
      ));
    } else {
      await Navigator.push(context, MaterialPageRoute(
        builder: (context) => MockTestPlayerScreen(mockTest: test),
      ));
    }
    _refresh(); // Обновляем данные после прохождения теста
  }

  // Обработчик нажатия на результат из списка "Нәтижелер"
  void _handleResultTap(MockTestAttempt attempt, List<MockTest> allTests) async {
    final courseViewModel = Provider.of<CourseViewModel>(context, listen: false);
    
    // Находим полную информацию о тесте, к которому относится эта попытка
    final testInfo = allTests.firstWhere((t) => t.id == attempt.testId, orElse: () => allTests.first);
    
    showDialog(context: context, builder: (context) => const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    
    try {
      if (testInfo.testType == MockTestType.ubt) {
        final subjectsWithQuestions = await courseViewModel.fetchUbtTestWithQuestions(attempt.testId);
        if (!mounted) return;
        Navigator.of(context).pop();

        Navigator.push(context, MaterialPageRoute(
          builder: (_) => UbtResultDetailScreen(
            attempt: attempt,
            subjects: subjectsWithQuestions,
          ),
        ));
      } else {
        final questions = await courseViewModel.fetchQuestionsForMockTest(attempt.testId);
        if (!mounted) return;
        Navigator.of(context).pop();

        Navigator.push(context, MaterialPageRoute(
          builder: (_) => MockDetailedResultsScreen(
            questions: questions,
            userAnswers: (attempt.userAnswers['main'] as Map<dynamic, dynamic>).map((key, value) => MapEntry(int.parse(key), value as int)),
          ),
        ));
      }
    } catch(e) {
      if (mounted) Navigator.of(context).pop();
      print("Ошибка при открытии результатов: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Тест'),
          actions: [IconButton(onPressed: (){}, icon: const Icon(Icons.search))],
          bottom: const TabBar(tabs: [
            Tab(text: 'Тест'),
            Tab(text: 'Нәтижелер'),
          ]),
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<Map<String, dynamic>>(
            future: _dataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) return Center(child: Text('Произошла ошибка: ${snapshot.error}'));
              if (!snapshot.hasData) return const Center(child: Text('Нет данных.'));

              final allTests = snapshot.data!['allTests'] as List<MockTest>;
              final allAttempts = snapshot.data!['allAttempts'] as List<MockTestAttempt>;
              
              return TabBarView(
                children: [
                  _buildAllTestsList(allTests),
                  _buildResultsList(allAttempts, allTests),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAllTestsList(List<MockTest> tests) {
    if (tests.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: const Center(child: Text('Пробных тестов пока нет.')),
          ),
        ),
      );
    }
    
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      itemCount: tests.length,
      itemBuilder: (context, index) {
        final test = tests[index];
        return TestCard(
          title: test.title,
          subject: test.subject,
          language: test.language,
          questionCount: test.questionCount,
          studentCount: 0, 
          isPassed: false,
          onTap: () => _handleTestTap(test),
        );
      },
    );
  }

  Widget _buildResultsList(List<MockTestAttempt> attempts, List<MockTest> allTests) {
    if (attempts.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: const Center(child: Text('Вы еще не завершили ни одного теста.')),
          ),
        ),
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      itemCount: attempts.length,
      itemBuilder: (context, index) {
        final attempt = attempts[index];
        final formattedDate = DateFormat('dd.MM.yyyy • HH:mm').format(attempt.completedAt.toDate());
        final score = '${attempt.score}/${attempt.totalQuestions}';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(attempt.testTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(formattedDate),
            trailing: Chip(
              label: Text(score, style: const TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            ),
            onTap: () => _handleResultTap(attempt, allTests),
          ),
        );
      },
    );
  }
}
