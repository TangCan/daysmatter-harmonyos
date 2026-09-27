# 记得那天 · DaysMatter

> 一个为 HarmonyOS NEXT 打造的极简倒数日应用。记录重要日子，桌面卡片一眼看到"还有几天"。

![HarmonyOS](https://img.shields.io/badge/HarmonyOS-NEXT-0D70F2) ![ArkTS](https://img.shields.io/badge/ArkTS-API%2012-blue) ![License](https://img.shields.io/badge/License-MIT-green)

## ✨ 功能特性

- **倒数/正数日期**：自动判断"还有 X 天"、"已过 X 天"、"就是今天"
- **临期配色**：7 天内红色预警、30 天内琥珀色提醒、更远蓝色、已过灰色
- **数据本地化**：Preferences 持久化，无网络、无追踪、数据不离开设备
- **桌面卡片（FormKit）**：2×2 卡片实时显示最近的事件与剩余天数，应用内增删自动刷新
- **极简交互**：右下角 + 快速添加（名称 + 日期），列表左滑删除

## 📸 预览

<!-- 【TODO: 上架前补充 Previewer/云真机截图】 -->

## 🚀 快速开始

### 环境要求

- [DevEco Studio](https://developer.huawei.com/consumer/cn/deveco-studio/) 5.0.x
- HarmonyOS SDK（API 12+，DevEco 内置下载）

### 运行

```bash
git clone https://github.com/<你的用户名>/daysmatter-harmonyos.git
```

1. 用 DevEco Studio 打开项目根目录
2. 等待依赖同步完成（首次约 1~3 分钟）
3. 打开 `entry/src/main/ets/pages/Index.ets`，右侧 Previewer 实时预览
4. 真机/云真机运行：`Run > entry`

### 项目结构

```
entry/src/main/ets/
├── model/
│   └── CountdownEvent.ets    # 数据模型 + 天数计算
├── common/
│   ├── EventStore.ets        # Preferences JSON 持久化
│   └── CardSync.ets          # 桌面卡片数据推送
├── pages/
│   └── Index.ets             # 主界面（列表/添加/删除）
├── widget/
│   └── pages/WidgetCard.ets  # 2×2 桌面卡片 UI
└── entryformability/
    └── EntryFormAbility.ets  # 卡片生命周期管理
```

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

## License

[MIT](LICENSE) © 2026
