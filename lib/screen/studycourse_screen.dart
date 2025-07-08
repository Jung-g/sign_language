import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
                  SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.all(0),
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
                                  final selected = studyList[index];
                                  final courseName = selected['Study_Course'];

                                  try {
                                    final detail =
                                        await StudyApi.fetchCourseDetail(
                                          courseName,
                                        );
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.setString(
                                      'selectedCourse',
                                      courseName,
                                    );
                                    await prefs.setInt('sid', detail['sid']);
                                    await prefs.setString(
                                      'words',
                                      jsonEncode(detail['words']),
                                    );
                                    await prefs.setStringList(
                                      'allCourses',
                                      studyList
                                          .map<String>(
                                            (e) => e['Study_Course'].toString(),
                                          )
                                          .toList(),
                                    );
                                    await prefs.setInt('currentDay', 1);
                                    final totalSteps = detail['words']
                                        .map((e) => e['step'])
                                        .toSet()
                                        .length;
                                    await prefs.setInt('totalDays', totalSteps);

                                    // 홈으로 데이터 전달
                                    Navigator.pop(context, {
                                      'course': courseName,
                                      'sid': detail['sid'],
                                      'words': detail['words'],
                                      'courseList': studyList
                                          .map<String>(
                                            (e) => e['Study_Course'].toString(),
                                          )
                                          .toList(),
                                    });
                                  } catch (e) {
                                    Fluttertoast.showToast(
                                      msg: '코스 정보 불러오기 실패',
                                    );
                                  }
                                },

                                onClose: () =>
                                    setState(() => currentCourseIndex = null),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: BottomNavBar(),
    );
  }
}
