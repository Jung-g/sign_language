import 'package:flutter/material.dart';

class DaybarWidget extends StatelessWidget {
  final int totalDays;
  final int currentDay; // 1부터 시작
  const DaybarWidget({
    super.key,
    required this.totalDays,
    required this.currentDay,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalDays, (index) {
        bool isCompleted = index < currentDay;
        bool isCurrent = index + 1 == currentDay;
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.04, // 디바이스별 간격
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? Colors.pink
                      : isCompleted
                      ? Colors.pink[100]
                      : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isCurrent ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 4),
              Text('${index + 1}단계'),
            ],
          ),
        );
      }),
    );
  }
}
