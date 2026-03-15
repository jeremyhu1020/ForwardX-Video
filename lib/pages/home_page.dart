import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/video_provider.dart';
import '../data/locale_provider.dart';
import '../l10n/app_localizations.dart';
import '../widgets/video_card.dart';
import 'video_player_page.dart';
import 'filter_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF0F2F5),
      endDrawer: const FilterDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildQuickFilter(),
            _buildActiveFilterBar(),
            Expanded(child: _buildVideoGrid()),
          ],
        ),
      ),
    );
  }

  // ── 顶部 Header ─────────────────────────────

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    return Container(
      color: const Color(0xFF1A73E8),
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
      child: Row(
        children: [
          // 标题 + 视频数量
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Consumer<VideoProvider>(
                  builder: (_, provider, __) => Text(
                    l10n.appSubtitle(provider.filteredItems.length),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 语言切换按钮
          Consumer<LocaleProvider>(
            builder: (_, localeProvider, __) => TextButton(
              onPressed: () => localeProvider.toggle(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                side: const BorderSide(color: Colors.white38, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language, size: 14, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    l10n.switchLang,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 4),

          // 筛选按钮
          Consumer<VideoProvider>(
            builder: (_, provider, __) => Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.tune_rounded,
                      color: Colors.white, size: 26),
                  onPressed: () =>
                      _scaffoldKey.currentState?.openEndDrawer(),
                  tooltip: l10n.filter,
                ),
                if (provider.filter.activeCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${provider.filter.activeCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 快速筛选（产品横向） ──────────────────────

  Widget _buildQuickFilter() {
    final l10n = AppLocalizations.of(context);
    return Consumer<VideoProvider>(
      builder: (_, provider, __) {
        final products = provider.allProducts;
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 搜索框
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(
                        color: Color(0xFF1A1A1A), fontSize: 14),
                    decoration: InputDecoration(
                      hintText: l10n.search,
                      hintStyle: const TextStyle(
                          color: Colors.black38, fontSize: 14),
                      prefixIcon: const Icon(Icons.search,
                          color: Colors.black38, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    onChanged: (v) =>
                        context.read<VideoProvider>().updateSearch(v),
                  ),
                ),
              ),
              // 产品快速筛选条
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildQuickChip(
                      label: l10n.all,
                      selected:
                          provider.filter.selectedProducts.isEmpty,
                      onTap: () {
                        for (final p in provider.allProducts) {
                          if (provider.filter.selectedProducts
                              .contains(p)) {
                            provider.toggleProduct(p);
                          }
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ...products.map((p) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildQuickChip(
                            label: p,
                            selected: provider.filter.selectedProducts
                                .contains(p),
                            onTap: () => provider.toggleProduct(p),
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF1A73E8)
              : const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.normal,
            color: selected
                ? Colors.white
                : const Color(0xFF555555),
          ),
        ),
      ),
    );
  }

  // ── 已激活筛选条 ─────────────────────────────

  Widget _buildActiveFilterBar() {
    return Consumer<VideoProvider>(
      builder: (_, provider, __) {
        final filter = provider.filter;
        if (filter.activeCount == 0) return const SizedBox.shrink();

        final chips = <Widget>[];
        for (final s in filter.selectedScenes) {
          chips.add(_buildActiveTag(
              s,
              const Color(0xFF388E3C),
              () => provider.toggleScene(s)));
        }
        for (final c in filter.selectedCases) {
          chips.add(_buildActiveTag(
              c,
              const Color(0xFF7B1FA2),
              () => provider.toggleCase(c)));
        }

        if (chips.isEmpty) return const SizedBox.shrink();

        return Container(
          color: Colors.white,
          padding:
              const EdgeInsets.only(left: 16, right: 16, bottom: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: chips),
          ),
        );
      },
    );
  }

  Widget _buildActiveTag(
      String label, Color color, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.only(
          left: 10, top: 4, bottom: 4, right: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close,
                size: 14, color: color.withOpacity(0.7)),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ── 视频网格 ─────────────────────────────────

  Widget _buildVideoGrid() {
    final l10n = AppLocalizations.of(context);
    return Consumer<VideoProvider>(
      builder: (_, provider, __) {
        final items = provider.filteredItems;

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_library_outlined,
                    size: 64,
                    color: Colors.black.withOpacity(0.2)),
                const SizedBox(height: 16),
                Text(
                  l10n.noResults,
                  style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black38,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => provider.clearAllFilters(),
                  child: Text(l10n.clearFilters),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final video = items[index];
            return VideoCard(
              video: video,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        VideoPlayerPage(video: video),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
