import 'package:flutter/material.dart';
import 'package:sign_language/widget/bottom_nav_bar.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [const Spacer(), const BottomNavBar()]),
      ),
    );
  }
}
