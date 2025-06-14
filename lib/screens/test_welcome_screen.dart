// lib/screens/test_welcome_screen.dart

import 'package:flutter/material.dart';
import '../models/content_item_model.dart';
import 'test_player_screen.dart';

class TestWelcomeScreen extends StatelessWidget {
  final String courseId;
  final String moduleId;
  final ContentItem testItem;

  const TestWelcomeScreen({
    super.key,
    required this.courseId,
    required this.moduleId,
    required this.testItem,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Используем название теста из объекта testItem
        title: Text(testItem.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Онлайн тест',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Пройдите онлайн тест, чтобы закрепить материалы курса и получить сертификат.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 48),

            // Используем данные из testItem для отображения информации
            _buildInfoRow(
              context,
              Icons.timer_outlined,
              'Прохождения теста занимает ${testItem.timeLimitMinutes ?? 'N/A'} минут.',
            ),
            const SizedBox(height: 24),
            _buildInfoRow(
              context,
              Icons.list_alt_outlined,
              'Тест состоит из ${testItem.questionCount ?? 'N/A'} вопросов.',
            ),
            const SizedBox(height: 24),
            _buildInfoRow(
              context,
              Icons.check_circle_outline,
              'Чтобы пройти тест вам нужно ответить правильно на ${testItem.passingPercentage ?? 50}% и более вопросов.',
            ),

            const Spacer(), // Занимает все свободное место

            ElevatedButton(
              onPressed: () {
                // Заменяем текущий экран на экран теста, чтобы пользователь не мог вернуться назад
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TestPlayerScreen(
                      courseId: courseId,
                      moduleId: moduleId,
                      testItem: testItem,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Начать тестирование', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Вспомогательный виджет для создания строки с информацией
  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}