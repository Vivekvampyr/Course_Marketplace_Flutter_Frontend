import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import 'package:flutter/foundation.dart';

class VideoPlayerScreen extends StatefulWidget {
  final int lectureId;
  final String title;

  const VideoPlayerScreen({
    super.key,
    required this.lectureId,
    required this.title,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      final token = await AuthService().getAccessToken();
      final baseUrl = ApiConfig.baseUrl;
      final lectureId = widget.lectureId;

      // Platform-specific URL building
      String streamUrl;
      Map<String, String> headers = {};

      if (kIsWeb) {
        // Web: pass token as query param (headers not supported in web video)
        streamUrl = '$baseUrl/lectures/$lectureId/stream?token=$token';
      } else {
        // Android: use Authorization header
        streamUrl = '$baseUrl/lectures/$lectureId/stream';
        headers = {'Authorization': 'Bearer $token'};
      }

      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(streamUrl),
        httpHeaders: headers,
      );

      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFF6C63FF),
          handleColor: const Color(0xFF6C63FF),
          bufferedColor: Colors.white30,
          backgroundColor: Colors.white10,
        ),
      );

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          // ── Video Player ───────────────────────────────
          AspectRatio(
            aspectRatio: 16 / 9,
            child:
                _loading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6C63FF),
                      ),
                    )
                    : _error != null
                    ? _buildError()
                    : _chewieController != null
                    ? Chewie(controller: _chewieController!)
                    : const SizedBox(),
          ),

          // ── Lecture Info ───────────────────────────────
          Expanded(
            child: Container(
              color: const Color(0xFF1A1A2E),
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Now Playing',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Player controls info ───────────────
                  Row(
                    children: [
                      _infoChip(
                        Icons.touch_app_outlined,
                        'Tap video for controls',
                      ),
                      const SizedBox(width: 12),
                      _infoChip(
                        Icons.screen_rotation_outlined,
                        'Rotate for fullscreen',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, color: Colors.white54, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Could not load video',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _initPlayer();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }
}
