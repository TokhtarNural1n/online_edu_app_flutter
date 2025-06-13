import 'package:flutter/material.dart';
import '../widgets/test_card.dart';

class MyTestsScreen extends StatelessWidget {
  const MyTestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // DefaultTabController автоматически управляет состоянием вкладок
    return DefaultTabController(
      length: 3, // У нас 3 вкладки
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Мои тесты'),
          // В bottom AppBar'а мы помещаем наши вкладки
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Все'),
              Tab(text: 'Новые'),
              Tab(text: 'Завершенные'),
            ],
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
          ),
        ),
        // TabBarView отображает контент для каждой вкладки
        body: TabBarView(
          children: [
            // Для примера, покажем одинаковый список на всех вкладках
            _buildTestsList(isPassed: true), // Вкладка "Все"
            _buildTestsList(), // Вкладка "Новые"
            _buildTestsList(isPassed: true), // Вкладка "Завершенные"
          ],
        ),
      ),
    );
  }

  // Вспомогательный метод для создания списка тестов
  Widget _buildTestsList({bool isPassed = false}) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        TestCard(
          title: 'Құқық негіздері. Жаңа формат. Диагностикалық тест',
          subject: 'Основы права',
          language: 'KK',
          questionCount: 40,
          studentCount: 4458,
          isPassed: isPassed,
        ),
        TestCard(
          title: 'Информатика. Жаңа база сұрақтары. Нұсқа 004',
          subject: 'Информатика',
          language: 'KK',
          questionCount: 40,
          studentCount: 1502,
          isPassed: isPassed,
        ),
        TestCard(
          title: 'Дүниежүзі тарихы. Жаңа база сұрақтары. Нұсқа 006',
          subject: 'Вс. история',
          language: 'KK',
          questionCount: 40,
          studentCount: 408,
          isPassed: isPassed,
        ),
      ],
    );
  }
}