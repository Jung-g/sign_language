import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sign_language/model/course_model.dart';
import 'package:sign_language/screen/study_calendar.dart';
import 'package:sign_language/screen/study_screen.dart';
import 'package:sign_language/screen/user_screen.dart';
import 'package:sign_language/service/calendar_api.dart';
import 'package:sign_language/service/study_api.dart';
import 'package:sign_language/widget/coursestepcard_widget.dart';
import 'package:sign_language/widget/review_widget.dart';
import 'package:sign_language/widget/stetscard_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static DateTime normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  Set<DateTime> learnedDates = {};
  int learnedWordsCount = 0;
  int streakDays = 0;
  bool isLoading = true;
  double overallPercent = 0.0;

  @override
  void initState() {
    super.initState();
    loadStudyStats();
    context.read<CourseModel>().debugWords();
    context.read<CourseModel>().loadReviewableStep5Words();
  }

  Future<void> loadStudyStats() async {
    try {
      final result = await StudyApi.getStudyStats();
      final rate = await StudyApi.getCompletionRate();

      final courseModel = context.read<CourseModel>();
      courseModel.updateCompletedSteps(result.completedSteps);

      setState(() {
        learnedDates = result.learnedDates.toSet();
        streakDays = result.streakDays;
        learnedWordsCount = result.learnedWordsCount;
        overallPercent = rate;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('학습 통계 로딩 실패: $e');
      setState(() => isLoading = false);
    }
  }

  bool get isFireActive {
    final today = HomeScreen.normalize(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    return learnedDates.contains(today) || learnedDates.contains(yesterday);
  }

  Future<void> loadLearnedDates() async {
    try {
      final result = await CalendarApi.fetchLearnedDates();
      setState(() {
        learnedDates = result.learnedDates;
        streakDays = result.streakDays;
      });
    } catch (e) {
      debugPrint('학습 날짜 불러오기 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseModel = context.watch<CourseModel>();
    final horizontalPadding = MediaQuery.of(context).size.width * 0.02;
    final mq = MediaQuery.of(context);
    final boxHeight = mq.size.height * 0.25;

    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: Icon(
                            Icons.local_fire_department,
                            color: isFireActive
                                ? Colors.pinkAccent
                                : Colors.black.withAlpha(100),
                            size: 54,
                          ),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const StudyCalendar(),
                              ),
                            );
                            await loadLearnedDates();
                          },
                        ),
                      ),
                      Center(
                        child: Text(
                          courseModel.selectedCourse ?? '학습 코스를 선택해 주세요',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.purple.shade100,
                          child: IconButton(
                            icon: const Icon(
                              Icons.person,
                              color: Colors.purple,
                              size: 36,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                CoursestepcardWidget(
                  boxHeight: boxHeight,
                  horizontalPadding: horizontalPadding,
                  selectedCourse: courseModel.selectedCourse,
                  currentDay: courseModel.currentDay,
                  totalDays: courseModel.totalDays,
                  steps: courseModel.steps,
                  onSelectCourse: (_) async {
                    await courseModel.loadFromPrefs();
                  },
                  onStartStudy: (day) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudyScreen(
                          course: courseModel.selectedCourse!,
                          day: day,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Flexible(
                  flex: 1,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: StetscardWidget(
                        learnedWords: learnedWordsCount,
                        streakDays: streakDays,
                        overallPercent: overallPercent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Flexible(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ReviewCard(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
    );
  }
}
