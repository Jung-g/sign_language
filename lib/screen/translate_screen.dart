import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sign_language/service/translate_api.dart';
import 'package:sign_language/widget/animation_widget.dart';
import 'package:sign_language/widget/bottom_nav_bar.dart';
import 'package:image/image.dart' as img;

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
  final List<String> langs = ['한국어', '영어', '일본어', '중국어'];
  String selectedLang = '한국어';

  String? resultKorean;
  String? resultEnglish;
  String? resultJapanese;
  String? resultChinese;

  final GlobalKey<AnimationWidgetState> animationKey =
      GlobalKey<AnimationWidgetState>();
  List<Uint8List> decodedFrames = [];

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
    print("프레임 ${frames.length}개 서버로 전송 시도...");
    final List<String> base64Frames = frames
        .map((frame) => base64Encode(frame))
        .toList();
    print(base64Frames);
    try {
      final result = await TranslateApi.sendFrames(base64Frames);
      if (result != null) {
        print("서버 응답 성공: $result");
      } else {
        print("서버 응답 실패: result is null");
      }
    } catch (e) {
      print("프레임 전송 중 오류 발생: $e");
    }
  }

  void onFrameAvailable(CameraImage image) async {
    if (isProcessingFrame) return;
    isProcessingFrame = true;

    try {
      final jpeg = await convertYUV420toJPEG(image);
      if (jpeg != null) {
        frameBuffer.add(jpeg);

        if (frameBuffer.length >= 10) {
          await sendFrames(List.from(frameBuffer));
          frameBuffer.clear();
        }
      } else {
        print("JPEG 변환 실패: convertYUV420toJPEG에서 null 반환");
      }
    } catch (e) {
      print("프레임 처리 오류 (YUV->JPEG): $e");
    } finally {
      isProcessingFrame = false;
    }
  }

  void toggleDirection() {
    setState(() {
      isSignToKorean = !isSignToKorean;
      stopCamera();

      inputController.clear();
      resultKorean = null;
      resultEnglish = null;
      resultJapanese = null;
      resultChinese = null;
      decodedFrames = [];
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
      // ResolutionPreset.medium,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await cameraController!.initialize();
      await cameraController!.startImageStream(onFrameAvailable);
      setState(() => isCameraOn = true);
      print("카메라 스트림 시작됨.");
    } catch (e) {
      print("카메라 시작 실패: $e");
      Fluttertoast.showToast(msg: "카메라 시작 실패: $e");
    }
  }

  Future<void> stopCamera() async {
    if (cameraController == null) return;

    print("카메라 중지 요청 수신");

    try {
      if (cameraController!.value.isStreamingImages) {
        print("이미지 스트림 중지 시도...");
        await cameraController!.stopImageStream();
        print("이미지 스트림 중지 완료");
      }
    } catch (e) {
      print("이미지 스트림 중지 오류: $e");
    }

    if (frameBuffer.isNotEmpty) {
      try {
        print("잔여 프레임 ${frameBuffer.length}개 서버에 전송 중...");
        await sendFrames(List.from(frameBuffer));
        frameBuffer.clear();
      } catch (e) {
        print("잔여 프레임 전송 실패: $e");
      }
    }

    await Future.delayed(Duration(milliseconds: 300));

    try {
      await cameraController!.dispose();
      print("컨트롤러 dispose 완료");
    } catch (e) {
      print("컨트롤러 dispose 오류: $e");
    } finally {
      cameraController = null;
    }

    if (mounted) {
      setState(() {
        isCameraOn = false;
      });
    }
  }

  // Future<Uint8List?> convertYUV420toJPEG(CameraImage image) async {
  //   try {
  //     final width = image.width;
  //     final height = image.height;
  //     final img.Image imgData = img.Image(width: width, height: height);

  //     final planeY = image.planes[0];
  //     final planeU = image.planes[1];
  //     final planeV = image.planes[2];

  //     final bytesY = planeY.bytes;
  //     final bytesU = planeU.bytes;
  //     final bytesV = planeV.bytes;

  //     final int rowStrideY = planeY.bytesPerRow;
  //     final int rowStrideU = planeU.bytesPerRow;
  //     final int rowStrideV = planeV.bytesPerRow;

  //     final int pixelStrideU = planeU.bytesPerPixel ?? 1;
  //     final int pixelStrideV = planeV.bytesPerPixel ?? 1;

  //     for (int y = 0; y < height; y++) {
  //       for (int x = 0; x < width; x++) {
  //         final int uvIndex = (y ~/ 2) * rowStrideU + (x ~/ 2) * pixelStrideU;
  //         final int yIndex = y * rowStrideY + x;

  //         final yp = bytesY[yIndex];
  //         final up = bytesU[uvIndex];
  //         final vp = bytesV[uvIndex];

  //         int r = (yp + 1.402 * (vp - 128)).round();
  //         int g = (yp - 0.344136 * (up - 128) - 0.714136 * (vp - 128)).round();
  //         int b = (yp + 1.772 * (up - 128)).round();

  //         imgData.setPixelRgb(
  //           x,
  //           y,
  //           r.clamp(0, 255),
  //           g.clamp(0, 255),
  //           b.clamp(0, 255),
  //         );
  //       }
  //     }

  //     final encodedBytes = img.encodeJpg(imgData, quality: 80);
  //     return Uint8List.fromList(encodedBytes);
  //   } catch (e) {
  //     debugPrint("convertYUV420toJPEG 오류: $e");
  //     return null;
  //   }
  // }

  Future<Uint8List?> convertYUV420toJPEG(CameraImage image) async {
    try {
      final int width = image.width;
      final int height = image.height;

      final planeY = image.planes[0];
      final planeU = image.planes[1];
      final planeV = image.planes[2];

      final Uint8List bytesY = planeY.bytes;
      final Uint8List bytesU = planeU.bytes;
      final Uint8List bytesV = planeV.bytes;

      final int yStride = planeY.bytesPerRow;
      final int uStride = planeU.bytesPerRow;
      final int pixelStrideU = planeU.bytesPerPixel ?? 1;

      String format = 'UNKNOWN';
      final int uvHeight = planeU.bytes.length ~/ uStride;

      final int yHeight = height;
      final int yWidth = width;

      final int uWidthGuess = uStride ~/ (planeU.bytesPerPixel ?? 1);
      final int uHeightGuess = planeU.bytes.length ~/ uStride;

      if ((uWidthGuess - yWidth).abs() <= 32 &&
          (uHeightGuess - yHeight).abs() <= 2) {
        format = 'YUV444';
      } else if ((uWidthGuess - yWidth ~/ 2).abs() <= 32 &&
          (uHeightGuess - yHeight).abs() <= 2) {
        format = 'YUV422';
      } else if ((uWidthGuess - yWidth ~/ 2).abs() <= 32 &&
          (uHeightGuess - yHeight ~/ 2).abs() <= 2) {
        format = 'YUV420';
      } else {
        print("Unknown YUV format");
        print(
          "→ uStride: $uStride, uHeightGuess: $uHeightGuess, pixelStrideU: $pixelStrideU",
        );
        return null;
      }

      final img.Image output = img.Image(width: width, height: height);

      for (int y = 0; y < height; y++) {
        final int yRow = y * yStride;
        final int uvY = (format == 'YUV420')
            ? y ~/ 2
            : (format == 'YUV422')
            ? y
            : y;

        for (int x = 0; x < width; x++) {
          final int yIndex = yRow + x;

          final int uvX = (format == 'YUV444') ? x : x ~/ 2;
          final int uvIndex = uvY * uStride + uvX * pixelStrideU;

          final int Y = bytesY[yIndex];
          final int U = bytesU[uvIndex] - 128;
          final int V = bytesV[uvIndex] - 128;

          // TTA 기반 변환 공식
          int R = (Y + 0.956 * U + 0.621 * V).round();
          int G = (Y - 0.272 * U - 0.647 * V).round();
          int B = (Y + 1.106 * U + 1.703 * V).round();

          output.setPixelRgb(
            x,
            y,
            R.clamp(0, 255),
            G.clamp(0, 255),
            B.clamp(0, 255),
          );
        }
      }

      final encoded = img.encodeJpg(output, quality: 80);
      return Uint8List.fromList(encoded);
    } catch (e) {
      debugPrint("변환 오류: $e");
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
                      // border: Border.all(color: Colors.black),
                      color: Color.fromARGB(255, 238, 229, 255),
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
                      // border: Border.all(color: Colors.black),
                      color: Color.fromARGB(255, 238, 229, 255),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.topLeft,
                    child: resultKorean == null
                        ? Text('번역 결과', style: TextStyle(fontSize: 16))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // if (isSignToKorean && resultKorean != null) ...[
                              //   Text(
                              //     '한글: $resultKorean',
                              //     style: TextStyle(fontSize: 16),
                              //   ),
                              //   Text(
                              //     '영어: $resultEnglish',
                              //     style: TextStyle(fontSize: 16),
                              //   ),
                              //   Text(
                              //     '일본어: $resultJapanese',
                              //     style: TextStyle(fontSize: 16),
                              //   ),
                              //   Text(
                              //     '중국어: $resultChinese',
                              //     style: TextStyle(fontSize: 16),
                              //   ),
                              //   const SizedBox(height: 12),
                              // ],
                              if (isSignToKorean && resultKorean != null) ...[
                                if (selectedLang == '한국어')
                                  Text(
                                    '$resultKorean',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                if (selectedLang == '영어')
                                  Text(
                                    '$resultEnglish',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                if (selectedLang == '일본어')
                                  Text(
                                    '$resultJapanese',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                if (selectedLang == '중국어')
                                  Text(
                                    '$resultChinese',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                const SizedBox(height: 12),
                              ],
                              if (!isSignToKorean && decodedFrames.isNotEmpty)
                                Column(
                                  children: [
                                    AspectRatio(
                                      aspectRatio: 16 / 9,
                                      child: AnimationWidget(
                                        key: animationKey,
                                        frames: decodedFrames,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          animationKey.currentState?.reset(),
                                      icon: const Icon(Icons.replay),
                                      label: const Text('다시보기'),
                                    ),
                                  ],
                                )
                              else if (!isSignToKorean)
                                const SizedBox(
                                  height: 180,
                                  child: Center(child: Text('수어 영상 없음')),
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
                      // 프레임 기반이라 영상 파일 존재 여부는 체크할 필요 없음
                      final result = await TranslateApi.translateLatest();
                      if (result != null) {
                        setState(() {
                          resultKorean = result['korean'] is List
                              ? (result['korean'] as List).join(' ')
                              : result['korean']?.toString();
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
                  child: Text('번역하기'),
                ),
              ],
            ),
          ),
        ),
      ),
      // bottomNavigationBar: BottomNavBar(),
    );
  }
}
