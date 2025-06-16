import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/mock_test_model.dart';
import '../models/ubt_subject_model.dart';
import '../models/mock_test_attempt_model.dart';
import '../view_models/course_view_model.dart';
import '../widgets/ubt_question_modal.dart';
import 'ubt_result_detail_screen.dart';

class UbtPlayerScreen extends StatefulWidget {
  final MockTest ubtTest;
  const UbtPlayerScreen({super.key, required this.ubtTest});

  @override
  State<UbtPlayerScreen> createState() => _UbtPlayerScreenState();
}

class _UbtPlayerScreenState extends State<UbtPlayerScreen> {
  late Future<List<UbtSubject>> _dataFuture;
  
  // Здесь будем хранить ответы: {id предмета: {индекс вопроса: индекс ответа}}
  final Map<String, Map<int, int>> _userAnswers = {};

    // --- НОВОЕ ПОЛЕ: Хранит индекс открытого предмета ---
  int _currentlyExpandedIndex = 0; 

  @override
  void initState() {
    super.initState();
    _dataFuture = Provider.of<CourseViewModel>(context, listen: false)
        .fetchUbtTestWithQuestions(widget.ubtTest.id);
  }

  // --- НЕДОСТАЮЩИЕ МЕТОДЫ, КОТОРЫЕ МЫ ДОБАВЛЯЕМ ---

  // Вспомогательный метод для выбора иконки
  IconData _getIconForSubject(String subjectTitle) {
    String lowerCaseSubject = subjectTitle.toLowerCase();
    if (lowerCaseSubject.contains('математика')) return Icons.calculate_outlined;
    if (lowerCaseSubject.contains('оқу сауаттылығы')) return Icons.menu_book_outlined;
    if (lowerCaseSubject.contains('тарих')) return Icons.account_balance_outlined;
    if (lowerCaseSubject.contains('информатика')) return Icons.computer_outlined;
    if (lowerCaseSubject.contains('физика')) return Icons.flash_on_outlined;
    if (lowerCaseSubject.contains('химия')) return Icons.science_outlined;
    if (lowerCaseSubject.contains('биология')) return Icons.biotech_outlined;
    if (lowerCaseSubject.contains('география')) return Icons.public_outlined;
    return Icons.school_outlined;
  }

  // Метод для показа модального окна с вопросом
  void _showQuestionModal(UbtSubject subject, int questionIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UbtQuestionModal(
        questions: subject.questions,
        initialIndex: questionIndex,
        currentAnswers: _userAnswers[subject.id] ?? {},
        onAnswersUpdated: (newAnswers) {
          setState(() {
            _userAnswers[subject.id] = newAnswers;
          });
        },
      ),
    );
  }

  // Метод для завершения теста
  void _finishUbtTest(List<UbtSubject> subjects) async {
    final courseViewModel = Provider.of<CourseViewModel>(context, listen: false);
    int totalScore = 0;
    int totalQuestions = 0;

    for (final subject in subjects) {
      totalQuestions += subject.questions.length;
      final subjectAnswers = _userAnswers[subject.id];
      if (subjectAnswers != null) {
        for (int i = 0; i < subject.questions.length; i++) {
          if (subjectAnswers.containsKey(i) && subject.questions[i].options[subjectAnswers[i]!].isCorrect) {
            totalScore++;
          }
        }
      }
    }

    showDialog(context: context, builder: (context) => const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    
    await courseViewModel.saveMockTestAttempt(
      testId: widget.ubtTest.id,
      testTitle: widget.ubtTest.title,
      score: totalScore,
      totalQuestions: totalQuestions,
      userAnswers: _userAnswers,
    );

    if (!mounted) return;
    Navigator.of(context).pop();

    final attempt = MockTestAttempt(
      id: '',
      testId: widget.ubtTest.id,
      testTitle: widget.ubtTest.title,
      score: totalScore,
      totalQuestions: totalQuestions,
      completedAt: Timestamp.now(),
      userAnswers: _userAnswers.map((key, value) => MapEntry(key, value.map((k, v) => MapEntry(k.toString(), v))))
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => UbtResultDetailScreen(
          attempt: attempt,
          subjects: subjects,
        )
      )
    );
  }

  // ------------------------------------
  Future<bool> _onWillPop() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Завершить тест?'),
        content: const Text('Вы уверены, что хотите выйти? Прогресс не будет сохранен.'),
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
        appBar: AppBar(title: Text(widget.ubtTest.title)),
        body: FutureBuilder<List<UbtSubject>>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Не удалось загрузить тест.'));
            }
            final subjects = snapshot.data!;
            
            // --- ИЗМЕНЕНИЕ: Используем SingleChildScrollView и ExpansionPanelList ---
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
              child: ExpansionPanelList(
                elevation: 0,
                dividerColor: Colors.transparent,
                expandedHeaderPadding: EdgeInsets.zero,
                // Callback, который срабатывает при нажатии на шапку
                expansionCallback: (int index, bool isExpanded) {
                  setState(() {
                    _currentlyExpandedIndex = isExpanded ? index : -1;
                  });
                },
                children: subjects.map<ExpansionPanel>((UbtSubject subject) {
                  final int subjectIndex = subjects.indexOf(subject);
                  return ExpansionPanel(
                    canTapOnHeader: true,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    headerBuilder: (BuildContext context, bool isExpanded) {
                      return _buildSubjectHeader(subject);
                    },
                    body: _buildSubjectBody(subject),
                    isExpanded: _currentlyExpandedIndex == subjectIndex,
                  );
                }).toList(),
              ),
            );
          },
        ),
        bottomNavigationBar: FutureBuilder<List<UbtSubject>>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () => _finishUbtTest(snapshot.data!),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text('Аяқтау'),
              ),
            );
          }
        ),
      ),
    );
  }

  // Новый виджет для шапки предмета
  Widget _buildSubjectHeader(UbtSubject subject) {
    final answeredCount = _userAnswers[subject.id]?.length ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Icon(_getIconForSubject(subject.title), color: Theme.of(context).primaryColor),
              const SizedBox(width: 12),
              Expanded(child: Text(subject.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              Text('$answeredCount/${subject.questions.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          if (subject.questions.isNotEmpty)
            LinearProgressIndicator(
              value: answeredCount / subject.questions.length,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
        ],
      ),
    );
  }
  
  // Новый виджет для тела предмета (сетки вопросов)
  Widget _buildSubjectBody(UbtSubject subject) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: subject.questions.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5, crossAxisSpacing: 10, mainAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
          final bool isAnswered = _userAnswers[subject.id]?.containsKey(index) ?? false;
          return InkWell(
            onTap: () => _showQuestionModal(subject, index),
            borderRadius: BorderRadius.circular(25),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isAnswered ? const Color(0xFFECEAFF) : Colors.white,
                border: Border.all(color: isAnswered ? const Color(0xFF8662F3) : Colors.grey.shade300),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isAnswered ? const Color(0xFF8662F3) : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
