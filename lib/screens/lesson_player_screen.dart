// lib/screens/lesson_player_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/lesson_model.dart';
import '../view_models/course_view_model.dart';


class LessonPlayerScreen extends StatefulWidget {
  final Lesson lesson;
  final String courseId; 

  const LessonPlayerScreen({
    super.key, 
    required this.lesson,
    required this.courseId,
  });

  @override
  State<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends State<LessonPlayerScreen> {
  late YoutubePlayerController _controller;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.lesson.videoUrl);
    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? '',
      flags: const YoutubePlayerFlags(autoPlay: false, forceHD: false),
    )..addListener(_playerListener);
  }

  void _playerListener() {
    if (_controller.value.playerState == PlayerState.ended && !_isCompleted) {
      setState(() { _isCompleted = true; });
      Provider.of<CourseViewModel>(context, listen: false)
          .markContentAsCompleted(widget.courseId, widget.lesson.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Урок пройден!'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_playerListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(controller: _controller),
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(title: Text(widget.lesson.title)),
          body: ListView(
            children: [
              player,
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.lesson.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const Divider(height: 32),
                    Text(widget.lesson.content, style: const TextStyle(fontSize: 16, height: 1.5)),
                    
                    // --- НОВЫЙ БЛОК ДЛЯ ДОП. ИНФОРМАЦИИ ---
                    if (widget.lesson.additionalInfoTitle != null && widget.lesson.additionalInfoTitle!.isNotEmpty)
                      _buildAdditionalInfoSection(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Виджет для отображения доп. информации
  Widget _buildAdditionalInfoSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 32),
          Text(
            widget.lesson.additionalInfoTitle!,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (widget.lesson.additionalInfoContent != null && widget.lesson.additionalInfoContent!.isNotEmpty)
            Text(
              widget.lesson.additionalInfoContent!,
              style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
            ),
        ],
      ),
    );
  }
}