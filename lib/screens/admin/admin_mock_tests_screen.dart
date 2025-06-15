// lib/screens/admin/admin_mock_tests_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/mock_test_model.dart';
import '../../view_models/admin_view_model.dart';
import 'admin_add_mock_test_screen.dart';

class AdminMockTestsScreen extends StatefulWidget {
  const AdminMockTestsScreen({super.key});

  @override
  State<AdminMockTestsScreen> createState() => _AdminMockTestsScreenState();
}

class _AdminMockTestsScreenState extends State<AdminMockTestsScreen> {
  late Future<List<MockTest>> _testsFuture;

  @override
  void initState() {
    super.initState();
    _loadTests();
  }

  void _loadTests() {
    _testsFuture = Provider.of<AdminViewModel>(context, listen: false).fetchAllMockTests();
  }

  void _refreshList() {
    setState(() {
      _loadTests();
    });
  }

  void _deleteTest(MockTest test) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтвердите удаление'),
        content: Text('Вы уверены, что хотите удалить тест "${test.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Отмена')),
          TextButton(
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.of(context).pop();
              await Provider.of<AdminViewModel>(context, listen: false).deleteMockTest(testId: test.id);
              _refreshList();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Управление пробными тестами')),
      body: FutureBuilder<List<MockTest>>(
        future: _testsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Тесты еще не добавлены.'));
          }
          final tests = snapshot.data!;
          return ListView.builder(
            itemCount: tests.length,
            itemBuilder: (context, index) {
              final test = tests[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(test.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${test.subject} • ${test.questionCount} вопросов'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _deleteTest(test),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminAddMockTestScreen()),
          );
          if (result == true) {
            _refreshList();
          }
        },
        tooltip: 'Добавить пробный тест',
        child: const Icon(Icons.add),
      ),
    );
  }
}