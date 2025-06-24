import 'package:flutter/material.dart';

class WordTile extends StatelessWidget {
  final String word;
  final bool isBookmarked;
  final VoidCallback onTap;
  final VoidCallback onBookmarkToggle;

  const WordTile({
    super.key,
    required this.word,
    required this.isBookmarked,
    required this.onTap,
    required this.onBookmarkToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(word),
      trailing: IconButton(
        icon: Icon(
          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
          color: isBookmarked ? Colors.amber : null,
        ),
        onPressed: onBookmarkToggle,
      ),
      onTap: onTap,
    );
  }
}
