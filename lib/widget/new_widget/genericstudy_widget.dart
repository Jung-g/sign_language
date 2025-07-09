import 'package:flutter/material.dart';
import 'package:sign_language/screen/study_screen.dart';
import 'package:video_player/video_player.dart';

class GenericStudyWidget extends StatefulWidget {
  final List<String> items;
  final VoidCallback? onReview;
  const GenericStudyWidget({super.key, required this.items, this.onReview});

  @override
  State<GenericStudyWidget> createState() => GenericStudyWidgetState();
}

class GenericStudyWidgetState extends State<GenericStudyWidget> {
  late PageController pageCtrl;
  int pageIndex = 0;
  VideoPlayerController? videoplayer;

  @override
  void initState() {
    super.initState();
    pageCtrl = PageController(initialPage: 0);
    // initVideo();
  }

  void initVideo() {
    final item = widget.items[pageIndex];

    videoplayer?.dispose();
    videoplayer =
        VideoPlayerController.networkUrl(
            Uri.parse(
              'http://10.101.132.200/video/${Uri.encodeComponent(item)}.mp4',
            ),
          )
          ..setLooping(true)
          ..setPlaybackSpeed(1.0);
  }

  void onNext() {
    if (pageIndex < widget.items.length - 1) {
      pageCtrl.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
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
    videoplayer?.dispose();
    pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // PageView: 각 아이템 수어 애니메이션 보여주기
        Expanded(
          child: PageView.builder(
            controller: pageCtrl,
            itemCount: widget.items.length,
            onPageChanged: (idx) {
              setState(() => pageIndex = idx);
              initVideo();
            },
            itemBuilder: (_, i) {
              final item = widget.items[i];
              final size = MediaQuery.of(context).size.width * 0.7;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item,
                    style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 24),
                  Container(
                    width: size,
                    height: size,
                    color: Colors.black,
                    child:
                        videoplayer != null && videoplayer!.value.isInitialized
                        ? AspectRatio(
                            aspectRatio: videoplayer!.value.aspectRatio,
                            child: VideoPlayer(videoplayer!),
                          )
                        : Center(child: CircularProgressIndicator()),
                  ),
                  SizedBox(height: 24),
                  Text('여기 카메라넣을 자리임', style: TextStyle(fontSize: 30)),
                  SizedBox(height: 24),
                  Text('$item 수어 표현 방법 적어야함', style: TextStyle(fontSize: 20)),
                ],
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
          Expanded(
            child: OutlinedButton(
              onPressed: widget.onReview,
              child: Text("복습하기"),
            ),
          ),
      ],
    );
  }
}
