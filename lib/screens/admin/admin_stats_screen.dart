import 'package:flutter/material.dart';

class AdminStatsScreen extends StatelessWidget {
  const AdminStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Статистика')),
      body: const Center(child: Text('Раздел статистики появится здесь')),
    );
  }
}