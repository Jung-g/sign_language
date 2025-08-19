import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sign_language/model/course_model.dart';
import 'package:sign_language/screen/login_screen.dart';
import 'package:sign_language/screen/main_screen.dart';
import 'package:sign_language/service/auto_login_api.dart';
import 'package:sign_language/service/token_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final refreshToken = await TokenStorage.getRefreshToken();
  bool isLoggedIn = false;

  if (refreshToken != null && refreshToken.isNotEmpty) {
    final result = await AutoLoginApi.autoLogin(refreshToken);
    isLoggedIn = result == true;
  } else {
    debugPrint('[INFO] refresh token 없음 또는 복호화 실패 → 자동 로그인 실패 → 토큰 초기화');
    await TokenStorage.clearTokens();
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => CourseModel()..loadFromPrefs(),
      child: MyApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '수어 학습 앱',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: isLoggedIn ? const MainScreen() : const LoginScreen(),
    );
  }
}
