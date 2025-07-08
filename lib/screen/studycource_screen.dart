import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sign_language/screen/home_screen.dart';
import 'package:sign_language/service/study_api.dart';
import 'package:sign_language/widget/bottom_nav_bar.dart';
import 'package:sign_language/widget/choice_widget.dart';
import 'package:sign_language/widget/menu_button.dart';

class StudycourceScreen extends StatefulWidget {
  const StudycourceScreen({super.key});

  @override
  State<StudycourceScreen> createState() => StudycourceScreenState();
}

class StudycourceScreenState extends State<StudycourceScreen> {
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
                                onSelect: () {
                                  // 여기에 학습 코스 뭐 설정했다는 코드가 필요함
                                  setState(() {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => HomeScreen(),
                                      ),
                                    );
                                  });
                                },
                                onClose: () => setState(() {
                                  currentCourseIndex = -1;
                                }),
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
