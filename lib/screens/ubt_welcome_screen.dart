import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mock_test_model.dart';
import '../models/ubt_subject_model.dart';
import '../view_models/course_view_model.dart';
import 'ubt_player_screen.dart'; // Мы создадим этот экран на следующем шаге


class UbtWelcomeScreen extends StatelessWidget {
  final MockTest ubtTest;
  const UbtWelcomeScreen({super.key, required this.ubtTest});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${ubtTest.id.substring(0, 6)}-нұсқа'),
      ),
      body: FutureBuilder<List<UbtSubject>>(
        future: Provider.of<CourseViewModel>(context, listen: false).fetchSubjectsForUbtTest(ubtTest.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Не удалось загрузить предметы этого теста.'));
          }
          final subjects = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ҰБТ стандарты бойынша', style: TextStyle(color: Colors.grey.shade600)),
                    Text('#${ubtTest.id.substring(0, 6)}', style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(height: 24),
                    const Text('Тест состоит из следующих предметов:', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: subjects.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(subjects[index].title, style: const TextStyle(fontWeight: FontWeight.w500)),
                    );
                  },
                  separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            // Заменяем текущий экран на экран плеера
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => UbtPlayerScreen(ubtTest: ubtTest),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: const Color(0xFF8662F3),
            foregroundColor: Colors.white,
          ),
          child: const Text('Бастау', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}
