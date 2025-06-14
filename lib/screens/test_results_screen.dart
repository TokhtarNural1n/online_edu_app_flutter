// lib/screens/test_results_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <-- Добавляем импорт
import 'dart:math';

import '../models/content_item_model.dart';
import '../models/question_model.dart';
import '../view_models/course_view_model.dart'; // <-- Добавляем импорт
import 'detailed_results_screen.dart';
import 'test_welcome_screen.dart';

// 1. Превращаем виджет в StatefulWidget
class TestResultsScreen extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final List<Question> questions;
  final Map<int, int> userAnswers;
  final ContentItem testItem;
  final String courseId;
  final String moduleId;

  const TestResultsScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.questions,
    required this.userAnswers,
    required this.testItem,
    required this.courseId,
    required this.moduleId,
  });

  @override
  State<TestResultsScreen> createState() => _TestResultsScreenState();
}

class _TestResultsScreenState extends State<TestResultsScreen> {
  @override
  void initState() {
    super.initState();
    // Вызываем метод сохранения прогресса при первом открытии экрана
    _saveProgressIfNeeded();
  }

  // 2. Создаем метод, который проверяет балл и сохраняет прогресс
  void _saveProgressIfNeeded() {
    final double percentage = widget.totalQuestions > 0
        ? (widget.score / widget.totalQuestions) * 100
        : 0;
    final bool hasPassed = percentage >= (widget.testItem.passingPercentage ?? 50);

    // Если пользователь набрал проходной балл, отмечаем тест как пройденный
    if (hasPassed) {
      Provider.of<CourseViewModel>(context, listen: false)
          .markContentAsCompleted(widget.courseId, widget.testItem.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 3. Вся логика отображения теперь использует `widget.` для доступа к данным
    final double percentage = widget.totalQuestions > 0
        ? (widget.score / widget.totalQuestions) * 100
        : 0;
    final bool hasPassed = percentage >= (widget.testItem.passingPercentage ?? 50);
    final Color progressColor = hasPassed ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Завершение теста'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: CustomPaint(
                  painter: ResultGaugePainter(
                    percentage: percentage,
                    color: progressColor,
                  ),
                  child: Center(
                    child: Text(
                      '${widget.score} из ${widget.totalQuestions}',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                hasPassed
                    ? 'Поздравляем! Вы прошли тест.'
                    : 'У вас меньше ${widget.testItem.passingPercentage ?? 50}% правильных ответов.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (!hasPassed)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Вам нужно заново пройти тест.',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailedResultsScreen(
                        questions: widget.questions,
                        userAnswers: widget.userAnswers,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: progressColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Результаты'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TestWelcomeScreen(
                        testItem: widget.testItem,
                        courseId: widget.courseId,
                        moduleId: widget.moduleId,
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Пройти заново'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('На главную'),
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