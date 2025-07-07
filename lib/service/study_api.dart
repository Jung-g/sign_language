import 'dart:convert';
import 'package:http/http.dart' as http;

const String baseUrl = 'http://10.101.132.200';

class StudyApi {
  // 학습 코스 목록 불러오기
  static Future<List<Map<String, dynamic>>> fetchStudyCourses() async {
    try {
      final url = Uri.parse('$baseUrl/study/list');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('코스 불러오기 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }
}
