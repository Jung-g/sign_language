import 'package:flutter/foundation.dart';

class CourseModel extends ChangeNotifier {
  String? _selectedCourse;
  int _currentDay = 1;
  final int _totalDays = 5;
  bool get isStepCompleted => _currentDay >= _totalDays;

  String? get selectedCourse => _selectedCourse;
  int get currentDay => _currentDay < 1 ? 1 : _currentDay;
  int get totalDays => _totalDays;
  double get percent => _currentDay / _totalDays;

  void selectCourse(String course) {
    _selectedCourse = course;
    notifyListeners();
  }

  Future<void> completeOneDay() async {
    if (_currentDay < _totalDays) {
      _currentDay++;
      notifyListeners();
    }

    // 여기에 db 저장 호출 넣어야함.
  }

  // 전체 코스 진행률용
  final List<String> _allCourses = ['한글 자음/모음', '코스2', '코스3'];
  final Set<String> _completedCourses = {};
  double get overallPercent =>
      _allCourses.isEmpty ? 0.0 : _completedCourses.length / _allCourses.length;

  List<String> get allCourses => _allCourses;
  Set<String> get completedCourses => _completedCourses;

  void completeCourse(String course) {
    // 임시 로직: 완료된 코스 목록에 추가
    _completedCourses.add(course);
    notifyListeners();
  }

  void resetProgress() {
    // 임시 초기화
    _completedCourses.clear();
    _currentDay = 1;
    notifyListeners();
  }
}
