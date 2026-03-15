# 视频展示中心 - Flutter App

## 功能简介

一款支持多维度筛选浏览的产品视频展示应用，适用于 Android / iOS。

### 核心功能
- **多标签筛选**：按「产品」「场景」「案例」三个维度组合筛选
- **顶部快速切换**：横向滚动的产品快速筛选条
- **右侧筛选抽屉**：场景和案例的详细筛选面板
- **关键词搜索**：全文搜索视频标题、描述、标签
- **视频播放**：内置播放器，支持全屏、进度控制
- **激活标签展示**：已选筛选条件可单独删除

---

## 快速开始

### 1. 环境要求

- Flutter SDK >= 3.0.0
- Android SDK >= 21（Android 5.0+）
- Xcode >= 14（iOS 开发）

### 2. 安装依赖

```bash
cd video_showcase
flutter pub get
```

### 3. 运行

```bash
# Android
flutter run

# 构建 APK
flutter build apk --release
```

---

## 添加真实视频

### 步骤 1：放入视频文件

将 `.mp4` 视频文件放入 `assets/videos/` 目录：

```
assets/
  videos/
    camera_home_security.mp4
    camera_face_door.mp4
    lock_remote_open.mp4
    ...
```

### 步骤 2：修改数据

打开 `lib/data/mock_data.dart`，修改每条数据的 `videoPath` 和 `thumbnailPath`：

```dart
VideoItem(
  id: '001',
  title: '你的视频标题',
  description: '视频描述',
  videoPath: 'assets/videos/your_video.mp4',  // ← 改这里
  thumbnailPath: 'assets/thumbnails/thumb_001.jpg',  // ← 改这里
  product: '产品名称',
  scene: '应用场景',
  caseTag: '案例标签',
),
```

### 步骤 3：确认 pubspec.yaml

确保 `pubspec.yaml` 中已声明 assets：

```yaml
flutter:
  assets:
    - assets/videos/
    - assets/thumbnails/
```

---

## 项目结构

```
lib/
├── main.dart                    # 入口
├── models/
│   ├── video_item.dart          # 视频数据模型
│   └── filter_state.dart        # 筛选状态模型
├── data/
│   ├── mock_data.dart           # 本地模拟数据（在这里添加视频）
│   └── video_provider.dart      # 状态管理 (Provider)
├── pages/
│   ├── home_page.dart           # 首页（列表+筛选）
│   ├── video_player_page.dart   # 视频播放页
│   └── filter_drawer.dart       # 筛选抽屉
└── widgets/
    ├── video_card.dart          # 视频卡片组件
    └── filter_chip_widget.dart  # 筛选标签组件
```

---

## 扩展提示

- **接入网络数据**：将 `mock_data.dart` 中的静态列表替换为 HTTP 请求返回的数据即可
- **添加分类**：直接在 `mock_data.dart` 中的数据项里填写新的 product / scene / caseTag，筛选系统会自动识别
- **缩略图**：推荐使用 `16:9` 比例的 JPG/PNG，放入 `assets/thumbnails/`
