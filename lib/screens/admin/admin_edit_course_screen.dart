import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/course_model.dart';
import '../../models/module_model.dart';
import '../../models/promo_code_model.dart';
import '../../models/subject_model.dart';
import '../../view_models/admin_view_model.dart';
import 'admin_module_detail_screen.dart';
import 'package:flutter/services.dart';

class AdminEditCourseScreen extends StatefulWidget {
  final Course course;
  const AdminEditCourseScreen({super.key, required this.course});

  @override
  State<AdminEditCourseScreen> createState() => _AdminEditCourseScreenState();
}

class _AdminEditCourseScreenState extends State<AdminEditCourseScreen> {
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _originalPriceController;
  final _promoCodeCountController = TextEditingController(text: '10');
  
  bool _isLoading = false;
  XFile? _imageXFile;
  String? _currentImageUrl;
  bool _areLessonsSequential = false;

  List<Subject> _subjects = [];
  Subject? _selectedSubject;
  bool _isSubjectsLoading = true;

  late Future<List<Module>> _modulesFuture;
  late Future<List<PromoCode>> _promoCodesFuture;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.course.title);
    _authorController = TextEditingController(text: widget.course.author);
    _descriptionController = TextEditingController(text: widget.course.description);
    _priceController = TextEditingController(text: widget.course.price);
    _originalPriceController = TextEditingController(text: widget.course.originalPrice);
    _currentImageUrl = widget.course.imageUrl;
    _areLessonsSequential = widget.course.areLessonsSequential;

    _loadSubCollections();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final adminViewModel = Provider.of<AdminViewModel>(context, listen: false);
    final subjects = await adminViewModel.fetchSubjects();
    if (mounted) {
      setState(() {
        _subjects = subjects;
        try {
          _selectedSubject = _subjects.firstWhere((s) => s.name == widget.course.category);
        } catch (e) { _selectedSubject = null; }
        _isSubjectsLoading = false;
      });
    }
  }

  void _loadSubCollections() {
    if (mounted) {
      final adminViewModel = Provider.of<AdminViewModel>(context, listen: false);
      setState(() {
        _modulesFuture = adminViewModel.fetchModules(widget.course.id);
        _promoCodesFuture = adminViewModel.fetchPromoCodesForCourse(widget.course.id);
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageXFile = pickedFile;
        _currentImageUrl = null;
      });
    }
  }

  void _handleUpdateCourseDetails() async {
    if (_selectedSubject == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Пожалуйста, выберите категорию курса.')));
       return;
    }
    setState(() { _isLoading = true; });
    final adminViewModel = Provider.of<AdminViewModel>(context, listen: false);
    
    String? newImageUrl, newThumbnailUrl;

    if (_imageXFile != null) {
      final imageUrls = await adminViewModel.uploadCourseImageAndThumbnail(_imageXFile!);
      if (imageUrls != null) {
        newImageUrl = imageUrls['imageUrl'];
        newThumbnailUrl = imageUrls['thumbnailUrl'];
      }
    }

    String? error = await adminViewModel.updateCourse(
      courseId: widget.course.id,
      title: _titleController.text,
      author: _authorController.text,
      category: _selectedSubject!.name,
      description: _descriptionController.text,
      price: _priceController.text,
      originalPrice: _originalPriceController.text,
      areLessonsSequential: _areLessonsSequential,
      newImageUrl: newImageUrl,
      newThumbnailUrl: newThumbnailUrl,
      oldImageUrl: widget.course.imageUrl,
    );
    
    if (mounted) {
      setState(() { _isLoading = false; });
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Данные курса обновлены!'), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $error'), backgroundColor: Colors.red));
      }
    }
  }

  void _showModuleDialog({Module? existingModule}) {
    final moduleTitleController = TextEditingController(text: existingModule?.title ?? '');
    final adminViewModel = Provider.of<AdminViewModel>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingModule == null ? 'Добавить модуль' : 'Редактировать модуль'),
        content: TextField(
          controller: moduleTitleController,
          decoration: const InputDecoration(labelText: 'Название модуля'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Отмена')),
          TextButton(
            child: const Text('Сохранить'),
            onPressed: () async {
              if (existingModule == null) {
                await adminViewModel.addModule(courseId: widget.course.id, title: moduleTitleController.text);
              } else {
                await adminViewModel.updateModule(courseId: widget.course.id, moduleId: existingModule.id, newTitle: moduleTitleController.text);
              }
              Navigator.of(context).pop();
              _loadSubCollections();
            },
          ),
        ],
      ),
    );
  }

  void _handleGeneratePromoCodes() async {
    final count = int.tryParse(_promoCodeCountController.text);
    if (count == null || count <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите корректное количество кодов')));
      return;
    }
    setState(() { _isLoading = true; });
    final adminViewModel = Provider.of<AdminViewModel>(context, listen: false);
    await adminViewModel.generatePromoCodes(
      courseId: widget.course.id,
      courseTitle: widget.course.title,
      count: count,
    );
    if (mounted) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$count промокодов успешно создано!')));
      _loadSubCollections(); // Обновляем список промокодов
    }
  }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Редактировать курс')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text("Основная информация", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GestureDetector(onTap: _pickImage, child: _buildImagePreview()),
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
                items: _subjects.map((Subject subject) {
                  return DropdownMenuItem<Subject>(value: subject, child: Text(subject.name));
                }).toList(),
                onChanged: (Subject? newValue) {
                  setState(() { _selectedSubject = newValue; });
                },
                decoration: const InputDecoration(labelText: 'Категория', border: OutlineInputBorder()),
              ),
          const SizedBox(height: 16),

          _buildTextField(_descriptionController, 'Описание', maxLines: 5),
          _buildTextField(_priceController, 'Цена'),
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
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _isLoading ? null : _handleUpdateCourseDetails, child: const Text('Сохранить информацию о курсе')),
          const Divider(height: 40, thickness: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Программа курса", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.add_circle, color: Colors.green), onPressed: () => _showModuleDialog(), tooltip: 'Добавить модуль'),
            ],
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<Module>>(
            future: _modulesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const Text('Модули еще не добавлены.');
              final modules = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: modules.length,
                itemBuilder: (context, index) {
                  final module = modules[index];
                  return Card(
                    child: ListTile(
                      title: Text(module.title),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _showModuleDialog(existingModule: module)),
                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () async {
                            await Provider.of<AdminViewModel>(context, listen: false).deleteModule(courseId: widget.course.id, moduleId: module.id);
                            _loadSubCollections();
                          },
                        ),
                      ]),
                      onTap: (){
                        Navigator.push(context, MaterialPageRoute(builder: (_) => AdminModuleDetailScreen(courseId: widget.course.id, moduleId: module.id, moduleTitle: module.title)));
                      },
                    ),
                  );
                },
              );
            },
          ),
          const Divider(height: 40, thickness: 1),
          _buildPromoCodeSection(),
        ],
      ),
    );
  }

  Widget _buildPromoCodeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Промокоды для курса", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _promoCodeCountController,
                decoration: const InputDecoration(labelText: 'Количество', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleGeneratePromoCodes,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
              child: const Text('Сгенерировать'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text("Активные промокоды:", style: TextStyle(fontWeight: FontWeight.w600)),
        FutureBuilder<List<PromoCode>>(
          future: _promoCodesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Padding(padding: EdgeInsets.all(8.0), child: Text('Активных промокодов для этого курса нет.'));
            }
            final codes = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: codes.length,
              itemBuilder: (context, index) {
                final code = codes[index];
                return Card(
                  child: ListTile(
                    title: Text(code.id, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy_outlined, size: 20),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code.id));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Промокод ${code.id} скопирован!')));
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(controller: controller, maxLines: maxLines, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder())),
    );
  }

  Widget _buildImagePreview() {
    if (_imageXFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: kIsWeb ? Image.network(_imageXFile!.path, fit: BoxFit.cover) : Image.file(File(_imageXFile!.path), fit: BoxFit.cover),
      );
    }
    if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(_currentImageUrl!, fit: BoxFit.cover),
      );
    }
    return const Center(child: Text('Нажмите, чтобы выбрать фото'));
  }
}