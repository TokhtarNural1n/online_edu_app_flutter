// lib/screens/test_player_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/content_item_model.dart';
import '../models/question_model.dart';
import '../view_models/course_view_model.dart';
import 'test_results_screen.dart';

class TestPlayerScreen extends StatefulWidget {
  final String courseId;
  final String moduleId;
  final ContentItem testItem;

  const TestPlayerScreen({
    super.key,
    required this.courseId,
    required this.moduleId,
    required this.testItem,
  });

  @override
  State<TestPlayerScreen> createState() => _TestPlayerScreenState();
}

class _TestPlayerScreenState extends State<TestPlayerScreen> {
  late Future<List<Question>> _questionsFuture;
  int _currentQuestionIndex = 0;
  final Map<int, int> _userAnswers = {};

  Timer? _timer;
  Duration? _remainingTime;

  @override
  void initState() {
    super.initState();
    _questionsFuture = Provider.of<CourseViewModel>(context, listen: false)
        .fetchTestQuestions(
      courseId: widget.courseId,
      moduleId: widget.moduleId,
      testId: widget.testItem.id,
    );
    _startTimer();
  }

  void _startTimer() {
    if (widget.testItem.timeLimitMinutes != null) {
      _remainingTime = Duration(minutes: widget.testItem.timeLimitMinutes!);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingTime!.inSeconds <= 0) {
          timer.cancel();
          _finishTest();
        } else {
          if (mounted) {
            setState(() {
              _remainingTime = Duration(seconds: _remainingTime!.inSeconds - 1);
            });
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- НОВЫЙ МЕТОД: для перехода к предыдущему вопросу ---
  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _handleNext(int totalQuestions) {
    if (_currentQuestionIndex < totalQuestions - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _finishTest();
    }
  }

  void _finishTest() {
    _timer?.cancel();
    _questionsFuture.then((questions) {
      int score = 0;
      for (int i = 0; i < questions.length; i++) {
        if (_userAnswers.containsKey(i) &&
            questions[i].options[_userAnswers[i]!].isCorrect) {
          score++;
        }
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TestResultsScreen(
            score: score,
            totalQuestions: questions.length,
            questions: questions,
            userAnswers: _userAnswers,
            testItem: widget.testItem,
            courseId: widget.courseId,
            moduleId: widget.moduleId,
          ),
        ),
      );
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.testItem.title, style: const TextStyle(fontSize: 16)),
        actions: [
          if (_remainingTime != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Chip(
                avatar: const Icon(Icons.timer_outlined, size: 18, color: Colors.white),
                label: Text(
                  _formatDuration(_remainingTime!),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.green,
              ),
            ),
        ],
      ),
      body: FutureBuilder<List<Question>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Не удалось загрузить вопросы.'));
          }

          final questions = snapshot.data!;
          final currentQuestion = questions[_currentQuestionIndex];
          final bool isLastQuestion = _currentQuestionIndex == questions.length - 1;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Вопрос ${_currentQuestionIndex + 1} из ${questions.length}',
                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        currentQuestion.questionText,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (currentQuestion.imageUrl != null && currentQuestion.imageUrl!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 250),
                                child: Image.network(currentQuestion.imageUrl!),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      ...List.generate(currentQuestion.options.length, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          decoration: BoxDecoration(
                            color: _userAnswers[_currentQuestionIndex] == index
                                ? Theme.of(context).primaryColor.withOpacity(0.1)
                                : null,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _userAnswers[_currentQuestionIndex] == index
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade300,
                            ),
                          ),
                          child: RadioListTile<int>(
                            title: Text(currentQuestion.options[index].text),
                            value: index,
                            groupValue: _userAnswers[_currentQuestionIndex],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _userAnswers[_currentQuestionIndex] = value;
                                });
                              }
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              // --- ОБНОВЛЕННЫЙ БЛОК НАВИГАЦИИ ---
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Кнопка "Назад"
                    OutlinedButton(
                      // Кнопка неактивна на первом вопросе
                      onPressed: _currentQuestionIndex == 0 ? null : _previousQuestion,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Назад'),
                    ),
                    // Кнопка "Далее" или "Завершить"
                    ElevatedButton(
                      onPressed: () => _handleNext(questions.length),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        backgroundColor: isLastQuestion ? Colors.green : null,
                      ),
                      child: Text(isLastQuestion ? 'Завершить тест' : 'Следующий вопрос'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}