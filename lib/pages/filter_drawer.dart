import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/video_provider.dart';
import '../l10n/app_localizations.dart';
import '../widgets/filter_chip_widget.dart';

class FilterDrawer extends StatelessWidget {
  const FilterDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Consumer<VideoProvider>(
      builder: (context, provider, _) {
        final filter = provider.filter;
        return Container(
          width: MediaQuery.of(context).size.width * 0.82,
          color: const Color(0xFFF8F9FA),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题栏
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                  child: Row(
                    children: [
                      const Icon(Icons.tune_rounded,
                          color: Color(0xFF1A73E8), size: 22),
                      const SizedBox(width: 8),
                      Text(
                        l10n.filter,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const Spacer(),
                      if (!filter.isEmpty)
                        TextButton(
                          onPressed: () => provider.clearAllFilters(),
                          child: Text(
                            l10n.clearAll,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 13),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // 筛选内容
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FilterSection(
                          title: l10n.product,
                          options: provider.allProducts,
                          selected: filter.selectedProducts,
                          onToggle: (v) => provider.toggleProduct(v),
                          chipColor: const Color(0xFF1976D2),
                        ),
                        const SizedBox(height: 24),
                        FilterSection(
                          title: l10n.scene,
                          options: provider.allScenes,
                          selected: filter.selectedScenes,
                          onToggle: (v) => provider.toggleScene(v),
                          chipColor: const Color(0xFF388E3C),
                        ),
                        const SizedBox(height: 24),
                        FilterSection(
                          title: l10n.caseLabel,
                          options: provider.allCaseTags,
                          selected: filter.selectedCases,
                          onToggle: (v) => provider.toggleCase(v),
                          chipColor: const Color(0xFF7B1FA2),
                        ),
                      ],
                    ),
                  ),
                ),
                // 底部按钮
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A73E8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        filter.isEmpty
                            ? l10n.viewAll
                            : l10n.viewResults(
                                context
                                    .read<VideoProvider>()
                                    .filteredItems
                                    .length),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
