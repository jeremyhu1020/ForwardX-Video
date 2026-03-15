import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/video_item.dart';

class VideoProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  // 数据
  List<VideoItem> _allItems = [];
  List<VideoCategory> _categories = [];

  // 加载状态
  bool _isLoading = false;
  String? _errorMessage;

  // 筛选状态
  String _selectedCategoryId = ''; // 空字符串表示"全部"
  String _searchText = '';

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<VideoCategory> get categories => _categories;
  String get selectedCategoryId => _selectedCategoryId;

  /// 筛选后的视频列表
  List<VideoItem> get filteredItems {
    var result = _allItems.where((v) => v.isPublished).toList();

    // 按分类筛选
    if (_selectedCategoryId.isNotEmpty) {
      result = result
          .where((v) => v.categoryIds.contains(_selectedCategoryId))
          .toList();
    }

    // 搜索文字过滤
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

    // 按排序字段排序
    result.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return result;
  }

  /// 初始化：从 Supabase 加载数据
  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 并行加载分类和视频
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
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// 切换分类
  void selectCategory(String categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  /// 更新搜索文字
  void updateSearch(String text) {
    _searchText = text;
    notifyListeners();
  }

  /// 清除所有筛选
  void clearAllFilters() {
    _selectedCategoryId = '';
    _searchText = '';
    notifyListeners();
  }

  /// 重试加载
  Future<void> retry() => loadData();
}
