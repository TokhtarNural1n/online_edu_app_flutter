import 'package:flutter/material.dart';
import 'admin_users_screen.dart';
import 'admin_courses_screen.dart';
import 'admin_news_screen.dart';
import 'admin_mock_tests_screen.dart'; // <-- Новый импорт
import 'admin_profile_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int _selectedIndex = 0;

  // Заменяем экран статистики на новый экран тестов
  static const List<Widget> _adminScreens = <Widget>[
    AdminUsersScreen(),
    AdminCoursesScreen(),
    AdminNewsScreen(),
    AdminMockTestsScreen(), // <-- НОВЫЙ ЭКРАН
    AdminProfileScreen(), 
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _adminScreens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Пользователи',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            label: 'Курсы',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article_outlined),
            label: 'Новости',
          ),
          // --- ИЗМЕНЕНИЕ ---
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz_outlined),
            label: 'Проб. тесты',
          ),
          // ------------------
          BottomNavigationBarItem(
            icon: Icon(Icons.person_pin),
            label: 'Профиль',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}