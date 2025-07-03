import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sign_language/service/translate_api.dart';
import 'package:sign_language/widget/bottom_nav_bar.dart';
import 'package:video_player/video_player.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => TranslateScreenState();
}

class TranslateScreenState extends State<TranslateScreen> {
  bool isSignToKorean = true; // true: 수어 -> 한글 | false 한글 -> 수어
  bool isCameraOn = false;
  int countdown = 0;
  XFile? capturedVideo;

  CameraController? cameraController;

  final TextEditingController inputController = TextEditingController();

  // 콤보박스
  final List<String> langs = ['한국어', 'English', '日本語', '中文'];
  String selectedLang = '한국어';

  String? resultKorean;
  String? resultEnglish;
  String? resultJapanese;
  String? resultChinese;

  VideoPlayerController? controller;
  Future<void>? initVideoPlayer;

  void toggleDirection() {
    setState(() {
      isSignToKorean = !isSignToKorean;
      isCameraOn = false;
    });
  }

  Future<void> toggleCamera() async {
    if (isCameraOn) {
      await stopCamera();
    } else {
      await startCamera();
    }
  }

  Future<void> startCamera() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();
    if (!cameraStatus.isGranted || !micStatus.isGranted) {
      Fluttertoast.showToast(
        msg: '카메라 또는 마이크 권한이 거부되었습니다.',
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await cameraController!.initialize();
      await cameraController!.prepareForVideoRecording();
      await cameraController!.startVideoRecording();
    } catch (e) {
      Fluttertoast.showToast(msg: "카메라 시작 실패: $e");
      return;
    }

    setState(() {
      isCameraOn = true;
    });
  }

  Future<void> stopCamera() async {
    if (cameraController == null) return;

    try {
      if (cameraController!.value.isRecordingVideo) {
        final file = await cameraController!.stopVideoRecording();

        await Future.delayed(Duration(milliseconds: 300));

        capturedVideo = file;
        final size = await File(file.path).length();
        print("영상 저장됨: ${file.path}, 크기: $size bytes");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "녹화 종료 실패: $e");
      return;
    }

    try {
      await Future.delayed(Duration(milliseconds: 100));
      await cameraController!.dispose();
    } catch (e) {
      print("카메라 dispose 중 오류: $e");
    }

    cameraController = null;

    if (mounted) {
      setState(() {
        isCameraOn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputLabel = isSignToKorean ? '수어 영상 촬영' : '$selectedLang 입력';

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
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 왼쪽 '수어' 혹은 언어 드롭다운
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: isSignToKorean
                                ? Text(
                                    '수어',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  )
                                : DropdownButton<String>(
                                    value: selectedLang,
                                    icon: Icon(Icons.arrow_drop_down, size: 24),
                                    underline: SizedBox(),
                                    items: langs
                                        .map(
                                          (lang) => DropdownMenuItem(
                                            value: lang,
                                            child: Text(
                                              lang,
                                              style: TextStyle(fontSize: 24),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (lang) =>
                                        setState(() => selectedLang = lang!),
                                  ),
                          ),
                        ),

                        // 변환 아이콘
                        IconButton(
                          icon: Icon(Icons.sync_alt, size: 30),
                          onPressed: toggleDirection,
                        ),

                        // 오른쪽 '수어' 혹은 언어 드롭다운
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: isSignToKorean
                                ? DropdownButton<String>(
                                    value: selectedLang,
                                    icon: Icon(Icons.arrow_drop_down, size: 24),
                                    underline: SizedBox(),
                                    items: langs
                                        .map(
                                          (lang) => DropdownMenuItem(
                                            value: lang,
                                            child: Text(
                                              lang,
                                              style: TextStyle(fontSize: 24),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (lang) =>
                                        setState(() => selectedLang = lang!),
                                  )
                                : Text(
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
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 330,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        // 카메라 영상 미리보기
                        if (isSignToKorean &&
                            isCameraOn &&
                            cameraController != null &&
                            cameraController!.value.isInitialized)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CameraPreview(cameraController!),
                            ),
                          ),

                        // 입력창
                        Positioned.fill(
                          child: Container(
                            color: isSignToKorean && isCameraOn
                                ? Colors.black.withValues(alpha: 0.5)
                                : Colors.transparent,
                            padding: EdgeInsets.only(right: 40),
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
                              ),
                              maxLines: null,
                              readOnly: isSignToKorean,
                            ),
                          ),
                        ),

                        // 카메라 아이콘
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

                        // 카운트다운
                        if (isSignToKorean && isCameraOn && countdown > 0)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.5),
                              alignment: Alignment.center,
                              child: Text(
                                '$countdown',
                                style: TextStyle(
                                  fontSize: 60,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 330,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.topLeft,
                    child: resultKorean == null
                        ? Text('번역 결과', style: TextStyle(fontSize: 16))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isSignToKorean && resultKorean != null) ...[
                                Text(
                                  '한글: $resultKorean',
                                  style: TextStyle(fontSize: 28),
                                ),
                                Text(
                                  '영어: $resultEnglish',
                                  style: TextStyle(fontSize: 28),
                                ),
                                Text(
                                  '일본어: $resultJapanese',
                                  style: TextStyle(fontSize: 28),
                                ),
                                Text(
                                  '중국어: $resultChinese',
                                  style: TextStyle(fontSize: 28),
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (!isSignToKorean && initVideoPlayer != null)
                                FutureBuilder(
                                  key: ValueKey(controller),
                                  future: initVideoPlayer,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                            ConnectionState.done &&
                                        controller != null &&
                                        controller!.value.isInitialized) {
                                      return Column(
                                        children: [
                                          AspectRatio(
                                            aspectRatio:
                                                controller!.value.aspectRatio,
                                            child: VideoPlayer(controller!),
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              IconButton(
                                                icon: Icon(
                                                  controller!.value.isPlaying
                                                      ? Icons.pause
                                                      : Icons.play_arrow,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    controller!.value.isPlaying
                                                        ? controller!.pause()
                                                        : controller!.play();
                                                  });
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.stop),
                                                onPressed: () {
                                                  controller!.pause();
                                                  controller!.seekTo(
                                                    Duration.zero,
                                                  );
                                                  setState(() {});
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    } else {
                                      return const SizedBox(
                                        height: 180,
                                        child: Center(child: Text("수어 영상 없음")),
                                      );
                                    }
                                  },
                                ),
                              if (resultKorean == null)
                                Text('번역 결과', style: TextStyle(fontSize: 16)),
                            ],
                          ),
                  ),
                ),
                SizedBox(height: 4),
                ElevatedButton(
                  onPressed: () async {
                    if (isSignToKorean) {
                      // 수어 -> 한글/일본어/영어/중국어
                      if (capturedVideo == null) {
                        print('촬영된 영상이 없습니다.');
                        return;
                      }

                      final videoBytes = await capturedVideo!.readAsBytes();
                      final result =
                          await TranslateApi.translate_camera_to_word(
                            videoBytes,
                          );
                      if (result != null) {
                        setState(() {
                          resultKorean = result['korean'];
                          resultEnglish = result['english'];
                          resultJapanese = result['japanese'];
                          resultChinese = result['chinese'];
                        });
                      } else {
                        print('번역 실패');
                      }
                    } else {
                      // 한국어 → 수어
                      final word = inputController.text.trim();
                      if (word.isEmpty) {
                        Fluttertoast.showToast(msg: '번역할 단어를 입력하세요.');
                        return;
                      }

                      final videoUrl =
                          await TranslateApi.translate_word_to_video(word);
                      if (controller != null &&
                          controller!.value.isInitialized) {
                        await controller!.pause();
                        await controller!.dispose();
                      }

                      if (videoUrl != null) {
                        controller = VideoPlayerController.networkUrl(
                          Uri.parse(videoUrl),
                        )..setPlaybackSpeed(1.0);

                        initVideoPlayer = controller!.initialize().then((_) {
                          setState(() {
                            resultKorean = word;
                          });
                          controller!.play();
                        });
                      } else {
                        Fluttertoast.showToast(msg: '수어 애니메이션이 없습니다.');
                      }
                    }
                  },
                  child: Text('번역하기'),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(),
    );
  }
}
