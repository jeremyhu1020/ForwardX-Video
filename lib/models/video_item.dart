/// 视频条目数据模型
class VideoItem {
  final String id;
  final String title;
  final String description;
  final String videoPath;      // assets 路径或网络 URL
  final String thumbnailPath;  // 缩略图路径
  final String product;        // 所属产品
  final String scene;          // 应用场景
  final String caseTag;        // 案例标签
  final Duration? duration;    // 视频时长（可选）
  final DateTime? publishDate; // 发布日期（可选）

  const VideoItem({
    required this.id,
    required this.title,
    required this.description,
    required this.videoPath,
    required this.thumbnailPath,
    required this.product,
    required this.scene,
    required this.caseTag,
    this.duration,
    this.publishDate,
  });

  /// 从 JSON 构建
  factory VideoItem.fromJson(Map<String, dynamic> json) {
    return VideoItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      videoPath: json['videoPath'] as String,
      thumbnailPath: json['thumbnailPath'] as String,
      product: json['product'] as String,
      scene: json['scene'] as String,
      caseTag: json['caseTag'] as String,
      duration: json['durationSeconds'] != null
          ? Duration(seconds: json['durationSeconds'] as int)
          : null,
      publishDate: json['publishDate'] != null
          ? DateTime.parse(json['publishDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'videoPath': videoPath,
        'thumbnailPath': thumbnailPath,
        'product': product,
        'scene': scene,
        'caseTag': caseTag,
        'durationSeconds': duration?.inSeconds,
        'publishDate': publishDate?.toIso8601String(),
      };

  @override
  String toString() => 'VideoItem(id: $id, title: $title)';
}
