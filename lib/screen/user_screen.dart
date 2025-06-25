import 'package:flutter/material.dart';
import 'package:sign_language/screen/login_screen.dart';
import 'package:sign_language/widget/bottom_nav_bar.dart';
import 'package:sign_language/widget/menu_button.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => UserScreenState();
}

class UserScreenState extends State<UserScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Icon(Icons.person, color: Colors.purple, size: 120),
            SizedBox(height: 8),
            Text(
              '사용자 이름 받아넣기',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 50),
            MenuButton(text: '회원 정보 수정', onTap: () {}),
            MenuButton(
              text: '로그아웃',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
            ),

            const Spacer(),
            MenuButton(
              text: '회원 탈퇴',
              textStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.red,
              ),
              onTap: () {},
            ),
            BottomNavBar(),
          ],
        ),
      ),
    );
  }
}
