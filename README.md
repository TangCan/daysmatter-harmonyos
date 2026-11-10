# 记得那天 · DaysMatter

> 一个为 HarmonyOS NEXT 打造的极简倒数日应用。记录重要日子，桌面卡片一眼看到"还有几天"。

![HarmonyOS](https://img.shields.io/badge/HarmonyOS-NEXT-0D70F2) ![ArkTS](https://img.shields.io/badge/ArkTS-API%2012-blue) ![License](https://img.shields.io/badge/License-MIT-green)

## ✨ 功能特性

- **倒数/正数日期**：自动判断"还有 X 天"、"已过 X 天"、"就是今天"
- **临期配色**：7 天内红色预警、30 天内琥珀色提醒、更远蓝色、已过灰色
- **系统级提醒**：当天 / 提前 1 天本地通知，重复事件每年自动循环
- **事件准备清单**：每个日子挂待办（订蛋糕、买礼物），勾选即见进度
- **里程碑时间轴**：100 天 / 周年 / 满 N 岁节点自动生成
- **数据本地化**：Preferences 持久化，无网络、无追踪、数据不离开设备
- **桌面卡片（FormKit）**：2×2 与 2×4 卡片实时显示最近事件
- **极简交互**：分类筛选、搜索、置顶、每年重复、照片背景、分享图、JSON 备份、隐私锁

## 📸 预览

<!-- 【TODO: 上架前补充 Previewer/云真机截图】 -->

## 🚀 快速开始

### 环境要求

- [DevEco Studio](https://developer.huawei.com/consumer/cn/deveco-studio/) 5.0.x
- HarmonyOS SDK（API 12+，DevEco 内置下载）

### 运行

```bash
git clone https://github.com/TangCan/daysmatter-harmonyos.git
```

1. 用 DevEco Studio 打开项目根目录
2. 等待依赖同步完成（首次约 1~3 分钟）
3. 打开 `entry/src/main/ets/pages/Index.ets`，右侧 Previewer 实时预览
4. 真机/云真机运行：`Run > entry`

### 项目结构

```
entry/src/main/ets/
├── model/
│   ├── CountdownEvent.ets    # 数据模型 + 天数/里程碑/工作日计算
│   ├── EventQuery.ets        # 列表过滤排序、统计、展示文案（纯函数）
│   └── DateStepper.ets       # 日期步进器 + 日期计算器逻辑（纯函数）
├── common/
│   ├── EventStore.ets        # Preferences JSON 持久化 + 隐私锁
│   ├── CardSync.ets          # 桌面卡片数据推送
│   ├── ReminderScheduler.ets # reminderAgentManager 本地提醒
│   ├── DataBackup.ets        # JSON 导出 / 导入
│   └── FestivalTemplates.ets # 节日模板库（含农历对照表）
├── pages/
│   └── Index.ets             # 主界面（列表/详情/设置/统计）
├── widget/
│   └── pages/WidgetCard.ets  # 2×2 / 2×4 桌面卡片 UI
└── entryformability/
    └── EntryFormAbility.ets  # 卡片生命周期管理

entry/src/test/               # 单元测试（hypium 风格）
tools/coverage/               # Node 覆盖率运行器（.ets -> CJS + kit 桩）
```

## 🧪 测试与覆盖率

业务逻辑集中在 `model/` 与 `common/`（纯函数 + 可注入的系统能力），由 hypium 风格用例覆盖：

```bash
# 一键跑单元测试 + 覆盖率（无需模拟器/真机）
node tools/coverage/run.js

# 自定义阈值（默认 95%）
node tools/coverage/run.js --threshold=95
```

运行器做了三件事：把 `.ets` 转译为 CommonJS（保留 source map，覆盖率直接映射回 `.ets` 行号）、
把 `@kit.*` 系统能力替换为内存桩（Preferences / FormKit / NotificationKit / reminderAgentManager / 文件选择器）、
用内置的 hypium 兼容层执行 `entry/src/test/*.test.ets`。

当前结果（137 个用例）：**行覆盖 99.6% / 分支覆盖 98.5% / 函数覆盖 99.7%**，
明细见 [docs/testing/覆盖率报告.md](docs/testing/覆盖率报告.md)。低于阈值时命令以非 0 退出，可直接接入 CI。

> 说明：`pages/Index.ets` 与卡片 UI 属声明式 UI DSL，无法在 Node 中渲染，其逻辑已抽离到
> `EventQuery.ets` / `DateStepper.ets` 并被完整覆盖；界面改动仍需云真机回归。

## 📦 商业授权

本仓库代码默认遵循 MIT 协议开源（见 [LICENSE](LICENSE)）。

如果你希望**省下踩坑时间、获得完整教学与持续更新**，我们提供付费版本：

| | 免费版（本仓库） | 个人授权 ¥49 | 商业授权 ¥299 |
|---|---|---|---|
| 完整可运行源码 | ✅ | ✅ | ✅ |
| 详细注释 + 架构讲解文档 | — | ✅ | ✅ |
| 二次开发指南（改名/换主题/加功能） | — | ✅ | ✅ |
| 商用授权（用于商业项目/外包交付） | — | — | ✅ |
| 一年版本更新 | — | ✅ | ✅ |
| 微信答疑（环境/报错） | — | — | ✅ |

购买方式：[面包多店铺链接 <!-- TODO -->]

## 🛠 技术栈

- ArkTS + ArkUI 声明式开发
- @kit.ArkData（Preferences）
- @kit.FormKit（formProvider / FormExtensionAbility）
- 兼容 API 12+，Intel/ARM 均可编译

## 📝 更新日志

- **v1.0.0**：倒数列表、添加/删除、持久化、2×2 桌面卡片
- **v1.1.0**：隐私弹窗、分类筛选、每年重复、备注、置顶、搜索、2×4 卡片
- **v1.2.0**：系统级提醒、节日模板库（含农历）、数据概览
- **v1.3.0**：事件准备清单、里程碑时间轴、分享卡片
- **v1.3.1**：照片背景、多单位倒计时、那年今天、JSON 备份、隐私锁、日期计算器
- **v1.3.2**：逻辑层抽离（EventQuery / DateStepper）+ 单元测试与覆盖率体系（99%+）

## License

[MIT](LICENSE) © 2026
