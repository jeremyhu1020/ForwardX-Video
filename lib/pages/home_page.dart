import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/video_provider.dart';
import '../data/locale_provider.dart';
import '../data/local_video_scanner.dart';
import '../l10n/app_localizations.dart';
import '../models/video_item.dart';
import 'video_player_page.dart';
import 'config_editor_page.dart';

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
      color: const Color(0xFF2BB80F),
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
          // 模式切换按钮
          Consumer<VideoProvider>(
            builder: (_, provider, __) => IconButton(
              icon: Icon(
                provider.isLocalMode ? Icons.wifi_off_rounded : Icons.cloud_outlined,
                color: Colors.white,
                size: 22,
              ),
              tooltip: provider.isLocalMode ? '当前：本地模式' : '当前：云端模式',
              onPressed: () => _showModeSwitchDialog(provider),
            ),
          ),
          // 刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
            onPressed: () => context.read<VideoProvider>().loadData(),
            tooltip: '刷新',
          ),
          // 管理入口（仅本地模式显示）
          Consumer<VideoProvider>(
            builder: (_, provider, __) => provider.isLocalMode
                ? IconButton(
                    icon: const Icon(Icons.tune_rounded,
                        color: Colors.white, size: 22),
                    tooltip: '内容管理',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const ConfigEditorPage()),
                    ),
                  )
                : const SizedBox.shrink(),
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

  // ── 分类大方块图标 + 二级子分类 ─────────────────
  Widget _buildCategoryTabs() {
    return Consumer2<VideoProvider, LocaleProvider>(
      builder: (_, provider, localeProvider, __) {
        final isZh = localeProvider.locale.languageCode == 'zh';
        final categories = provider.categories;

        if (categories.isEmpty && !provider.isLoading) {
          return const SizedBox(height: 10);
        }

        // 分离「全部」和普通分类
        final allCat = categories.where((c) => c.type == 'all').firstOrNull;
        final topCats = categories.where((c) => c.type != 'all').toList();

        // 找到当前选中的顶级分类
        final selectedId = provider.selectedCategoryId;
        VideoCategory? activeCat;
        for (final cat in topCats) {
          final allIds = cat.flatten().map((c) => c.id).toSet();
          if (allIds.contains(selectedId) || cat.id == selectedId) {
            activeCat = cat;
            break;
          }
        }

        return Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 大方块图标行
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Row(
                  children: [
                    // 「全部」方块
                    if (allCat != null)
                      _buildCategoryBlock(
                        label: allCat.getName(isZh),
                        icon: Icons.apps_rounded,
                        selected: selectedId.isEmpty,
                        onTap: () => provider.selectCategory(''),
                      ),
                    if (allCat != null) const SizedBox(width: 8),
                    // 其他顶级分类方块
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: topCats.map((cat) {
                            final catSelected =
                                cat.id == selectedId ||
                                    cat.flatten()
                                        .any((c) => c.id == selectedId);
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildCategoryBlock(
                                label: cat.getName(isZh),
                                icon: _iconForCategory(cat),
                                selected: catSelected,
                                hasChildren: cat.hasChildren,
                                onTap: () => provider.selectCategory(
                                    catSelected && cat.id == selectedId
                                        ? cat.id
                                        : cat.id),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 二级子分类横向标签（仅当激活的父分类有 children 时显示）
              if (activeCat != null && activeCat.hasChildren) ...[
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Row(
                    children: [
                      // 子级「全部」标签（显示父分类所有视频）
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildSubChip(
                          label: isZh ? '全部${activeCat.getName(isZh)}' : 'All',
                          selected: selectedId == activeCat.id,
                          onTap: () => provider.selectCategory(activeCat!.id),
                        ),
                      ),
                      ...activeCat.children.map((sub) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildSubChip(
                              label: sub.getName(isZh),
                              selected: selectedId == sub.id,
                              onTap: () => provider.selectCategory(sub.id),
                            ),
                          )),
                    ],
                  ),
                ),
              ] else
                const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// 大方块分类图标
  Widget _buildCategoryBlock({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    bool hasChildren = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2BB80F)
              : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2BB80F).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 28,
              color: selected ? Colors.white : const Color(0xFF2BB80F),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.white : const Color(0xFF444444),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (hasChildren)
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 12,
                color: selected
                    ? Colors.white70
                    : const Color(0xFF2BB80F).withOpacity(0.7),
              ),
          ],
        ),
      ),
    );
  }

  /// 二级子分类小标签
  Widget _buildSubChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2BB80F).withOpacity(0.12)
              : const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? const Color(0xFF2BB80F)
                : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected
                ? const Color(0xFF2BB80F)
                : const Color(0xFF666666),
          ),
        ),
      ),
    );
  }

  /// 根据分类名称/ID 返回合适的图标
  IconData _iconForCategory(VideoCategory cat) {
    final name = cat.nameZh.toLowerCase() + cat.id.toLowerCase();
    if (name.contains('产品') || name.contains('product')) {
      return Icons.precision_manufacturing_rounded;
    } else if (name.contains('场景') || name.contains('scene')) {
      return Icons.account_balance_rounded;
    } else if (name.contains('案例') || name.contains('case')) {
      return Icons.workspace_premium_rounded;
    } else if (name.contains('视频') || name.contains('video')) {
      return Icons.play_circle_outline_rounded;
    }
    return Icons.folder_rounded;
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
                CircularProgressIndicator(color: Color(0xFF2BB80F)),
                SizedBox(height: 16),
                Text('加载中...', style: TextStyle(color: Colors.black45)),
              ],
            ),
          );
        }

  // ── 加载失败
        if (provider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_outlined,
                    size: 64, color: Colors.black26),
                const SizedBox(height: 16),
                const Text(
                  '加载失败，请检查网络',
                  style: TextStyle(color: Colors.black45, fontSize: 15),
                ),
                const SizedBox(height: 4),
                // 本地模式提示
                if (provider.isLocalMode)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      '未找到视频文件夹\n请将视频复制到：\n${LocalVideoScanner.videoFolder}',
                      style: const TextStyle(color: Colors.black38, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
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
                    ? _buildThumbnail(video.thumbnailUrl!)
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
      color: const Color(0xFF2BB80F).withOpacity(0.08),
      child: const Center(
        child: Icon(Icons.play_circle_outline,
            color: Color(0xFF2BB80F), size: 36),
      ),
    );
  }

  /// 智能封面图：本地文件用 Image.file，网络图用 CachedNetworkImage
  Widget _buildThumbnail(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, __) => _buildPlaceholderThumb(),
        errorWidget: (_, __, ___) => _buildPlaceholderThumb(),
      );
    } else {
      return Image.file(
        File(url),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholderThumb(),
      );
    }
  }

  /// 模式切换对话框
  void _showModeSwitchDialog(VideoProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('切换数据来源'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.wifi_off_rounded, color: Color(0xFF2BB80F)),
              title: const Text('本地模式（展会离线）'),
              subtitle: Text(LocalVideoScanner.videoFolder,
                  style: const TextStyle(fontSize: 11)),
              selected: provider.isLocalMode,
              onTap: () {
                Navigator.pop(ctx);
                provider.switchToLocal();
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud_outlined, color: Color(0xFF2BB80F)),
              title: const Text('云端模式（在线）'),
              subtitle: const Text('从 Supabase 加载视频',
                  style: TextStyle(fontSize: 11)),
              selected: !provider.isLocalMode,
              onTap: () {
                Navigator.pop(ctx);
                provider.switchToCloud();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
