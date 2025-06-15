// lib/screens/test_history_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/mock_test_attempt_model.dart';
import '../models/mock_test_model.dart';
import '../models/question_model.dart';
import '../view_models/course_view_model.dart';
import 'mock_detailed_results_screen.dart';
import 'mock_test_player_screen.dart';

class TestHistoryScreen extends StatefulWidget {
  final MockTest test;
  const TestHistoryScreen({super.key, required this.test});

  @override
  State<TestHistoryScreen> createState() => _TestHistoryScreenState();
}

class _TestHistoryScreenState extends State<TestHistoryScreen> {
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    final courseViewModel = Provider.of<CourseViewModel>(context, listen: false);
    _dataFuture = Future.wait([
      courseViewModel.fetchAttemptsForMockTest(widget.test.id),
      courseViewModel.fetchQuestionsForMockTest(widget.test.id),
    ]).then((responses) => {
      'attempts': responses[0],
      'questions': responses[1],
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('История: ${widget.test.title}'),
        // --- ИЗМЕНЕНИЕ ЗДЕСЬ ---
        actions: [
          // Заменяем IconButton на TextButton со стилем
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(
                    builder: (context) => MockTestPlayerScreen(mockTest: widget.test),
                  ));
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.orangeAccent, // Задаем желто-оранжевый цвет
                ),
                child: const Text(
                  'Начать заново',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || (snapshot.data!['attempts'] as List).isEmpty) {
            return const Center(child: Text('Вы еще не проходили этот тест.'));
          }

          final attempts = snapshot.data!['attempts'] as List<MockTestAttempt>;
          final questions = snapshot.data!['questions'] as List<Question>;

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: attempts.length,
            itemBuilder: (context, index) {
              final attempt = attempts[index];
              final formattedDate = DateFormat('dd.MM.yyyy в HH:mm').format(attempt.completedAt.toDate());

              final userAnswers = (attempt.userAnswers).map((key, value) => MapEntry(int.parse(key), value as int));

              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text('Результат: ${attempt.score} из ${attempt.totalQuestions}'),
                  subtitle: Text('Пройден: $formattedDate'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => MockDetailedResultsScreen(
                        questions: questions,
                        userAnswers: userAnswers,
                      ),
                    ));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}