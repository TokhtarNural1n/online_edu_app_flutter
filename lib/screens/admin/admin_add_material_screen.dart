// lib/screens/admin/admin_add_material_screen.dart

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/admin_view_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AdminAddMaterialScreen extends StatefulWidget {
  final String courseId;
  final String moduleId;

  const AdminAddMaterialScreen({
    super.key,
    required this.courseId,
    required this.moduleId,
  });

  @override
  State<AdminAddMaterialScreen> createState() => _AdminAddMaterialScreenState();
}

class _AdminAddMaterialScreenState extends State<AdminAddMaterialScreen> {
  final _titleController = TextEditingController();
  PlatformFile? _selectedFile;
  bool _isLoading = false;

  Future<void> _pickFile() async {
    // Мы просим file_picker также считать содержимое файла в память (особенно важно для веба)
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      // withData: true обязательно для веба, для мобильных устройств мы используем путь
      withData: kIsWeb,
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  void _handleSave() async {
    if (_titleController.text.isEmpty || _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Пожалуйста, введите название и выберите файл.'),
      ));
      return;
    }

    setState(() { _isLoading = true; });
    final adminViewModel = Provider.of<AdminViewModel>(context, listen: false);

    // 1. Загружаем файл в Storage
    final fileUrl = await adminViewModel.uploadCourseMaterial(_selectedFile!);
    if (fileUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ошибка загрузки файла.')));
      setState(() { _isLoading = false; });
      return;
    }

    // 2. Сохраняем информацию в Firestore
    await adminViewModel.addMaterial(
      courseId: widget.courseId,
      moduleId: widget.moduleId,
      title: _titleController.text,
      fileUrl: fileUrl,
      fileName: _selectedFile!.name,
      fileType: _selectedFile!.extension ?? '',
    );

    if (mounted) {
      setState(() { _isLoading = false; });
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Добавить материал')),
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
              label: const Text('Выбрать файл'),
              onPressed: _pickFile,
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
            const SizedBox(height: 16),
            if (_selectedFile != null)
              Center(child: Text('Выбранный файл: ${_selectedFile!.name}')),
            const Spacer(),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSave,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Сохранить материал'),
            ),
          ],
        ),
      ),
    );
  }
}