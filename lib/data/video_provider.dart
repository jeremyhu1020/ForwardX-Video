import 'package:flutter/foundation.dart';
import '../models/video_item.dart';
import '../models/filter_state.dart';
import '../data/mock_data.dart';

class VideoProvider extends ChangeNotifier {
  // 全部数据
  final List<VideoItem> _allItems = MockVideoData.items;

  // 筛选状态
  FilterState _filter = const FilterState();

  FilterState get filter => _filter;

  // 筛选后的列表
  List<VideoItem> get filteredItems {
    var result = _allItems.toList();

    // 按产品筛选
    if (_filter.selectedProducts.isNotEmpty) {
      result = result
          .where((e) => _filter.selectedProducts.contains(e.product))
          .toList();
    }

    // 按场景筛选
    if (_filter.selectedScenes.isNotEmpty) {
      result = result
          .where((e) => _filter.selectedScenes.contains(e.scene))
          .toList();
    }

    // 按案例标签筛选
    if (_filter.selectedCases.isNotEmpty) {
      result = result
          .where((e) => _filter.selectedCases.contains(e.caseTag))
          .toList();
    }

    // 搜索文字过滤
    if (_filter.searchText.isNotEmpty) {
      final q = _filter.searchText.toLowerCase();
      result = result
          .where((e) =>
              e.title.toLowerCase().contains(q) ||
              e.description.toLowerCase().contains(q) ||
              e.product.toLowerCase().contains(q) ||
              e.scene.toLowerCase().contains(q) ||
              e.caseTag.toLowerCase().contains(q))
          .toList();
    }

    return result;
  }

  // 所有可用标签
  List<String> get allProducts => MockVideoData.allProducts;
  List<String> get allScenes => MockVideoData.allScenes;
  List<String> get allCaseTags => MockVideoData.allCaseTags;

  // ── 筛选操作 ──────────────────────────────────

  void toggleProduct(String product) {
    final set = Set<String>.from(_filter.selectedProducts);
    if (set.contains(product)) {
      set.remove(product);
    } else {
      set.add(product);
    }
    _filter = _filter.copyWith(selectedProducts: set);
    notifyListeners();
  }

  void toggleScene(String scene) {
    final set = Set<String>.from(_filter.selectedScenes);
    if (set.contains(scene)) {
      set.remove(scene);
    } else {
      set.add(scene);
    }
    _filter = _filter.copyWith(selectedScenes: set);
    notifyListeners();
  }

  void toggleCase(String caseTag) {
    final set = Set<String>.from(_filter.selectedCases);
    if (set.contains(caseTag)) {
      set.remove(caseTag);
    } else {
      set.add(caseTag);
    }
    _filter = _filter.copyWith(selectedCases: set);
    notifyListeners();
  }

  void updateSearch(String text) {
    _filter = _filter.copyWith(searchText: text);
    notifyListeners();
  }

  void clearAllFilters() {
    _filter = const FilterState();
    notifyListeners();
  }
}
