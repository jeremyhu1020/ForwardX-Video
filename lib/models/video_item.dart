/// 视频条目数据模型（适配 Supabase 数据结构）
class VideoItem {
  final String id;
  final String titleZh;
  final String titleEn;
  final String descriptionZh;
  final String descriptionEn;
  final String videoUrl;        // Supabase Storage 或外部视频 URL
  final String? thumbnailUrl;   // 封面图 URL
  final List<String> categoryIds; // 关联分类 ID
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

/// 分类数据模型
class VideoCategory {
  final String id;
  final String nameZh;
  final String nameEn;
  final String type; // product / scene / case / all
  final int sortOrder;

  const VideoCategory({
    required this.id,
    required this.nameZh,
    required this.nameEn,
    required this.type,
    this.sortOrder = 0,
  });

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
}
