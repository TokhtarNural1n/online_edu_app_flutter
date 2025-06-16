import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/question_model.dart';
import '../models/option_model.dart';

class UbtQuestionReviewModal extends StatefulWidget {
  final List<Question> questions;
  final int initialIndex;
  final Map<int, int> userAnswers;

  const UbtQuestionReviewModal({
    super.key,
    required this.questions,
    required this.initialIndex,
    required this.userAnswers,
  });

  @override
  State<UbtQuestionReviewModal> createState() => _UbtQuestionReviewModalState();
}

class _UbtQuestionReviewModalState extends State<UbtQuestionReviewModal> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Используем Scaffold, чтобы окно занимало весь экран
    return Scaffold(
      appBar: AppBar(
        title: Text('${_currentIndex + 1}-сұрақ'),
        leading: const CloseButton(),
        elevation: 1,
      ),
      body: PageView.builder(
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
                  final option = question.options[optionIndex];
                  final bool isSelectedByUser = widget.userAnswers[index] == optionIndex;
                  return _buildOptionTile(context, option: option, isSelectedByUser: isSelectedByUser);
                }),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
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
    );
  }

  Widget _buildOptionTile(BuildContext context, {required Option option, required bool isSelectedByUser}) {
    Color tileColor = Colors.transparent;
    IconData leadingIcon = Icons.radio_button_unchecked;
    Color iconColor = Colors.grey;

    if (option.isCorrect) {
      tileColor = Colors.green.withOpacity(0.1);
      leadingIcon = Icons.check_circle;
      iconColor = Colors.green;
    } else if (isSelectedByUser && !option.isCorrect) {
      tileColor = Colors.red.withOpacity(0.1);
      leadingIcon = Icons.cancel;
      iconColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(leadingIcon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(child: Text(option.text, style: const TextStyle(fontSize: 16))),
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
