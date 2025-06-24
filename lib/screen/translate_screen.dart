import 'package:flutter/material.dart';
import 'package:sign_language/widget/bottom_nav_bar.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  bool isSignToKorean = true; // true: 수어 > 한글 | false 한글 > 수어
  bool isCameraOn = false;

  final TextEditingController inputController = TextEditingController();

  void toggleDirection() {
    setState(() {
      isSignToKorean = !isSignToKorean;
      isCameraOn = false;
    });
  }

  void toggleCamera() {
    setState(() {
      isCameraOn = !isCameraOn;
    });
  }

  @override
  Widget build(BuildContext context) {
    final inputLabel = isSignToKorean ? '수어 입력' : '한글 입력';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 상단 전환 버튼
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isSignToKorean ? '수어' : '한글',
                    style: const TextStyle(fontSize: 30),
                  ),
                  IconButton(
                    icon: const Icon(Icons.sync_alt, size: 30),
                    onPressed: toggleDirection,
                  ),
                  Text(
                    isSignToKorean ? '한글' : '수어',
                    style: const TextStyle(fontSize: 30),
                  ),
                ],
              ),
            ),

            // 입력 영역
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 200,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: inputController,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: inputLabel,
                        ),
                        maxLines: null,
                      ),
                    ),
                    if (isSignToKorean)
                      IconButton(
                        icon: Icon(
                          isCameraOn ? Icons.camera_alt : Icons.no_photography,
                          size: 32,
                        ),
                        onPressed: toggleCamera,
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 출력 영역 (한글을 번역하면 수어 애니메이션 출력하기)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.topLeft,
                child: const Text('번역 결과', style: TextStyle(fontSize: 16)),
              ),
            ),

            const SizedBox(height: 16),

            // 번역 버튼
            ElevatedButton(
              onPressed: () {
                print('번역 버튼 클릭');
              },
              child: const Text('번역하기'),
            ),

            const Spacer(),
            BottomNavBar(),
          ],
        ),
      ),
    );
  }
}
