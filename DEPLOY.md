# 🚀 GitHub Actions 自动构建 APK 指南

## 前提条件
- 有 GitHub 账号（免费注册：https://github.com）
- 电脑上安装了 **Git**（下载：https://git-scm.com）

---

## 第一步：在 GitHub 创建仓库

1. 登录 GitHub，点击右上角 **「+」→「New repository」**
2. 填写仓库名，如：`forwardx-robotics-videos`
3. 选择 **Public**（公开，Actions 免费无限制）或 Private
4. **不要勾选** Initialize README
5. 点击 **「Create repository」**
6. 复制页面上显示的仓库地址，例如：
   ```
   https://github.com/你的用户名/forwardx-robotics-videos.git
   ```

---

## 第二步：推送代码到 GitHub

打开命令行，进入项目目录：

```bash
cd c:\Users\ld\WorkBuddy\20260315103557\video_showcase

# 初始化 Git
git init

# 添加所有文件
git add .

# 提交
git commit -m "初始提交：ForwardX Robotics Videos App"

# 关联远程仓库（替换为你的仓库地址）
git remote add origin https://github.com/你的用户名/forwardx-robotics-videos.git

# 推送
git push -u origin main
```

---

## 第三步：等待自动构建

1. 打开 GitHub 仓库页面
2. 点击顶部 **「Actions」** 标签
3. 可以看到「Build Android APK」工作流正在运行（橙色圆圈）
4. 等待约 **5-8 分钟**构建完成（变为绿色对勾 ✅）

---

## 第四步：下载 APK

**方法 A：从 Releases 下载（推荐）**
1. 点击仓库页面右侧 **「Releases」**
2. 找到最新的 `Build #1`
3. 下载 `app-release.apk`

**方法 B：从 Artifacts 下载**
1. 点击 **「Actions」** → 点击最新的构建记录
2. 页面底部找到 **「Artifacts」** 区域
3. 点击 `ForwardX-Robotics-Videos-release` 下载 ZIP
4. 解压得到 `app-release.apk`

---

## 第五步：安装到 Android 手机

1. 将 APK 文件传到手机（微信/QQ/数据线均可）
2. 在手机上打开 APK 文件
3. 如果提示「不允许安装未知来源应用」：
   - 进入手机 **「设置」→「安全」→「安装未知应用」**
   - 允许来自「文件管理器」的安装
4. 点击安装，完成！

---

## 后续更新

每次修改代码后，只需：

```bash
git add .
git commit -m "更新：描述你的修改"
git push
```

GitHub Actions 会自动重新构建，几分钟后新 APK 就出来了。

---

## 常见问题

**Q：构建失败怎么办？**
点击 Actions 页面中失败的任务，查看红色报错信息，截图发给我分析。

**Q：APK 安装后打开是空白？**
正常，因为 `assets/videos/` 目录里还没有真实视频文件。
添加视频后重新构建即可正常播放。

**Q：想换个应用名称？**
修改 `android/app/src/main/AndroidManifest.xml` 中的 `android:label` 字段。
