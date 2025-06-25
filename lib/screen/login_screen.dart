import 'package:flutter/material.dart';
import 'package:sign_language/screen/home_screen.dart';
import 'package:sign_language/widget/menu_button.dart';
import 'package:sign_language/widget/textbox.dart';
import 'package:sign_language/screen/insertuser_screen.dart';
import 'package:sign_language/screen/passwordrecovery_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController idcontroller = TextEditingController();
  final TextEditingController passwordcontrollder = TextEditingController();

  @override
  void dispose() {
    idcontroller.dispose();
    passwordcontrollder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Text(
                  '바루',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 40),

                Textbox(controller: idcontroller, hintText: '아이디'),
                Textbox(
                  controller: passwordcontrollder,
                  hintText: '비밀번호',
                  obscureText: true,
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 100,
                        child: MenuButton(
                          text: '로그인',
                          padding: EdgeInsets.symmetric(vertical: 8),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HomeScreen(),
                              ),
                            );
                          },
                        ),
                      ),

                      SizedBox(
                        width: 100,
                        child: MenuButton(
                          text: '회원가입',
                          padding: EdgeInsets.symmetric(vertical: 8),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InsertuserScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 12,
          top: 8,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '비밀번호를 잊어버렸나요? ',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PasswordRecoveryScreen()),
                );
              },
              child: Text(
                '비밀번호 찾기',
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
