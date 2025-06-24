import 'package:flutter/material.dart';
import 'package:sign_language/sample_word.dart';
import 'package:sign_language/widget/bottom_nav_bar.dart';
import 'package:sign_language/widget/indexbar.dart';
import 'package:sign_language/widget/word_details.dart';
import 'package:sign_language/widget/word_tile.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final Set<String> bookmarked = {};
  final Map<String, GlobalKey> wordKeys = {};
  final ScrollController scrollController = ScrollController();
  String? selected;

  // 초성 리스트
  final List<String> initials = [
    'ㄱ',
    'ㄲ',
    'ㄴ',
    'ㄷ',
    'ㄸ',
    'ㄹ',
    'ㅁ',
    'ㅂ',
    'ㅃ',
    'ㅅ',
    'ㅆ',
    'ㅇ',
    'ㅈ',
    'ㅉ',
    'ㅊ',
    'ㅋ',
    'ㅌ',
    'ㅍ',
    'ㅎ',
  ];

  final TextEditingController searchController = TextEditingController();
  List<String> filteredWordList = List.from(sampleWordList);

  @override
  void initState() {
    super.initState();
    for (var word in sampleWordList) {
      wordKeys[word] = GlobalKey();
    }
  }

  String getInitial(String text) {
    final code = text.codeUnitAt(0) - 0xAC00;
    if (code < 0 || code > 11171) return text[0];
    final initial = initials[code ~/ 588];
    return initials.contains(initial) ? initial : text[0];
  }

  void toggleBookmark(String word) {
    setState(() {
      if (bookmarked.contains(word)) {
        bookmarked.remove(word);
      } else {
        bookmarked.add(word);
      }
    });
  }

  void selectWord(String word) {
    setState(() {
      if (selected == word) {
        selected = null; // 같은 단어 다시 누르면 닫기
      } else {
        selected = word; // 다른 단어 누르면 해당 단어 보여줌
      }
    });
  }

  void scrollToFirstWordWith(String initial) {
    final index = sampleWordList.indexWhere(
      (word) => getInitial(word) == initial,
    );
    if (index != -1) {
      scrollController.animateTo(
        index * 56, // 워드 타일 사이즈 이용해서 이동
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void performSearch() {
    final query = searchController.text.trim();
    if (query.isEmpty) return;

    final match = sampleWordList.firstWhere(
      (word) => word.contains(query),
      orElse: () => '',
    );

    if (match.isNotEmpty) {
      setState(() {
        selected = match;
        filteredWordList = sampleWordList
            .where((word) => word.contains(query))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 상단 헤더
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: '단어 검색',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                      ),
                      onSubmitted: (_) => performSearch(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: performSearch,
                  ),
                ],
              ),
            ),

            // 사전 리스트 + 인덱스 바
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: ListView(
                      controller: scrollController,
                      children: sampleWordList.map((word) {
                        return WordTile(
                          key: wordKeys[word],
                          word: word,
                          isBookmarked: bookmarked.contains(word),
                          onTap: () => selectWord(word),
                          onBookmarkToggle: () => toggleBookmark(word),
                        );
                      }).toList(),
                    ),
                  ),
                  IndexBar(initials: initials, onTap: scrollToFirstWordWith),
                ],
              ),
            ),

            // 단어 상세 정보
            if (selected != null)
              WordDetails(
                word: selected!,
                onClose: () => setState(() {
                  selected = null;
                }),
              ),

            BottomNavBar(),
          ],
        ),
      ),
    );
  }
}
