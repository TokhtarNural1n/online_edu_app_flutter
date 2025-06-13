import 'package:flutter/material.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/grant_result_card.dart';

class GrantChanceResultsScreen extends StatelessWidget {
  const GrantChanceResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Узнать шансы на грант'),
      ),
      body: Column(
        children: [
           // Top Summary Card
          Container(
            color: Colors.blue.shade700,
            padding: const EdgeInsets.all(16.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Баллы в ЕНТ: 127', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orangeAccent, foregroundColor: Colors.white),
                            child: const Text('Изменить'),
                        ),
                      ],
                   ),
                   const SizedBox(height: 10),
                   const Text('Профильные предметы:\nБиология - Химия', style: TextStyle(color: Colors.white, fontSize: 16)),
                   const SizedBox(height: 10),
                    Row(
                        children: [
                            const Text('Конкурс:', style: TextStyle(color: Colors.white, fontSize: 16)),
                            const SizedBox(width: 10),
                            Expanded(child: CustomDropdown(hint: 'Все', items: const ['Все', 'Общий', 'Сельская квота'], backgroundColor: Colors.blue.shade800, textColor: Colors.white)),
                        ],
                    )
                ],
            ),
          ),
          // Results List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: 3, // Example count
              itemBuilder: (context, index) {
                return GrantResultCard(
                  chance: 100,
                  specialtyCode: 'B012',
                  specialtyName: 'Педагогические науки',
                  competitionType: index == 2 ? 'Серпін' : 'Общий конкурс',
                  universityInfo: index == 2
                      ? '035 - Кокшетауский университет им. Ш. Уалиханова'
                      : 'ВУЗы, в которые вы можете поступить на эту специальность: 22',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}