import 'package:flutter/material.dart';

class VideoPlayerScreen extends StatelessWidget {
  final int lectureId;
  final String title;
  const VideoPlayerScreen({
    super.key,
    required this.lectureId,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: const Center(
        child: Text(
          'Video Player Coming Soon',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
