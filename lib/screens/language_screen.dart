import 'package:flutter/material.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Язык'),
      ),
      body: const Center(
        child: Text('Страница выбора языка скоро появится здесь!'),
      ),
    );
  }
}