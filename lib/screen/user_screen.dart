import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sign_language/screen/delete_user_screen.dart';
import 'package:sign_language/screen/login_screen.dart';
import 'package:sign_language/screen/update_user_screen.dart';
import 'package:sign_language/service/logout_api.dart';
import 'package:sign_language/service/token_storage.dart';
import 'package:sign_language/widget/menu_button.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => UserScreenState();
}

class UserScreenState extends State<UserScreen> {
  String nickname = '';

  @override
  void initState() {
    super.initState();
    getnickname();
  }

  void getnickname() async {
    final loadnickname = await TokenStorage.getNickName();
    setState(() {
      nickname = loadnickname ?? 'noname';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('사용자 설정')),
      body: SafeArea(
        child: Column(
          children: [
            Icon(Icons.person, color: Colors.purple, size: 120),
            SizedBox(height: 8),
            Text(
              nickname,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 20),
            MenuButton(
              text: '회원 정보 수정',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UpdateUserScreen(),
                  ),
                );
              },
            ),
            MenuButton(
              text: '로그아웃',
              onTap: () async {
                final refreshToken = await TokenStorage.getRefreshToken();

                if (refreshToken == null || refreshToken.isEmpty) {
                  print('토큰 오류(유효하지 않은 토큰)');
                  return;
                }

                final success = await LogoutApi.logout(refreshToken);

                if (success) {
                  await TokenStorage.clearTokens(); // 토큰 삭제
                  Fluttertoast.showToast(
                    msg: '로그아웃 되었습니다',
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.green,
                    textColor: Colors.white,
                  );
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                    (route) => false,
                  );
                } else {
                  Fluttertoast.showToast(
                    msg: '로그아웃 실패',
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                  );
                }
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DeleteUserScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
