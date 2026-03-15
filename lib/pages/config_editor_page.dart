import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../data/local_video_scanner.dart';
import '../data/video_provider.dart';

/// App 内置内容管理页面
/// 可在展会设备上直接编辑 config.json（分类模块 + 视频元信息）
class ConfigEditorPage extends StatefulWidget {
  const ConfigEditorPage({super.key});

  @override
  State<ConfigEditorPage> createState() => _ConfigEditorPageState();
}

class _ConfigEditorPageState extends State<ConfigEditorPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<_CatItem> _categories = [];
  Map<String, Map<String, dynamic>> _videoMap = {}; // filename -> config

  bool _isLoading = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── 数据加载 / 保存 ─────────────────────────────

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final text = await LocalVideoScanner.readConfigText();
    if (text != null) {
      try {
        _parse(jsonDecode(text) as Map<String, dynamic>);
      } catch (_) {
        _loadDefaults();
      }
    } else {
      _loadDefaults();
    }
    setState(() => _isLoading = false);
  }

  void _parse(Map<String, dynamic> json) {
    _categories = [];
    if (json['categories'] is List) {
      for (final c in json['categories'] as List) {
        final m = c as Map<String, dynamic>;
        _categories.add(_CatItem(
          id: m['id'] as String? ?? '',
          nameZh: m['name_zh'] as String? ?? '',
          nameEn: m['name_en'] as String? ?? '',
          sortOrder: m['sort_order'] as int? ?? 0,
        ));
      }
    }
    _videoMap = {};
    if (json['videos'] is List) {
      for (final v in json['videos'] as List) {
        final m = v as Map<String, dynamic>;
        final file = m['file'] as String? ?? '';
        if (file.isNotEmpty) _videoMap[file] = Map.from(m);
      }
    }
  }

  void _loadDefaults() {
    _categories = [
      _CatItem(id: 'cat_product', nameZh: '产品', nameEn: 'Products', sortOrder: 1),
      _CatItem(id: 'cat_scene', nameZh: '场景', nameEn: 'Scenes', sortOrder: 2),
      _CatItem(id: 'cat_case', nameZh: '案例', nameEn: 'Cases', sortOrder: 3),
    ];
    _videoMap = {};
  }

  Future<void> _save() async {
    // 重排 sort_order
    for (int i = 0; i < _categories.length; i++) {
      _categories[i] = _CatItem(
        id: _categories[i].id,
        nameZh: _categories[i].nameZh,
        nameEn: _categories[i].nameEn,
        sortOrder: i + 1,
      );
    }
    final json = {
      'categories': _categories
          .map((c) => {
                'id': c.id,
                'name_zh': c.nameZh,
                'name_en': c.nameEn,
                'sort_order': c.sortOrder,
              })
          .toList(),
      'videos': _videoMap.values.toList(),
    };
    final ok = await LocalVideoScanner.saveConfigText(
        const JsonEncoder.withIndent('  ').convert(json));
    if (!mounted) return;
    if (ok) {
      setState(() => _hasChanges = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✅ 保存成功，数据已重新加载'),
        backgroundColor: Color(0xFF1A73E8),
        behavior: SnackBarBehavior.floating,
      ));
      context.read<VideoProvider>().switchToLocal();
    } else {
      // 保存失败：引导用户去系统设置开启权限
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.folder_off_outlined, color: Colors.orange),
            SizedBox(width: 8),
            Text('需要文件访问权限'),
          ],
        ),
        content: const Text(
          '保存失败，App 需要「所有文件访问权限」才能写入配置文件。\n\n'
          '请按以下步骤操作：\n'
          '① 点击「去设置」\n'
          '② 找到「ForwardX」App\n'
          '③ 开启「所有文件访问权限」\n'
          '④ 返回 App 重新保存',
          style: TextStyle(fontSize: 14, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8)),
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings(); // 跳转系统设置
            },
            child: const Text('去设置',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── 主体 UI ──────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        title: const Text('内容管理', style: TextStyle(fontSize: 17)),
        actions: [
          if (_hasChanges)
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded, color: Colors.white, size: 18),
              label: const Text('保存', style: TextStyle(color: Colors.white)),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.category_outlined, size: 18), text: '分类模块'),
            Tab(icon: Icon(Icons.video_library_outlined, size: 18), text: '视频配置'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A73E8)))
          : TabBarView(
              controller: _tabController,
              children: [_buildCatTab(), _buildVideoTab()],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        onPressed: () {
          if (_tabController.index == 0) {
            _showEditCatDialog();
          } else {
            _showEditVideoDialog(null);
          }
        },
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? '添加模块' : '添加视频'),
      ),
    );
  }

  // ── 分类 Tab ─────────────────────────────────

  Widget _buildCatTab() {
    return Column(
      children: [
        _banner(
          '自定义展示模块，例如「产品」「场景」「案例」。\n拖动可调整顺序，分类 ID 建议使用英文。',
        ),
        Expanded(
          child: _categories.isEmpty
              ? _empty('暂无分类', '点击右下角 + 添加模块')
              : ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  onReorder: (a, b) {
                    setState(() {
                      if (b > a) b--;
                      final item = _categories.removeAt(a);
                      _categories.insert(b, item);
                      _hasChanges = true;
                    });
                  },
                  itemCount: _categories.length,
                  itemBuilder: (_, i) =>
                      _catCard(_categories[i], i, key: ValueKey(_categories[i].id)),
                ),
        ),
      ],
    );
  }

  Widget _catCard(_CatItem cat, int idx, {required Key key}) {
    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1A73E8).withOpacity(0.12),
          child: Text(
            cat.nameZh.isNotEmpty ? cat.nameZh[0] : '?',
            style: const TextStyle(
                color: Color(0xFF1A73E8), fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          '${cat.nameZh}  /  ${cat.nameEn}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text('ID: ${cat.id}',
            style: const TextStyle(fontSize: 12, color: Colors.black38)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  size: 20, color: Color(0xFF1A73E8)),
              onPressed: () => _showEditCatDialog(idx),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: Colors.redAccent),
              onPressed: () => _deleteCat(idx),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.drag_handle, color: Colors.black26, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCatDialog([int? editIdx]) {
    final isEdit = editIdx != null;
    final cat = isEdit ? _categories[editIdx] : null;
    final idCtrl = TextEditingController(text: cat?.id ?? '');
    final zhCtrl = TextEditingController(text: cat?.nameZh ?? '');
    final enCtrl = TextEditingController(text: cat?.nameEn ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? '编辑分类模块' : '添加分类模块'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(idCtrl, '分类 ID（英文唯一标识）', 'cat_product',
                enabled: !isEdit),
            const SizedBox(height: 12),
            _field(zhCtrl, '中文名称', '产品'),
            const SizedBox(height: 12),
            _field(enCtrl, '英文名称', 'Products'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8)),
            onPressed: () {
              final id = idCtrl.text.trim();
              final zh = zhCtrl.text.trim();
              if (id.isEmpty || zh.isEmpty) return;
              setState(() {
                if (isEdit) {
                  _categories[editIdx] = _CatItem(
                      id: id,
                      nameZh: zh,
                      nameEn: enCtrl.text.trim(),
                      sortOrder: cat!.sortOrder);
                } else {
                  _categories.add(_CatItem(
                      id: id,
                      nameZh: zh,
                      nameEn: enCtrl.text.trim(),
                      sortOrder: _categories.length + 1));
                }
                _hasChanges = true;
              });
              Navigator.pop(ctx);
            },
            child: Text(isEdit ? '保存' : '添加',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteCat(int idx) {
    final cat = _categories[idx];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除分类'),
        content: Text('确认删除「${cat.nameZh}」？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              setState(() {
                _categories.removeAt(idx);
                _hasChanges = true;
              });
              Navigator.pop(ctx);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ── 视频 Tab ─────────────────────────────────

  Widget _buildVideoTab() {
    final entries = _videoMap.entries.toList();
    return Column(
      children: [
        _banner(
          '为视频文件设置标题和所属模块。\n文件名须与手机 ${LocalVideoScanner.videoFolder} 中一致。',
        ),
        Expanded(
          child: entries.isEmpty
              ? _empty('暂无视频配置', '点击右下角 + 添加视频')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  itemCount: entries.length,
                  itemBuilder: (_, i) =>
                      _videoCard(entries[i].key, entries[i].value),
                ),
        ),
      ],
    );
  }

  Widget _videoCard(String fileName, Map<String, dynamic> cfg) {
    final titleZh = cfg['title_zh'] as String? ?? fileName;
    final catIds =
        (cfg['category_ids'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final catNames = catIds.map((id) {
      try {
        return _categories.firstWhere((c) => c.id == id).nameZh;
      } catch (_) {
        return id;
      }
    }).join('、');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF1A73E8).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.videocam_outlined,
              color: Color(0xFF1A73E8), size: 22),
        ),
        title: Text(titleZh,
            style:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(fileName,
                style:
                    const TextStyle(fontSize: 11, color: Colors.black38)),
            if (catNames.isNotEmpty)
              Text('模块：$catNames',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF1A73E8))),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  size: 20, color: Color(0xFF1A73E8)),
              onPressed: () => _showEditVideoDialog(fileName),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: Colors.redAccent),
              onPressed: () => _deleteVideo(fileName),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditVideoDialog(String? editFile) {
    final isEdit = editFile != null;
    final cfg = isEdit ? Map<String, dynamic>.from(_videoMap[editFile]!) : {};

    final fileCtrl = TextEditingController(text: editFile ?? '');
    final zhCtrl = TextEditingController(text: cfg['title_zh'] as String? ?? '');
    final enCtrl = TextEditingController(text: cfg['title_en'] as String? ?? '');
    final descZhCtrl =
        TextEditingController(text: cfg['description_zh'] as String? ?? '');
    final descEnCtrl =
        TextEditingController(text: cfg['description_en'] as String? ?? '');
    final durCtrl = TextEditingController(
        text: (cfg['duration'] as int?)?.toString() ?? '');
    final selCats = ((cfg['category_ids'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [])
        .toSet();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDS) => AlertDialog(
          title: Text(isEdit ? '编辑视频' : '添加视频配置'),
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _field(fileCtrl, '视频文件名', 'robot_demo.mp4',
                      enabled: !isEdit),
                  const SizedBox(height: 10),
                  _field(zhCtrl, '中文标题', 'AMR机器人演示'),
                  const SizedBox(height: 10),
                  _field(enCtrl, '英文标题', 'AMR Robot Demo'),
                  const SizedBox(height: 10),
                  _field(descZhCtrl, '中文描述（可选）', '', maxLines: 2),
                  const SizedBox(height: 10),
                  _field(descEnCtrl, '英文描述（可选）', '', maxLines: 2),
                  const SizedBox(height: 10),
                  _field(durCtrl, '时长（秒，可选）', '120',
                      type: TextInputType.number),
                  const SizedBox(height: 14),
                  const Text('所属模块',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  _categories.isEmpty
                      ? const Text('先在「分类模块」中添加分类',
                          style: TextStyle(
                              color: Colors.black45, fontSize: 12))
                      : Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _categories
                              .map((c) => FilterChip(
                                    label: Text(c.nameZh),
                                    selected: selCats.contains(c.id),
                                    selectedColor: const Color(0xFF1A73E8)
                                        .withOpacity(0.15),
                                    checkmarkColor: const Color(0xFF1A73E8),
                                    onSelected: (v) => setDS(() =>
                                        v ? selCats.add(c.id) : selCats.remove(c.id)),
                                  ))
                              .toList(),
                        ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8)),
              onPressed: () {
                final file = fileCtrl.text.trim();
                if (file.isEmpty) return;
                final newCfg = <String, dynamic>{
                  'file': file,
                  'title_zh': zhCtrl.text.trim(),
                  'title_en': enCtrl.text.trim(),
                  'description_zh': descZhCtrl.text.trim(),
                  'description_en': descEnCtrl.text.trim(),
                  'category_ids': selCats.toList(),
                  if (durCtrl.text.trim().isNotEmpty)
                    'duration': int.tryParse(durCtrl.text.trim()),
                  'sort_order': _videoMap[editFile ?? '']?['sort_order'] ??
                      _videoMap.length,
                };
                setState(() {
                  if (isEdit) _videoMap.remove(editFile);
                  _videoMap[file] = newCfg;
                  _hasChanges = true;
                });
                Navigator.pop(ctx);
              },
              child: const Text('保存',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteVideo(String fileName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除视频配置'),
        content: Text('确认删除「$fileName」的配置？\n（不会删除手机上的视频文件）'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              setState(() {
                _videoMap.remove(fileName);
                _hasChanges = true;
              });
              Navigator.pop(ctx);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ── 通用小组件 ─────────────────────────────────

  Widget _banner(String text) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A73E8).withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1A73E8).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: Color(0xFF1A73E8)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style:
                    const TextStyle(fontSize: 12, color: Color(0xFF444444))),
          ),
        ],
      ),
    );
  }

  Widget _empty(String title, String sub) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 60, color: Colors.black26),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black45)),
          const SizedBox(height: 4),
          Text(sub,
              style: const TextStyle(fontSize: 13, color: Colors.black38)),
        ],
      ),
    );
  }

  TextField _field(
    TextEditingController ctrl,
    String label,
    String hint, {
    bool enabled = true,
    int maxLines = 1,
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: type,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint.isEmpty ? null : hint,
        hintStyle: const TextStyle(color: Colors.black26, fontSize: 13),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: Color(0xFF1A73E8), width: 1.5),
        ),
      ),
    );
  }
}

// ── 数据类 ──────────────────────────────────────

class _CatItem {
  final String id;
  final String nameZh;
  final String nameEn;
  final int sortOrder;

  _CatItem({
    required this.id,
    required this.nameZh,
    required this.nameEn,
    required this.sortOrder,
  });
}
