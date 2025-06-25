import 'package:flutter/material.dart';
import 'package:sign_language/widget/bottom_nav_bar.dart';
import 'package:sign_language/widget/menu_button.dart';

class StudycourceScreen extends StatefulWidget {
  const StudycourceScreen({super.key});

  @override
  State<StudycourceScreen> createState() => StudycourceScreenState();
}

class StudycourceScreenState extends State<StudycourceScreen> {
  final ScrollController scrollController = ScrollController();
  final List<String> sampleWordList = [
    '한글 자음/모음',
    '숫자',
    '단어 1',
    '단어 2',
    '3',
    '5',
    '6',
    '123',
    '51231',
    '23123',
  ];

  late final List<GlobalKey> itemKeys;

  @override
  void initState() {
    super.initState();
    itemKeys = List.generate(sampleWordList.length, (_) => GlobalKey());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                '학습코스 선택',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: EdgeInsets.only(
                  top: 16,
                  bottom:
                      kBottomNavigationBarHeight +
                      MediaQuery.of(context).padding.bottom +
                      16,
                ),
                itemCount: sampleWordList.length,
                itemBuilder: (context, index) {
                  return MenuButton(
                    text: sampleWordList[index],
                    onTap: () {
                      /*버튼 역할 코드 생성해야됨.*/
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
