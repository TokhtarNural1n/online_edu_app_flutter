import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/course_model.dart';
import '../../models/module_model.dart';
import '../../view_models/admin_view_model.dart';
import 'admin_module_detail_screen.dart';

class AdminEditCourseScreen extends StatefulWidget {
  final Course course;
  const AdminEditCourseScreen({super.key, required this.course});

  @override
  State<AdminEditCourseScreen> createState() => _AdminEditCourseScreenState();
}

class _AdminEditCourseScreenState extends State<AdminEditCourseScreen> {
  // Контроллеры для основной информации о курсе
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _originalPriceController;
  
  bool _isLoading = false;
  XFile? _imageXFile;
  String? _currentImageUrl;

  // Состояние для списка модулей
  late Future<List<Module>> _modulesFuture;

  @override
  void initState() {
    super.initState();
    // Инициализируем контроллеры
    _titleController = TextEditingController(text: widget.course.title);
    _authorController = TextEditingController(text: widget.course.author);
    _descriptionController = TextEditingController(text: widget.course.description);
    _priceController = TextEditingController(text: widget.course.price);
    _originalPriceController = TextEditingController(text: widget.course.originalPrice);
    _currentImageUrl = widget.course.imageUrl;

    // Загружаем модули при открытии экрана
    _loadModules();
  }
  
  void _loadModules() {
    if(mounted){
      setState(() {
        _modulesFuture = Provider.of<AdminViewModel>(context, listen: false).fetchModules(widget.course.id);
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
        _currentImageUrl = null;
      });
    }
  }

  // Метод для сохранения основных данных курса
  void _handleUpdateCourseDetails() async {
    setState(() { _isLoading = true; });
    final adminViewModel = Provider.of<AdminViewModel>(context, listen: false);

    String? error = await adminViewModel.updateCourse(
      courseId: widget.course.id,
      title: _titleController.text,
      author: _authorController.text,
      description: _descriptionController.text,
      price: _priceController.text,
      originalPrice: _originalPriceController.text,
      newImageFile: _imageXFile,
      oldImageUrl: widget.course.imageUrl,
    );

    if (mounted) {
      setState(() { _isLoading = false; });
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Данные курса обновлены!'), backgroundColor: Colors.green));
        // Мы не выходим с экрана, просто показываем сообщение
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $error'), backgroundColor: Colors.red));
      }
    }
  }

  // Диалог для добавления/редактирования модуля
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
              _loadModules();
            },
          ),
        ],
      ),
    );
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
          // --- ФОРМА РЕДАКТИРОВАНИЯ КУРСА ---
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 200,
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
              child: _buildImagePreview(),
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField(_titleController, 'Название курса'),
          _buildTextField(_authorController, 'Автор курса'),
          _buildTextField(_descriptionController, 'Описание', maxLines: 5),
          _buildTextField(_priceController, 'Цена (напр. 150 000 т)'),
          _buildTextField(_originalPriceController, 'Старая цена (необязательно)'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleUpdateCourseDetails,
            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Сохранить информацию о курсе'),
          ),

          const Divider(height: 40, thickness: 1),

          // --- НОВЫЙ БЛОК: Программа курса ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Программа курса", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.green),
                onPressed: () => _showModuleDialog(),
                tooltip: 'Добавить модуль',
              ),
            ],
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<Module>>(
            future: _modulesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('Модули еще не добавлены.');
              }
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
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => _showModuleDialog(existingModule: module),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () async {
                              await Provider.of<AdminViewModel>(context, listen: false)
                                  .deleteModule(courseId: widget.course.id, moduleId: module.id);
                              _loadModules();
                            },
                          ),
                        ],
                      ),
                      onTap: (){
                        // Переходим на новый экран управления уроками этого модуля
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (_) => AdminModuleDetailScreen(
                            courseId: widget.course.id,
                            moduleId: module.id,
                            moduleTitle: module.title,
                          ))
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
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
        child: kIsWeb
            ? Image.network(_imageXFile!.path, fit: BoxFit.cover)
            : Image.file(File(_imageXFile!.path), fit: BoxFit.cover),
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
