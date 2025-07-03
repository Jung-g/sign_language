import 'package:flutter/material.dart';

class IndexBar extends StatelessWidget {
  final List<String> initials;
  final void Function(String) onTap;

  const IndexBar({super.key, required this.initials, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: EdgeInsets.only(
          right: 4,
          bottom: bottomInset > 0 ? bottomInset : 0,
        ),
        child: SingleChildScrollView(
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
      ),
    );
  }
}
