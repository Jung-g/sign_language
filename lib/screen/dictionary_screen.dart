import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sign_language/service/bookmark_api.dart';
import 'package:sign_language/service/word_detail_api.dart';
import 'package:sign_language/widget/animation_widget.dart';
import 'package:sign_language/widget/bottom_nav_bar.dart';
import 'package:sign_language/widget/indexbar.dart';
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
  late List<String> filteredWordList;
  final Set<String> bookmarked = {};
  final Map<String, GlobalKey> wordKeys = {};
  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();

  String? selected;
  int? selectedWid;
  String? selectedPos;
  String? selectedDefinition;
  bool isLoadingDetail = false;

  GlobalKey<AnimationWidgetState>? animationKey;
  List<Uint8List>? animationFrames;

  // 초성 인덱스
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

  @override
  void initState() {
    super.initState();
    filteredWordList = List.from(widget.words);
    filteredWordList.sort((a, b) => a.compareTo(b));
    for (var w in widget.words) {
      wordKeys[w] = GlobalKey();
    }
    animationKey = GlobalKey<AnimationWidgetState>();
    animationFrames = null;
    loadInitialBookmarks();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> loadInitialBookmarks() async {
    try {
      final result = await BookmarkApi.loadBookmark();
      setState(() {
        bookmarked.addAll(result.keys);
      });
    } catch (e) {
      Fluttertoast.showToast(msg: '북마크 로드 실패');
    }
  }

  String getInitial(String word) {
    final code = word.codeUnitAt(0);
    if (code < 0xAC00 || code > 0xD7A3) return '#';
    const init = [
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
    return init[(code - 0xAC00) ~/ 588];
  }

  void toggleBookmark(String word, bool success) {
    if (!success) {
      Fluttertoast.showToast(msg: '북마크 변경 실패');
      return;
    }
    setState(() {
      if (bookmarked.contains(word)) {
        bookmarked.remove(word);
        Fluttertoast.showToast(msg: '$word 북마크 해제');
      } else {
        bookmarked.add(word);
        Fluttertoast.showToast(msg: '$word 북마크 추가');
      }
    });
  }

  void selectWord(String word) async {
    FocusScope.of(context).unfocus();

    final wid = widget.wordIdMap[word];
    if (wid == null || wid == 0) return;

    setState(() {
      selected = word;
      selectedWid = wid;
      selectedPos = null;
      selectedDefinition = null;
      isLoadingDetail = true;
    });

    try {
      final data = await WordDetailApi.fetch(wid: wid);
      final decodedFrames = data['frames'] as List<Uint8List>;

      setState(() {
        selectedPos = data['pos'];
        selectedDefinition = data['definition'];
        animationKey = GlobalKey<AnimationWidgetState>();
        animationFrames = decodedFrames;
        isLoadingDetail = false;
      });

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.4,
            maxChildSize: 0.8,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(245),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: ListView(
                  controller: scrollController,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selected ?? '',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '[${selectedPos ?? ''}] ${selectedDefinition ?? ''}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    animationFrames != null && animationFrames!.isNotEmpty
                        ? Column(
                            children: [
                              AnimationWidget(
                                key: animationKey,
                                frames: animationFrames!,
                                fps: 12.0,
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    animationKey?.currentState?.reset(),
                                icon: const Icon(Icons.replay),
                                label: const Text('다시보기'),
                              ),
                            ],
                          )
                        : const SizedBox(
                            height: 150,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                  ],
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      Fluttertoast.showToast(msg: '단어 정보를 불러오는 데 실패했습니다.');
      setState(() => isLoadingDetail = false);
    }
  }

  void scrollToFirstWordWith(String initial) {
    final idx = initial == '#'
        ? filteredWordList.indexWhere((w) => RegExp(r'^[0-9]').hasMatch(w))
        : filteredWordList.indexWhere((w) => getInitial(w) == initial);
    if (idx != -1) {
      scrollController.animateTo(
        idx * 56.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
      );
    }
  }

  void performSearch() {
    final q = searchController.text.trim();
    setState(() {
      if (q.isEmpty) {
        filteredWordList = List.from(widget.words);
      } else {
        filteredWordList = widget.words.where((w) => w.contains(q)).toList();
      }
      selected = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('단어 사전'),
        automaticallyImplyLeading: false,
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              // 검색창
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
                        onTap: () => setState(() => selected = null),
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

              // 단어 리스트 + 인덱스바
              Expanded(
                child: Stack(
                  children: [
                    ListView(
                      controller: scrollController,
                      padding: EdgeInsets.only(bottom: bottomInset, right: 24),
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
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: selected != null ? 250 : 0,
                      child: isKeyboardVisible
                          ? const SizedBox.shrink()
                          : IndexBar(
                              initials: initials,
                              onTap: scrollToFirstWordWith,
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // bottomNavigationBar: const BottomNavBar(),
    );
  }
}
