import 'package:flutter/material.dart';
import 'package:sign_language/screen/home_screen.dart';
import 'package:sign_language/screen/login_screen.dart';
import 'package:sign_language/service/auto_login_api.dart';
import 'package:sign_language/service/token_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final refreshToken = await TokenStorage.getRefreshToken();
  bool isLoggedIn = false;

  if (refreshToken != null && refreshToken.isNotEmpty) {
    final result = await AutoLoginApi.autoLogin(refreshToken);
    isLoggedIn = result == true;
  }

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '수어 학습 앱',
      debugShowCheckedModeBanner: false,
      home: isLoggedIn ? HomeScreen() : LoginScreen(),
    );
  }
}
