import 'package:flutter/material.dart';
import 'package:sign_language/service/bookmark_api.dart';
import 'package:sign_language/widget/bottom_nav_bar.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  Map<String, int> bookmarkedWords = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadBookmarks();
  }

  Future<void> loadBookmarks() async {
    try {
      final result = await BookmarkApi.fetchBookmarkedWords();
      setState(() {
        bookmarkedWords = result;
        isLoading = false;
      });
    } catch (e) {
      print('북마크 로딩 실패: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("북마크 단어")),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : bookmarkedWords.isEmpty
            ? const Center(child: Text("북마크된 단어가 없습니다."))
            : ListView.builder(
                itemCount: bookmarkedWords.length,
                itemBuilder: (context, index) {
                  final word = bookmarkedWords.keys.elementAt(index);
                  return ListTile(
                    title: Text(word),
                    onTap: () {
                      // 단어 상세 정보 보기 추가
                    },
                  );
                },
              ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
