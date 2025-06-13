import 'package:flutter/material.dart';
import 'admin_users_screen.dart';
import 'admin_courses_screen.dart';
import 'admin_news_screen.dart'; // <-- 1. Импортируем новый экран
import 'admin_stats_screen.dart';
import 'admin_profile_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int _selectedIndex = 0;

  // 2. Добавляем новый экран в список
  static const List<Widget> _adminScreens = <Widget>[
    AdminUsersScreen(),
    AdminCoursesScreen(),
    AdminNewsScreen(), // <-- Наш новый раздел
    AdminStatsScreen(),
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
      // 3. Добавляем пятую кнопку в навигацию
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
            icon: Icon(Icons.article_outlined), // <-- Новая иконка и вкладка
            label: 'Новости',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Статистика',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_pin),
            label: 'Профиль',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
