import 'package:flutter/material.dart';
import 'package:sign_language/service/bookmark_api.dart';

class WordTile extends StatelessWidget {
  final String word;
  final int wid;
  final String userID;
  final bool isBookmarked;
  final VoidCallback onTap;
  final void Function(bool) onBookmarkToggle;

  const WordTile({
    super.key,
    required this.word,
    required this.wid,
    required this.isBookmarked,
    required this.onTap,
    required this.onBookmarkToggle,
    required this.userID,
  });

  Future<void> handleBookmarkToggle() async {
    final result = await BookmarkApi.toggleBookmark(userID: userID, wid: wid);

    if (result != null) {
      onBookmarkToggle(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(word),
      trailing: IconButton(
        icon: Icon(
          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
          color: isBookmarked ? Colors.amber : null,
        ),
        onPressed: handleBookmarkToggle,
      ),
      onTap: onTap,
    );
  }
}
