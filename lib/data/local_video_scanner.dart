import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
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

  /// 读取完整配置（分类 + 视频映射）
  static Future<_ConfigData> _loadFullConfig() async {
    final file = File(configFile);
    if (!await file.exists()) return _ConfigData(categories: [], videoMap: {});
    try {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      // 读取自定义分类列表（支持含 children 的二级分类）
      final List<VideoCategory> categories = [];
      if (json.containsKey('categories')) {
        for (final cat in json['categories'] as List) {
          categories.add(
              VideoCategory.fromConfig(cat as Map<String, dynamic>));
        }
      }

      // 读取视频配置映射
      Map<String, dynamic> videoMap = {};
      if (json.containsKey('videos')) {
        final videos = json['videos'] as List;
        videoMap = {
          for (final v in videos)
            (v['file'] as String? ?? ''): v as Map<String, dynamic>
        };
      } else {
        // 兼容旧格式：直接是 filename -> config 的 map
        videoMap = Map<String, dynamic>.from(json);
      }

      return _ConfigData(categories: categories, videoMap: videoMap);
    } catch (_) {
      return _ConfigData(categories: [], videoMap: {});
    }
  }

  /// 扫描本地视频目录，返回视频列表
  static Future<List<VideoItem>> scanVideos() async {
    final dir = Directory(videoFolder);
    if (!await dir.exists()) return [];

    final config = await _loadFullConfig();

    final List<VideoItem> items = [];
    int index = 0;

    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final ext = p.extension(entity.path).toLowerCase();
      if (!supportedExtensions.contains(ext)) continue;

      final fileName = p.basename(entity.path);
      final nameWithoutExt = p.basenameWithoutExtension(entity.path);

      // 从配置文件查找此视频的信息
      final videoConfig = config.videoMap[fileName] ??
          config.videoMap[nameWithoutExt] ??
          <String, dynamic>{};

      items.add(VideoItem(
        id: 'local_$index',
        titleZh: videoConfig['title_zh'] as String? ?? nameWithoutExt,
        titleEn: videoConfig['title_en'] as String? ?? nameWithoutExt,
        descriptionZh: videoConfig['description_zh'] as String? ?? '',
        descriptionEn: videoConfig['description_en'] as String? ?? '',
        videoUrl: entity.path,
        thumbnailUrl: _findThumbnail(entity.path),
        categoryIds: (videoConfig['category_ids'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        duration: videoConfig['duration'] as int?,
        sortOrder: videoConfig['sort_order'] as int? ?? index,
        isPublished: true,
      ));
      index++;
    }

    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return items;
  }

  /// 读取分类列表（供 VideoProvider 使用）
  static Future<List<VideoCategory>> loadCategories() async {
    final config = await _loadFullConfig();
    return config.categories;
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

  /// 读取原始 config.json 文本内容
  static Future<String?> readConfigText() async {
    final file = File(configFile);
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  /// 保存 config.json 文本内容（保存前自动申请存储权限）
  static Future<bool> saveConfigText(String content) async {
    try {
      // 先验证 JSON 合法性
      jsonDecode(content);
    } catch (_) {
      return false; // JSON 格式错误
    }

    try {
      // Android 11+：申请 MANAGE_EXTERNAL_STORAGE 权限
      if (Platform.isAndroid) {
        // 优先申请管理所有文件权限（Android 11+）
        final manageStatus = await Permission.manageExternalStorage.status;
        if (!manageStatus.isGranted) {
          final result = await Permission.manageExternalStorage.request();
          if (!result.isGranted) {
            // 降级：尝试普通写入权限（Android 10 及以下）
            final writeStatus = await Permission.storage.request();
            if (!writeStatus.isGranted) {
              return false;
            }
          }
        }
      }

      // 确保目录存在
      final dir = Directory(videoFolder);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final file = File(configFile);
      await file.writeAsString(content, flush: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 从 config.json 中删除指定视频（按文件名匹配），并保存
  /// 返回 true 表示成功
  static Future<bool> removeVideoFromConfig(String fileName) async {
    final file = File(configFile);
    Map<String, dynamic> json = {};

    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        json = jsonDecode(content) as Map<String, dynamic>;
      } catch (_) {
        json = {};
      }
    }

    // 确保有 videos 列表
    final List videos = json['videos'] as List? ?? [];
    final nameWithoutExt = p.basenameWithoutExtension(fileName);

    // 移除匹配的视频条目
    videos.removeWhere((v) {
      final f = (v as Map<String, dynamic>)['file'] as String? ?? '';
      return f == fileName || f == nameWithoutExt;
    });

    json['videos'] = videos;

    final newContent = const JsonEncoder.withIndent('  ').convert(json);
    return saveConfigText(newContent);
  }

  /// 生成示例配置文件内容（支持二级子分类）
  static String get sampleConfig => const JsonEncoder.withIndent('  ').convert({
    'categories': [
      {
        'id': 'cat_product',
        'name_zh': '产品',
        'name_en': 'Products',
        'sort_order': 1,
        'children': [
          {'id': 'cat_amr', 'name_zh': 'AMR机器人', 'name_en': 'AMR Robot', 'sort_order': 1},
          {'id': 'cat_agv', 'name_zh': 'AGV小车', 'name_en': 'AGV', 'sort_order': 2},
        ],
      },
      {
        'id': 'cat_scene',
        'name_zh': '场景',
        'name_en': 'Scenes',
        'sort_order': 2,
        'children': [
          {'id': 'cat_warehouse', 'name_zh': '智能仓储', 'name_en': 'Warehouse', 'sort_order': 1},
          {'id': 'cat_factory', 'name_zh': '智能工厂', 'name_en': 'Factory', 'sort_order': 2},
        ],
      },
      {
        'id': 'cat_case',
        'name_zh': '案例',
        'name_en': 'Cases',
        'sort_order': 3,
      },
    ],
    'videos': [
      {
        'file': 'robot_demo.mp4',
        'title_zh': 'AMR机器人演示',
        'title_en': 'AMR Robot Demo',
        'description_zh': '展示AMR移动机器人在仓储场景中的自动导航和搬运能力',
        'description_en': 'AMR robot autonomous navigation in warehouse',
        'category_ids': ['cat_product', 'cat_amr'],
        'duration': 120,
        'sort_order': 1,
      },
    ]
  });
}

/// 内部数据类，用于传递配置解析结果
class _ConfigData {
  final List<VideoCategory> categories;
  final Map<String, dynamic> videoMap;
  _ConfigData({required this.categories, required this.videoMap});
}
