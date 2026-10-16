# CUSTOMIZATION.md

> **本文件用途**：记录本仓库（fork）相对于上游原仓库所做的**全部定制改动**，供后续维护者与 AI 助手在「同步上游更新」时参照执行。
>
> **给 AI 助手的强制阅读须知**：在处理本仓库的任何合并 / 同步 / 冲突解决任务之前，**必须完整阅读本文件**。本文件中标记为「定制改动」的内容均为**有意为之**，**不得**被当作过时代码、冗余代码或错误代码而回退、删除或"优化"。违反此约束将导致用户功能丢失。

---

## 1. 仓库基本信息

| 项目 | 值 |
|---|---|
| 上游原仓库（upstream） | `https://github.com/bggRGjQaUbCoE/PiliPlus` |
| 本 fork 仓库（origin） | `https://github.com/Godwin9527/PiliPlus` |
| 默认分支 | `main` |
| 项目类型 | Flutter 应用（BiliBili 第三方客户端） |
| Flutter 版本 | `3.47.7`（见 `.fvmrc`） |
| 本文件最后更新 | 2026-10-16 |
| 最后更新的定制提交 | `9a819ea9e` |

---

## 2. 改动总览

本 fork 相对上游的全部改动如下，**共涉及 8 个文件、2 个定制提交**。

| # | 文件 | 改动类型 | 是否属于"定制"（禁止回退） |
|---|---|---|---|
| 1 | `lib/common/widgets/video_popup_menu.dart` | 重构 + 新增公共函数 | ✅ 是 |
| 2 | `lib/common/widgets/video_card/video_card_v.dart` | 行为修改 | ✅ 是 |
| 3 | `lib/common/widgets/video_card/video_card_h.dart` | 行为修改 | ✅ 是 |
| 4 | `lib/pages/member_video/widgets/video_card_h_member_video.dart` | 行为修改 | ✅ 是 |
| 5 | `lib/http/api.dart` | 常量指向变更 | ✅ 是 |
| 6 | `lib/common/constants.dart` | 常量指向变更 | ✅ 是 |
| 7 | `.github/workflows/build.yml` | CI 配置变更 | ✅ 是 |
| 8 | `.gitignore` | 新增忽略规则 | ✅ 是 |

对应提交：

```
9a819ea9e  chore: 忽略本地签名密钥目录 .keys
2202c3061  长按视频卡片改为弹出三点菜单，并将更新源指向 fork 仓库
```

---

## 3. 逐项改动详解

### 3.1 长按视频卡片 → 弹出三点菜单（核心定制）

**需求背景**：上游行为是「长按视频卡片封面 → 弹出封面放大预览弹窗（`imageSaveDialog`）」。用户认为该功能无用，希望改为「长按 = 点击右下角三点按钮」，因为三点按钮点击区域过小，长按整卡更便于操作。

**改动范围**：3 个"视频卡片"组件。**注意：只改这 3 个，其余卡片的 `imageSaveDialog` 调用为上游原有行为，不要改动。**

#### (a) `lib/common/widgets/video_popup_menu.dart`

这是**改动的核心**。做了两件事：

**① 抽出公共函数 `buildVideoMenuItems`（文件内约第 65 行）**

将原本内联在 `PopupMenuButton.itemBuilder` 中的菜单项构造逻辑抽出为顶层函数：

```dart
List<PopupMenuEntry<dynamic>> buildVideoMenuItems(
  BuildContext context,
  BaseSimpleVideoItemModel videoItem, {
  double menuItemHeight = 45,
  VoidCallback? onRemove,
}) {
  return [
        // ...原有全部菜单项，逐项原样搬运...
      ]
        .map((e) => PopupMenuItem(...))
        .toList();
}
```

> ⚠️ **注意**：该函数的函数体是从原 `itemBuilder` **原样搬运**的，仅做了缩进调整。文件中显示的 `593 行改动` 绝大部分是**缩进变化**，逻辑完全一致。若上游修改了菜单项内容，**应保留上游的新菜单项，仅维持函数抽取结构**。

**② 新增公共函数 `showVideoPopupMenu`（文件内约第 364 行）**

```dart
Future<void> showVideoPopupMenu(
  BuildContext context,
  BaseSimpleVideoItemModel videoItem, {
  RelativeRect? position,
  double menuItemHeight = 45,
  VoidCallback? onRemove,
}) {
  return showMenu<dynamic>(
    context: context,
    position: position ?? /* 默认在组件下方弹出 */,
    items: buildVideoMenuItems(...),
  );
}
```

该函数是长按手势的入口。当 `position` 为空时，会通过 `PageUtils.menuPosition` 计算默认弹出位置（组件下方）。

**③ `VideoPopupMenu.itemBuilder` 改为调用 `buildVideoMenuItems`**

```dart
itemBuilder: (context) => buildVideoMenuItems(
  context,
  videoItem,
  menuItemHeight: menuItemHeight,
  onRemove: onRemove,
),
```

> **设计意图**：让「三点按钮」与「长按」共用**同一份**菜单构造逻辑，从而保证两条入口弹出的菜单**永远一致**。这是本重构的**唯一目的**。合并时**必须保留这种共用结构**，不得改回内联写法。

**④ 新增 import**

```dart
import 'package:PiliPlus/utils/page_utils.dart';
```

#### (b) `lib/common/widgets/video_card/video_card_v.dart`

- `onLongPress` 由调用 `imageSaveDialog(...)` 改为调用 `showVideoPopupMenu(context, videoItem, onRemove: onRemove)`（约第 84 行）
- **删除** import：`package:PiliPlus/common/widgets/image/image_save.dart`

#### (c) `lib/common/widgets/video_card/video_card_h.dart`

- `onLongPress` 签名由 `void onLongPress()` 改为 `void onLongPress(BuildContext context)`，内部调用 `showVideoPopupMenu(context, videoItem, onRemove: onRemove)`（约第 30 行）
- 两处调用点（`onLongPress` / `onSecondaryTap`）改为 `() => onLongPress(context)`（约第 45、48 行）
- **删除** import：`image_save.dart`

#### (d) `lib/pages/member_video/widgets/video_card_h_member_video.dart`

- `onLongPress` 改为 `showVideoPopupMenu(context, videoItem)`（约第 34 行）
- **删除** import：`image_save.dart`

> **关键约束**：`onRemove` 参数必须透传。它用于"不感兴趣 / 拉黑"成功后从列表中移除卡片。遗漏会导致点了菜单但卡片不消失的 bug。

---

### 3.2 更新源指向本 fork 仓库

**需求背景**：App 内置「检查更新」功能会请求 GitHub Releases API。上游代码写死了作者仓库地址，导致 fork 构建的 App 会检查到上游的版本。必须指向本 fork，才能实现「fork 自己的版本更新」。

**改动 1**：`lib/http/api.dart`（约第 414 行）

```dart
// 修改前
static const String latestApp =
    'https://api.github.com/repos/bggRGjQaUbCoE/PiliPlus/releases';
// 修改后
static const String latestApp =
    'https://api.github.com/repos/Godwin9527/PiliPlus/releases';
```

**改动 2**：`lib/common/constants.dart`（约第 3 行）

```dart
// 修改前
static const sourceCodeUrl = 'https://github.com/bggRGjQaUbCoE/PiliPlus';
// 修改后
static const sourceCodeUrl = 'https://github.com/Godwin9527/PiliPlus';
```

> ⚠️ **合并时极易冲突**。上游若修改这两个文件，冲突解决策略：**保留本 fork 的 URL（Godwin9527），同时接受上游对该文件其他部分的改动**。

**相关机制**（供理解，非改动点）：`lib/utils/update.dart` 的 `Update.checkUpdate()` 读取该 URL，用 `BuildConfig.buildTime` 与本仓库 Release 的 `created_at` 比对判断是否有新版本。

---

### 3.3 CI 构建配置

`.github/workflows/build.yml`：3 处 `github.repository` 判断的仓库名，由 `bggRGjQaUbCoE/PiliPlus` 改为 `Godwin9527/PiliPlus`（约第 52、148、162 行）。

> 说明：这些条件仅用于「PR 触发构建」场景。手动触发（`workflow_dispatch`）走的是 `github.event.inputs.build_xxx == 'true'` 分支，不受影响。合并时**保留本 fork 的仓库名**。

---

### 3.4 `.gitignore`

新增一行（文件末尾附近）：

```
/.keys/
```

> **原因**：本地 Android 签名密钥目录 `.keys/` 必须禁止提交。该目录含 `piliplus.jks` 与密码明文，**泄露将导致签名被伪造**。合并时**必须保留**此行。

---

## 4. 上游同步标准流程（AI 执行指引）

> **执行前提**：确认本文件第 2 节的「定制改动」清单已读完。

### 4.1 首次配置 upstream 远程

```bash
git remote add upstream https://github.com/bggRGjQaUbCoE/PiliPlus.git
git remote -v   # 确认 origin=本fork, upstream=上游
```

### 4.2 同步步骤

```bash
# 1) 拉取上游最新代码
git fetch upstream

# 2) 切到 main 并确保本地最新
git checkout main
git pull origin main

# 3) 合并上游（推荐 merge，保留定制提交历史）
git merge upstream/main

# 4) 若出现冲突 → 按第 5 节「冲突处理策略」逐项解决
#    解决后：
git add <已解决的文件>
git commit

# 5) 推送回本 fork
git push origin main
```

### 4.3 合并后的验证清单（**必做**）

合并完成后，AI **必须**逐项确认以下内容仍然正确，否则视为任务失败：

- [ ] `lib/common/widgets/video_popup_menu.dart` 中仍存在 `buildVideoMenuItems` 与 `showVideoPopupMenu` 两个顶层函数
- [ ] `VideoPopupMenu.itemBuilder` 仍然调用 `buildVideoMenuItems`（未改回内联）
- [ ] 3 个视频卡片的 `onLongPress` 仍调用 `showVideoPopupMenu`，且 `onRemove` 已透传
- [ ] `lib/http/api.dart` 的 `latestApp` 仍指向 `Godwin9527/PiliPlus`
- [ ] `lib/common/constants.dart` 的 `sourceCodeUrl` 仍指向 `Godwin9527/PiliPlus`
- [ ] `.github/workflows/build.yml` 中的仓库名仍为 `Godwin9527/PiliPlus`
- [ ] `.gitignore` 中仍保留 `/.keys/`
- [ ] 全仓搜索 `bggRGjQaUbCoE`，确认**代码与配置中**无残留（注释、issue 链接中的该字样属正常，无需修改）

---

## 5. 冲突处理策略

| 文件 | 冲突概率 | 处理原则 |
|---|---|---|
| `lib/http/api.dart` | 🔴 高 | 保留 fork 的 URL；接受上游其他改动 |
| `lib/common/constants.dart` | 🔴 高 | 同上 |
| `.github/workflows/build.yml` | 🟡 中 | 保留 fork 的仓库名；接受上游其他 CI 改动 |
| `lib/common/widgets/video_popup_menu.dart` | 🟡 中 | **保留函数抽取结构**；若上游新增/修改菜单项，将其并入 `buildVideoMenuItems` 函数体 |
| 3 个 `video_card*.dart` | 🟡 中 | 保留 `onLongPress` → `showVideoPopupMenu` 的调用；接受上游其他改动 |
| `.gitignore` | 🟢 低 | 保留 `/.keys/` |

### 冲突解决的**最高原则**

> 当不确定某段冲突属于"上游新改动"还是"本 fork 定制"时，**先查第 2、3 节**。若属于本 fork 定制 → **保留本 fork 版本**；若属于上游新功能 → **接受上游版本**；若两者都有 → **合并两者**（保留定制行为 + 引入上游新特性）。

---

## 6. 禁止事项（红线）

以下行为**严格禁止**，除非用户明确要求：

1. ❌ 不得将 `onLongPress` 改回 `imageSaveDialog`（恢复封面放大预览）
2. ❌ 不得将 `latestApp` / `sourceCodeUrl` 改回上游地址
3. ❌ 不得删除 `.gitignore` 中的 `/.keys/`
4. ❌ 不得将 `VideoPopupMenu` 的菜单构造逻辑改回内联（破坏与长按的共用结构）
5. ❌ 不得提交 `.keys/` 目录下的任何文件
6. ❌ 不得在未告知用户的情况下，把本 fork 的定制"清理"为上游原状

---

## 7. 构建与发布说明

### 7.1 触发构建

本仓库已配置 GitHub Actions（`Build` workflow）。手动触发（**必须提供非空 `tag`，否则不会创建 Release**）：

```bash
gh workflow run Build --repo Godwin9527/PiliPlus \
  -f build_android=true -f build_win_x64=true \
  -f build_ios=false -f build_mac=false -f build_linux_x64=false \
  -f tag=v2.1.8
```

> iOS / macOS 构建需要额外证书配置，当前保持关闭。

### 7.2 Android 签名

- 签名密钥由 GitHub Secrets 提供：`SIGN_KEYSTORE_BASE64`、`KEYSTORE_PASSWORD`、`KEY_ALIAS`、`KEY_PASSWORD`
- 签名密钥指纹（SHA-256）：
  `60:5E:4F:60:3B:26:CA:F7:AC:AC:AA:F5:AB:E1:F2:CC:51:1A:0C:68:56:E2:4A:45:37:6D:78:22:87:A6:FE:65`
- 本地密钥文件位于 `.keys/`（已被 gitignore），**切勿提交**

### 7.3 版本号机制

- `lib/scripts/build.ps1` 用 `git rev-list --count HEAD` 作为 versionCode
- 构建时写入 `pili_release.json`，其中 `pili.time` 作为 `BuildConfig.buildTime`
- **App 内更新检测**依赖 `buildTime` 与 Release `created_at` 的比较，故此机制不可破坏

---

## 8. 变更记录

| 日期 | 说明 |
|---|---|
| 2026-10-16 | 初版。记录长按菜单改造、更新源指向 fork、CI 仓库名适配、.keys 忽略规则 |

---

> **维护提示**：若后续新增任何定制改动，**必须同步更新本文件**的第 2、3、5、8 节。本文件是本 fork 的"定制事实来源"（single source of truth）。
