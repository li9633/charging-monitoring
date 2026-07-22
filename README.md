# 充电桩监测

实时监测充电桩在线状态，支持离线/在线/错误筛选，自动拉取充电记录，日志导出与设备信息收集。

## 功能

- **状态监测**：自动拉取充电桩状态，支持下拉刷新
- **多维筛选**：全部 / 离线 / 在线 / 错误，四种 Tab 快速筛选
- **充电记录**：优先从充电记录提取桩号，失败自动回退默认配置
- **日志系统**：INFO / WARN / ERROR / DEBUG 四级日志，支持长按复制、导出文件
- **设备信息**：导出日志自动附带设备型号、系统版本、API 级别等
- **可配置**：自定义 WX-Token、默认桩号、位置标签、充电记录开关、默认筛选

## 快速开始

```bash
# 安装依赖
flutter pub get

# 运行（模拟器）
flutter run -d emulator-5554

# 打包
flutter build apk --split-per-abi --release
```

## 技术栈

- **框架**：Flutter 3.x + Dart
- **网络**：http
- **持久化**：shared_preferences
- **设备信息**：device_info_plus / package_info_plus
- **分享**：share_plus / path_provider

## 项目结构

```
lib/
├── main.dart                  # 入口，底部导航壳
├── pages/
│   ├── monitor_page.dart      # 监测页（状态检测 + Tab 筛选）
│   ├── logs_page.dart         # 日志页（筛选 + 复制 + 导出）
│   ├── settings_page.dart     # 设置页（Token / 桩号 / 标签 / 开关）
│   └── about_page.dart        # 关于页（版本 / 开发者 / GitHub）
└── services/
    ├── pile_service.dart      # API 请求 + 并发批处理
    ├── settings_service.dart  # 配置持久化
    └── log_service.dart       # 全局日志服务
```

## 开发者

- **GitHub**：[li9633](https://github.com/li9633/charging-monitoring)
