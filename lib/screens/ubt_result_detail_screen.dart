import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/mock_test_attempt_model.dart';
import '../models/ubt_subject_model.dart';
import '../widgets/ubt_question_review_modal.dart';

class UbtResultDetailScreen extends StatefulWidget {
  final MockTestAttempt attempt;
  final List<UbtSubject> subjects;

  const UbtResultDetailScreen({
    super.key,
    required this.attempt,
    required this.subjects,
  });

  @override
  State<UbtResultDetailScreen> createState() => _UbtResultDetailScreenState();
}

class _UbtResultDetailScreenState extends State<UbtResultDetailScreen> {

  IconData _getIconForSubject(String subjectTitle) {
    String lowerCaseSubject = subjectTitle.toLowerCase();
    if (lowerCaseSubject.contains('математика') && lowerCaseSubject.contains('сауаттылық')) return Icons.functions;
    if (lowerCaseSubject.contains('оқу сауаттылығы')) return Icons.menu_book_outlined;
    if (lowerCaseSubject.contains('математика')) return Icons.calculate_outlined;
    if (lowerCaseSubject.contains('тарих')) return Icons.account_balance_outlined;
    if (lowerCaseSubject.contains('информатика')) return Icons.computer_outlined;
    if (lowerCaseSubject.contains('физика')) return Icons.flash_on_outlined;
    if (lowerCaseSubject.contains('химия')) return Icons.science_outlined;
    if (lowerCaseSubject.contains('биология')) return Icons.biotech_outlined;
    if (lowerCaseSubject.contains('география')) return Icons.public_outlined;
    return Icons.school_outlined;
  }

  void _showQuestionReview(BuildContext context, UbtSubject subject, int questionIndex) {
    final Map<int, int> subjectAnswers = (widget.attempt.userAnswers[subject.id] as Map<dynamic, dynamic>?)
        ?.map((key, value) => MapEntry(int.parse(key.toString()), value as int)) ?? {};
        
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UbtQuestionReviewModal(
        questions: subject.questions,
        initialIndex: questionIndex,
        userAnswers: subjectAnswers,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final testId = widget.attempt.testId;
    final formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(widget.attempt.completedAt.toDate());

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.attempt.testTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                '${widget.attempt.score}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: widget.subjects.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ҰБТ стандарты бойынша', style: TextStyle(color: Colors.grey.shade600)),
                  Text('#${testId.substring(0, 6)} • $formattedDate', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            );
          }
          final subject = widget.subjects[index - 1];
          return _buildSubjectResultCard(context, subject);
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
          child: const Text('Апелляцияға беру'),
        ),
      ),
    );
  }

  // --- ОБНОВЛЕННЫЙ ВИДЖЕТ ДЛЯ ПРЕДМЕТА ---
  Widget _buildSubjectResultCard(BuildContext context, UbtSubject subject) {
    final Map<int, int> subjectAnswers = (widget.attempt.userAnswers[subject.id] as Map<dynamic, dynamic>?)
        ?.map((key, value) => MapEntry(int.parse(key.toString()), value as int)) ?? {};

    int subjectScore = 0;
    for (int i = 0; i < subject.questions.length; i++) {
      if (subjectAnswers.containsKey(i) && subject.questions[i].options[subjectAnswers[i]!].isCorrect) {
        subjectScore++;
      }
    }
    
    // Используем ExpansionTile для создания разворачиваемой панели
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        // Шапка с названием предмета и результатом
        title: Row(
          children: [
            Icon(_getIconForSubject(subject.title), color: Theme.of(context).primaryColor, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(subject.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            Text('$subjectScore/${subject.questions.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        // Разворачиваемое содержимое - сетка с вопросами
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subject.questions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5, crossAxisSpacing: 10, mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final question = subject.questions[index];
                final userAnswerIndex = subjectAnswers[index];
                
                bool? isCorrect;
                if (userAnswerIndex != null) isCorrect = question.options[userAnswerIndex].isCorrect;

                Color buttonColor = Colors.white;
                Color textColor = Colors.black87;
                Border border = Border.all(color: Colors.grey.shade300);

                if (isCorrect == true) {
                  buttonColor = Colors.green.withOpacity(0.15);
                  textColor = Colors.green.shade800;
                  border = Border.all(color: Colors.green);
                } else if (isCorrect == false) {
                  buttonColor = Colors.red.withOpacity(0.15);
                  textColor = Colors.red.shade800;
                  border = Border.all(color: Colors.red);
                }

                return InkWell(
                  onTap: () => _showQuestionReview(context, subject, index),
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: buttonColor,
                      border: border,
                    ),
                    child: Center(child: Text('${index + 1}', style: TextStyle(color: textColor, fontWeight: FontWeight.bold))),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
