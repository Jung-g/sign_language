import 'package:flutter/material.dart';
import 'package:sign_language/model/mistak.dart';
import 'package:sign_language/widget/word_details.dart';

class AlllistWidget extends StatelessWidget {
  final List<Mistake> mistakes;
  const AlllistWidget({super.key, required this.mistakes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('전체 보기')),
      body: ListView.builder(
        controller: ScrollController(),
        itemCount: mistakes.length,
        itemBuilder: (context, index) {
          final mistake = mistakes[index];
          return Card(
            margin: EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(mistake.correct),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) => WordDetails(
                    word: mistake.correct,
                    pos: '',
                    definition: '',
                    onClose: () => Navigator.pop(context),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
