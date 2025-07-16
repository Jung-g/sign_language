import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sign_language/service/translate_api.dart';
import 'package:sign_language/widget/bottom_nav_bar.dart';
import 'package:video_player/video_player.dart';
import 'package:image/image.dart' as img;
// import 'package:sign_language/widget/camera_widget.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => TranslateScreenState();
}

class TranslateScreenState extends State<TranslateScreen> {
  bool isSignToKorean = true; // true: 수어 -> 한글 | false 한글 -> 수어
  bool isCameraOn = false;
  XFile? capturedVideo;
  bool isProcessingFrame = false;
  CameraController? cameraController;
  final List<Uint8List> frameBuffer = [];

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

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  @override
  void dispose() {
    stopCamera();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await [Permission.camera].request();
  }

  Future<void> sendFrames(List<Uint8List> frames) async {
    print("--- 프레임 ${frames.length}개 서버로 전송 시도...");
    final List<String> base64Frames = frames
        .map((frame) => base64Encode(frame))
        .toList();

    try {
      final result = await TranslateApi.sendFrames(base64Frames);
      if (result != null) {
        print("--- 서버 응답 성공: $result");
      } else {
        print("--- 서버 응답 실패: result is null");
      }
    } catch (e) {
      print("--- 프레임 전송 중 오류 발생: $e");
    }
  }

  void onFrameAvailable(CameraImage image) async {
    if (isProcessingFrame) return;
    isProcessingFrame = true;

    try {
      final jpeg = await convertYUV420toJPEG(image);
      if (jpeg != null) {
        frameBuffer.add(jpeg);

        if (frameBuffer.length >= 5) {
          await sendFrames(List.from(frameBuffer));
          frameBuffer.clear();
        }
      } else {
        print("--- JPEG 변환 실패: convertYUV420toJPEG에서 null 반환");
      }
    } catch (e) {
      print("--- 프레임 처리 오류 (YUV->JPEG): $e");
    } finally {
      isProcessingFrame = false;
    }
  }

  void toggleDirection() {
    setState(() {
      isSignToKorean = !isSignToKorean;
      stopCamera();
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
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420, // JPEG이 아닌 YUV로 유지
    );

    try {
      await cameraController!.initialize();
      await cameraController!.startImageStream(onFrameAvailable);
      setState(() => isCameraOn = true);
      print("--- 카메라 스트림 시작됨.");
    } catch (e) {
      print("--- 카메라 시작 실패: $e");
      Fluttertoast.showToast(msg: "카메라 시작 실패: $e");
    }
  }

  Future<void> stopCamera() async {
    if (cameraController == null) return;

    try {
      if (cameraController!.value.isStreamingImages) {
        await cameraController!.stopImageStream();
        print("--- 카메라 이미지 스트림 중지됨.");
      }
      if (cameraController!.value.isRecordingVideo) {
        final file = await cameraController!.stopVideoRecording();
        capturedVideo = file;
        final size = await File(file.path).length();
        print("--- 영상 저장됨: ${file.path}, 크기: $size bytes");
      }
    } catch (e) {
      print("--- 녹화/스트림 종료 실패: $e");
      Fluttertoast.showToast(msg: "녹화/스트림 종료 실패: $e");
    }

    try {
      await cameraController!.dispose();
      print("--- 카메라 컨트롤러 dispose 됨.");
    } catch (e) {
      print("--- 카메라 dispose 중 오류: $e");
    } finally {
      cameraController = null;
    }

    if (mounted) {
      setState(() {
        isCameraOn = false;
      });
    }
  }

  Future<Uint8List?> convertYUV420toJPEG(CameraImage image) async {
    try {
      final width = image.width;
      final height = image.height;

      final img.Image imgData = img.Image(width: width, height: height);

      final planeY = image.planes[0];
      final planeU = image.planes[1];
      final planeV = image.planes[2];

      final bytesY = planeY.bytes;
      final bytesU = planeU.bytes;
      final bytesV = planeV.bytes;

      final int rowStrideY = planeY.bytesPerRow;
      final int rowStrideU = planeU.bytesPerRow;
      final int rowStrideV = planeV.bytesPerRow;
      final int pixelStrideU = planeU.bytesPerPixel ?? 1;
      final int pixelStrideV = planeV.bytesPerPixel ?? 1;

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int uvIndex = (y ~/ 2) * rowStrideU + (x ~/ 2) * pixelStrideU;
          final int yIndex = y * rowStrideY + x;

          final yp = bytesY[yIndex];
          final up = bytesU[uvIndex];
          final vp = bytesV[uvIndex];

          int r = (yp + 1.402 * (vp - 128)).round();
          int g = (yp - 0.344136 * (up - 128) - 0.714136 * (vp - 128)).round();
          int b = (yp + 1.772 * (up - 128)).round();

          imgData.setPixelRgb(
            x,
            y,
            r.clamp(0, 255),
            g.clamp(0, 255),
            b.clamp(0, 255),
          );
        }
      }

      final encodedBytes = img.encodeJpg(imgData, quality: 80);
      return Uint8List.fromList(encodedBytes);
    } catch (e) {
      print("--- convertYUV420toJPEG 오류: $e");
      return null;
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
                        // if (isSignToKorean && isCameraOn)
                        //   Positioned.fill(
                        //     child: CameraWidget(
                        //       onFinish: (file) {
                        //         setState(() {
                        //           isCameraOn = false;
                        //           capturedVideo = file;
                        //         });
                        //       },
                        //     ),
                        //   ),

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
                              // onPressed: () {
                              //   setState(() => isCameraOn = !isCameraOn);
                              // },
                            ),
                          ),

                        // 카운트다운
                        // if (isSignToKorean && isCameraOn && countdown > 0)
                        //   Positioned.fill(
                        //     child: Container(
                        //       color: Colors.black.withValues(alpha: 0.5),
                        //       alignment: Alignment.center,
                        //       child: Text(
                        //         '$countdown',
                        //         style: TextStyle(
                        //           fontSize: 60,
                        //           color: Colors.white,
                        //         ),
                        //       ),
                        //     ),
                        //   ),
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
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  '영어: $resultEnglish',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  '일본어: $resultJapanese',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  '중국어: $resultChinese',
                                  style: TextStyle(fontSize: 16),
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
                  // onPressed: () async {
                  //   if (isSignToKorean) {
                  //     // 수어 -> 한글/일본어/영어/중국어
                  //     if (capturedVideo == null) {
                  //       print('촬영된 영상이 없습니다.');
                  //       return;
                  //     }

                  //     // final videoBytes = await capturedVideo!.readAsBytes();
                  //     // final result =
                  //     //     await TranslateApi.translate_camera_to_word(
                  //     //       videoBytes,
                  //     //     );
                  //     final result = await TranslateApi.translateLatest();
                  //     if (result != null) {
                  //       setState(() {
                  //         resultKorean = result['korean'];
                  //         resultEnglish = result['english'];
                  //         resultJapanese = result['japanese'];
                  //         resultChinese = result['chinese'];
                  //       });
                  //     } else {
                  //       print('번역 실패');
                  //     }
                  //   } else {
                  //     // 한국어 → 수어
                  //     final word = inputController.text.trim();
                  //     if (word.isEmpty) {
                  //       Fluttertoast.showToast(msg: '번역할 단어를 입력하세요.');
                  //       return;
                  //     }

                  //     final videoUrl =
                  //         await TranslateApi.translate_word_to_video(word);
                  //     if (controller != null &&
                  //         controller!.value.isInitialized) {
                  //       await controller!.pause();
                  //       await controller!.dispose();
                  //     }

                  //     if (videoUrl != null) {
                  //       controller = VideoPlayerController.networkUrl(
                  //         Uri.parse(videoUrl),
                  //       )..setPlaybackSpeed(1.0);

                  //       initVideoPlayer = controller!.initialize().then((_) {
                  //         setState(() {
                  //           resultKorean = word;
                  //         });
                  //         controller!.play();
                  //       });
                  //     } else {
                  //       Fluttertoast.showToast(msg: '수어 애니메이션이 없습니다.');
                  //     }
                  //   }
                  // },
                  onPressed: () async {
                    if (isSignToKorean) {
                      // ✅ 프레임 기반이라 영상 파일 존재 여부는 체크할 필요 없음
                      final result = await TranslateApi.translateLatest();
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
