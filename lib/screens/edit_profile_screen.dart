import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/auth_view_model.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // --- ИСПРАВЛЕННЫЙ МЕТОД ЗАГРУЗКИ ---
  Future<void> _loadUserData() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    // Получаем не Map, а готовый объект UserModel
    final userModel = await authViewModel.getUserData();

    if (mounted) {
      setState(() {
        if (userModel != null) {
          // Заполняем поля из полей модели, а не из карты
          _nameController.text = userModel.name;
          _surnameController.text = userModel.surname;
        }
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    String? error = await authViewModel.updateUserData(
      name: _nameController.text,
      surname: _surnameController.text,
    );

    if (mounted) {
      setState(() { _isLoading = false; });
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Данные успешно сохранены!')));
        // ИЗМЕНЯЕМ ЭТУ СТРОКУ
        Navigator.of(context).pop(true); // <-- БЫЛО: Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактировать профиль'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Имя'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _surnameController,
                    decoration: const InputDecoration(labelText: 'Фамилия'),
                  ),
                  const SizedBox(height: 16),
                  const TextField(
                    enabled: false, // Пока не реализуем, делаем неактивными
                    decoration: InputDecoration(labelText: 'г. Астана'),
                  ),
                  const SizedBox(height: 16),
                   const TextField(
                    enabled: false,
                    decoration: InputDecoration(labelText: 'район Алматы')),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Сохранить'),
                  ),
                ],
              ),
            ),
    );
  }
}