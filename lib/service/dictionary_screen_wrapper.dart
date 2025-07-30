import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sign_language/screen/dictionary_screen.dart';
import 'package:sign_language/service/dictionary_api.dart';
import 'package:sign_language/service/token_storage.dart';

class DictionaryScreenWrapper extends StatefulWidget {
  const DictionaryScreenWrapper({super.key});

  @override
  State<DictionaryScreenWrapper> createState() =>
      _DictionaryScreenWrapperState();
}

class _DictionaryScreenWrapperState extends State<DictionaryScreenWrapper> {
  bool isLoading = true;
  dynamic wordData;
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadDictionaryData();
  }

  Future<void> _loadDictionaryData() async {
    try {
      final data = await DictionaryApi.fetchWords();
      final uid = await TokenStorage.getUserID();
      setState(() {
        wordData = data;
        userId = uid;
        isLoading = false;
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "사전 로딩 오류");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return DictionaryScreen(
      words: wordData.words,
      wordIdMap: wordData.wordIDMap,
      userID: userId!,
    );
  }
}
