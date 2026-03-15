import 'package:flutter/material.dart';

/// 所有 UI 文本的本地化定义
class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const _strings = {
    'en': {
      // App
      'appTitle': 'ForwardX Robotics Videos',
      'appSubtitle': '{count} videos',

      // Filter / Search
      'search': 'Search videos, products, scenes...',
      'filter': 'Filter',
      'all': 'All',
      'clearAll': 'Clear All',
      'viewResults': 'View Results ({count})',
      'viewAll': 'View All Videos',

      // Filter categories
      'product': 'Product',
      'scene': 'Scene',
      'case': 'Case',

      // Video list
      'noResults': 'No matching videos found',
      'clearFilters': 'Clear Filters',

      // Video player
      'videoIntro': 'Introduction',
      'loadFailed': 'Failed to load video: {error}',
      'retry': 'Retry',

      // Info tags
      'tagProduct': 'Product',
      'tagScene': 'Scene',
      'tagCase': 'Case',

      // Language switcher
      'switchLang': '中文',
    },
    'zh': {
      // App
      'appTitle': 'ForwardX Robotics Videos',
      'appSubtitle': '共 {count} 个视频',

      // Filter / Search
      'search': '搜索视频、产品、场景...',
      'filter': '筛选',
      'all': '全部',
      'clearAll': '清除全部',
      'viewResults': '查看筛选结果（{count} 个）',
      'viewAll': '查看全部视频',

      // Filter categories
      'product': '产品',
      'scene': '场景',
      'case': '案例',

      // Video list
      'noResults': '没有找到匹配的视频',
      'clearFilters': '清除筛选条件',

      // Video player
      'videoIntro': '视频介绍',
      'loadFailed': '视频加载失败：{error}',
      'retry': '重试',

      // Info tags
      'tagProduct': '产品',
      'tagScene': '场景',
      'tagCase': '案例',

      // Language switcher
      'switchLang': 'English',
    },
  };

  String get languageCode => locale.languageCode;
  bool get isZh => locale.languageCode == 'zh';

  Map<String, String> get _t =>
      (_strings[locale.languageCode] ?? _strings['en'])!
          .map((k, v) => MapEntry(k, v));

  /// 获取字符串，支持 {count} {error} 等占位符替换
  String tr(String key, {Map<String, String>? args}) {
    String text = _t[key] ?? key;
    if (args != null) {
      args.forEach((k, v) => text = text.replaceAll('{$k}', v));
    }
    return text;
  }

  // ── 常用快捷属性 ──────────────────────────────

  String get appTitle => tr('appTitle');
  String appSubtitle(int count) => tr('appSubtitle', args: {'count': '$count'});
  String get search => tr('search');
  String get filter => tr('filter');
  String get all => tr('all');
  String get clearAll => tr('clearAll');
  String viewResults(int count) => tr('viewResults', args: {'count': '$count'});
  String get viewAll => tr('viewAll');
  String get product => tr('product');
  String get scene => tr('scene');
  String get caseLabel => tr('case');
  String get noResults => tr('noResults');
  String get clearFilters => tr('clearFilters');
  String get videoIntro => tr('videoIntro');
  String loadFailed(String error) => tr('loadFailed', args: {'error': error});
  String get retry => tr('retry');
  String get tagProduct => tr('tagProduct');
  String get tagScene => tr('tagScene');
  String get tagCase => tr('tagCase');
  String get switchLang => tr('switchLang');
}

/// 本地化代理
class AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'zh'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
