import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import '../models/video_item.dart';

/// 本地视频扫描服务
/// 扫描手机固定目录下的视频文件和配置文件
class LocalVideoScanner {
  /// 视频存放目录（手机上的固定路径）
  static const String videoFolder = '/sdcard/ForwardX/videos';

  /// 配置文件路径（描述每个视频的标题、分类等信息）
  static const String configFile = '/sdcard/ForwardX/videos/config.json';

  /// 支持的视频格式
  static const List<String> supportedExtensions = [
    '.mp4', '.mov', '.avi', '.mkv', '.m4v', '.3gp', '.wmv'
  ];

  /// 扫描本地视频目录，返回视频列表
  static Future<List<VideoItem>> scanVideos() async {
    final dir = Directory(videoFolder);
    if (!await dir.exists()) return [];

    // 读取配置文件（如果存在）
    final configMap = await _loadConfig();

    // 扫描所有视频文件
    final List<VideoItem> items = [];
    int index = 0;

    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final ext = p.extension(entity.path).toLowerCase();
      if (!supportedExtensions.contains(ext)) continue;

      final fileName = p.basename(entity.path);
      final nameWithoutExt = p.basenameWithoutExtension(entity.path);

      // 从配置文件查找此视频的信息
      final config = configMap[fileName] ?? configMap[nameWithoutExt] ?? {};

      items.add(VideoItem(
        id: 'local_$index',
        titleZh: config['title_zh'] as String? ?? nameWithoutExt,
        titleEn: config['title_en'] as String? ?? nameWithoutExt,
        descriptionZh: config['description_zh'] as String? ?? '',
        descriptionEn: config['description_en'] as String? ?? '',
        videoUrl: entity.path,  // 本地文件路径
        thumbnailUrl: _findThumbnail(entity.path),
        categoryIds: (config['category_ids'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        duration: config['duration'] as int?,
        sortOrder: config['sort_order'] as int? ?? index,
        isPublished: true,
      ));
      index++;
    }

    // 按 sort_order 排序
    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return items;
  }

  /// 加载配置文件
  static Future<Map<String, dynamic>> _loadConfig() async {
    final file = File(configFile);
    if (!await file.exists()) return {};
    try {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      // 支持两种格式：{"videos": [...]} 或直接 {"filename": {...}}
      if (json.containsKey('videos')) {
        final videos = json['videos'] as List;
        return {
          for (final v in videos)
            (v['file'] as String? ?? ''): v as Map<String, dynamic>
        };
      }
      return json;
    } catch (_) {
      return {};
    }
  }

  /// 查找同名缩略图（.jpg/.png）
  static String? _findThumbnail(String videoPath) {
    final nameWithoutExt = p.withoutExtension(videoPath);
    for (final ext in ['.jpg', '.jpeg', '.png', '.webp']) {
      final thumb = File('$nameWithoutExt$ext');
      if (thumb.existsSync()) return thumb.path;
    }
    return null;
  }

  /// 检查视频目录是否存在
  static Future<bool> hasVideoFolder() async {
    return Directory(videoFolder).exists();
  }

  /// 生成示例配置文件内容（供用户参考）
  static String get sampleConfig => const JsonEncoder.withIndent('  ').convert({
    'videos': [
      {
        'file': 'robot_demo.mp4',
        'title_zh': 'AMR机器人演示',
        'title_en': 'AMR Robot Demo',
        'description_zh': '展示AMR移动机器人在仓储场景中的自动导航和搬运能力',
        'description_en': 'AMR robot autonomous navigation in warehouse',
        'category_ids': [],
        'duration': 120,
        'sort_order': 1,
      },
      {
        'file': 'forklift_demo.mp4',
        'title_zh': '叉车机器人演示',
        'title_en': 'Forklift Robot Demo',
        'description_zh': '叉车机器人自动装卸货物演示',
        'description_en': 'Forklift robot automatic loading demo',
        'category_ids': [],
        'duration': 90,
        'sort_order': 2,
      }
    ]
  });
}
