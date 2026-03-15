import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/video_item.dart';
import 'local_video_scanner.dart';

/// 数据来源模式
enum DataMode {
  local,   // 本地文件夹（展会离线模式）
  cloud,   // Supabase 云端
}

class VideoProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  // 数据
  List<VideoItem> _allItems = [];
  List<VideoCategory> _categories = [];

  // 当前模式
  DataMode _mode = DataMode.local;

  // 加载状态
  bool _isLoading = false;
  String? _errorMessage;

  // 筛选状态
  String _selectedCategoryId = '';
  String _searchText = '';

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<VideoCategory> get categories => _categories;
  String get selectedCategoryId => _selectedCategoryId;
  DataMode get mode => _mode;
  bool get isLocalMode => _mode == DataMode.local;

  /// 筛选后的视频列表
  List<VideoItem> get filteredItems {
    var result = _allItems.where((v) => v.isPublished).toList();

    if (_selectedCategoryId.isNotEmpty) {
      result = result
          .where((v) => v.categoryIds.contains(_selectedCategoryId))
          .toList();
    }

    if (_searchText.isNotEmpty) {
      final q = _searchText.toLowerCase();
      result = result
          .where((v) =>
              v.titleZh.toLowerCase().contains(q) ||
              v.titleEn.toLowerCase().contains(q) ||
              v.descriptionZh.toLowerCase().contains(q) ||
              v.descriptionEn.toLowerCase().contains(q))
          .toList();
    }

    result.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return result;
  }

  /// 初始化：自动检测模式并加载数据
  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 优先检测本地视频目录是否存在
      final hasLocal = await LocalVideoScanner.hasVideoFolder();
      if (hasLocal) {
        await _loadLocalVideos();
      } else {
        await _loadCloudVideos();
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// 加载本地视频
  Future<void> _loadLocalVideos() async {
    _mode = DataMode.local;

    // Android 13+ 需要 READ_MEDIA_VIDEO 权限
    if (Platform.isAndroid) {
      final status = await Permission.videos.request();
      if (status.isDenied) {
        // 降级尝试旧权限
        await Permission.storage.request();
      }
    }

    final videos = await LocalVideoScanner.scanVideos();
    _allItems = videos;

    // 从 config.json 读取自定义分类模块
    final configCategories = await LocalVideoScanner.loadCategories();
    _categories = _buildLocalCategories(videos, configCategories);

    _isLoading = false;
    notifyListeners();
  }

  /// 加载云端视频
  Future<void> _loadCloudVideos() async {
    _mode = DataMode.cloud;

    final results = await Future.wait([
      _supabase
          .from('categories')
          .select()
          .order('sort_order', ascending: true),
      _supabase
          .from('videos')
          .select()
          .eq('is_published', true)
          .order('sort_order', ascending: true),
    ]);

    _categories = (results[0] as List<dynamic>)
        .map((e) => VideoCategory.fromSupabase(e as Map<String, dynamic>))
        .toList();

    _allItems = (results[1] as List<dynamic>)
        .map((e) => VideoItem.fromSupabase(e as Map<String, dynamic>))
        .toList();

    _isLoading = false;
    notifyListeners();
  }

  /// 从本地视频列表和配置分类构建分类标签
  /// 优先使用 config.json 中定义的分类；如果没有则自动从视频 categoryIds 推断
  List<VideoCategory> _buildLocalCategories(
      List<VideoItem> videos, List<VideoCategory> configCategories) {
    final allTab = const VideoCategory(
      id: '',
      nameZh: '全部',
      nameEn: 'All',
      type: 'all',
      sortOrder: 0,
    );

    if (configCategories.isNotEmpty) {
      // config.json 有定义分类，直接用
      return [allTab, ...configCategories];
    }

    // 没有配置分类，自动从视频 categoryIds 收集（去重）
    final seen = <String>{};
    final List<VideoCategory> inferred = [];
    int order = 1;
    for (final video in videos) {
      for (final cid in video.categoryIds) {
        if (!seen.contains(cid)) {
          seen.add(cid);
          inferred.add(VideoCategory(
            id: cid,
            nameZh: cid,
            nameEn: cid,
            type: 'custom',
            sortOrder: order++,
          ));
        }
      }
    }
    return [allTab, ...inferred];
  }

  /// 手动切换到本地模式
  Future<void> switchToLocal() async {
    _selectedCategoryId = '';
    _searchText = '';
    await _loadLocalVideos();
  }

  /// 手动切换到云端模式
  Future<void> switchToCloud() async {
    _selectedCategoryId = '';
    _searchText = '';
    await _loadCloudVideos();
  }

  void selectCategory(String categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void updateSearch(String text) {
    _searchText = text;
    notifyListeners();
  }

  void clearAllFilters() {
    _selectedCategoryId = '';
    _searchText = '';
    notifyListeners();
  }

  Future<void> retry() => loadData();
}
