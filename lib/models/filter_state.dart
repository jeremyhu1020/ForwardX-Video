/// 筛选条件模型
class FilterState {
  final Set<String> selectedProducts;
  final Set<String> selectedScenes;
  final Set<String> selectedCases;
  final String searchText;

  const FilterState({
    this.selectedProducts = const {},
    this.selectedScenes = const {},
    this.selectedCases = const {},
    this.searchText = '',
  });

  FilterState copyWith({
    Set<String>? selectedProducts,
    Set<String>? selectedScenes,
    Set<String>? selectedCases,
    String? searchText,
  }) {
    return FilterState(
      selectedProducts: selectedProducts ?? this.selectedProducts,
      selectedScenes: selectedScenes ?? this.selectedScenes,
      selectedCases: selectedCases ?? this.selectedCases,
      searchText: searchText ?? this.searchText,
    );
  }

  bool get isEmpty =>
      selectedProducts.isEmpty &&
      selectedScenes.isEmpty &&
      selectedCases.isEmpty &&
      searchText.isEmpty;

  /// 获取激活筛选数量
  int get activeCount =>
      selectedProducts.length + selectedScenes.length + selectedCases.length;
}
