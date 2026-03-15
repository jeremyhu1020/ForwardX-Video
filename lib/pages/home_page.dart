import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/video_provider.dart';
import '../data/locale_provider.dart';
import '../l10n/app_localizations.dart';
import '../models/video_item.dart';
import 'video_player_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 页面加载时拉取云端数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VideoProvider>().loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildCategoryTabs(),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(
        children: [
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
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          // 语言切换
          Consumer<LocaleProvider>(
            builder: (_, localeProvider, __) => TextButton(
              onPressed: () => localeProvider.toggle(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                side: const BorderSide(color: Colors.white38, width: 1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language, size: 14, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(l10n.switchLang,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white)),
                ],
              ),
            ),
          ),
          // 刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
            onPressed: () => context.read<VideoProvider>().loadData(),
            tooltip: '刷新',
          ),
        ],
      ),
    );
  }

  // ── 搜索框 ────────────────────────────────────

  Widget _buildSearchBar() {
    final l10n = AppLocalizations.of(context);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 14),
          decoration: InputDecoration(
            hintText: l10n.search,
            hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
            prefixIcon:
                const Icon(Icons.search, color: Colors.black38, size: 20),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          onChanged: (v) => context.read<VideoProvider>().updateSearch(v),
        ),
      ),
    );
  }

  // ── 分类标签横向滚动 ───────────────────────────

  Widget _buildCategoryTabs() {
    return Consumer2<VideoProvider, LocaleProvider>(
      builder: (_, provider, localeProvider, __) {
        final isZh = localeProvider.locale.languageCode == 'zh';
        final categories = provider.categories;

        if (categories.isEmpty && !provider.isLoading) {
          return const SizedBox(height: 10);
        }

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: categories.map((cat) {
                final isSelected = cat.type == 'all'
                    ? provider.selectedCategoryId.isEmpty
                    : provider.selectedCategoryId == cat.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildCategoryChip(
                    label: cat.getName(isZh),
                    selected: isSelected,
                    onTap: () => provider.selectCategory(
                        cat.type == 'all' ? '' : cat.id),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1A73E8) : const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? Colors.white : const Color(0xFF555555),
          ),
        ),
      ),
    );
  }

  // ── 视频网格 ─────────────────────────────────

  Widget _buildVideoGrid() {
    final l10n = AppLocalizations.of(context);
    return Consumer2<VideoProvider, LocaleProvider>(
      builder: (_, provider, localeProvider, __) {
        final isZh = localeProvider.locale.languageCode == 'zh';

        // 加载中
        if (provider.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF1A73E8)),
                SizedBox(height: 16),
                Text('加载中...', style: TextStyle(color: Colors.black45)),
              ],
            ),
          );
        }

        // 加载失败
        if (provider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_outlined,
                    size: 64, color: Colors.black26),
                const SizedBox(height: 16),
                Text(
                  '加载失败，请检查网络',
                  style: const TextStyle(color: Colors.black45, fontSize: 15),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => provider.retry(),
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }

        final items = provider.filteredItems;

        // 空结果
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_library_outlined,
                    size: 64, color: Colors.black.withOpacity(0.2)),
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
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final video = items[index];
            return _buildVideoCard(video, isZh);
          },
        );
      },
    );
  }

  Widget _buildVideoCard(VideoItem video, bool isZh) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VideoPlayerPage(video: video),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 封面图
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: video.thumbnailUrl != null &&
                        video.thumbnailUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: video.thumbnailUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: const Color(0xFF1A73E8).withOpacity(0.1),
                          child: const Center(
                            child: Icon(Icons.play_circle_outline,
                                color: Color(0xFF1A73E8), size: 36),
                          ),
                        ),
                        errorWidget: (_, __, ___) => _buildPlaceholderThumb(),
                      )
                    : _buildPlaceholderThumb(),
              ),
            ),
            // 标题和信息
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.getTitle(isZh),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      video.getDescription(isZh),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF888888),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // 时长
                    if (video.duration != null)
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 11, color: Colors.black38),
                          const SizedBox(width: 3),
                          Text(
                            _formatDuration(video.duration!),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.black38),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderThumb() {
    return Container(
      color: const Color(0xFF1A73E8).withOpacity(0.08),
      child: const Center(
        child: Icon(Icons.play_circle_outline,
            color: Color(0xFF1A73E8), size: 36),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
