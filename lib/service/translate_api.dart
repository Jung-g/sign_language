import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:sign_language/service/token_storage.dart';

const String baseUrl = 'http://10.101.132.200';

class TranslateApi {
  // 수어 -> 단어
  static Future<Map<String, String>?> translate_camera_to_word(
    Uint8List imageBytes,
  ) async {
    final accessToken = await TokenStorage.getAccessToken();
    final refreshToken = await TokenStorage.getRefreshToken();

    final url = Uri.parse("$baseUrl/translate/sign_to_text");

    final request = http.MultipartRequest("POST", url)
      ..headers['Authorization'] = 'Bearer $accessToken'
      ..headers['X-Refresh-Token'] = refreshToken ?? ''
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'video.mp4',
          contentType: MediaType('video', 'mp4'),
        ),
      );

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final newToken = response.headers['x-new-access-token'];
      if (newToken != null && newToken.isNotEmpty) {
        await TokenStorage.setAccessToken(newToken);
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'korean': data['korean'],
          'english': data['english'],
          'chinese': data['chinese'],
          'japanese': data['japanese'],
        };
      } else {
        print("번역 실패: ${response.statusCode} ${response.body}");
        return null;
      }
    } catch (e) {
      print("번역 요청 중 오류 발생: $e");
      return null;
    }
  }

  // 단어 -> 수어
  static Future<String?> translate_word_to_video(String wordText) async {
    final accessToken = await TokenStorage.getAccessToken();
    final refreshToken = await TokenStorage.getRefreshToken();

    final url = Uri.parse(
      "$baseUrl/translate/text_to_sign?word_text=$wordText",
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'X-Refresh-Token': refreshToken ?? '',
        },
      );

      final newToken = response.headers['x-new-access-token'];
      if (newToken != null && newToken.isNotEmpty) {
        await TokenStorage.setAccessToken(newToken);
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final videoURL = data['URL'] ?? '';
        return videoURL;
      } else {
        print("영상 URL 요청 실패: ${response.statusCode} ${response.body}");
        return null;
      }
    } catch (e) {
      print("영상 URL 요청 중 오류 발생: $e");
      return null;
    }
  }
}
