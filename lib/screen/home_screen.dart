import 'package:flutter/material.dart';
import 'package:sign_language/screen/study_calendar.dart';
import 'package:sign_language/screen/user_screen.dart';
import 'package:sign_language/service/calendar_api.dart';
import 'package:sign_language/widget/bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Set<DateTime> learnedDates = {};
  bool isLoading = true;
  static DateTime normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    loadLearnedDates();
  }

  Future<void> loadLearnedDates() async {
    try {
      final result = await CalendarApi.fetchLearnedDates();
      setState(() {
        learnedDates = result.map(normalize).toSet();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('홈 학습 날짜 로딩 실패: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  bool get isFireActive {
    final today = normalize(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    return learnedDates.contains(today) || learnedDates.contains(yesterday);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 학습 달력 아이콘
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StudyCalendar(),
                        ),
                      );
                    },
                  ),
                ),

                const Center(
                  child: Text('학습 코스를 선택해 주세요', style: TextStyle(fontSize: 16)),
                ),

                // 사용자 설정 아이콘
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
                          MaterialPageRoute(builder: (context) => UserScreen()),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),
          const BottomNavBar(),
        ],
      ),
    );
  }
}
