// lib/screens/admin/admin_add_course_screen.dart

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/subject_model.dart';
import '../../view_models/admin_view_model.dart';

class AdminAddCourseScreen extends StatefulWidget {
  const AdminAddCourseScreen({super.key});

  @override
  State<AdminAddCourseScreen> createState() => _AdminAddCourseScreenState();
}

class _AdminAddCourseScreenState extends State<AdminAddCourseScreen> {
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  
  bool _isLoading = false;
  XFile? _imageXFile;

  List<Subject> _subjects = [];
  Subject? _selectedSubject;
  bool _isSubjectsLoading = true;
  bool _areLessonsSequential = false; // <-- Состояние для нового переключателя

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final adminViewModel = Provider.of<AdminViewModel>(context, listen: false);
    final subjects = await adminViewModel.fetchSubjects();
    if (mounted) {
      setState(() {
        _subjects = subjects;
        _isSubjectsLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageXFile = pickedFile;
      });
    }
  }

  void _handlePublish() async {
    if (_titleController.text.isEmpty || _authorController.text.isEmpty || _priceController.text.isEmpty || _selectedSubject == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пожалуйста, заполните все обязательные поля.'), backgroundColor: Colors.orange),
        );
        return;
    }

    setState(() { _isLoading = true; });
    final adminViewModel = Provider.of<AdminViewModel>(context, listen: false);
    
    String? imageUrl;
    String? thumbnailUrl;

    if (_imageXFile != null) {
      final imageUrls = await adminViewModel.uploadCourseImageAndThumbnail(_imageXFile!);
      if (imageUrls != null) {
        imageUrl = imageUrls['imageUrl'];
        thumbnailUrl = imageUrls['thumbnailUrl'];
      }
    }

    // --- ИСПРАВЛЕНИЕ: Передаем все необходимые параметры ---
    String? error = await adminViewModel.addCourse(
      title: _titleController.text,
      author: _authorController.text,
      category: _selectedSubject!.name,
      description: _descriptionController.text,
      price: _priceController.text,
      originalPrice: _originalPriceController.text,
      areLessonsSequential: _areLessonsSequential, // <-- ПЕРЕДАЕМ НОВОЕ ЗНАЧЕНИЕ
      imageUrl: imageUrl,
      thumbnailUrl: thumbnailUrl,
    );

    if (mounted) {
      setState(() { _isLoading = false; });
      if (error == null) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Добавить новый курс')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                child: _imageXFile != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(12), child: kIsWeb ? Image.network(_imageXFile!.path, fit: BoxFit.cover) : Image.file(File(_imageXFile!.path), fit: BoxFit.cover))
                    : const Center(child: Icon(Icons.add_a_photo_outlined, size: 50, color: Colors.grey)),
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(_titleController, 'Название курса'),
            _buildTextField(_authorController, 'Автор курса'),
            const SizedBox(height: 16),
            _isSubjectsLoading
              ? const Center(child: CircularProgressIndicator())
              : DropdownButtonFormField<Subject>(
                  value: _selectedSubject,
                  hint: const Text('Выберите категорию'),
                  isExpanded: true,
                  items: _subjects.map((Subject subject) => DropdownMenuItem<Subject>(value: subject, child: Text(subject.name))).toList(),
                  onChanged: (Subject? newValue) => setState(() => _selectedSubject = newValue),
                  decoration: const InputDecoration(labelText: 'Категория', border: OutlineInputBorder()),
                ),
            const SizedBox(height: 16),
            _buildTextField(_descriptionController, 'Описание', maxLines: 5),
            _buildTextField(_priceController, 'Цена (напр. 15000 тг)'),
            _buildTextField(_originalPriceController, 'Старая цена (необязательно)'),
            const SizedBox(height: 16),
            Card(
              child: SwitchListTile(
                title: const Text('Сделать уроки последовательными'),
                subtitle: const Text('Включите, чтобы уроки стали стоп-уроками.'),
                value: _areLessonsSequential,
                onChanged: (value) => setState(() => _areLessonsSequential = value),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _handlePublish,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Добавить курс'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), alignLabelWithHint: true),
      ),
    );
  }
}