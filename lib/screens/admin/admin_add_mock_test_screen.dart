import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../models/mock_test_model.dart';
import '../../models/ubt_subject_model.dart';
import '../../models/question_model.dart';
import '../../models/option_model.dart';
import '../../view_models/admin_view_model.dart';

class AdminAddMockTestScreen extends StatefulWidget {
  const AdminAddMockTestScreen({super.key});

  @override
  State<AdminAddMockTestScreen> createState() => _AdminAddMockTestScreenState();
}

class _AdminAddMockTestScreenState extends State<AdminAddMockTestScreen> {
  // Контроллеры для общей информации
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController(); // Для простых тестов
  final _languageController = TextEditingController(text: 'RU');
  final _timeLimitController = TextEditingController(text: '240');

  // Переменная для выбора типа теста
  MockTestType _selectedTestType = MockTestType.simple;

  // Списки для хранения вопросов
  final List<Question> _simpleQuestions = [];
  final List<UbtSubject> _ubtSubjects = [];
  
  // Хранилище для файлов изображений
  final Map<String, XFile?> _questionImages = {}; // question.id -> XFile
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addNewSimpleQuestion();
    _addNewUbtSubject();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _languageController.dispose();
    _timeLimitController.dispose();
    super.dispose();
  }

  // --- МЕТОДЫ ДЛЯ УПРАВЛЕНИЯ СОСТОЯНИЕМ ---
  void _addNewSimpleQuestion() => setState(() => _simpleQuestions.add(Question(id: UniqueKey().toString(), questionText: '', options: [Option(text: ''), Option(text: '')])));
  void _addNewUbtSubject() => setState(() => _ubtSubjects.add(UbtSubject(id: UniqueKey().toString(), title: '', questions: [Question(id: UniqueKey().toString(), questionText: '', options: [Option(text: ''), Option(text: '')])])));
  void _addNewQuestionToSubject(int subjectIndex) => setState(() => _ubtSubjects[subjectIndex].questions.add(Question(id: UniqueKey().toString(), questionText: '', options: [Option(text: ''), Option(text: '')])));
  void _addOptionToQuestion(List<Question> questions, int questionIndex) => setState(() { if (questions[questionIndex].options.length < 6) questions[questionIndex].options.add(Option(text: '')); });
  void _removeOptionFromQuestion(List<Question> questions, int questionIndex, int optionIndex) => setState(() { if (questions[questionIndex].options.length > 2) questions[questionIndex].options.removeAt(optionIndex); });
  void _setCorrectAnswer(List<Question> questions, int questionIndex, int optionIndex) {
    setState(() {
      for (var option in questions[questionIndex].options) { option.isCorrect = false; }
      questions[questionIndex].options[optionIndex].isCorrect = true;
    });
  }
   Future<void> _pickImage(String questionId) async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) setState(() => _questionImages[questionId] = pickedFile);
  }

  // --- МЕТОД ДЛЯ СОХРАНЕНИЯ ТЕСТА ---
  void _handleSaveTest() async {
    setState(() { _isLoading = true; });
    final adminViewModel = Provider.of<AdminViewModel>(context, listen: false);
    
    final allQuestions = _selectedTestType == MockTestType.simple ? _simpleQuestions : _ubtSubjects.expand((s) => s.questions).toList();
    for (var question in allQuestions) {
      if (_questionImages.containsKey(question.id) && _questionImages[question.id] != null) {
        final imageUrl = await adminViewModel.uploadQuestionImage(_questionImages[question.id]!);
        question.imageUrl = imageUrl;
      }
    }

    String? error = await adminViewModel.addMockTest(
      title: _titleController.text,
      subject: _selectedTestType == MockTestType.simple ? _subjectController.text : 'ҰБТ',
      language: _languageController.text,
      timeLimitMinutes: int.tryParse(_timeLimitController.text) ?? 240,
      testType: _selectedTestType,
      simpleQuestions: _selectedTestType == MockTestType.simple ? _simpleQuestions : null,
      ubtSubjects: _selectedTestType == MockTestType.ubt ? _ubtSubjects : null,
    );

    if (mounted) {
      setState(() { _isLoading = false; });
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Тест успешно создан!'), backgroundColor: Colors.green));
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $error'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать новый тест'),
        actions: [IconButton(onPressed: _isLoading ? null : _handleSaveTest, icon: const Icon(Icons.save))],
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : buildForm(),
    );
  }

  Widget buildForm() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildTestInfoFields(),
        const SizedBox(height: 24),
        SegmentedButton<MockTestType>(
          segments: const <ButtonSegment<MockTestType>>[
            ButtonSegment<MockTestType>(value: MockTestType.simple, label: Text('Простой предметный')),
            ButtonSegment<MockTestType>(value: MockTestType.ubt, label: Text('ҰБТ')),
          ],
          selected: {_selectedTestType},
          onSelectionChanged: (Set<MockTestType> newSelection) {
            setState(() { _selectedTestType = newSelection.first; });
          },
        ),
        const Divider(height: 32),
        if (_selectedTestType == MockTestType.simple) _buildSimpleTestEditor() else _buildUbtTestEditor(),
      ],
    );
  }

  Widget _buildTestInfoFields() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Название теста')),
            const SizedBox(height: 16),
            if (_selectedTestType == MockTestType.simple)
              TextField(controller: _subjectController, decoration: const InputDecoration(labelText: 'Предмет')),
            const SizedBox(height: 16),
            TextField(controller: _languageController, decoration: const InputDecoration(labelText: 'Язык (напр. KK или RU)')),
            const SizedBox(height: 16),
            TextField(
              controller: _timeLimitController,
              decoration: const InputDecoration(labelText: 'Лимит времени (в минутах)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleTestEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ..._simpleQuestions.asMap().entries.map((entry) => _buildQuestionCard(entry.key, entry.value, _simpleQuestions)),
        const SizedBox(height: 16),
        OutlinedButton.icon(icon: const Icon(Icons.add), label: const Text('Добавить вопрос'), onPressed: _addNewSimpleQuestion),
      ],
    );
  }

  Widget _buildUbtTestEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ..._ubtSubjects.asMap().entries.map((entry) => _buildUbtSubjectCard(entry.key, entry.value)),
        const SizedBox(height: 16),
        OutlinedButton.icon(icon: const Icon(Icons.add), label: const Text('Добавить предмет'), onPressed: _addNewUbtSubject),
      ],
    );
  }

  Widget _buildUbtSubjectCard(int subjectIndex, UbtSubject subject) {
    return Card(
      color: Colors.grey.shade50,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              initialValue: subject.title,
              decoration: InputDecoration(labelText: 'Название предмета ${subjectIndex + 1}'),
              onChanged: (text) => subject.title = text,
            ),
            const Divider(height: 24),
            ...subject.questions.asMap().entries.map((entry) => _buildQuestionCard(entry.key, entry.value, subject.questions)),
            const SizedBox(height: 8),
            TextButton(onPressed: () => _addNewQuestionToSubject(subjectIndex), child: const Text('Добавить вопрос к предмету')),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int questionIndex, Question question, List<Question> questionList) {
    final imageFile = _questionImages[question.id];
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Вопрос №${questionIndex + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            if (imageFile != null)
              Center(child: kIsWeb ? Image.network(imageFile.path, height: 150) : Image.file(File(imageFile.path), height: 150)),
            TextButton.icon(
              onPressed: () => _pickImage(question.id!),
              icon: const Icon(Icons.image_outlined, size: 18),
              label: Text(imageFile == null ? 'Добавить картинку' : 'Изменить картинку'),
            ),
            TextFormField(
              initialValue: question.questionText,
              decoration: const InputDecoration(labelText: 'Текст вопроса'),
              onChanged: (text) => question.questionText = text,
            ),
            const SizedBox(height: 16),
            ...List.generate(question.options.length, (optionIndex) {
              final option = question.options[optionIndex];
              return Row(children: [
                Radio<int>(
                  value: optionIndex,
                  groupValue: question.options.indexWhere((opt) => opt.isCorrect),
                  onChanged: (value) {
                    if (value != null) _setCorrectAnswer(questionList, questionIndex, value);
                  },
                ),
                Expanded(child: TextFormField(
                  initialValue: option.text,
                  decoration: InputDecoration(labelText: 'Вариант ${optionIndex + 1}'),
                  onChanged: (text) => option.text = text,
                )),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.redAccent),
                  onPressed: () => _removeOptionFromQuestion(questionList, questionIndex, optionIndex),
                )
              ]);
            }),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Добавить вариант'),
              onPressed: () => _addOptionToQuestion(questionList, questionIndex),
            ),
          ],
        ),
      ),
    );
  }
}
