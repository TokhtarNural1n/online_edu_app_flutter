import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/question_model.dart';

class UbtQuestionModal extends StatefulWidget {
  final List<Question> questions;
  final int initialIndex;
  final Map<int, int> currentAnswers;
  // Callback, который вернет обновленные ответы на главный экран
  final ValueChanged<Map<int, int>> onAnswersUpdated;

  const UbtQuestionModal({
    super.key,
    required this.questions,
    required this.initialIndex,
    required this.currentAnswers,
    required this.onAnswersUpdated,
  });

  @override
  State<UbtQuestionModal> createState() => _UbtQuestionModalState();
}

class _UbtQuestionModalState extends State<UbtQuestionModal> {
  late PageController _pageController;
  late int _currentIndex;
  // Локальная копия ответов, чтобы не менять их напрямую до закрытия
  late Map<int, int> _answers;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    // Создаем копию ответов при открытии
    _answers = Map.from(widget.currentAnswers);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Обновляем ответ и сообщаем главному экрану через callback
  void _onAnswerSelected(int questionIndex, int optionIndex) {
    setState(() {
      _answers[questionIndex] = optionIndex;
    });
    widget.onAnswersUpdated(_answers);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // --- "Шапка" модального окна ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 48), // Пустое место для симметрии
                Text(
                  '${_currentIndex + 1}-сұрақ',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // --- "Листалка" вопросов ---
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.questions.length,
              onPageChanged: (index) {
                setState(() { _currentIndex = index; });
              },
              itemBuilder: (context, index) {
                final question = widget.questions[index];
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Сұрақ #${index + 1}', style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      Text(question.questionText, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, height: 1.4)),
                      if (question.imageUrl != null && question.imageUrl!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: CachedNetworkImage(
                            imageUrl: question.imageUrl!,
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                        ),
                      const SizedBox(height: 24),
                      ...List.generate(question.options.length, (optionIndex) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: _answers[index] == optionIndex ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _answers[index] == optionIndex ? Theme.of(context).primaryColor : Colors.grey.shade300),
                          ),
                          child: RadioListTile<int>(
                            title: Text(question.options[optionIndex].text),
                            value: optionIndex,
                            groupValue: _answers[index],
                            onChanged: (value) {
                              if(value != null) _onAnswerSelected(index, value);
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),

          // --- Нижняя панель навигации ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(top: BorderSide(color: Colors.grey.shade200))
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onPressed: _currentIndex > 0 ? () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn) : null,
                ),
                _buildNavButton(
                  icon: Icons.grid_view_outlined,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                _buildNavButton(
                  icon: Icons.arrow_forward_ios_rounded,
                  onPressed: _currentIndex < widget.questions.length - 1 ? () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn) : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({required IconData icon, required VoidCallback? onPressed}) {
    return Material(
      color: Colors.black.withOpacity(0.05),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Icon(
            icon,
            size: 24,
            color: onPressed != null ? Theme.of(context).textTheme.bodyLarge?.color : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}
