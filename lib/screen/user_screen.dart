import 'package:flutter/material.dart';
import 'package:sign_language/widget/bottom_nav_bar.dart';
import 'package:sign_language/widget/menuButton.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Icon(Icons.person, color: Colors.purple, size: 120),
            SizedBox(height: 8),
            Text(
              '홀리쉣',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 20),
            MenuButton(text: '회원 정보 수정', onTap: () {}),
            MenuButton(text: '로그아웃', onTap: () {}),

            const Spacer(),
            MenuButton(text: '회원 탈퇴', onTap: () {}),
            BottomNavBar(),
          ],
        ),
      ),
    );
  }
}
