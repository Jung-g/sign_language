import 'package:flutter/material.dart';

class IndexBar extends StatelessWidget {
  final List<String> initials;
  final void Function(String) onTap;

  const IndexBar({super.key, required this.initials, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: initials.map((char) {
            return GestureDetector(
              onTap: () => onTap(char),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  char,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
