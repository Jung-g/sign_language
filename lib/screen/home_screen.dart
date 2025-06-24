import 'package:flutter/material.dart';
import 'package:sign_language/widget/bottom_nav_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 학습 달력 부분
                Align(
                  alignment: Alignment.centerLeft,
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.teal,
                    child: IconButton(
                      icon: const Icon(
                        Icons.search, // 아이콘 다른거로 변경 예정
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () {
                        // 학습 달력 연결
                      },
                    ),
                  ),
                ),

                const Center(
                  child: Text('학습 코스를 선택해 주세요', style: TextStyle(fontSize: 16)),
                ),

                // 사용자 설정 부분
                Align(
                  alignment: Alignment.centerRight,
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.purple.shade100,
                    child: IconButton(
                      icon: const Icon(
                        Icons.person,
                        color: Colors.purple,
                        size: 24,
                      ),
                      onPressed: () {
                        // 사용자 설정 연결
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),
          BottomNavBar(),
        ],
      ),
    );
  }
}
