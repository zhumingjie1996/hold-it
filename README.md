# 忍一下 · Hold It

> 记录克制，成就更好的自己。

**忍一下**是一款专注于记录「忍住了什么」的极简 iOS App。我们不记录「完成了什么」，而是记录每一次对自己欲望的克制——没喝奶茶、没刷短视频、没冲动消费。每一次忍住，都是对自己的一次胜利。

---

## 截图

> *(待补充)*

---

## 核心功能

| 功能 | 说明 |
|---|---|
| 📝 **忍住记录** | 一键记录你每一次忍住的努力，支持添加备注 |
| 🎨 **自定义分类** | 在5个默认分类基础上，无限添加你自己的忍住项（PRO） |
| 📊 **多维统计** | 热力图、分类分析、月度趋势、时段分布、周几分布（PRO） |
| 💰 **节省统计** | 记录金额后自动计算累计节省、月度趋势、分类排行（PRO） |
| ✨ **每日鼓励** | 每日固定一句鼓励语，伴你坚持 |
| 🌍 **多语言** | 支持简体中文、繁体中文、English、日本語 |
| 🌙 **深色模式** | 跟随系统或手动切换明暗主题 |

### 默认忍住项

| 图标 | 名称 | 默认金额 |
|---|---|---|
| 🧋 | 奶茶 | ¥15 |
| 💸 | 冲动消费 | ¥100 |
| 🎮 | 游戏 | — |
| 📱 | 短视频 | — |
| ❤️ | 想TA | — |

---

## 会员功能（终身会员）

| 免费版 | 终身会员（PRO） |
|---|---|
| 忍住记录（无限） | 自定义忍住项（无限） |
| 基础统计卡片 | 热力图、分类分析、月度趋势、时段分析、周几分布 |
| 每日鼓励语 | 节省金额统计（时段对比、月度趋势、分类排行） |
| — | 抹除数据功能 |

- **Product ID**：`mj.holdit.lifetimeVip`（Non-Consumable）
- **付款方式**：一次购买，永久有效，通过 App Store 内购

---

## 技术栈

| 层 | 技术 |
|---|---|
| UI | SwiftUI |
| 数据持久化 | SwiftData（SQLite） |
| 内购 | StoreKit 2 |
| 轻量存储 | UserDefaults（主题、货币单位等偏好设置） |
| 国际化 | Localizable.xcstrings（xcstrings 格式） |
| 最低支持 | iOS 17+ |
| 开发工具 | Xcode 16+ |

---

## 项目结构

```
hold-it-ios/
├── Models/
│   ├── ResistRecord.swift          # 数据模型：忍住记录、分类
│   ├── EncourageQuote.swift        # 鼓励语模型
│   └── EncourageQuoteData+*.swift  # 鼓励语数据（中/英/日）
├── ViewModels/
│   ├── AppState.swift              # 全局状态：统计计算
│   └── StoreManager.swift          # StoreKit 2 内购管理
├── Views/
│   ├── Home/
│   │   ├── HomeView.swift          # 首页：统计卡片、每日鼓励、最近记录
│   │   ├── RecordSheet.swift       # 记录弹窗：分类选择、金额、备注
│   │   └── CelebrationView.swift   # 保存成功庆祝动画
│   ├── Stats/
│   │   ├── StatsView.swift         # 统计总览
│   │   ├── HeatmapView.swift       # 热力图
│   │   ├── CategoryStatsView.swift # 分类统计
│   │   ├── MonthlyTrendView.swift  # 月度趋势
│   │   ├── TimeOfDayView.swift     # 时段分析
│   │   ├── WeekdayDistributionView.swift # 周几分布
│   │   └── SavedAmountStatsView.swift    # 节省金额统计
│   ├── Timeline/
│   │   └── TimelineView.swift      # 全部记录 & 节省记录列表
│   └── Settings/
│       └── SettingsView.swift      # 设置：主题、货币、语言、会员、关于
├── Assets.xcassets/                # 图片资源（AppLogo、AccentColor）
├── Localizable.xcstrings           # 多语言翻译文件
├── ContentView.swift               # 根视图（TabView）
└── hold_it_iosApp.swift            # App 入口
```

---

## 本地运行

1. 克隆仓库
2. 用 Xcode 16+ 打开 `hold-it-ios.xcodeproj`
3. 选择模拟器或真机（iOS 17+）
4. 运行即可，无需任何第三方依赖

> **内购测试**：在真机上使用 StoreKit Configuration 文件或 Sandbox 账号测试内购流程。

---

## 数据说明

- 所有数据**完全本地存储**，不收集、不上传任何个人信息
- 数据库：SwiftData（SQLite），路径位于 App 沙盒 `Application Support/` 目录
- 卸载 App 将永久删除所有数据

---

## License

MIT
