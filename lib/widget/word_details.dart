import 'package:flutter/material.dart';

class WordDetails extends StatelessWidget {
  final String word;
  final String pos;
  final String definition;
  final VoidCallback onClose;

  const WordDetails({
    super.key,
    required this.word,
    required this.pos,
    required this.definition,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  word,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: onClose),
              ],
            ),
            const SizedBox(height: 8),
            if (pos.isNotEmpty)
              Text(
                '[$pos] $definition',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            const SizedBox(height: 8),
            Container(
              height: 120,
              color: Colors.grey.shade300,
              child: const Center(child: Text('수화 애니메이션 재생 영역')),
            ),
            const SizedBox(height: 8),
            const Text('수화 설명 출력 예정'),
          ],
        ),
      ),
    );
  }
}
