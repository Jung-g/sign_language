import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sign_language/dummy_data.dart';
import 'package:sign_language/model/course_model.dart';
import 'package:sign_language/widget/new_widget/coursestepcard_widget.dart';
import 'package:sign_language/widget/new_widget/genericquiz_widget.dart';
import 'package:sign_language/widget/new_widget/genericstudy_widget.dart';
import 'package:sign_language/widget/new_widget/recentmistakescard_widget.dart';
import 'package:sign_language/widget/new_widget/stepdata.dart';
import 'package:sign_language/widget/new_widget/stetscard_widget.dart';

class StudyScreen extends StatefulWidget {
  final String course;
  final int day;
  const StudyScreen({super.key, required this.course, required this.day});

  @override
  StudyScreenState createState() => StudyScreenState();
}

class StudyScreenState extends State<StudyScreen> {
  int currentStep = 0;
  late List<StepData> steps;
  late List<String> todayItems;

  void setupData() {
    todayItems = getItemsForCourse(widget.course, widget.day - 1);

    if (widget.day < 5) {
      steps = [
        StepData(
          title: '학습',
          widget: GenericStudyWidget(items: todayItems),
        ),
      ];
    } else {
      steps = [
        StepData(
          title: '퀴즈',
          widget: GenericQuizWidget(items: todayItems),
        ),
      ];
    }
    currentStep = 0;
  }

  @override
  void initState() {
    super.initState();
    setupData();
  }

  @override
  void didUpdateWidget(covariant StudyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.day != widget.day || oldWidget.course != widget.course) {
      setState(() {
        setupData();
      });
    }
  }

  // course → items 매핑 헬퍼
  List<String> getItemsForCourse(String course, int step) {
    switch (course) {
      case '한글 자음/모음':
        if (step == 0) return DummyData.consonants;
        if (step == 1) return DummyData.vowels;
        if (step == 2) return DummyData.words;
        if (step == 3) return DummyData.numbers;
        if (step == 4)
          return [
            ...DummyData.consonants,
            ...DummyData.vowels,
            ...DummyData.words,
            ...DummyData.numbers,
          ];
        break;
    }
    return [];
  }

  /// 다음 단계로 이동하거나, 마지막이면 Pop
  Future<void> nextStep() async {
    if (currentStep < steps.length - 1) {
      setState(() => currentStep++);
    } else {
      context.read<CourseModel>().completeOneDay();
      if (context.read<CourseModel>().isStepCompleted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('단계 완료')));
      }
      // api 호출해서 학습완료 기록해야함.
      Navigator.pop(context); // 홈으로 돌아가기
    }
  }

  @override
  Widget build(BuildContext context) {
    // steps 가 비어 있으면 에러 화면 처리
    final stepData = steps[currentStep];
    if (todayItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.course)),
        body: Center(child: Text('학습할 콘텐츠가 없습니다.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('${widget.course} ${stepData.title}')),
      body: stepData.widget,
    );
  }
}
