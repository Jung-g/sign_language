import 'dart:async';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:ffi/ffi.dart' as ffi_pkg;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:permission_handler/permission_handler.dart';
import 'package:sign_language/service/translate_api.dart';
import 'package:sign_language/widget/animation_widget.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => TranslateScreenState();
}

class TranslateScreenState extends State<TranslateScreen> {
  // 수어 → 한글(true) / 한글 → 수어(false)
  bool isSignToKorean = true;

  // 카메라 상태
  bool isCameraOn = false;
  CameraController? cameraController;

  // 프레임 버퍼와 전송 제어
  final List<Uint8List> frameBuffer = [];
  static const int batchSize = 45; // 서버로 보낼 배치 크기
  static const int maxBuffer = 120; // 메모리 보호 상한
  bool busy = false; // 프레임 콜백 배압 플래그

  // 전송 큐(직렬화). 한 번에 하나의 전송만 수행되도록 보장
  Future<void> sendQueue = Future.value();

  // 입력 및 출력
  final TextEditingController inputController = TextEditingController();
  final List<String> langs = ['한국어', '영어', '일본어', '중국어'];
  String selectedLang = '한국어';

  String? resultKorean;
  String? resultEnglish;
  String? resultJapanese;
  String? resultChinese;
  String? lastShownword;

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

  String? selectedTranslation() {
    switch (selectedLang) {
      case '한국어':
        return resultKorean;
      case '영어':
        return resultEnglish;
      case '일본어':
        return resultJapanese;
      case '중국어':
        return resultChinese;
      default:
        return resultKorean;
    }
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      Fluttertoast.showToast(msg: '카메라 권한이 필요합니다.');
    }
  }

  // YUV_420_888 → NVxx(NV21: VU / NV12: UV)로 재배열
  Uint8List yuv420ToNVsp(CameraImage image, {required bool useNV12}) {
    final int w = image.width, h = image.height;

    final planeY = image.planes[0];
    final planeU = image.planes[1];
    final planeV = image.planes[2];

    final out = Uint8List(w * h + (w * h) ~/ 2);

    // Y 복사 (rowStride 반영)
    int dst = 0;
    for (int r = 0; r < h; r++) {
      final src = r * planeY.bytesPerRow;
      out.setRange(dst, dst + w, planeY.bytes, src);
      dst += w;
    }

    // UV/VU 인터리브
    final int ch = h ~/ 2, cw = w ~/ 2;
    int cIdx = w * h;

    final int uvRowStride = planeU.bytesPerRow;
    final int uvPixStride = planeU.bytesPerPixel ?? 1;

    for (int r = 0; r < ch; r++) {
      final int row = r * uvRowStride;
      for (int c = 0; c < cw; c++) {
        final int off = row + c * uvPixStride;
        final int U = planeU.bytes[off];
        final int V = planeV.bytes[off];
        if (useNV12) {
          out[cIdx++] = U; // NV12: UV
          out[cIdx++] = V;
        } else {
          out[cIdx++] = V; // NV21: VU
          out[cIdx++] = U;
        }
      }
    }
    return out;
  }

  // OpenCV로 NVxx → BGR 변환 후 회전/리사이즈 → JPEG 인메모리 인코딩
  Future<Uint8List?> encodeJpegWithOpenCV(
    CameraImage image, {
    bool useNV12 = false,
  }) async {
    final int w = image.width, h = image.height;

    final nv = yuv420ToNVsp(image, useNV12: useNV12);

    final ptr = ffi_pkg.calloc<ffi.Uint8>(nv.length);
    try {
      ptr.asTypedList(nv.length).setAll(0, nv);
      final yuv = cv.Mat.fromBuffer(
        h + h ~/ 2,
        w,
        cv.MatType.CV_8UC1,
        ptr.cast<ffi.Void>(),
      );

      final code = useNV12 ? cv.COLOR_YUV2BGR_NV12 : cv.COLOR_YUV2BGR_NV21;
      final bgr = cv.cvtColor(yuv, code);

      final rotated = cv.rotate(bgr, cv.ROTATE_90_COUNTERCLOCKWISE);

      final resized = cv.resize(rotated, (
        720,
        480,
      ), interpolation: cv.INTER_AREA);

      final params = cv.VecI32.fromList([cv.IMWRITE_JPEG_QUALITY, 90]);
      final rec = cv.imencode('.jpg', resized, params: params);
      final ok = rec.$1;
      final jpeg = rec.$2;

      yuv.dispose();
      bgr.dispose();
      rotated.dispose();
      resized.dispose();

      if (!ok) return null;
      return jpeg;
    } catch (e) {
      debugPrint('OpenCV 인코딩 오류: $e');
      return null;
    } finally {
      ffi_pkg.calloc.free(ptr);
    }
  }

  // 서버 전송 함수: Base64로 변환하여 API 호출
  Future<void> sendFrames(List<Uint8List> frames) async {
    try {
      final payload = frames.map((f) => base64Encode(f)).toList();
      final res = await TranslateApi.sendFrames(payload);
      if (res == null) {
        debugPrint('서버 응답 실패: result is null');
        return;
      }

      final String korean = (res['korean'] as String? ?? '').trim();
      if (korean.isEmpty) return; // 이번 배치 인식 없음
      if (korean == lastShownword) return; // 중복 토큰 방지
      if (!mounted) return;

      setState(() {
        lastShownword = korean;

        // 모드와 무관하게 최신 번역 상태를 업데이트
        resultKorean = korean;
        resultEnglish = (res['english'] as String?) ?? '';
        resultJapanese = (res['japanese'] as String?) ?? '';
        resultChinese = (res['chinese'] as String?) ?? '';
      });
    } catch (e) {
      debugPrint('프레임 전송 중 오류: $e');
    }
  }

  // 전송을 직렬화하기 위한 큐 등록기
  void _enqueueSend(List<Uint8List> frames) {
    sendQueue = sendQueue.then((_) => sendFrames(frames));
  }

  // 카메라 프레임 콜백
  void onFrameAvailable(CameraImage image) async {
    if (busy) return;
    busy = true;

    try {
      final jpeg = await encodeJpegWithOpenCV(image, useNV12: false);
      if (jpeg != null) {
        if (frameBuffer.length >= maxBuffer) {
          final int drop = frameBuffer.length - maxBuffer + 1;
          frameBuffer.removeRange(0, drop);
        }
        frameBuffer.add(jpeg);

        while (frameBuffer.length >= batchSize) {
          final chunk = List<Uint8List>.from(frameBuffer.take(batchSize));
          frameBuffer.removeRange(0, batchSize);
          _enqueueSend(chunk);
        }
      }
    } catch (e) {
      debugPrint('프레임 처리 오류: $e');
    } finally {
      busy = false;
    }
  }

  void toggleDirection() {
    setState(() {
      isSignToKorean = !isSignToKorean;
      stopCamera();

      lastShownword = null;

      inputController.clear();
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
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await cameraController!.initialize();
      await cameraController!.startImageStream(onFrameAvailable);
      setState(() => isCameraOn = true);
      debugPrint('카메라 스트림 시작됨');
    } catch (e) {
      debugPrint('카메라 시작 실패: $e');
      Fluttertoast.showToast(msg: '카메라 시작 실패: $e');
    }
  }

  Future<void> stopCamera() async {
    if (cameraController == null) return;

    debugPrint('카메라 중지 요청 수신');

    try {
      if (cameraController!.value.isStreamingImages) {
        debugPrint('이미지 스트림 중지 시도');
        await cameraController!.stopImageStream();
        debugPrint('이미지 스트림 중지 완료');
      }
    } catch (e) {
      debugPrint('이미지 스트림 중지 오류: $e');
    }

    try {
      await sendQueue;
    } catch (_) {}

    if (frameBuffer.isNotEmpty) {
      try {
        final leftover = List<Uint8List>.from(frameBuffer);
        frameBuffer.clear();
        await sendFrames(leftover);
      } catch (e) {
        debugPrint('잔여 프레임 전송 실패: $e');
      }
    }

    await Future.delayed(const Duration(milliseconds: 300));

    try {
      await cameraController!.dispose();
      debugPrint('컨트롤러 dispose 완료');
    } catch (e) {
      debugPrint('컨트롤러 dispose 오류: $e');
    } finally {
      cameraController = null;
    }

    if (mounted) {
      setState(() => isCameraOn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputLabel = isSignToKorean ? '수어 영상 촬영' : '$selectedLang 입력';
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
                        color: isCameraOn ? Colors.green : Colors.red,
                      ),
                    ),
                    child: Stack(
                      children: [
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

                        Positioned.fill(
                          child: Container(
                            color: isSignToKorean && isCameraOn
                                ? Colors.black.withValues(alpha: 0.5)
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasText)
                          Text(
                            displayText,
                            style: const TextStyle(fontSize: 16),
                          )
                        else if (!isSignToKorean && decodedFrames.isEmpty)
                          const Text('번역 결과', style: TextStyle(fontSize: 16)),

                        if (!isSignToKorean && decodedFrames.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: AnimationWidget(
                              key: animationKey,
                              frames: decodedFrames,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => animationKey.currentState?.reset(),
                            icon: const Icon(Icons.replay),
                            label: const Text('다시보기'),
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
                        setState(() {
                          resultKorean = result['korean'] is List
                              ? (result['korean'] as List).join(' ')
                              : result['korean']?.toString();
                          resultEnglish = result['english'];
                          resultJapanese = result['japanese'];
                          resultChinese = result['chinese'];
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
