// lib/screens/detailed_results_screen.dart

import 'package:flutter/material.dart';
import '../models/question_model.dart';
import '../models/option_model.dart';

class DetailedResultsScreen extends StatelessWidget {
  final List<Question> questions;
  final Map<int, int> userAnswers;

  const DetailedResultsScreen({
    super.key,
    required this.questions,
    required this.userAnswers,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Результаты теста'),
      ),
      // Используем ListView.builder для эффективного отображения списка
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final question = questions[index];
          // Получаем ответ пользователя на этот вопрос (может быть null, если не ответил)
          final userAnswerIndex = userAnswers[index]; 
          
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Номер и текст вопроса ---
                  Text(
                    '${index + 1} - вопрос',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(question.questionText, style: const TextStyle(fontSize: 17)),
                  
                  // --- Изображение вопроса (если есть) ---
                  if (question.imageUrl != null && question.imageUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(question.imageUrl!)
                      ),
                    ),
                  
                  const Divider(height: 32),
                  
                  // --- Список вариантов ответов ---
                  ...List.generate(question.options.length, (optionIndex) {
                    final option = question.options[optionIndex];
                    return _buildOptionTile(
                      context,
                      option: option,
                      isSelectedByUser: userAnswerIndex == optionIndex,
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Вспомогательный виджет для отображения одного варианта ответа
  Widget _buildOptionTile(BuildContext context, {
    required Option option,
    required bool isSelectedByUser,
  }) {
    Color? tileColor;
    Color? borderColor;
    IconData? leadingIcon;
    Color? iconColor;

    if (option.isCorrect) {
      // Правильный ответ всегда подсвечиваем зеленым
      tileColor = Colors.green.withOpacity(0.1);
      borderColor = Colors.green;
      leadingIcon = Icons.check_circle;
      iconColor = Colors.green;
    } else if (isSelectedByUser && !option.isCorrect) {
      // Неправильный выбор пользователя подсвечиваем красным
      tileColor = Colors.red.withOpacity(0.1);
      borderColor = Colors.red;
      leadingIcon = Icons.cancel;
      iconColor = Colors.red;
    } else {
      // Остальные варианты
      tileColor = Theme.of(context).scaffoldBackgroundColor;
      borderColor = Colors.grey.shade300;
      leadingIcon = Icons.radio_button_unchecked;
      iconColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(leadingIcon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(child: Text(option.text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}