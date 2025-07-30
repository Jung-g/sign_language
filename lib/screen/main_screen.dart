import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:sign_language/screen/home_screen.dart';
import 'package:sign_language/screen/translate_screen.dart';
import 'package:sign_language/screen/studycourse_screen.dart';
import 'package:sign_language/screen/bookmark_screen.dart';
import 'package:sign_language/service/dictionary_screen_wrapper.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 2; // 기본: 홈

  final List<Widget> screens = const [
    DictionaryScreenWrapper(), // 0
    TranslateScreen(), // 1
    HomeScreen(), // 2
    StudycourseScreen(), // 3
    BookmarkScreen(), // 4
  ];

  void _onItemTapped(int index) {
    setState(() => selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: screens),
      bottomNavigationBar: SalomonBottomBar(
        currentIndex: selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: [
          SalomonBottomBarItem(
            icon: Icon(Icons.search),
            title: Text("사전"),
            selectedColor: Colors.orange,
          ),
          SalomonBottomBarItem(
            icon: Icon(Icons.g_translate),
            title: Text("번역"),
            selectedColor: Colors.purple,
          ),
          SalomonBottomBarItem(
            icon: Icon(Icons.home),
            title: Text("홈"),
            selectedColor: Colors.teal,
          ),
          SalomonBottomBarItem(
            icon: Icon(Icons.menu_book),
            title: Text("학습"),
            selectedColor: Colors.green,
          ),
          SalomonBottomBarItem(
            icon: Icon(Icons.bookmark_border),
            title: Text("북마크"),
            selectedColor: Colors.red,
          ),
        ],
      ),
    );
  }
}
