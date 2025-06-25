import 'package:flutter/material.dart';
import 'package:sign_language/screen/login_screen.dart';
import 'package:sign_language/widget/menu_button.dart';
import 'package:sign_language/widget/textbox.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  State<PasswordRecoveryScreen> createState() => PasswordRecoveryScreenState();
}

class PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final TextEditingController idcontrollor = TextEditingController();
  final TextEditingController pwcontrollor = TextEditingController();
  final TextEditingController passwordcontrollor = TextEditingController();
  bool found = false;

  @override
  void dispose() {
    idcontrollor.dispose();
    pwcontrollor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 80,
        title: Text(
          '비밀번호 찾기',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w600,
            color: Colors.blue,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Textbox(controller: idcontrollor, hintText: '아이디를 입력해주세요'),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 100,
                        child: MenuButton(
                          text: '찾기',
                          padding: EdgeInsets.symmetric(vertical: 8),
                          onTap: () {
                            setState(() {
                              found = true;
                            });
                          },
                        ),
                      ),
                      if (found) ...[
                        Textbox(
                          controller: pwcontrollor,
                          hintText: '새 비밀번호 입력하세요',
                          obscureText: true,
                        ),
                        Textbox(
                          controller: passwordcontrollor,
                          hintText: '비밀번호 확인',
                          obscureText: true,
                        ),
                        SizedBox(
                          width: 100,
                          child: MenuButton(
                            text: '돌아가기',
                            padding: EdgeInsets.symmetric(vertical: 8),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoginScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
