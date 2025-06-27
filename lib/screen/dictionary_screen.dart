import 'package:flutter/material.dart';
import 'package:sign_language/widget/bottom_nav_bar.dart';
import 'package:sign_language/widget/indexbar.dart';
import 'package:sign_language/widget/word_details.dart';
import 'package:sign_language/widget/word_tile.dart';

class DictionaryScreen extends StatefulWidget {
  final List<String> words;
  final Map<String, int> wordIdMap;
  final String userID;

  const DictionaryScreen({
    super.key,
    required this.words,
    required this.wordIdMap,
    required this.userID,
  });

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
    '#',
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
  late List<String> filteredWordList = []; // = List.from(sampleWordList);

  @override
  void initState() {
    super.initState();
    filteredWordList = List.from(widget.words);
    for (var word in widget.words) {
      wordKeys[word] = GlobalKey();
    }
  }

  String getInitial(String text) {
    final code = text.codeUnitAt(0);
    if (code < 0xAC00 || code > 0xD7A3) {
      return '#';
    }

    final initialCode = ((code - 0xAC00) ~/ 28 ~/ 21);
    const initialsMap = [
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
    return initialsMap[initialCode];
  }

  void toggleBookmark(String word, bool result) {
    setState(() {
      if (result) {
        bookmarked.add(word);
      } else {
        bookmarked.remove(word);
      }
    });
  }

  void selectWord(String word) {
    FocusScope.of(context).unfocus();
    setState(() {
      if (selected == word) {
        selected = null; // 같은 단어 다시 누르면 닫기
      } else {
        selected = word; // 다른 단어 누르면 해당 단어 보여줌
      }
    });
  }

  void scrollToFirstWordWith(String initial) {
    int index = -1;

    if (initial == '#') {
      index = filteredWordList.indexWhere(
        (word) => RegExp(r'^[0-9]').hasMatch(word),
      );
    } else {
      index = filteredWordList.indexWhere(
        (word) => getInitial(word) == initial,
      );
    }

    if (index != -1) {
      scrollController.animateTo(
        index * 56.0, // WordTile 높이 기준
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void performSearch() {
    final query = searchController.text.trim();
    if (query.isEmpty) return;

    final match = filteredWordList.firstWhere(
      (word) => word.contains(query),
      orElse: () => '',
    );

    if (match.isNotEmpty) {
      setState(() {
        selected = match;
        filteredWordList = filteredWordList
            .where((word) => word.contains(query))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
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
                        onTap: () {
                          setState(() {
                            selected = null;
                          });
                        },
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
                        children: filteredWordList.map((word) {
                          return WordTile(
                            key: wordKeys[word],
                            word: word,
                            wid: widget.wordIdMap[word] ?? 0,
                            userID: widget.userID,
                            isBookmarked: bookmarked.contains(word),
                            onTap: () => selectWord(word),
                            onBookmarkToggle: (result) =>
                                toggleBookmark(word, result),
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
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
