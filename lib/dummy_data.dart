// 테스트용 더미데이터
final Set<DateTime> learnedDates = {
  DateTime.now().subtract(const Duration(days: 3)),
  DateTime.now().subtract(const Duration(days: 2)),
  DateTime.now(), //.subtract(const Duration(days: 1)), // 어제
};

final Set<DateTime> rawDates = learnedDates
    .map((d) => DateTime(d.year, d.month, d.day))
    .toSet();

class DummyData {
  static const consonants = ['ㄱ', 'ㄴ', 'ㄷ' /* … */];
  static const vowels = ['ㅏ', 'ㅑ', 'ㅓ' /* … */];
  static const numbers = ['0', '1', '2', '3' /* … */];
  static const words = ['안녕하세요', '감사합니다', '사랑해요' /* … */];
}
