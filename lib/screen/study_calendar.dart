import 'package:flutter/material.dart';
import 'package:sign_language/dummy_data.dart';
import 'package:sign_language/model/calendar_model.dart';
import 'package:sign_language/widget/bottom_nav_bar.dart';
import 'package:table_calendar/table_calendar.dart';

class StudyCalendar extends StatefulWidget {
  const StudyCalendar({super.key});

  @override
  State<StudyCalendar> createState() => _StudyCalendarState();
}

class _StudyCalendarState extends State<StudyCalendar> {
  final DateTime today = _normalize(DateTime.now());
  DateTime focusedDay = DateTime.now();

  final Set<DateTime> learnedDate = rawDates.map(_normalize).toSet();

  static DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isLearned(DateTime day) => learnedDate.contains(_normalize(day));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('학습 달력')),
      body: Column(
        children: [
          const SizedBox(height: 80),
          buildStreakStats(learnedDate),
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
            firstDay: DateTime(2020, 1, 1),
            lastDay: DateTime(2030, 12, 31),
            focusedDay: focusedDay,
            onPageChanged: (day) => setState(() => focusedDay = day),
            headerVisible: false,
            calendarFormat: CalendarFormat.month,
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
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, _) {
                final isToday = _normalize(day) == today;
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
        ],
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
