// lib/screens/mock_test_player_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/mock_test_model.dart';
import '../models/question_model.dart';
import '../view_models/course_view_model.dart';
import 'mock_test_results_screen.dart';

class MockTestPlayerScreen extends StatefulWidget {
  final MockTest mockTest;
  const MockTestPlayerScreen({super.key, required this.mockTest});

  @override
  State<MockTestPlayerScreen> createState() => _MockTestPlayerScreenState();
}

class _MockTestPlayerScreenState extends State<MockTestPlayerScreen> {
  late Future<List<Question>> _questionsFuture;
  int _currentQuestionIndex = 0;
  final Map<int, int> _userAnswers = {};

  // --- Поля для таймера ---
  Timer? _timer;
  Duration? _remainingTime;

  @override
  void initState() {
    super.initState();
    _questionsFuture = Provider.of<CourseViewModel>(context, listen: false)
        .fetchQuestionsForMockTest(widget.mockTest.id);
    _startTimer();
  }

  void _startTimer() {
    // Убеждаемся, что лимит времени > 0
    if (widget.mockTest.timeLimitMinutes > 0) {
      _remainingTime = Duration(minutes: widget.mockTest.timeLimitMinutes);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_remainingTime!.inSeconds <= 0) {
          timer.cancel();
          _finishTest();
        } else {
          setState(() {
            _remainingTime = Duration(seconds: _remainingTime!.inSeconds - 1);
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- Метод для подтверждения выхода ---
  Future<bool> _onWillPop() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: const Text('Вы уверены, что хотите выйти? Ваш прогресс будет сброшен.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Остаться'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

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
    _timer?.cancel(); // Останавливаем таймер при завершении
    _questionsFuture.then((questions) {
      int score = 0;
      for (int i = 0; i < questions.length; i++) {
        if (_userAnswers.containsKey(i) &&
            questions[i].options[_userAnswers[i]!].isCorrect) {
          score++;
        }
      }
      Provider.of<CourseViewModel>(context, listen: false).saveMockTestAttempt(
        testId: widget.mockTest.id,
        testTitle: widget.mockTest.title,
        score: score,
        totalQuestions: questions.length,
        userAnswers: {'main': _userAnswers}, // Оборачиваем в Map с ключом 'main'
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MockTestResultsScreen(
            mockTest: widget.mockTest,
            score: score,
            totalQuestions: questions.length,
            questions: questions, // <-- Передаем вопросы и ответы дальше
            userAnswers: _userAnswers,
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
    // Оборачиваем Scaffold в PopScope для перехвата нажатия "назад"
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.mockTest.title),
          // --- Виджет Таймера ---
          actions: [
            if (_remainingTime != null)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Chip(
                  avatar: const Icon(Icons.timer_outlined, size: 18),
                  label: Text(_formatDuration(_remainingTime!)),
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
                        Text('Вопрос ${_currentQuestionIndex + 1} из ${questions.length}', style: const TextStyle(color: Colors.grey, fontSize: 16)),
                        const SizedBox(height: 16),
                        Text(currentQuestion.questionText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        if (currentQuestion.imageUrl != null && currentQuestion.imageUrl!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(child: ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 250),
                                child: Image.network(currentQuestion.imageUrl!),
                              ),
                            )),
                          ),
                        const SizedBox(height: 24),
                        ...List.generate(currentQuestion.options.length, (index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            decoration: BoxDecoration(
                              color: _userAnswers[_currentQuestionIndex] == index ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _userAnswers[_currentQuestionIndex] == index ? Theme.of(context).primaryColor : Colors.grey.shade300,
                              ),
                            ),
                            child: RadioListTile<int>(
                              title: Text(currentQuestion.options[index].text),
                              value: index,
                              groupValue: _userAnswers[_currentQuestionIndex],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() { _userAnswers[_currentQuestionIndex] = value; });
                                }
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton(
                        onPressed: _currentQuestionIndex == 0 ? null : _previousQuestion,
                        child: const Text('Назад'),
                      ),
                      ElevatedButton(
                        onPressed: _userAnswers[_currentQuestionIndex] != null ? () => _handleNext(questions.length) : null,
                        style: ElevatedButton.styleFrom(backgroundColor: isLastQuestion ? Colors.green : null),
                        child: Text(isLastQuestion ? 'Завершить тест' : 'Следующий вопрос'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}