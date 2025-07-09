import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CourseModel with ChangeNotifier {
  String? _selectedCourse;
  int _sid = 0;
  List<Map<String, dynamic>> _words = [];
  List<Map<String, dynamic>> _steps = [];
  int _currentDay = 1;
  int _totalDays = 1;

  String? get selectedCourse => _selectedCourse;
  int get sid => _sid;
  List<Map<String, dynamic>> get words => _words;
  List<Map<String, dynamic>> get steps => _steps;
  int get currentDay => _currentDay;
  int get totalDays => _totalDays;

  bool get isStepCompleted => _currentDay > _totalDays;

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedCourse = prefs.getString('selectedCourse');
    _sid = prefs.getInt('sid') ?? 0;
    _words = List<Map<String, dynamic>>.from(
      jsonDecode(prefs.getString('words') ?? '[]'),
    );
    _steps = List<Map<String, dynamic>>.from(
      jsonDecode(prefs.getString('steps') ?? '[]'),
    );
    _currentDay = prefs.getInt('currentDay') ?? 1;
    _totalDays = prefs.getInt('totalDays') ?? 1;
    notifyListeners();
  }

  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedCourse != null) {
      await prefs.setString('selectedCourse', _selectedCourse!);
      await prefs.setInt('sid', _sid);
      await prefs.setString('words', jsonEncode(_words));
      await prefs.setString('steps', jsonEncode(_steps));
      await prefs.setInt('currentDay', _currentDay);
      await prefs.setInt('totalDays', _totalDays);
    }
  }

  void selectCourse({
    required String course,
    required int sid,
    required List<Map<String, dynamic>> words,
    required List<Map<String, dynamic>> steps,
  }) {
    _selectedCourse = course;
    _sid = sid;
    _words = words;
    _steps = steps;
    _currentDay = 1;
    _totalDays = steps.length;
    saveToPrefs();
    notifyListeners();
  }

  void completeOneDay() {
    if (_currentDay <= _totalDays) {
      _currentDay++;
      saveToPrefs();
      notifyListeners();
    }
  }

  void resetProgress() {
    _currentDay = 1;
    saveToPrefs();
    notifyListeners();
  }
}
