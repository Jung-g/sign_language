import 'package:flutter/material.dart';

class MenuButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry padding;
  final bool useDecoration;

  const MenuButton({
    super.key,
    required this.text,
    required this.onTap,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
    this.textStyle,
    this.useDecoration = true,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: double.infinity,
      padding: padding,
      decoration: useDecoration
          ? BoxDecoration(
              color: const Color.fromARGB(255, 254, 234, 255),
              border: Border.all(
                color: Color.fromARGB(255, 254, 237, 255),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(16),
            )
          : null,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style:
            textStyle ??
            const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }
}
