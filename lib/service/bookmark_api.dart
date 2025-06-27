import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sign_language/service/token_storage.dart';

const String baseUrl = 'http://10.101.52.226';

class BookmarkApi {
  // 북마크 저장
  static Future<bool?> toggleBookmark({
    required String userID,
    required int wid,
  }) async {
    final url = Uri.parse("$baseUrl/bookmark/add");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"user_id": userID, "word_id": wid}),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result["bookmarked"] as bool;
      } else {
        print("북마크 실패: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("오류: $e");
      return false;
    }
  }

  // 북마크 보기
  static Future<Map<String, int>> fetchBookmarkedWords() async {
    final accessToken = await TokenStorage.getAccessToken();
    if (accessToken == null) throw Exception("accessToken 없음");

    final response = await http.get(
      Uri.parse("$baseUrl/bookmark/list"),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      final Map<String, int> bookmarkedMap = {};
      for (final item in data) {
        bookmarkedMap[item['word']] = item['wid'];
      }
      return bookmarkedMap;
    } else {
      throw Exception("북마크 리스트 요청 실패: ${response.statusCode}");
    }
  }
}
