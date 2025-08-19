import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:sign_language/screen/dictionary_screen.dart';
import 'package:sign_language/screen/home_screen.dart';
import 'package:sign_language/screen/translate_screen.dart';
import 'package:sign_language/screen/studycourse_screen.dart';
import 'package:sign_language/screen/bookmark_screen.dart';
import 'package:sign_language/service/dictionary_api.dart';
import 'package:sign_language/service/token_storage.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 2; // 홈을 기본 선택

  Future<void> _onItemTapped(int index) async {
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        // 사전
        try {
          final wordData = await DictionaryApi.fetchWords();
          final userId = await TokenStorage.getUserID();
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DictionaryScreen(
                words: wordData.words,
                wordIdMap: wordData.wordIDMap,
                userID: userId!,
              ),
            ),
          );
        } catch (e) {
          Fluttertoast.showToast(msg: '사전 로딩 오류');
        }
        break;
      case 1:
        // 번역
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TranslateScreen()),
        );
        break;
      case 2:
        // 홈
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        break;
      case 3:
        // 학습
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StudycourseScreen()),
        );
        break;
      case 4:
        // 북마크
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BookmarkScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SalomonBottomBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.grey,
      items: [
        SalomonBottomBarItem(
          icon: const Icon(Icons.search),
          title: const Text("사전"),
          selectedColor: Colors.orange,
        ),
        SalomonBottomBarItem(
          icon: const Icon(Icons.g_translate),
          title: const Text("작문 연습"),
          selectedColor: Colors.purple,
        ),
        SalomonBottomBarItem(
          icon: const Icon(Icons.home),
          title: const Text("홈"),
          selectedColor: Colors.teal,
        ),
        SalomonBottomBarItem(
          icon: const Icon(Icons.menu_book_rounded),
          title: const Text("학습"),
          selectedColor: Colors.green,
        ),
        SalomonBottomBarItem(
          icon: const Icon(Icons.bookmark_border),
          title: const Text("북마크"),
          selectedColor: Colors.red,
        ),
      ],
    );
  }
}
