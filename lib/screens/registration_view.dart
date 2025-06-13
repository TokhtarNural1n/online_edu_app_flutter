import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/custom_auth_textfield.dart';

class RegistrationView extends StatefulWidget {
  final VoidCallback onNavigateToLogin;

  const RegistrationView({super.key, required this.onNavigateToLogin});

  @override
  State<RegistrationView> createState() => _RegistrationViewState();
}

class _RegistrationViewState extends State<RegistrationView> {
  // Добавляем контроллеры для новых полей
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegistration() async {
    if (!mounted) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Пароли не совпадают!')));
      return;
    }

    setState(() { _isLoading = true; });
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    
    // Передаем все данные в метод signUp
    String? error = await authViewModel.signUp(
      email: _emailController.text,
      password: _passwordController.text,
      name: _nameController.text,
      surname: _surnameController.text,
    );
    
    if (mounted) {
      setState(() { _isLoading = false; });
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0D47A1);
    const accentColor = Color(0xFFFF9800);

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: widget.onNavigateToLogin,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.person_add_alt_1_outlined, color: Colors.white, size: 60),
            const SizedBox(height: 20),
            const Text('Регистрация', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),

            // --- Новые поля для имени и фамилии ---
            CustomAuthTextField(controller: _nameController, hintText: 'Имя', icon: Icons.person_outline),
            const SizedBox(height: 16),
            CustomAuthTextField(controller: _surnameController, hintText: 'Фамилия', icon: Icons.person_outline),
            const SizedBox(height: 16),
            // ------------------------------------

            CustomAuthTextField(controller: _emailController, hintText: 'Email', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            CustomAuthTextField(controller: _passwordController, hintText: 'Пароль', icon: Icons.lock_outline, isPassword: true),
            const SizedBox(height: 16),
            CustomAuthTextField(controller: _confirmPasswordController, hintText: 'Повторите пароль', icon: Icons.lock_outline, isPassword: true),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleRegistration,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading 
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                  : const Text('Зарегистрироваться', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}