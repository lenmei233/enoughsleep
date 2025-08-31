# 🌙 EnoughSleep - 好眠助手

<div align="center">

![EnoughSleep Logo](https://img.shields.io/badge/EnoughSleep-好眠助手-4E65FF?style=for-the-badge&logo=moon&logoColor=white)

[![Flutter](https://img.shields.io/badge/Flutter-3.8.1+-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Windows-lightgrey?style=flat-square)](https://flutter.dev)

**一款优雅的睡眠跟踪与质量评估应用，帮助你养成良好的睡眠习惯。**

[📱 下载体验](#下载) • [🚀 快速开始](#快速开始) • [📖 使用指南](#功能特性) • [🤝 贡献代码](#贡献)

</div>

---

## ✨ 功能特性

### 🎯 核心功能
- **睡眠时间跟踪** - 精确记录你的睡眠开始和结束时间
- **睡眠质量评价** - 5星评级系统，记录每晚睡眠感受
- **数据统计分析** - 直观的图表展示你的睡眠趋势
- **睡眠目标设置** - 个性化设定理想睡眠时长
- **历史记录查看** - 完整的睡眠历史数据

### 🎨 设计亮点
- **现代化UI设计** - 采用蓝紫色渐变主题（#4E65FF → #92EFFD）
- **流畅动画效果** - 精心设计的淡入、脉冲、缩放动画
- **开屏动画** - 美观的启动页面，包含随机暖心提示
- **中文本土化** - 完全中文界面，贴合中文用户习惯
- **响应式布局** - 适配多种屏幕尺寸

### 📊 数据可视化
- **周统计图表** - 过去7天睡眠时长可视化
- **平均数据** - 睡眠时长和质量平均值
- **目标对比** - 实际睡眠与目标对比
- **历史趋势** - 长期睡眠模式分析

---

## 🚀 快速开始

### 📋 环境要求

- **Flutter**: >= 3.8.1
- **Dart**: >= 3.0
- **Android Studio**: 最新版本（Android开发）
- **Visual Studio**: 2019或更高版本（Windows开发）
- **Xcode**: 12.0+（iOS开发）

### 🛠️ 安装步骤

1. **克隆项目**
   ```bash
   git clone https://github.com/lenmei233/enoughsleep.git
   cd enoughsleep
   ```

2. **安装依赖**
   ```bash
   flutter pub get
   ```

3. **运行项目**
   ```bash
   # 调试模式
   flutter run
   
   # 指定设备
   flutter run -d chrome  # Web版本
   flutter run -d windows # Windows版本
   ```

### 📦 构建发布版本

```bash
# Android APK
flutter build apk --release

# iOS应用
flutter build ios --release

# Windows应用
flutter build windows --release

# Web应用
flutter build web --release
```

---

## 💻 技术栈

### 🏗️ 架构设计
- **状态管理**: Provider
- **本地存储**: SharedPreferences
- **数据可视化**: FL Chart
- **国际化**: Flutter Intl

### 📱 支持平台
- ✅ **Android** (5.0+)
- ✅ **iOS** (12.0+)
- ✅ **Web** (Chrome, Firefox, Safari)
- ✅ **Windows** (10+)
- ⏳ **macOS** (即将支持)
- ⏳ **Linux** (即将支持)

### 📚 主要依赖
```yaml
dependencies:
  flutter: sdk
  provider: ^6.0.5
  shared_preferences: ^2.2.2
  fl_chart: ^0.68.0
  intl: ^0.18.1
```

---

## 📖 使用指南

### 🌙 开始睡眠跟踪

1. **点击"开始睡眠"按钮** - 开始记录睡眠时间
2. **睡醒后点击"结束睡眠"** - 停止时间记录
3. **评价睡眠质量** - 使用5星评级系统
4. **查看统计数据** - 在统计页面查看分析结果

### ⚙️ 个性化设置

- **睡眠目标**: 设置理想的睡眠时长（建议7-9小时）
- **睡眠提醒**: 开启/关闭睡眠时间提醒
- **数据管理**: 导出或重置睡眠数据

### 📊 数据分析

- **实时显示**: 当前睡眠时长实时更新
- **历史对比**: 与过往数据对比分析
- **趋势预测**: 基于历史数据的睡眠建议

---

## 🎯 路线图

### 📅 已完成功能
- [x] 基础睡眠跟踪
- [x] 睡眠质量评价
- [x] 数据统计可视化
- [x] 多平台支持
- [x] 中文本地化
- [x] 现代化UI设计

### 🔮 计划功能
- [ ] 智能睡眠建议
- [ ] 睡眠音乐播放
- [ ] 数据云端同步
- [ ] 社交分享功能
- [ ] Apple Health 集成
- [ ] 穿戴设备支持
- [ ] 深度睡眠分析
- [ ] 睡眠报告生成

---

## 🤝 贡献

我们欢迎所有形式的贡献！无论是新功能、Bug修复、文档改进还是问题反馈。

### 📝 贡献方式

1. **Fork 项目**
2. **创建功能分支** (`git checkout -b feature/AmazingFeature`)
3. **提交更改** (`git commit -m 'Add some AmazingFeature'`)
4. **推送到分支** (`git push origin feature/AmazingFeature`)
5. **创建 Pull Request**

### 🐛 问题反馈

发现bug或有功能建议？请[创建Issue](https://github.com/lenmei233/enoughsleep/issues)

### 📋 开发规范

- 遵循 [Flutter代码规范](https://flutter.dev/docs/development/tools/formatting)
- 提交信息使用中文，格式清晰
- 添加必要的注释和文档
- 确保代码通过所有测试

---

## 📄 许可证

本项目基于 MIT 许可证开源 - 详见 [LICENSE](LICENSE) 文件

---

## 👨‍💻 作者

**lenmei233**
- GitHub: [@lenmei233](https://github.com/lenmei233)
- Email: your.email@example.com

---

## 🙏 致谢

感谢以下开源项目的支持：

- [Flutter](https://flutter.dev) - 跨平台应用开发框架
- [FL Chart](https://github.com/imaNNeoFighT/fl_chart) - 数据可视化图表库
- [Provider](https://pub.dev/packages/provider) - 状态管理方案

---

## 📱 预览截图

<div align="center">
  <img src="screenshots/splash.png" width="200" alt="启动页面"/>
  <img src="screenshots/home.png" width="200" alt="主页面"/>
  <img src="screenshots/stats.png" width="200" alt="统计页面"/>
  <img src="screenshots/settings.png" width="200" alt="设置页面"/>
</div>

---

<div align="center">

**如果这个项目对你有帮助，请给个 ⭐️ 支持一下！**

Made with ❤️ by [lenmei233](https://github.com/lenmei233)

</div>