import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sign_language/screen/dictionary_screen.dart';
import 'package:sign_language/screen/home_screen.dart';
import 'package:sign_language/screen/translate_screen.dart';
import 'package:sign_language/screen/studycource_screen.dart';
import 'package:sign_language/screen/bookmark_screen.dart';
import 'package:sign_language/service/dictionary_api.dart';
import 'package:sign_language/service/token_storage.dart';

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
            // 사전
            onPressed: () async {
              try {
                final wordData = await DictionaryApi.fetchWords();
                final userId = await TokenStorage.getUserID();
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
                // print('오류: $e');
                Fluttertoast.showToast(msg: '사전 로딩 오류');
              }
            },
            icon: Icon(Icons.search, size: 28),
          ),
          IconButton(
            // 번역
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TranslateScreen()),
              );
            },
            icon: Icon(Icons.g_translate, size: 28),
          ),
          IconButton(
            // 홈 스크린
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            },
            icon: Icon(Icons.home, size: 50),
          ),
          IconButton(
            // 학습 코스 선택
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StudycourceScreen()),
              );
            },
            icon: Icon(Icons.menu_book_rounded, size: 28),
          ),
          IconButton(
            // 단어 북마크
            onPressed: () {
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
