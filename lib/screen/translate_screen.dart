import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sign_language/service/translate_api.dart';
import 'package:sign_language/widget/bottom_nav_bar.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => TranslateScreenState();
}

class TranslateScreenState extends State<TranslateScreen> {
  bool isSignToKorean = true; // true: 수어 > 한글 | false 한글 > 수어
  bool isCameraOn = false;
  int countdown = 0;
  Uint8List? capturedFrame;

  CameraController? cameraController;

  final TextEditingController inputController = TextEditingController();

  // 콤보박스
  final List<String> langs = ['한국어', 'English', '日本語', '中文'];
  String selectedLang = '한국어';

  String? resultKorean;
  String? resultEnglish;
  String? resultJapanese;
  String? resultChinese;

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
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      Fluttertoast.showToast(
        msg: '카메라 권한이 거부되었습니다.',
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    cameraController = CameraController(
      firstCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await cameraController!.initialize();

    setState(() {
      isCameraOn = true;
      countdown = 3;
    });

    for (int i = 3; i > 0; i--) {
      setState(() => countdown = i);
      await Future.delayed(Duration(seconds: 1));
    }
    setState(() => countdown = 0);

    await Future.delayed(Duration(seconds: 6));
    await captureFrame();
    await stopCamera();
  }

  Future<void> stopCamera() async {
    if (cameraController != null) {
      await cameraController!.dispose();
      cameraController = null;
    }
    setState(() {
      isCameraOn = false;
      countdown = 0;
    });
  }

  Future<void> captureFrame() async {
    if (cameraController == null || !cameraController!.value.isInitialized)
      return;

    try {
      final file = await cameraController!.takePicture();
      capturedFrame = await file.readAsBytes();
      print("프레임 캡처 완료");
    } catch (e) {
      print("프레임 캡처 실패: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputLabel = isSignToKorean ? '수어 입력' : '$selectedLang 입력';

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
                // 상단 전환 버튼
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: isSignToKorean
                                ? Text('수어', style: TextStyle(fontSize: 30))
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

                        // 2) 가운데 고정 아이콘
                        IconButton(
                          icon: Icon(Icons.sync_alt, size: 30),
                          onPressed: toggleDirection,
                        ),

                        // 3) 오른쪽: '수어' 혹은 드롭다운 (반대 상황)
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
                                : Text('수어', style: TextStyle(fontSize: 30)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 입력 영역
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 200,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: inputController,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: inputLabel,
                            ),
                            maxLines: null,
                          ),
                        ),
                        if (isSignToKorean)
                          IconButton(
                            icon: Icon(
                              isCameraOn
                                  ? Icons.camera_alt
                                  : Icons.no_photography,
                              size: 32,
                            ),
                            onPressed: toggleCamera,
                          ),
                      ],
                    ),
                  ),
                ),
                if (isCameraOn &&
                    cameraController != null &&
                    cameraController!.value.isInitialized)
                  Column(
                    children: [
                      SizedBox(
                        height: 240,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CameraPreview(cameraController!),
                            if (countdown > 0)
                              Container(
                                color: Colors.black.withOpacity(0.5),
                                child: Text(
                                  '$countdown',
                                  style: TextStyle(
                                    fontSize: 60,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        countdown == 0 ? '촬사 중...' : '곧 촬사 시작...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                SizedBox(height: 16),

                // 출력 영역 (한글을 번역하면 수어 애니메이션 출력하기)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 420,
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
                            ],
                          ),
                  ),
                ),
                SizedBox(height: 16),

                // 번역 버튼
                ElevatedButton(
                  onPressed: () async {
                    if (!isSignToKorean) return;

                    if (capturedFrame == null) {
                      print('촬영된 프레임이 없습니다.');
                      return;
                    }

                    final result = await TranslateApi.translate(capturedFrame!);
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
