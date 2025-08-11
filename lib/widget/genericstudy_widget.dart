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
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      try {
        await StudyApi.completeStudy(sid: widget.sid, step: widget.step);
        print("학습 완료 저장 성공");
      } catch (e) {
        print("학습 완료 저장 실패: $e");
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
        // PageView: 각 아이템 수어 애니메이션 보여주기
        Expanded(
          child: PageView.builder(
            key: PageStorageKey('study_pageview'), // 현재 페이지 고정용 키
            controller: pageCtrl,
            itemCount: widget.items.length,
            onPageChanged: (idx) {
              setState(() => pageIndex = idx);
              loadAnimationFrames(widget.items[idx]);
            },
            itemBuilder: (_, i) {
              final item = widget.items[i];
              final size = MediaQuery.of(context).size.width * 0.7;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item,
                      style: TextStyle(
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
                                        icon: Icon(Icons.replay),
                                        label: Text("다시보기"),
                                      ),
                                    ],
                                  )
                                : const Center(child: Text("영상 없음"))),
                    ),
                    SizedBox(height: 5),
                    IconButton(
                      icon: Icon(Icons.videocam, size: 36),
                      onPressed: () => setState(() => showCamera = true),
                    ),
                    if (showCamera)
                      SizedBox(
                        width: size,
                        height: size,
                        child: CameraWidget(
                          onFinish: (file) async {
                            setState(() {
                              isAnalyzing = true;
                            });

                            final expected = widget.items[pageIndex];
                            final result = await TranslateApi.signToText(
                              file.path,
                              expected,
                            );
                            final isCorrect = result['match'] == true;

                            setState(() {
                              isAnalyzing = false;
                              showCamera = false;
                            });

                            if (!mounted) return;

                            if (!isCorrect) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (pageCtrl.hasClients &&
                                    pageCtrl.page?.round() != pageIndex) {
                                  pageCtrl.jumpToPage(pageIndex);
                                }
                              }); // 오답 시 현재 페이지 유지
                            }

                            await showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: isCorrect
                                    ? const Text(
                                        '정답입니다!',
                                        style: TextStyle(color: Colors.green),
                                      )
                                    : const Text(
                                        '오답입니다',
                                        style: TextStyle(color: Colors.red),
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
                                    isCorrect
                                        ? const SizedBox.shrink()
                                        : const Padding(
                                            padding: EdgeInsets.only(top: 10),
                                            child: Text(
                                              '다시 시도해주세요',
                                              style: TextStyle(fontSize: 16),
                                            ),
                                          ),
                                  ],
                                ),
                              ),
                            );

                            // 정답이면 다음 페이지로 자동 이동 또는 학습 완료
                            if (isCorrect) {
                              await Future.delayed(
                                const Duration(milliseconds: 500),
                              );
                              if (pageIndex < widget.items.length - 1) {
                                pageCtrl.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              } else {
                                await onNext();
                              }
                            }
                          },
                        ),
                      )
                    else
                      Text(
                        '카메라를 실행하려면 아이콘을 누르세요',
                        style: TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        // 다음 단계 버튼
        Padding(
          padding: EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: onNext,
            child: Text(pageIndex < widget.items.length - 1 ? '다음' : '학습 완료'),
          ),
        ),

        // 복습
        if (widget.onReview != null) SizedBox(width: 12),
        if (widget.onReview != null)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onReview,
                    child: Text("복습하기"),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
