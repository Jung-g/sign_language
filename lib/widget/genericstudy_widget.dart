import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:sign_language/screen/study_screen.dart';
import 'package:sign_language/service/animation_api.dart';
import 'package:sign_language/service/study_api.dart';
import 'package:sign_language/service/translate_api.dart';
import 'package:sign_language/widget/animation_widget.dart';
import 'package:sign_language/widget/camera_widget.dart';

class GenericStudyWidget extends StatefulWidget {
  final List<String> items;
  final int sid;
  final int step;
  final VoidCallback? onReview;
  const GenericStudyWidget({
    super.key,
    required this.items,
    required this.sid,
    required this.step,
    this.onReview,
  });

  @override
  State<GenericStudyWidget> createState() => GenericStudyWidgetState();
}

class GenericStudyWidgetState extends State<GenericStudyWidget> {
  late PageController pageCtrl;
  int pageIndex = 0;
  bool showCamera = false;
  bool isAnalyzing = false;
  bool isLoading = false;
  List<Uint8List>? base64Frames;
  final GlobalKey<AnimationWidgetState> animationKey = GlobalKey();
  final GlobalKey<CameraWidgetState> cameraKey = GlobalKey<CameraWidgetState>();

  @override
  void initState() {
    super.initState();
    pageCtrl = PageController(initialPage: 0);
    loadAnimationFrames(widget.items[pageIndex]);
  }

  Future<void> loadAnimationFrames(String wordText) async {
    setState(() {
      isLoading = true;
      base64Frames = null;
    });

    final result = await AnimationApi.loadAnimation(wordText);
    if (result != null) {
      setState(() {
        base64Frames = result.map((b64) => base64Decode(b64)).toList();
      });
    }

    setState(() => isLoading = false);
  }

  Future<void> onNext() async {
    if (pageIndex < widget.items.length - 1) {
      pageCtrl.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      try {
        await StudyApi.completeStudy(sid: widget.sid, step: widget.step);
        debugPrint("학습 완료 저장 성공");
      } catch (e) {
        debugPrint("학습 완료 저장 실패: $e");
      }

      final screenState = context.findAncestorStateOfType<StudyScreenState>();
      if (screenState != null) {
        screenState.nextStep();
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  void dispose() {
    if (showCamera) {
      cameraKey.currentState?.stop();
    }
    pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isAnalyzing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("동작 확인중! 조금만 기다려주세요", style: TextStyle(fontSize: 18)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            key: const PageStorageKey('study_pageview'),
            controller: pageCtrl,
            itemCount: widget.items.length,
            onPageChanged: (idx) async {
              if (showCamera) {
                await cameraKey.currentState?.stop();
                if (mounted) setState(() => showCamera = false);
              }
              setState(() => pageIndex = idx);
              loadAnimationFrames(widget.items[idx]);
            },
            itemBuilder: (_, i) {
              final item = widget.items[i];
              final size = MediaQuery.of(context).size.width * 0.7;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      width: size,
                      height: size,
                      color: Colors.black,
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : (base64Frames != null
                                ? Column(
                                    children: [
                                      Expanded(
                                        child: AnimationWidget(
                                          key: animationKey,
                                          frames: base64Frames!,
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () {
                                          animationKey.currentState?.reset();
                                        },
                                        icon: const Icon(Icons.replay),
                                        label: const Text("다시보기"),
                                      ),
                                    ],
                                  )
                                : const Center(child: Text("영상 없음"))),
                    ),
                    const SizedBox(height: 5),
                    IconButton(
                      icon: Icon(
                        showCamera ? Icons.videocam_off : Icons.videocam,
                        size: 36,
                      ),
                      onPressed: () async {
                        if (!showCamera) {
                          setState(() => showCamera = true);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            cameraKey.currentState?.start();
                          });
                        } else {
                          await cameraKey.currentState?.stop();
                          if (mounted) setState(() => showCamera = false);
                        }
                      },
                    ),
                    if (showCamera)
                      SizedBox(
                        width: size,
                        height: size,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CameraWidget(
                                key: cameraKey,
                                batchSize: 45,
                                maxBuffer: 120,
                                useNV12: false,
                                rotate90CCW: true,
                                targetSize: const Size(720, 480),
                                preferFrontCamera: true,
                                visible: true,
                                paused: false,
                                onSend: (frames) async {
                                  return await TranslateApi.sendFrames(frames);
                                },
                                onServerResponse: (_) {}, // 중간 응답 무시
                                onCameraState: (on) async {
                                  setState(() => showCamera = on);

                                  if (!on) {
                                    setState(() => isAnalyzing = true);

                                    final expected = widget.items[pageIndex];
                                    final result =
                                        await TranslateApi.translateLatest2();
                                    final recognized =
                                        result?['korean']?.toString().trim() ??
                                        '';

                                    // 빈 값/안내문구는 무조건 오답
                                    final isCorrect =
                                        recognized.isNotEmpty &&
                                        recognized != "인식된 단어가 없습니다." &&
                                        recognized == expected;

                                    setState(() => isAnalyzing = false);

                                    if (!mounted) return;
                                    await showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: Text(
                                          isCorrect ? '정답입니다!' : '오답입니다',
                                          style: TextStyle(
                                            color: isCorrect
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              isCorrect ? 'O' : 'X',
                                              style: TextStyle(
                                                fontSize: 80,
                                                fontWeight: FontWeight.bold,
                                                color: isCorrect
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                            ),
                                            if (!isCorrect)
                                              const Padding(
                                                padding: EdgeInsets.only(
                                                  top: 10,
                                                ),
                                                child: Text(
                                                  '다시 시도해주세요',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );

                                    // 정답일 때만 다음으로 이동
                                    if (isCorrect) {
                                      await Future.delayed(
                                        const Duration(milliseconds: 500),
                                      );
                                      if (pageIndex < widget.items.length - 1) {
                                        pageCtrl.nextPage(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          curve: Curves.easeInOut,
                                        );
                                      } else {
                                        await onNext();
                                      }
                                    }
                                  }
                                },
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Material(
                                color: Colors.transparent,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                  ),
                                  onPressed: () async {
                                    await cameraKey.currentState?.stop();
                                    if (mounted) {
                                      setState(() => showCamera = false);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const Text(
                        '카메라를 실행하려면 아이콘을 누르세요',
                        style: TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: onNext,
            child: Text(pageIndex < widget.items.length - 1 ? '다음' : '학습 완료'),
          ),
        ),
        if (widget.onReview != null) const SizedBox(width: 12),
        if (widget.onReview != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onReview,
                    child: const Text("복습하기"),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
