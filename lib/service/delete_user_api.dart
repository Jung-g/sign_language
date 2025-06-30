import 'dart:convert';
import 'package:http/http.dart' as http;

const String baseUrl = 'http://10.101.92.18';

class DeleteUserApi {
  static Future<bool> deleteUser({
    required String password,
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/delete_user');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'X-Refresh-Token': refreshToken,
        },
        body: jsonEncode({'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final success = data['success'];

        return success;
      } else {
        return false;
      }
    } catch (e) {
      print('회원탈퇴 오류: $e');
      return false;
    }
  }
}
