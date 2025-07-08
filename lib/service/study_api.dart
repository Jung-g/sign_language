import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sign_language/service/token_storage.dart';

const String baseUrl = 'http://10.101.132.200';

class StudyApi {
  // 학습 코스 목록 불러오기
  static Future<List<Map<String, dynamic>>> StudyCourses() async {
    final accessToken = await TokenStorage.getAccessToken();
    final refreshToken = await TokenStorage.getRefreshToken();

    if (accessToken == null) throw Exception("accessToken 없음");
    if (refreshToken == null) throw Exception("refreshToken 없음");

    final response = await http.get(
      Uri.parse('$baseUrl/study/list'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'X-Refresh-Token': refreshToken,
      },
    );

    final newAccessToken = response.headers['x-new-access-token'];
    if (newAccessToken != null && newAccessToken.isNotEmpty) {
      await TokenStorage.setAccessToken(newAccessToken);
    }

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('코스 불러오기 실패: ${response.statusCode}');
    }
  }

  static Future<List<Map<String, dynamic>>> StudyCoursesData() async {
    final accessToken = await TokenStorage.getAccessToken();
    final refreshToken = await TokenStorage.getRefreshToken();

    if (accessToken == null) throw Exception("accessToken 없음");
    if (refreshToken == null) throw Exception("refreshToken 없음");

    final response = await http.get(
      Uri.parse('$baseUrl/study/course'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'X-Refresh-Token': refreshToken,
      },
    );

    final newAccessToken = response.headers['x-new-access-token'];
    if (newAccessToken != null && newAccessToken.isNotEmpty) {
      await TokenStorage.setAccessToken(newAccessToken);
    }

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('세부 데이터 불러오기 실패: ${response.statusCode}');
    }
  }
}
