// lib/screens/admin/admin_add_material_screen.dart

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/content_item_model.dart';
import '../../view_models/admin_view_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AdminAddMaterialScreen extends StatefulWidget {
  final String courseId;
  final String moduleId;
  final ContentItem? materialToEdit; // <-- Поле для редактирования

  const AdminAddMaterialScreen({
    super.key,
    required this.courseId,
    required this.moduleId,
    this.materialToEdit,
  });

  @override
  State<AdminAddMaterialScreen> createState() => _AdminAddMaterialScreenState();
}

class _AdminAddMaterialScreenState extends State<AdminAddMaterialScreen> {
  final _titleController = TextEditingController();
  PlatformFile? _selectedFile;
  bool _isLoading = false;
  bool get isEditing => widget.materialToEdit != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _titleController.text = widget.materialToEdit!.title;
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      withData: kIsWeb,
    );
    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  void _handleSave() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Пожалуйста, введите название материала.'),
      ));
      return;
    }
    // В режиме создания файл обязателен
    if (!isEditing && _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Пожалуйста, выберите файл.'),
      ));
      return;
    }

    setState(() { _isLoading = true; });
    final adminViewModel = Provider.of<AdminViewModel>(context, listen: false);

    String? error;

    if (isEditing) {
      // РЕЖИМ РЕДАКТИРОВАНИЯ
      error = await adminViewModel.updateMaterial(
        courseId: widget.courseId,
        moduleId: widget.moduleId,
        contentId: widget.materialToEdit!.id,
        title: _titleController.text,
        newFile: _selectedFile,
        oldFileUrl: widget.materialToEdit!.fileUrl,
      );

    } else {
      // РЕЖИМ СОЗДАНИЯ
      final fileUrl = await adminViewModel.uploadCourseMaterial(_selectedFile!);
      if (fileUrl == null) {
        error = 'Ошибка загрузки файла.';
      } else {
        error = await adminViewModel.addMaterial(
          courseId: widget.courseId,
          moduleId: widget.moduleId,
          title: _titleController.text,
          fileUrl: fileUrl,
          fileName: _selectedFile!.name,
          fileType: _selectedFile!.extension ?? '',
        );
      }
    }

    if (mounted) {
      setState(() { _isLoading = false; });
      if (error == null) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Редактировать материал' : 'Добавить материал')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Название материала', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.attach_file),
              label: Text(isEditing ? 'Заменить файл' : 'Выбрать файл'),
              onPressed: _pickFile,
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                _selectedFile?.name ?? (isEditing ? 'Текущий файл: ${widget.materialToEdit!.fileName}' : 'Файл не выбран'),
                style: const TextStyle(color: Colors.grey),
              )
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSave,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(isEditing ? 'Сохранить изменения' : 'Добавить'),
            ),
          ],
        ),
      ),
    );
  }
}