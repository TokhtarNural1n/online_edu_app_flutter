import 'package:flutter/material.dart';

class TestCard extends StatelessWidget {
  final String title;
  final String subject;
  final String language;
  final int questionCount;
  final int studentCount;
  final bool isPassed;
  final VoidCallback? onTap;

  const TestCard({
    super.key,
    required this.title,
    required this.subject,
    required this.language,
    required this.questionCount,
    required this.studentCount,
    this.isPassed = false,
    this.onTap,
  });

  // --- ОБНОВЛЕННЫЙ МЕТОД ДЛЯ ВЫБОРА ИКОНКИ ---
  IconData _getIconForSubject(String subject) {
    String lowerCaseSubject = subject.toLowerCase();
    if (lowerCaseSubject.contains('матем')) { // Математика, Математикалық
      return Icons.calculate_outlined;
    } else if (lowerCaseSubject.contains('тарих')) { // Тарих, История
      return Icons.account_balance_outlined;
    } else if (lowerCaseSubject.contains('хим')) { // Химия
      return Icons.science_outlined;
    } else if (lowerCaseSubject.contains('физик')) { // Физика
      return Icons.flash_on_outlined;
    } else if (lowerCaseSubject.contains('информ')) { // Информатика
      return Icons.computer_outlined;
    } else if (lowerCaseSubject.contains('биолог')) { // Биология
      return Icons.biotech_outlined;
    } else if (lowerCaseSubject.contains('ағылшын') || lowerCaseSubject.contains('англ')) { // Ағылшын тілі, Английский
      return Icons.language_outlined;
    } else if (lowerCaseSubject.contains('географ')) { // География
      return Icons.public_outlined;
    }
    return Icons.quiz_outlined; // Иконка по умолчанию
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                _getIconForSubject(subject),
                size: 40,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text(subject, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildIconWithText(Icons.list_alt_outlined, '$questionCount вопросов'),
                        const SizedBox(width: 16),
                        _buildIconWithText(Icons.language, language.toUpperCase()),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isPassed)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 28),
                    const SizedBox(height: 4),
                    const Text('Пройден', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconWithText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade500, size: 16),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      ],
    );
  }
}