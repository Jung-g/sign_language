import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sign_language/model/calendar_model.dart';
import 'package:sign_language/service/calendar_api.dart';
import 'package:table_calendar/table_calendar.dart';

class StudyCalendar extends StatefulWidget {
  const StudyCalendar({super.key});

  @override
  State<StudyCalendar> createState() => _StudyCalendarState();
}

class _StudyCalendarState extends State<StudyCalendar> {
  final DateTime today = normalize(DateTime.now());
  DateTime focusedDay = DateTime.now();
  Set<DateTime> learnedDate = {};
  int streakDays = 0;
  int bestStreakDays = 0;
  static DateTime normalize(DateTime d) => DateTime(d.year, d.month, d.day);
  bool _isLearned(DateTime day) => learnedDate.contains(normalize(day));

  DateTime? selectedDay;
  bool isLoadingRecords = false;
  ({String date, List<DayRecordItem> items})? dayResult;

  bool get isFireActive {
    final yesterday = today.subtract(const Duration(days: 1));
    return learnedDate.contains(today) || learnedDate.contains(yesterday);
  }

  @override
  void initState() {
    super.initState();
    CalendarApi.fetchLearnedDates()
        .then((stats) {
          setState(() {
            learnedDate = stats.learnedDates.map(normalize).toSet();
            streakDays = stats.streakDays;
            bestStreakDays = stats.bestStreakDays;
          });
        })
        .catchError((e) {
          Fluttertoast.showToast(msg: '학습 날짜 불러오기 실패했습니다.');
        });
  }

  // Future<void> showDayRecords(BuildContext context, DateTime day) async {
  //   try {
  //     final result = await CalendarApi.fetchDayRecords(day);

  //     if (!mounted) return;

  //     if (result.items.isEmpty) {
  //       Fluttertoast.showToast(
  //         msg: '학습 기록이 없습니다.',
  //         toastLength: Toast.LENGTH_SHORT,
  //         gravity: ToastGravity.BOTTOM,
  //       );
  //       return;
  //     }

  //     showModalBottomSheet(
  //       context: context,
  //       showDragHandle: true,
  //       builder: (_) {
  //         return ListView.separated(
  //           padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
  //           itemCount: result.items.length + 1,
  //           separatorBuilder: (_, __) => const Divider(height: 1),
  //           itemBuilder: (_, idx) {
  //             if (idx == 0) {
  //               return Padding(
  //                 padding: const EdgeInsets.symmetric(vertical: 8),
  //                 child: Text(
  //                   '${result.date} 학습 기록',
  //                   style: const TextStyle(
  //                     fontSize: 16,
  //                     fontWeight: FontWeight.w700,
  //                   ),
  //                 ),
  //               );
  //             }
  //             final r = result.items[idx - 1];
  //             final time = TimeOfDay.fromDateTime(r.studyTime);
  //             final timeStr =
  //                 '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  //             return ListTile(
  //               title: Text(r.studyCourse),
  //               subtitle: Text(
  //                 r.stepName != null
  //                     ? 'Step ${r.step} · ${r.stepName}'
  //                     : 'Step ${r.step}',
  //               ),
  //               trailing: Column(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 crossAxisAlignment: CrossAxisAlignment.end,
  //                 children: [
  //                   Text(timeStr, style: const TextStyle(fontSize: 12)),
  //                   const SizedBox(height: 4),
  //                   Container(
  //                     padding: const EdgeInsets.symmetric(
  //                       horizontal: 8,
  //                       vertical: 2,
  //                     ),
  //                     decoration: BoxDecoration(
  //                       color: r.complete
  //                           ? Colors.green.withAlpha(30)
  //                           : Colors.grey.withAlpha(30),
  //                       borderRadius: BorderRadius.circular(12),
  //                     ),
  //                     child: Text(
  //                       r.complete ? '완료' : '미완료',
  //                       style: TextStyle(
  //                         fontSize: 12,
  //                         color: r.complete ? Colors.green : Colors.grey,
  //                         fontWeight: FontWeight.w600,
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             );
  //           },
  //         );
  //       },
  //     );
  //   } catch (e) {
  //     if (!mounted) return;
  //     Fluttertoast.showToast(
  //       msg: '기록 조회 실패: $e',
  //       toastLength: Toast.LENGTH_SHORT,
  //       gravity: ToastGravity.BOTTOM,
  //     );
  //   }
  // }

  Future<void> showDayRecords(BuildContext context, DateTime day) async {
    setState(() {
      selectedDay = day;
      isLoadingRecords = true;
    });

    try {
      final result = await CalendarApi.fetchDayRecords(day);
      if (!mounted) return;

      setState(() {
        dayResult = result;
      });
    } catch (e) {
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: '기록 조회 실패: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoadingRecords = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('학습 달력')),
      body: Column(
        children: [
          const SizedBox(height: 10),
          buildStreakStats(
            bestStreakDays: bestStreakDays,
            streakDays: streakDays,
            isFireActive: isFireActive,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      focusedDay = DateTime(
                        focusedDay.year,
                        focusedDay.month - 1,
                        1,
                      );
                    });
                  },
                ),
                Text(
                  '${focusedDay.year}년 ${focusedDay.month}월',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      focusedDay = DateTime(
                        focusedDay.year,
                        focusedDay.month + 1,
                        1,
                      );
                    });
                  },
                ),
              ],
            ),
          ),
          TableCalendar(
            locale: 'ko_KR',
            firstDay: DateTime(2025, 1, 1),
            lastDay: DateTime(9999, 12, 31),
            focusedDay: focusedDay,
            onPageChanged: (day) => setState(() => focusedDay = day),
            onDaySelected: (selectedDay, newFocusedDay) async {
              setState(() => focusedDay = newFocusedDay);
              await showDayRecords(context, selectedDay);
            },
            headerVisible: false,
            calendarFormat: CalendarFormat.month,
            rowHeight: 48,
            daysOfWeekHeight: 24,
            selectedDayPredicate: _isLearned,
            calendarStyle: CalendarStyle(
              defaultTextStyle: const TextStyle(color: Colors.black),
              weekendTextStyle: const TextStyle(color: Colors.black),
              todayDecoration: BoxDecoration(
                color: Colors.red.shade900,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.red.shade400,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(color: Colors.transparent),
              cellMargin: const EdgeInsets.symmetric(vertical: 4),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, _) {
                final isToday = normalize(day) == today;
                final isLearned = _isLearned(day);
                if (!isToday && !isLearned) return null;
                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isToday ? Colors.red.shade900 : Colors.red.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: buildRecordsPanel(),
            ),
          ),
        ],
      ),
      // bottomNavigationBar: const BottomNavBar(),
    );
  }

  Widget buildRecordsPanel() {
    if (isLoadingRecords) {
      return const Center(child: CircularProgressIndicator());
    }

    if (selectedDay == null) {
      return const Center(child: Text('날짜를 선택하면 해당 날짜의 학습 기록이 표시됩니다.'));
    }

    if (dayResult == null || dayResult!.items.isEmpty) {
      final d = selectedDay!;
      final y = d.year.toString().padLeft(4, '0');
      final m = d.month.toString().padLeft(2, '0');
      final dd = d.day.toString().padLeft(2, '0');
      return Align(
        alignment: Alignment.topLeft,
        child: Text(
          '$y-$m-$dd 학습 기록이 없습니다.',
          style: const TextStyle(fontSize: 16),
        ),
      );
    }

    final items = dayResult!.items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${dayResult!.date} 학습 기록',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Scrollbar(
            thumbVisibility: true, // 데스크탑/웹에서 스크롤바 항상 보이게
            child: RefreshIndicator(
              onRefresh: () async {
                if (selectedDay != null) {
                  await showDayRecords(context, selectedDay!);
                }
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, idx) {
                  final r = items[idx];
                  final time = TimeOfDay.fromDateTime(r.studyTime);
                  final timeStr =
                      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    title: Text(r.studyCourse),
                    subtitle: Text(
                      r.stepName != null
                          ? 'Step ${r.step} · ${r.stepName}'
                          : 'Step ${r.step}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(timeStr, style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: r.complete
                                ? Colors.green.withAlpha(30)
                                : Colors.grey.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            r.complete ? '완료' : '미완료',
                            style: TextStyle(
                              fontSize: 12,
                              color: r.complete ? Colors.green : Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
