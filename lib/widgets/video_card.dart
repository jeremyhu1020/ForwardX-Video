import 'package:flutter/material.dart';
import '../models/video_item.dart';

class VideoCard extends StatelessWidget {
  final VideoItem video;
  final VoidCallback onTap;

  const VideoCard({
    super.key,
    required this.video,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 缩略图区域
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 缩略图（使用颜色占位，实际项目替换为图片）
                    _buildThumbnail(),
                    // 播放按钮遮罩
                    Center(
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 内容区域
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标签行
                  Row(
                    children: [
                      _buildTag(video.product, const Color(0xFF1976D2)),
                      const SizedBox(width: 6),
                      _buildTag(video.scene, const Color(0xFF388E3C)),
                      const Spacer(),
                      _buildTag(video.caseTag, const Color(0xFF7B1FA2)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 标题
                  Text(
                    video.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // 描述
                  Text(
                    video.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    // 根据 product 生成不同占位色调
    final colors = {
      '智能摄像头': [const Color(0xFF1565C0), const Color(0xFF0D47A1)],
      '智能门锁': [const Color(0xFF2E7D32), const Color(0xFF1B5E20)],
      '智能网关': [const Color(0xFF6A1B9A), const Color(0xFF4A148C)],
      '云平台': [const Color(0xFFE65100), const Color(0xFFBF360C)],
    };
    final gradient = colors[video.product] ??
        [const Color(0xFF37474F), const Color(0xFF263238)];

    final icons = {
      '智能摄像头': Icons.videocam_rounded,
      '智能门锁': Icons.lock_rounded,
      '智能网关': Icons.router_rounded,
      '云平台': Icons.cloud_rounded,
    };
    final icon = icons[video.product] ?? Icons.play_circle_rounded;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(icon, size: 48, color: Colors.white.withOpacity(0.3)),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
