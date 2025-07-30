import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:sign_language/model/course_model.dart';
import 'package:sign_language/service/study_api.dart';
import 'package:sign_language/widget/bottom_nav_bar.dart';
import 'package:sign_language/widget/choice_widget.dart';
import 'package:sign_language/widget/menu_button.dart';

class StudycourseScreen extends StatefulWidget {
  const StudycourseScreen({super.key});

  @override
  State<StudycourseScreen> createState() => StudycourseScreenState();
}

class StudycourseScreenState extends State<StudycourseScreen> {
  List<Map<String, dynamic>> studyList = [];
  int? currentCourseIndex;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStudyList();
  }

  Future<void> fetchStudyList() async {
    try {
      final data = await StudyApi.StudyCourses();
      setState(() {
        studyList = data;
        isLoading = false;
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "학습 코스 목록 불러오기 실패");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      '학습코스 선택',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: studyList.length,
                      itemBuilder: (context, index) {
                        final course = studyList[index];
                        final isSelected = currentCourseIndex == index;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MenuButton(
                              text: course['Study_Course'],
                              onTap: () {
                                setState(() {
                                  currentCourseIndex = isSelected
                                      ? null
                                      : index;
                                });
                              },
                            ),
                            if (isSelected)
                              ChoiceWidget(
                                description: "${course['Study_Course']} 코스입니다.",
                                onSelect: () async {
                                  final courseName = course['Study_Course'];
                                  try {
                                    final detail =
                                        await StudyApi.fetchCourseDetail(
                                          courseName,
                                        );

                                    final words =
                                        List<Map<String, dynamic>>.from(
                                          detail['words'],
                                        );
                                    final steps =
                                        List<Map<String, dynamic>>.from(
                                          detail['steps'],
                                        );

                                    context.read<CourseModel>().selectCourse(
                                      course: courseName,
                                      sid: detail['sid'],
                                      words: words,
                                      steps: steps,
                                    );

                                    Navigator.pop(context); // 홈으로 돌아감
                                  } catch (e) {
                                    Fluttertoast.showToast(
                                      msg: '코스 정보 불러오기 실패',
                                    );
                                  }
                                },
                                onClose: () {
                                  setState(() {
                                    currentCourseIndex = null;
                                  });
                                },
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      // bottomNavigationBar: const BottomNavBar(),
    );
  }
}
