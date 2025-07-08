import 'package:flutter/material.dart';
import 'package:sign_language/model/mistak.dart';
import 'package:sign_language/widget/new_widget/alllist_widget.dart';
import 'package:sign_language/widget/new_widget/genericquiz_widget.dart';
import 'package:sign_language/widget/new_widget/genericstudy_widget.dart';

/// 3. 최근 틀린 문제 카드 (스크롤 가능한 리스트)
class RecentMistakesCard extends StatelessWidget {
  final List<Mistake> mistakes;
  final VoidCallback? onReview;
  const RecentMistakesCard({super.key, required this.mistakes, this.onReview});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '최근 틀린 문제',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          // 리스트 영역 확장을 위해 Expanded 사용
          Expanded(
            child: mistakes.isEmpty
                ? Center(
                    child: Text(
                      '최근 틀린 문제가 없습니다.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  )
                : ListView.builder(
                    itemCount: mistakes.length,
                    itemBuilder: (ctx, idx) {
                      final m = mistakes[idx];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            // 문제 썸네일
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  m.correct,
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            // 질문 텍스트
                            Expanded(
                              child: Text(
                                m.prompt,
                                style: TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 12),
                            // 복습 버튼
                            OutlinedButton(
                              onPressed: onReview != null
                                  ? () => onReview!()
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => Scaffold(
                                            appBar: AppBar(
                                              title: Text('${m.correct} 복습'),
                                            ),
                                            body: GenericStudyWidget(
                                              items: [m.correct],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                              child: Text('복습', style: TextStyle(fontSize: 14)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          SizedBox(height: 8),
          // 전체 보기 버튼
          if (mistakes.length > 3)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AlllistWidget(mistakes: mistakes),
                      ),
                    );
                  },
                  child: Text('전체 보기'),
                ),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(title: Text('다시 풀기')),
                          body: GenericQuizWidget(
                            items: mistakes.map((m) => m.correct).toList(),
                          ),
                        ),
                      ),
                    );
                  },
                  child: Text('다시풀기'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
