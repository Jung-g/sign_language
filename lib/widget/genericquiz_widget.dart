import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:sign_language/model/course_model.dart';
import 'package:sign_language/service/animation_api.dart';
import 'package:sign_language/service/study_api.dart';
import 'package:sign_language/service/translate_api.dart';
import 'package:sign_language/widget/animation_widget.dart';
import 'package:sign_language/widget/camera_widget.dart';

class GenericQuizWidget extends StatefulWidget {
  final List<Map<String, dynamic>> words;
  final int? sid;
  final int? step;
  final bool completeOnFinish;
  final bool showAppBar;

  const GenericQuizWidget({
    super.key,
    required this.words,
    this.sid,
    this.step,
    this.completeOnFinish = true,
    this.showAppBar = false,
  });

  @override
  State<GenericQuizWidget> createState() => _GenericQuizWidgetState();
}

class _GenericQuizWidgetState extends State<GenericQuizWidget> {
  late List<Map<String, dynamic>> quizList;
  int index = 0;
  int correctCount = 0;
  bool answered = false;
  bool? answereIcon;

  late String correct;
  List<String> options = [];
  List<Uint8List>? base64Frames;
  bool isLoading = false;

  final GlobalKey<AnimationWidgetState> animationKey = GlobalKey();

  // 카메라 제어
  bool showCamera = false;
  bool isAnalyzing = false;
  final GlobalKey<CameraWidgetState> cameraKey = GlobalKey<CameraWidgetState>();

  @override
  void initState() {
    super.initState();
    quizList = List<Map<String, dynamic>>.from(widget.words)..shuffle();
    setup();
  }

  void setup() async {
    final current = quizList[index];
    correct = current['word']?.toString() ?? '';

    final allWords =
        widget.words
            .map((w) => w['word'].toString())
            .where((w) => w != correct)
            .toList()
          ..shuffle();

    options = [correct, ...allWords.take(3)]..shuffle();

    setState(() {
      isLoading = true;
      base64Frames = null;
    });

    final result = await AnimationApi.loadAnimation(correct);
    if (!mounted) return;

    if (result != null) {
      setState(() {
        base64Frames = result.map((b64) => base64Decode(b64)).toList();
      });
    }

    setState(() => isLoading = false);
  }

  void onOptionSelected(String selected) {
    if (answered) return;

    final isCorrect = selected == correct;

    setState(() {
      answered = true;
      answereIcon = isCorrect;
      if (isCorrect) correctCount++;
    });

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        answereIcon = null;
      });
      onNext();
    });
  }

  void onNext() async {
    if (showCamera) {
      await cameraKey.currentState?.stop();
      if (mounted) setState(() => showCamera = false);
    }

    if (index < quizList.length - 1) {
      setState(() {
        index++;
        answered = false;
      });
      setup();
    } else {
      final accuracy = correctCount / quizList.length;
      final percent = (accuracy * 100).toStringAsFixed(1);

      if (accuracy >= 0.6 &&
          widget.completeOnFinish &&
          widget.sid != null &&
          widget.step != null) {
        try {
          await StudyApi.completeStudy(sid: widget.sid!, step: widget.step!);

          final stats = await StudyApi.getStudyStats();
          if (context.mounted) {
            context.read<CourseModel>().updateCompletedSteps(
              stats.completedSteps,
            );
          }

          Fluttertoast.showToast(
            msg: "퀴즈 완료! 정답률: $percent%",
            toastLength: Toast.LENGTH_SHORT,
          );
        } catch (e) {
          Fluttertoast.showToast(
            msg: "저장 실패: $e",
            toastLength: Toast.LENGTH_SHORT,
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: "퀴즈 실패... ($percent%) 다시 도전해보세요!",
          toastLength: Toast.LENGTH_SHORT,
        );
      }

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    if (showCamera) {
      cameraKey.currentState?.stop();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 0.7;

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('복습 퀴즈'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () async {
                  if (showCamera) {
                    await cameraKey.currentState?.stop();
                  }
                  if (mounted) Navigator.pop(context);
                },
              ),
            )
          : null,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 100),
                Container(
                  width: size,
                  height: size,
                  color: Colors.black,
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : (base64Frames != null && base64Frames!.isNotEmpty
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
                const SizedBox(height: 8),

                // 카메라 토글 아이콘
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

                // 카메라 영역
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
                              // 서버 전송
                              final res = await TranslateApi.sendFrames(frames);
                              return res;
                            },
                            onServerResponse: (res) async {
                              final isCorrect =
                                  res['match'] == true ||
                                  (res['korean']?.toString().trim() == correct);

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
                                          padding: EdgeInsets.only(top: 10),
                                          child: Text(
                                            '다시 시도해보세요.',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            onCameraState: (on) {
                              setState(() => showCamera = on);
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
                        if (isAnalyzing)
                          const Positioned.fill(
                            child: ColoredBox(
                              color: Color.fromARGB(128, 0, 0, 0),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),
                Text(
                  '정답 $correctCount / ${quizList.length}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 32),

                // 보기 버튼들
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.8,
                    children: List.generate(options.length, (i) {
                      final opt = options[i];
                      return ElevatedButton(
                        onPressed: answered
                            ? null
                            : () => onOptionSelected(opt),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.deepPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(opt, style: const TextStyle(fontSize: 18)),
                      );
                    }),
                  ),
                ),
              ],
            ),

            // 정답/오답 오버레이
            if (answereIcon != null)
              Container(
                alignment: Alignment.center,
                child: Icon(
                  answereIcon! ? Icons.circle_outlined : Icons.close,
                  size: 150,
                  color: answereIcon! ? Colors.green : Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
