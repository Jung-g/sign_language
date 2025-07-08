import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sign_language/model/course_model.dart';
import 'package:sign_language/screen/study_screen.dart';

/// 3. 공통 퀴즈 위젯: 4지선다로 맞추기
class GenericQuizWidget extends StatefulWidget {
  final List<String> items;
  const GenericQuizWidget({super.key, required this.items});

  @override
  State<GenericQuizWidget> createState() => GenericQuizWidgetState();
}

class GenericQuizWidgetState extends State<GenericQuizWidget> {
  late final PageController pageCtrl;
  int pageIndex = 0;
  late String correct;
  late List<String> options;

  @override
  void initState() {
    super.initState();
    pageCtrl = PageController();
    makeQuiz(0);
  }

  @override
  void dispose() {
    pageCtrl.dispose();
    super.dispose();
  }

  void makeQuiz(int index) {
    final rnd = Random();
    correct = widget.items[index];
    options =
        <String>{correct}
            .union(
              List.generate(
                3,
                (_) => widget.items[rnd.nextInt(widget.items.length)],
              ).toSet(),
            )
            .toList()
          ..shuffle();
  }

  void onSubmit(String pick) {
    final ok = pick == correct;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(ok ? '정답입니다!' : '오답입니다'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (ok) {
                if (pageIndex < widget.items.length - 1) {
                  // 1) 다음 문제로
                  setState(() {
                    pageIndex++;
                    makeQuiz(pageIndex);
                  });
                  pageCtrl.nextPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else {
                  // 2) 마지막 문제면 퀴즈 스텝 종료
                  context
                      .findAncestorStateOfType<StudyScreenState>()
                      ?.nextStep();
                  final courseModel = context.read<CourseModel>();
                  final selected = courseModel.selectedCourse;
                  if (selected != null) {
                    courseModel.completeCourse(selected);
                  }

                  courseModel.completeOneDay(); // 단계 증가
                  if (courseModel.isStepCompleted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('단계 완료')));
                  }
                }
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 24),
        Text(
          '문제 (${pageIndex + 1} / ${widget.items.length})',
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 8),
        Text(
          '이것은 무엇인가요?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        // 1) PageView 로 문제마다 컨텐츠(예: 수어 영상) 변경
        Expanded(
          child: PageView.builder(
            // 영상 넣어야함
            controller: pageCtrl,
            physics: NeverScrollableScrollPhysics(),
            itemCount: widget.items.length,
            onPageChanged: (i) {
              setState(() {
                pageIndex = i;
                makeQuiz(i);
              });
            },
            itemBuilder: (_, i) {
              final item = widget.items[i];
              return Center(
                child: FractionallySizedBox(
                  widthFactor: 0.8,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      color: Colors.black12,
                      child: Center(child: Text('$item 영상 자리')),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // 2) 보기 4지선다
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: options.map((o) {
              return SizedBox(
                width: (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2,
                child: OutlinedButton(
                  onPressed: () => onSubmit(o),
                  child: Text(o, style: TextStyle(fontSize: 18)),
                ),
              );
            }).toList(),
          ),
        ),

        SizedBox(height: 16),
      ],
    );
  }
}
