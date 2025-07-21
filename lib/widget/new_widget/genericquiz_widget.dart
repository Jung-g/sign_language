import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:sign_language/model/course_model.dart';
import 'package:sign_language/service/study_api.dart';
import 'package:video_player/video_player.dart';

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
  VideoPlayerController? videoplayer;

  @override
  void initState() {
    super.initState();
    quizList = List<Map<String, dynamic>>.from(widget.words)..shuffle();
    setup();
  }

  void setup() {
    final current = quizList[index];
    correct = current['word']?.toString() ?? '';

    final allWords =
        widget.words
            .map((w) => w['word'].toString())
            .where((w) => w != correct)
            .toList()
          ..shuffle();

    options = [correct, ...allWords.take(3)]..shuffle();

    // videoplayer?.dispose();
    // videoplayer = VideoPlayerController.networkUrl(
    //   Uri.parse('http://10.101.170.168/video/${Uri.encodeComponent(correct)}.mp4'),
    // )
    //   ..setLooping(true)
    //   ..setPlaybackSpeed(1.0)
    //   ..initialize().then((_) {
    //     if (mounted) setState(() {});
    //   });
  }

  void onOptionSelected(String selected) {
    if (answered) return;

    final isCorrect = selected == correct;

    setState(() {
      answered = true;
      answereIcon = isCorrect;
      if (selected == correct) correctCount++;
    });

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        answereIcon = null;
      });
      onNext();
    });
  }

  void onNext() async {
    if (index < quizList.length - 1) {
      setState(() {
        index++;
        answered = false;
        setup();
      });
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

      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    videoplayer?.dispose();
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
                onPressed: () => Navigator.pop(context),
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
                const SizedBox(height: 30),
                Text(
                  // 디버그용 나중에 삭제할 것 + 바로 아래 SizedBox는 height: 100으로 수정
                  correct,
                  style: const TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: size,
                  height: size,
                  color: Colors.black,
                  child:
                      (videoplayer != null && videoplayer!.value.isInitialized)
                      ? AspectRatio(
                          aspectRatio: videoplayer!.value.aspectRatio,
                          child: VideoPlayer(videoplayer!),
                        )
                      : const Center(child: CircularProgressIndicator()),
                ),
                const SizedBox(height: 50),
                Text(
                  '정답 $correctCount / ${quizList.length}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 50),
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
