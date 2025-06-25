import 'package:flutter/material.dart';
import 'package:sign_language/screen/login_screen.dart';
import 'package:sign_language/widget/menu_button.dart';
import 'package:sign_language/widget/textbox.dart';

class InsertuserScreen extends StatefulWidget {
  const InsertuserScreen({super.key});

  @override
  State<InsertuserScreen> createState() => InsertuserScreenState();
}

class InsertuserScreenState extends State<InsertuserScreen> {
  final TextEditingController usercontroller = TextEditingController();
  final TextEditingController idcontroller = TextEditingController();
  final TextEditingController pwcontroller = TextEditingController();
  final TextEditingController passwordcontroller = TextEditingController();

  @override
  void dispose() {
    usercontroller.dispose();
    idcontroller.dispose();
    pwcontroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 80,
        title: Text(
          '회원가입',
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
                Textbox(controller: usercontroller, hintText: '닉네임을 입력하세요'),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 100,
                    child: MenuButton(
                      text: '중복확인',
                      padding: EdgeInsets.symmetric(vertical: 8),
                      onTap: () {},
                    ),
                  ),
                ),

                Textbox(controller: idcontroller, hintText: '아이디를 입력하세요'),
                Textbox(controller: pwcontroller, hintText: '비밀번호를 입력하세요'),
                Textbox(
                  controller: passwordcontroller,
                  hintText: '비밀번호 확인',
                  obscureText: true,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 100,
                    child: MenuButton(
                      text: '회원가입',
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
