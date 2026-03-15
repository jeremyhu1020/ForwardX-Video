/// 视频条目数据模型（适配 Supabase 数据结构）
class VideoItem {
  final String id;
  final String titleZh;
  final String titleEn;
  final String descriptionZh;
  final String descriptionEn;
  final String videoUrl;        // Supabase Storage 或外部视频 URL
  final String? thumbnailUrl;   // 封面图 URL
  final List<String> categoryIds; // 关联分类 ID（可以是父级或子级分类 ID）
  final int? duration;          // 视频时长（秒）
  final int sortOrder;
  final bool isPublished;
  final DateTime? createdAt;

  const VideoItem({
    required this.id,
    required this.titleZh,
    required this.titleEn,
    required this.descriptionZh,
    required this.descriptionEn,
    required this.videoUrl,
    this.thumbnailUrl,
    this.categoryIds = const [],
    this.duration,
    this.sortOrder = 0,
    this.isPublished = true,
    this.createdAt,
  });

  /// 根据当前语言返回标题
  String getTitle(bool isZh) => isZh ? titleZh : titleEn;

  /// 根据当前语言返回描述
  String getDescription(bool isZh) => isZh ? descriptionZh : descriptionEn;

  /// 从 Supabase JSON 构建
  factory VideoItem.fromSupabase(Map<String, dynamic> json) {
    return VideoItem(
      id: json['id'] as String,
      titleZh: json['title_zh'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      descriptionZh: json['description_zh'] as String? ?? '',
      descriptionEn: json['description_en'] as String? ?? '',
      videoUrl: json['video_url'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String?,
      categoryIds: (json['category_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      duration: json['duration'] as int?,
      sortOrder: json['sort_order'] as int? ?? 0,
      isPublished: json['is_published'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  @override
  String toString() => 'VideoItem(id: $id, title: $titleZh)';
}

/// 分类数据模型（支持二级子分类）
class VideoCategory {
  final String id;
  final String nameZh;
  final String nameEn;
  final String type;            // product / scene / case / all / custom / sub
  final int sortOrder;
  final String? parentId;       // 父分类 ID（null = 顶级分类）
  final List<VideoCategory> children; // 子分类列表

  const VideoCategory({
    required this.id,
    required this.nameZh,
    required this.nameEn,
    required this.type,
    this.sortOrder = 0,
    this.parentId,
    this.children = const [],
  });

  /// 是否为顶级分类
  bool get isTopLevel => parentId == null || parentId!.isEmpty;

  /// 是否有子分类
  bool get hasChildren => children.isNotEmpty;

  String getName(bool isZh) => isZh ? nameZh : nameEn;

  factory VideoCategory.fromSupabase(Map<String, dynamic> json) {
    return VideoCategory(
      id: json['id'] as String,
      nameZh: json['name_zh'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      type: json['type'] as String? ?? 'product',
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  /// 从 config.json 的 map 构建（含 children）
  factory VideoCategory.fromConfig(Map<String, dynamic> m, {String? parentId}) {
    final children = <VideoCategory>[];
    if (m['children'] is List) {
      for (final child in m['children'] as List) {
        children.add(VideoCategory.fromConfig(
          child as Map<String, dynamic>,
          parentId: m['id'] as String? ?? '',
        ));
      }
    }
    return VideoCategory(
      id: m['id'] as String? ?? '',
      nameZh: m['name_zh'] as String? ?? '',
      nameEn: m['name_en'] as String? ?? '',
      type: m['type'] as String? ?? 'custom',
      sortOrder: m['sort_order'] as int? ?? 0,
      parentId: parentId,
      children: children,
    );
  }

  /// 导出为 config.json 用的 Map
  Map<String, dynamic> toConfig() {
    final map = <String, dynamic>{
      'id': id,
      'name_zh': nameZh,
      'name_en': nameEn,
      'sort_order': sortOrder,
    };
    if (children.isNotEmpty) {
      map['children'] = children.map((c) => c.toConfig()).toList();
    }
    return map;
  }

  /// 返回包含自身和所有子孙的扁平列表（供筛选使用）
  List<VideoCategory> flatten() {
    final result = <VideoCategory>[this];
    for (final child in children) {
      result.addAll(child.flatten());
    }
    return result;
  }
}
