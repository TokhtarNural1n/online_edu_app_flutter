import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../models/mock_test_model.dart';
import '../models/question_model.dart';
import '../view_models/course_view_model.dart';
import 'mock_detailed_results_screen.dart';
import 'mock_test_player_screen.dart';

class MockTestResultsScreen extends StatefulWidget {
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

  @override
  State<MockTestResultsScreen> createState() => _MockTestResultsScreenState();
}

class _MockTestResultsScreenState extends State<MockTestResultsScreen> {
  @override
  void initState() {
    super.initState();
    // Сразу после открытия экрана сохраняем результат
    _saveAttempt();
  }

  void _saveAttempt() {
  Provider.of<CourseViewModel>(context, listen: false).saveMockTestAttempt(
    testId: widget.mockTest.id,
    testTitle: widget.mockTest.title,
    score: widget.score,
    totalQuestions: widget.totalQuestions,
    userAnswers: widget.userAnswers, // <-- ПЕРЕДАЕМ ОТВЕТЫ
  );
}

  @override
  Widget build(BuildContext context) {
    final double percentage = widget.totalQuestions > 0 ? (widget.score / widget.totalQuestions) * 100 : 0;
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
                      '${widget.score} из ${widget.totalQuestions}',
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
                      questions: widget.questions, userAnswers: widget.userAnswers,
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
                    builder: (context) => MockTestPlayerScreen(mockTest: widget.mockTest),
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

// --- Кастомный виджет для рисования индикатора ---
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