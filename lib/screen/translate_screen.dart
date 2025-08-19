import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sign_language/service/translate_api.dart';
import 'package:sign_language/widget/animation_widget.dart';
import 'package:sign_language/widget/camera_widget.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => TranslateScreenState();
}

class TranslateScreenState extends State<TranslateScreen> {
  // 수어 → 한국어(true) / 한국어 → 수어(false)
  bool isSignToKorean = true;

  // 카메라 상태
  bool isCameraOn = false;
  final GlobalKey<CameraWidgetState> camKey = GlobalKey<CameraWidgetState>();

  // 입력 및 출력
  final TextEditingController inputController = TextEditingController();
  final List<String> langs = ['한국어', '영어', '일본어', '중국어'];
  String selectedLang = '한국어';

  String? resultKorean;
  String? resultEnglish;
  String? resultJapanese;
  String? resultChinese;

  // 실시간 누적 자막
  final List<String> transcript = [];
  String? lastToken;
  static const int transcriptLimit = 200;
  static const Set<String> ignorePhrases = {
    '인식된 단어가 없습니다.',
    '인식 결과 없음',
    'no result',
  };

  // 최종 결과만 보여주는 잠금 플래그
  bool showFinalOnly = false;

  final GlobalKey<AnimationWidgetState> animationKey =
      GlobalKey<AnimationWidgetState>();
  List<Uint8List> decodedFrames = [];

  @override
  void dispose() {
    unawaited(camKey.currentState?.stop());
    super.dispose();
  }

  String? selectedTranslation() {
    switch (selectedLang) {
      case '한국어':
        return resultKorean;
      case '영어':
        return resultEnglish?.isNotEmpty == true ? resultEnglish : null;
      case '일본어':
        return resultJapanese?.isNotEmpty == true ? resultJapanese : null;
      case '중국어':
        return resultChinese?.isNotEmpty == true ? resultChinese : null;
      default:
        return resultKorean;
    }
  }

  // 서버 전송 함수(카메라 위젯에 주입)
  Future<Map<String, dynamic>?> _sendFramesToServer(List<String> base64Frames) {
    return TranslateApi.sendFrames(base64Frames);
  }

  // 서버 응답 처리(실시간)
  void _onServerResponse(Map<String, dynamic> res) {
    if (showFinalOnly) return;

    final token = (res['korean'] as String? ?? '').trim();
    if (token.isEmpty) return;
    if (ignorePhrases.contains(token)) return;
    if (token == lastToken) return;

    setState(() {
      lastToken = token;
      transcript.add(token);
      if (transcript.length > transcriptLimit) {
        transcript.removeRange(0, transcript.length - transcriptLimit);
      }

      resultKorean = token;
      resultEnglish = (res['english'] as String?)?.trim();
      resultJapanese = (res['japanese'] as String?)?.trim();
      resultChinese = (res['chinese'] as String?)?.trim();
    });
  }

  // 모드 전환
  void toggleDirection() {
    setState(() {
      isSignToKorean = !isSignToKorean;

      unawaited(camKey.currentState?.stop());

      showFinalOnly = false;
      lastToken = null;
      transcript.clear();

      inputController.clear();
      resultKorean = null;
      resultEnglish = null;
      resultJapanese = null;
      resultChinese = null;
      decodedFrames = [];
    });
  }

  // 카메라 토글
  Future<void> toggleCamera() async {
    if (isCameraOn) {
      await camKey.currentState?.stop();
    } else {
      await camKey.currentState?.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputLabel = isSignToKorean
        ? '수어를 촬영하면 번역 결과가 표시됩니다'
        : '$selectedLang로 번역할 단어를 입력하세요';

    final displayText = selectedTranslation();
    final hasText = (displayText != null && displayText.isNotEmpty);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: isSignToKorean
                                ? const Text(
                                    '수어',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  )
                                : DropdownButton<String>(
                                    value: selectedLang,
                                    icon: const Icon(
                                      Icons.arrow_drop_down,
                                      size: 24,
                                    ),
                                    underline: const SizedBox(),
                                    items: langs
                                        .map(
                                          (lang) => DropdownMenuItem(
                                            value: lang,
                                            child: Text(
                                              lang,
                                              style: const TextStyle(
                                                fontSize: 24,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (lang) =>
                                        setState(() => selectedLang = lang!),
                                  ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.sync_alt, size: 30),
                          onPressed: toggleDirection,
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: isSignToKorean
                                ? DropdownButton<String>(
                                    value: selectedLang,
                                    icon: const Icon(
                                      Icons.arrow_drop_down,
                                      size: 24,
                                    ),
                                    underline: const SizedBox(),
                                    items: langs
                                        .map(
                                          (lang) => DropdownMenuItem(
                                            value: lang,
                                            child: Text(
                                              lang,
                                              style: const TextStyle(
                                                fontSize: 24,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (lang) =>
                                        setState(() => selectedLang = lang!),
                                  )
                                : const Text(
                                    '수어',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 입력 영역 (CameraPreview 포함)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 330,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 238, 229, 255),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        width: 3,
                        color: isSignToKorean
                            ? (isCameraOn ? Colors.green : Colors.red)
                            : Colors.transparent,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // 카메라 위젯
                        if (isSignToKorean)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CameraWidget(
                                key: camKey,
                                visible: isSignToKorean && isCameraOn,
                                paused: showFinalOnly,
                                batchSize: 45,
                                maxBuffer: 120,
                                useNV12: false,
                                rotate90CCW: true,
                                targetSize: const Size(720, 480),
                                preferFrontCamera: true,
                                onSend: _sendFramesToServer,
                                onServerResponse: _onServerResponse,
                                onCameraState: (on) =>
                                    setState(() => isCameraOn = on),
                              ),
                            ),
                          ),

                        // 입력창
                        Positioned.fill(
                          child: Container(
                            color: isSignToKorean && isCameraOn
                                ? Colors.black.withAlpha(128)
                                : Colors.transparent,
                            padding: const EdgeInsets.only(right: 40),
                            alignment: Alignment.topLeft,
                            child: TextField(
                              controller: inputController,
                              style: isSignToKorean && isCameraOn
                                  ? const TextStyle(color: Colors.white)
                                  : const TextStyle(color: Colors.black),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: (isSignToKorean && isCameraOn)
                                    ? null
                                    : inputLabel,
                                hintStyle: TextStyle(
                                  color: Colors.black.withAlpha(153),
                                ),
                              ),
                              maxLines: null,
                              readOnly: isSignToKorean,
                            ),
                          ),
                        ),

                        if (isSignToKorean)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              icon: Icon(
                                isCameraOn
                                    ? Icons.camera_alt
                                    : Icons.no_photography,
                                color: Colors.black,
                                size: 32,
                              ),
                              onPressed: toggleCamera,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 결과 패널
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 330,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 238, 229, 255),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.topLeft,
                    child: isSignToKorean
                        ? ((!isCameraOn && transcript.isEmpty)
                              ? Text(
                                  '인식 결과가 여기에 줄바꿈으로 표시됩니다',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black.withAlpha(153),
                                  ),
                                )
                              : SingleChildScrollView(
                                  child: SelectableText(
                                    transcript.join('\n'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.4,
                                    ),
                                  ),
                                ))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (decodedFrames.isNotEmpty) ...[
                                AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: AnimationWidget(
                                    key: animationKey,
                                    frames: decodedFrames,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.center,
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        animationKey.currentState?.reset(),
                                    icon: const Icon(Icons.replay),
                                    label: const Text('다시보기'),
                                  ),
                                ),
                              ] else if (hasText) ...[
                                Text(
                                  displayText,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ] else ...[
                                Text(
                                  '번역 결과가 여기에 표시됩니다',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black.withAlpha(153),
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 4),

                ElevatedButton(
                  onPressed: () async {
                    if (isSignToKorean) {
                      final result = await TranslateApi.translateLatest();
                      if (result != null) {
                        final String k = (result['korean'] is List)
                            ? (result['korean'] as List).join(' ')
                            : (result['korean']?.toString() ?? '');

                        final String e = (result['english']?.toString() ?? '')
                            .trim();
                        final String j = (result['japanese']?.toString() ?? '')
                            .trim();
                        final String c = (result['chinese']?.toString() ?? '')
                            .trim();

                        setState(() {
                          showFinalOnly = true;

                          transcript
                            ..clear()
                            ..add(k);
                          if (transcript.length > transcriptLimit) {
                            transcript.removeRange(
                              0,
                              transcript.length - transcriptLimit,
                            );
                          }
                          lastToken = k;

                          resultKorean = k;
                          resultEnglish = e.isNotEmpty ? e : null;
                          resultJapanese = j.isNotEmpty ? j : null;
                          resultChinese = c.isNotEmpty ? c : null;
                        });
                      } else {
                        debugPrint('번역 실패');
                      }
                    } else {
                      final word = inputController.text.trim();
                      if (word.isEmpty) {
                        Fluttertoast.showToast(msg: '번역할 단어를 입력하세요.');
                        return;
                      }
                      final frameList =
                          await TranslateApi.translate_word_to_video(word);
                      if (frameList != null && frameList.isNotEmpty) {
                        setState(() {
                          decodedFrames = frameList
                              .map((b64) => base64Decode(b64))
                              .toList();
                          resultKorean = word;
                        });
                      } else {
                        Fluttertoast.showToast(msg: '수어 애니메이션이 없습니다.');
                      }
                    }
                  },
                  child: const Text('확인하기'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
