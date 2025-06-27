import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sign_language/screen/login_screen.dart';
import 'package:sign_language/service/reset_password_api.dart';
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Textbox(controller: idcontrollor, hintText: '아이디를 입력해주세요'),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 100,
                    child: MenuButton(
                      text: '찾기',
                      padding: EdgeInsets.symmetric(vertical: 8),
                      onTap: () async {
                        final id = idcontrollor.text.trim();
                        final exists = await PasswordResetApi.checkUserIDExists(
                          id,
                        );

                        if (!exists) {
                          Fluttertoast.showToast(
                            msg: "존재하지 않는 아이디입니다.",
                            gravity: ToastGravity.BOTTOM,
                            backgroundColor: Colors.red,
                            textColor: Colors.white,
                          );
                          return;
                        }

                        setState(() {
                          found = exists; // true면 비번 입력 칸 나옴
                        });
                      },
                    ),
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
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 100,
                      child: MenuButton(
                        text: '변경하기',
                        padding: EdgeInsets.symmetric(vertical: 8),
                        onTap: () async {
                          final id = idcontrollor.text.trim();
                          final newPw = pwcontrollor.text.trim();
                          final confirmPw = passwordcontrollor.text.trim();

                          if (newPw.isEmpty || confirmPw.isEmpty) {
                            Fluttertoast.showToast(
                              msg: "비밀번호를 모두 입력해주세요.",
                              gravity: ToastGravity.BOTTOM,
                              backgroundColor: Colors.red,
                              textColor: Colors.white,
                            );
                            return;
                          }

                          if (newPw != confirmPw) {
                            Fluttertoast.showToast(
                              msg: "비밀번호가 일치하지 않습니다.",
                              gravity: ToastGravity.BOTTOM,
                              backgroundColor: Colors.red,
                              textColor: Colors.white,
                            );
                            return;
                          }

                          final success = await PasswordResetApi.resetPassword(
                            userID: id,
                            newPassword: newPw,
                          );

                          if (success && mounted) {
                            Fluttertoast.showToast(
                              msg: "비밀번호가 재설정되었습니다.",
                              gravity: ToastGravity.BOTTOM,
                              backgroundColor: Colors.green,
                              textColor: Colors.white,
                            );
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => LoginScreen()),
                            );
                          } else {
                            Fluttertoast.showToast(
                              msg: "비밀번호 재설정 실패",
                              gravity: ToastGravity.BOTTOM,
                              backgroundColor: Colors.red,
                              textColor: Colors.white,
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
