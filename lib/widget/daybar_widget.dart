import 'package:flutter/material.dart';

class DaybarWidget extends StatelessWidget {
  final int totalDays;
  final int currentDay; // 1부터 시작
  final List<Map<String, dynamic>> steps;
  final bool enableNavigation;
  final ValueChanged<int>? onStepTap;

  const DaybarWidget({
    super.key,
    required this.totalDays,
    required this.currentDay,
    required this.steps,
    this.enableNavigation = false,
    this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalDays, (index) {
          final stepNumber = index + 1;
          bool isCompleted = index < currentDay;
          bool isCurrent = stepNumber == currentDay;
          final bool isAccessible = enableNavigation && isCompleted;
          final stepName = steps.length > index
              ? steps[index]['step_name'] ?? '$stepNumber단계'
              : '$stepNumber단계';

          Color bgColor;
          Widget inner;

          if (isCompleted) {
            bgColor = Colors.green;
            inner = const Icon(Icons.check, color: Colors.white, size: 18);
          } else if (isCurrent) {
            bgColor = Colors.pink;
            inner = Text(
              '$stepNumber',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            );
          } else {
            bgColor = Colors.grey[300]!;
            inner = Text(
              '$stepNumber',
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            );
          }

          final dot = Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: inner,
          );

          final tappable = (isAccessible && onStepTap != null)
              ? InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => onStepTap!(stepNumber),
                  child: dot,
                )
              : dot;

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.03,
            ),
            child: Column(
              children: [
                tappable,
                // Container(
                //   width: 36,
                //   height: 36,
                //   decoration: BoxDecoration(
                //     color: bgColor,
                //     shape: BoxShape.circle,
                //   ),
                //   alignment: Alignment.center,
                //   child: inner,
                // ),
                const SizedBox(height: 4),
                Text(
                  stepName,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
