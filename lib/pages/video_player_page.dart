import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/video_item.dart';
import '../data/locale_provider.dart';
import '../l10n/app_localizations.dart';

class VideoPlayerPage extends StatefulWidget {
  final VideoItem video;

  const VideoPlayerPage({super.key, required this.video});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      final url = widget.video.videoUrl;
      VideoPlayerController controller;

      if (url.startsWith('http://') || url.startsWith('https://')) {
        controller = VideoPlayerController.networkUrl(Uri.parse(url));
      } else {
        controller = VideoPlayerController.file(File(url));
      }

      _videoController = controller;
      await controller.initialize();

      _chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        // 进入播放页立即全屏
        fullScreenByDefault: true,
        placeholder: Container(color: Colors.black),
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFF2BB80F),
          handleColor: const Color(0xFF2BB80F),
          bufferedColor: Colors.white30,
          backgroundColor: Colors.white12,
        ),
      );

      // 监听播放状态：播放结束时退出全屏并返回上一页
      controller.addListener(_onVideoStatusChanged);

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  /// 播放结束自动退出全屏，并返回上一页
  void _onVideoStatusChanged() {
    final ctrl = _videoController;
    if (ctrl == null) return;
    final val = ctrl.value;
    // 播放完毕：position 到达 duration 且不在播放中
    if (val.duration.inMilliseconds > 0 &&
        val.position >= val.duration &&
        !val.isPlaying) {
      // 退出全屏
      if (_chewieController?.isFullScreen == true) {
        _chewieController?.exitFullScreen();
      }
      // 稍作延迟再返回，让动画完成
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  @override
  void dispose() {
    _videoController?.removeListener(_onVideoStatusChanged);
    _chewieController?.dispose();
    _videoController?.dispose();
    // 退出时恢复竖屏
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isZh =
        context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final video = widget.video;

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(video.getTitle(isZh)),
              _buildVideoArea(),
              Expanded(child: _buildInfoArea(video, isZh)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(String title) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoArea() {
    final l10n = AppLocalizations.of(context);
    return Container(
      color: Colors.black,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white))
            : _errorMessage != null
                ? _buildErrorView(l10n)
                : Chewie(controller: _chewieController!),
      ),
    );
  }

  Widget _buildErrorView(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white54, size: 48),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              l10n.loadFailed(_errorMessage ?? ''),
              style: const TextStyle(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _initPlayer();
            },
            child: Text(l10n.retry,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoArea(VideoItem video, bool isZh) {
    final l10n = AppLocalizations.of(context);
    return Container(
      color: const Color(0xFFF8F9FA),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              video.getTitle(isZh),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            if (video.duration != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time,
                      size: 14, color: Colors.black45),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(video.duration!),
                    style: const TextStyle(
                        fontSize: 13, color: Colors.black45),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Text(
              l10n.videoIntro,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              video.getDescription(isZh),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
