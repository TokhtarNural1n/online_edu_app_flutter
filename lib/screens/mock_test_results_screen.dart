import 'package:flutter/material.dart';
import 'dart:math';

import '../models/mock_test_model.dart';
import '../models/question_model.dart'; 
import 'mock_detailed_results_screen.dart';
import 'mock_test_player_screen.dart';

// --- ИЗМЕНЕНИЕ: Возвращаем виджет к простому StatelessWidget ---
class MockTestResultsScreen extends StatelessWidget {
  final MockTest mockTest;
  final int score;
  final int totalQuestions;
  final List<Question> questions;
  final Map<int, int> userAnswers;

  const MockTestResultsScreen({
    super.key,
    required this.mockTest,
    required this.score,
    required this.totalQuestions,
    required this.questions,
    required this.userAnswers,
  });

  // --- МЕТОДЫ initState() и _saveAttempt() ПОЛНОСТЬЮ УДАЛЕНЫ ---

  @override
  Widget build(BuildContext context) {
    final double percentage = totalQuestions > 0 ? (score / totalQuestions) * 100 : 0;
    final Color progressColor = percentage >= 50 ? Colors.green : Colors.orange;

    return Scaffold(
      appBar: AppBar(title: const Text('Результаты теста'), automaticallyImplyLeading: false),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Тест завершен!', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 32),
              SizedBox(
                width: 150,
                height: 150,
                child: CustomPaint(
                  painter: ResultGaugePainter(percentage: percentage, color: progressColor),
                  child: Center(
                    child: Text(
                      '$score из $totalQuestions',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => MockDetailedResultsScreen(
                      questions: questions, userAnswers: userAnswers,
                    ),
                  ));
                },
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: progressColor, foregroundColor: Colors.white),
                child: const Text('Посмотреть ответы'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(
                    builder: (context) => MockTestPlayerScreen(mockTest: mockTest),
                  ));
                },
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text('Пройти заново'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('К списку тестов'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Класс для рисования индикатора остается без изменений
class ResultGaugePainter extends CustomPainter {
  final double percentage;
  final Color color;

  ResultGaugePainter({required this.percentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    Paint backgroundPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    Paint progressPaint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const startAngle = -pi / 2;
    final sweepAngle = 2 * pi * (percentage / 100);

    canvas.drawCircle(center, radius, backgroundPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
