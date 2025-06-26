// lib/screens/subscription_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // <-- НОВЫЙ ИМПОРТ
import '../models/course_model.dart';

class SubscriptionScreen extends StatefulWidget {
  final Course course;
  const SubscriptionScreen({super.key, required this.course});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  // Список тарифов можно будет загружать из Firebase в будущем
  final List<Map<String, String>> _tariffs = [
    {'title': '1 ай', 'price': '9900 KZT'},
    {'title': '3 ай', 'price': '27900 KZT'},
  ];

  int? _selectedTariffIndex; // Индекс выбранного тарифа

  // --- МЕТОД ДЛЯ ПЕРЕХОДА В WHATSAPP ---
  void _launchWhatsApp() async {
    if (_selectedTariffIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, выберите тарифный план.')),
      );
      return;
    }


    final String phoneNumber = '77775142186';  

    final selectedTariff = _tariffs[_selectedTariffIndex!];
    final String courseName = widget.course.title;
    final String tariffInfo = '${selectedTariff['title']} - ${selectedTariff['price']}';

    
    final String message = 'Сәлеметсіз бе! Мен "${courseName}" курсын "${tariffInfo}" тарифі бойынша сатып алғым келеді.';
    
    
    final String encodedMessage = Uri.encodeComponent(message);
    
    
    final Uri whatsappUri = Uri.parse('https://wa.me/$phoneNumber?text=$encodedMessage');

    
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось открыть WhatsApp. Убедитесь, что он установлен.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Подписка на курс'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.course.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              widget.course.category,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),

            ListView.separated(
              shrinkWrap: true,
              itemCount: _tariffs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final tariff = _tariffs[index];
                return _buildTariffCard(
                  context,
                  title: tariff['title']!,
                  price: tariff['price']!,
                  value: index,
                );
              },
            ),

            const Spacer(),

            ElevatedButton(
              onPressed: _launchWhatsApp,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Оплатить через WhatsApp'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTariffCard(BuildContext context, {required String title, required String price, required int value}) {
    return Card(
      elevation: _selectedTariffIndex == value ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _selectedTariffIndex == value ? Theme.of(context).primaryColor : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: RadioListTile<int>(
        value: value,
        groupValue: _selectedTariffIndex,
        onChanged: (int? newValue) {
          setState(() {
            _selectedTariffIndex = newValue;
          });
        },
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(price, style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 18)),
        controlAffinity: ListTileControlAffinity.trailing,
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }
}