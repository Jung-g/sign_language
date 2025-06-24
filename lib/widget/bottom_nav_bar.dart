import 'package:flutter/material.dart';
import 'package:sign_language/screen/dictionary_screen.dart';
import 'package:sign_language/screen/home_screen.dart';
import 'package:sign_language/screen/translate_screen.dart';
import 'package:sign_language/screen/studycource_screen.dart';
import 'package:sign_language/screen/bookmark_screen.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 32),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              // 사전
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DictionaryScreen()),
              );
            },
            icon: Icon(Icons.search, size: 28),
          ),
          IconButton(
            onPressed: () {
              // 번역
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TranslateScreen()),
              );
            },
            icon: Icon(Icons.g_translate, size: 28),
          ),
          IconButton(
            onPressed: () {
              // 홈 스크린
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            },
            icon: Icon(Icons.home, size: 50),
          ),
          IconButton(
            onPressed: () {
              // 학습 코스 선택
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StudycourceScreen()),
              );
            },
            icon: Icon(Icons.menu_book_rounded, size: 28),
          ),
          IconButton(
            onPressed: () {
              // 단어 북마크
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BookmarkScreen()),
              );
            },
            icon: Icon(Icons.bookmark_border, size: 28),
          ),
        ],
      ),
    );
  }
}
