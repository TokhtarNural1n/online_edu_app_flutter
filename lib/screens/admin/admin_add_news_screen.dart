import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../view_models/admin_view_model.dart';

class AdminAddNewsScreen extends StatefulWidget {
  const AdminAddNewsScreen({super.key});

  @override
  State<AdminAddNewsScreen> createState() => _AdminAddNewsScreenState();
}

class _AdminAddNewsScreenState extends State<AdminAddNewsScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;
  XFile? _imageXFile; // 1. Меняем тип с File? на XFile?

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageXFile = pickedFile; // Сохраняем как XFile
      });
    }
  }

  void _handlePublish() async {
  if (_imageXFile == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Пожалуйста, выберите изображение.')));
    return;
  }
  
  setState(() { _isLoading = true; });
  final adminViewModel = Provider.of<AdminViewModel>(context, listen: false);

  // 1. Сначала загружаем фото и получаем обе ссылки
  final imageUrls = await adminViewModel.uploadNewsImageAndThumbnail(_imageXFile!);
  
  if (imageUrls == null) {
    // Обработка ошибки загрузки фото
    setState(() { _isLoading = false; });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось обработать изображение.')));
    return;
  }

  // 2. Затем сохраняем новость с полученными ссылками
  String? error = await adminViewModel.addNewsArticle(
    title: _titleController.text,
    content: _contentController.text,
    imageUrl: imageUrls['imageUrl']!,
    thumbnailUrl: imageUrls['thumbnailUrl']!,
  );

    if (mounted) {
      setState(() { _isLoading = false; });
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Новость успешно опубликована!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $error'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Создать новость')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: _imageXFile != null
                    // 3. Добавляем универсальный код для отображения
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb
                            ? Image.network(_imageXFile!.path, fit: BoxFit.cover)
                            : Image.file(File(_imageXFile!.path), fit: BoxFit.cover),
                      )
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Выбрать изображение'),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Заголовок', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _contentController, decoration: const InputDecoration(labelText: 'Содержание', border: OutlineInputBorder()), maxLines: 8),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.publish),
              label: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Опубликовать'),
              onPressed: _isLoading ? null : _handlePublish,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
