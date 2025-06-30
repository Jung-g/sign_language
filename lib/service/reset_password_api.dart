import 'dart:convert';
import 'package:http/http.dart' as http;

const String baseUrl = 'http://10.101.92.18';

class PasswordResetApi {
  // userID 존재 여부 확인
  static Future<bool> checkUserIDExists(String userID) async {
    final response = await http.get(
      Uri.parse("$baseUrl/user/check_id?id=$userID"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return !data['available'];
    } else {
      throw Exception("ID 존재 확인 실패: ${response.statusCode}");
    }
  }

  // 비밀번호 재설정
  static Future<bool> resetPassword({
    required String userID,
    required String newPassword,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/user/reset_password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userID, 'new_password': newPassword}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    } else {
      print("비밀번호 재설정 실패: ${response.statusCode}");
      return false;
    }
  }
}
