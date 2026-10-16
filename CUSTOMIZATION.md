# CUSTOMIZATION.md

> **本文件用途**：记录本仓库（fork）相对于上游原仓库所做的**全部定制改动**，供后续维护者与 AI 助手在「同步上游更新」时参照执行。
>
> **给 AI 助手的强制阅读须知**：在处理本仓库的任何合并 / 同步 / 冲突解决任务之前，**必须完整阅读本文件**。本文件中标记为「定制改动」的内容均为**有意为之**，**不得**被当作过时代码、冗余代码或错误代码而回退、删除或"优化"。违反此约束将导致用户功能丢失。
>
> **⚠️ 文档维护义务（对 AI 的硬性要求）**：本文件是「活文档」。任何修改本仓库代码的行为，**都必须同步更新本文件的对应章节**（第 2 节改动总览、第 3 节逐项详解、第 5 节冲突策略、第 8 节变更记录）。这是任务不可分割的一部分，**不是可选项**。若你修改了代码却未更新本文件，视为任务未完成。此义务同样适用于未来任何接手本仓库的 AI 助手 —— **无需用户提醒，自行执行**。详见第 9 节。

---

## 1. 仓库基本信息

| 项目 | 值 |
|---|---|
| 上游原仓库（upstream） | `https://github.com/bggRGjQaUbCoE/PiliPlus` |
| 本 fork 仓库（origin） | `https://github.com/Godwin9527/PiliPlus` |
| 默认分支 | `main` |
| 项目类型 | Flutter 应用（BiliBili 第三方客户端） |
| Flutter 版本 | `3.47.7`（见 `.fvmrc`） |
| 本文件最后更新 | 2026-10-17 |
| 最后更新的定制提交 | `d2078937b` |

---

## 2. 改动总览

本 fork 相对上游的全部改动如下，**共涉及 7 个文件、5 个定制提交**。

| # | 文件 | 改动类型 | 是否属于"定制"（禁止回退） |
|---|---|---|---|
| 1 | `lib/common/widgets/video_popup_menu.dart` | 重构 + 新增公共函数 | ✅ 是 |
| 2 | `lib/common/widgets/video_card/video_card_v.dart` | 行为修改 | ✅ 是 |
| 3 | `lib/common/widgets/video_card/video_card_h.dart` | 行为修改 | ✅ 是 |
| 4 | `lib/pages/member_video/widgets/video_card_h_member_video.dart` | 行为修改 | ✅ 是 |
| 5 | `lib/utils/update.dart` | 新增镜像回退逻辑 | ✅ 是 |
| 6 | `lib/scripts/build.ps1` | 构建脚本：注入仓库标识 + 版本号跟随 Release tag | ✅ 是 |
| 7 | `.gitignore` | 新增忽略规则 | ✅ 是 |

> **重要变更（2026-10-16 第二次优化）**：原先对 `lib/http/api.dart`、`lib/common/constants.dart`、`.github/workflows/build.yml` 的**硬编码修改已全部撤销**，改为「构建参数注入」。现在这三个文件**与上游保持一致**，同步上游时**不会再冲突**。详见第 3.2 节。

对应提交：

```
d2078937b  fix: 版本号跟随 Release tag，修复 App 内版本号不更新
069f5835d  feat: 检查更新支持镜像回退，解决国内 DNS 污染导致无法检测更新
430d6631b  refactor: URL 改为构建参数注入，消除上游同步冲突
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

### 3.2 仓库标识改为「构建参数注入」（2026-10-16 第二次优化）

**需求背景**：App 内置「检查更新」会请求 GitHub Releases API，且「关于」页会展示源码仓库地址。上游代码写死了作者仓库地址。

**第一次做法（已废弃）**：直接在 `lib/http/api.dart` 与 `lib/common/constants.dart` 里把 URL 硬编码改为本 fork 地址。
**问题**：这两个文件上游也会改动，导致每次同步上游都冲突。

**当前做法（现行）**：改为通过构建参数 `pili.repo` 注入，**源码默认值 = 上游原样**。

#### (a) `lib/common/constants.dart`

```dart
abstract final class Constants {
  static const appName = 'PiliPlus';

  /// 本 App 的源代码仓库地址。
  /// 通过构建参数 `pili.repo` 注入（见 lib/scripts/build.ps1）。
  /// 未注入时回退为上游原仓库，因此本文件无需为 fork 做任何硬编码修改。
  static const String _repo = String.fromEnvironment(
    'pili.repo',
    defaultValue: 'bggRGjQaUbCoE/PiliPlus',
  );
  static const sourceCodeUrl = 'https://github.com/$_repo';
```

#### (b) `lib/http/api.dart`（约第 413 行）

```dart
static const String latestApp =
    "https://api.github.com/repos/"
    "${const String.fromEnvironment('pili.repo', defaultValue: 'bggRGjQaUbCoE/PiliPlus')}"
    "/releases";
```

> ⚠️ **注意引号**：这里**必须**用双引号 `"`，否则 Dart 不会做 `$` 插值，会得到字面量字符串。这是一个容易踩的坑。

#### (c) `lib/scripts/build.ps1`

在生成 `pili_release.json` 时，从 CI 环境变量 `GITHUB_REPOSITORY` 读取仓库标识并注入：

```powershell
$repo = $env:GITHUB_REPOSITORY

$data = @{
    'pili.name' = $versionName
    'pili.code' = $versionCode
    'pili.hash' = $commitHash
    'pili.time' = $buildTime
}
if (-not [string]::IsNullOrWhiteSpace($repo)) {
    $data['pili.repo'] = $repo
}
```

> ⚠️ **关键细节（勿改）**：必须**在为空时省略该键**，而不能写入空字符串。因为 `String.fromEnvironment` 只在「**未定义**」时才使用 `defaultValue`；若传入空串，会得到空串，URL 会变成 `https://github.com/`（错误）。本地构建（无 `GITHUB_REPOSITORY`）时靠此逻辑回退到上游默认值。

#### 为什么这样做

| 好处 | 说明 |
|---|---|
| **源码零硬编码** | `api.dart` / `constants.dart` 与上游**逐字节一致**（仅多出解释性注释），同步上游时直接接受上游版本即可 |
| **fork 身份集中** | 仓库标识只在 `build.ps1` 一处出现 |
| **自动适配** | `GITHUB_REPOSITORY` 由 CI 自动提供 —— 构建发生在哪个仓库，App 就指向哪个仓库。上游自己构建时自动指向上游，本 fork 构建时自动指向本 fork，**无需任何手工配置** |
| **5 个平台全覆盖** | Android / iOS / macOS / Windows / Linux 的 workflow 全部调用 `build.ps1` 并消费 `pili_release.json`，故全部受益 |

#### 受影响的下游引用点（**均无需改动**，仅记录以便排查）

以下位置读取 `Constants.sourceCodeUrl` 或 `Api.latestApp`，注入后自动生效：

- `lib/utils/update.dart:25`（检查更新的 API 地址）
- `lib/utils/update.dart:69`、`:146`（更新弹窗的跳转链接）
- `lib/pages/about/view.dart:163`、`:176`、`:179`、`:190`（关于页展示源码地址）
- `lib/pages/setting/pages/logs.dart:148`（日志页的 issue 链接）

**验证方法**（已实测通过）：

```bash
# 默认 → 上游地址
dart run --define=... 不传 → https://api.github.com/repos/bggRGjQaUbCoE/PiliPlus/releases
# 注入 → fork 地址
dart run --define=pili.repo=Godwin9527/PiliPlus → https://api.github.com/repos/Godwin9527/PiliPlus/releases
```

---

### 3.3 检查更新支持「镜像回退」（2026-10-17 第三次优化）

**需求背景**：中国大陆网络环境下，`api.github.com` 的 DNS 常被污染（实测解析到 `47.128.243.133` 等无关 IP，而权威解析应为 `20.205.243.168`），导致 App 内「检查更新」长期失败（表现为「上传 251B / 下载 0B」）。

**改动文件**：`lib/utils/update.dart`（**仅此一个文件**）

#### (a) 新增镜像前缀常量

```dart
/// 可通过构建参数 `pili.mirror` 覆盖；置为空字符串则禁用镜像回退。
static const String _mirror = String.fromEnvironment(
  'pili.mirror',
  defaultValue: 'https://gh-proxy.com/',
);
```

#### (b) 候选地址链（直连优先，镜像兜底）

```dart
static List<(String, String)> get _sources => [
  ('', Api.latestApp),
  if (_mirror.isNotEmpty) (_mirror, '$_mirror${Api.latestApp}'),
];
```

镜像 URL 的构造方式是**直接把原始 URL 拼在前缀之后**：
`https://gh-proxy.com/` + `https://api.github.com/repos/OWNER/REPO/releases`

#### (c) `_fetchLatestRelease()` 依次尝试

新抽出的私有方法逐个尝试候选地址，**校验响应必须是「非空 List 且首元素为 Map」**才算成功，并把成功的前缀记入 `_downloadPrefix` 供下载复用。任一地址抛异常或返回异常结构则继续下一个。

> ⚠️ **原实现的 bug（已修）**：旧代码判断条件是 `if (res.data is Map || res.data.isEmpty)`，对**字符串/HTML 响应**不做校验，且失败后直接 `return`，不重试。新实现改为正向校验「是 List 且非空」，更健壮。

#### (d) 下载步骤复用前缀

`onDownload` 新增 `forceMirror` 参数：
- 默认使用 `_downloadPrefix`（即检查更新时探测成功的那个前缀）
- `forceMirror: true` 时强制走镜像

弹窗中为 Android 等平台新增了一个 **「镜像」** 按钮，作为直连下载失败时的手动兜底：

```dart
] else ...[
  downloadBtn('Github'),
  if (_mirror.isNotEmpty) downloadBtn('镜像', mirror: true),
],
```

#### 为什么默认启用镜像

镜像**仅作为兜底**：直连成功时完全不会用到它。因此对非大陆网络环境无副作用，无需开关。

#### 实测验证

- `https://gh-proxy.com/https://api.github.com/repos/Godwin9527/PiliPlus/releases` → HTTP 200，返回正确 JSON 数组
- 镜像对 release 资源下载同样有效（HTTP 206 分段请求正常）
- 已用 Dart 单独验证：候选链构造正确、直连抛异常时能正确回退到镜像、`Map?` 类型提升在闭包内成立

#### 其他镜像的实测结果（供将来替换参考）

| 镜像 | 对 API 端点 | 结论 |
|---|---|---|
| `https://gh-proxy.com/` | ✅ 200 稳定 | **当前采用** |
| `ghfast.top` / `ghproxy.net` / `gh.llkk.cc` | ❌ 403 | 不支持 API 代理 |
| `api.kkgithub.com` / `hub.gitmirror.com` | ❌ 连接失败 | 不可用 |

---

### 3.4 版本号跟随 Release tag（2026-10-17 第四次优化）

**问题背景**：发版时 `-f tag=v2.1.9` 只用于**命名 GitHub Release**，从不参与构建。App 内版本号来自 `pubspec.yaml` 的 `version: 2.1.6+1`（从未改动），因此出现「Release 是 v2.1.9，但 App 里显示 2.1.6」的不一致。

**改动位置**：`lib/scripts/build.ps1`（约第 12–32 行）

新增：从 GitHub 事件载荷中取出 `workflow_dispatch` 的 `tag` 输入，作为版本名。

```powershell
$releaseTag = $null
if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_EVENT_PATH) -and (Test-Path -Path $env:GITHUB_EVENT_PATH)) {
    try {
        $releaseTag = (Get-Content -Path $env:GITHUB_EVENT_PATH -Raw -Encoding UTF8 | ConvertFrom-Json).inputs.tag
    }
    catch {
        $releaseTag = $null
    }
}
```

并在读取 `pubspec.yaml` 版本的那一行后追加：

```powershell
# tag 优先（v2.1.10 -> 2.1.10）；tag 缺失或格式不符时回退 pubspec.yaml 原值。
if (-not [string]::IsNullOrWhiteSpace($releaseTag) -and $releaseTag -match '^[vV]?(\d+\.\d+\.\d+)') {
    $versionName = $matches[1]
}
```

**关键设计**：
- 通过 `GITHUB_EVENT_PATH`（GitHub Actions 自动提供的环境变量）读取事件 JSON，**无需修改任何 workflow 文件**，5 个平台共用同一份 `build.ps1` 自动生效
- `tag` 缺失（本地构建）或格式非法（如 `latest`）时**自动回退** `pubspec.yaml` 原值，不影响原有行为
- Android 仍保留 `-<commit hash 前9位>` 后缀；其他平台不带后缀（与上游原行为一致）

**实测结果**（pwsh 7，与 CI 一致）：

| 场景 | 参数 | 得到的 `pili.name` |
|---|---|---|
| `tag=v2.1.10` | android | `2.1.10-a38a5d427` |
| `tag=v2.1.10` | 无（Windows/macOS/Linux） | `2.1.10` |
| 无 tag | android | `2.1.6-a38a5d427`（回退） |
| `tag=latest`（非法） | android | `2.1.6-a38a5d427`（回退） |

> ⚠️ 合并上游时：**保留**这段 tag 推导逻辑。若上游重写了 `build.ps1` 的版本读取部分，需把该逻辑重新套用到新写法上。

---

### 3.5 `.gitignore`

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
- [ ] `lib/common/constants.dart` 的 `sourceCodeUrl` 仍通过 `String.fromEnvironment('pili.repo', ...)` 派生
- [ ] `lib/http/api.dart` 的 `latestApp` 仍通过 `String.fromEnvironment('pili.repo', ...)` 派生，且**使用的是双引号**
- [ ] `lib/scripts/build.ps1` 仍包含 `$env:GITHUB_REPOSITORY` 注入逻辑，且**为空时省略 `pili.repo` 键**
- [ ] `lib/scripts/build.ps1` 仍包含从 `$env:GITHUB_EVENT_PATH` 读取 `inputs.tag` 的版本推导逻辑，且保留了 `-match '^[vV]?(\d+\.\d+\.\d+)'` 的格式校验与回退分支
- [ ] `lib/utils/update.dart` 中仍存在 `_mirror` 常量与 `_fetchLatestRelease()`，且 `_sources` 保持「直连在前、镜像在后」的顺序
- [ ] `lib/utils/update.dart` 的 `onDownload` 仍支持 `forceMirror` 参数，下载 URL 仍带 `$prefix` 前缀
- [ ] `.gitignore` 中仍保留 `/.keys/`
- [ ] `.github/workflows/build.yml` 与上游一致（此文件已**不再**做 fork 定制；若上游有改动，直接接受）
- [ ] 全仓搜索 `bggRGjQaUbCoE`，确认**代码与配置中**无残留（注释、issue 链接中的该字样属正常，无需修改）

---

## 5. 冲突处理策略

> **好消息**：经 2026-10-16 第二次优化后，本 fork 的**冲突面已大幅缩小**。原先最易冲突的 URL 相关文件已与上游一致。

| 文件 | 冲突概率 | 处理原则 |
|---|---|---|
| `lib/http/api.dart` | 🟢 **低**（已消除） | 与上游一致，**直接接受上游版本**。仅在需保留 `pili.repo` 注释时作最小保留 |
| `lib/common/constants.dart` | 🟢 **低**（已消除） | 同上 |
| `lib/scripts/build.ps1` | 🟡 中 | 上游若改此文件，**保留 fork 的 `pili.repo` 注入逻辑与 tag 版本推导逻辑**，同时接受上游其他改动 |
| `lib/utils/update.dart` | 🟡 中 | **保留镜像回退结构**（`_mirror` / `_sources` / `_fetchLatestRelease` / `forceMirror`）；若上游改写了检查逻辑，需把镜像回退重新套用到新逻辑上，并保留 `forceMirror` 下载入口 |
| `lib/common/widgets/video_popup_menu.dart` | 🟡 中 | **保留函数抽取结构**；若上游新增/修改菜单项，将其并入 `buildVideoMenuItems` 函数体 |
| 3 个 `video_card*.dart` | 🟡 中 | 保留 `onLongPress` → `showVideoPopupMenu` 的调用；接受上游其他改动 |
| `.github/workflows/build.yml` | 🟢 **低**（已消除） | 与上游一致，**直接接受上游版本** |
| `.gitignore` | 🟢 低 | 保留 `/.keys/` |

### 冲突解决的**最高原则**

> 当不确定某段冲突属于"上游新改动"还是"本 fork 定制"时，**先查第 2、3 节**。若属于本 fork 定制 → **保留本 fork 版本**；若属于上游新功能 → **接受上游版本**；若两者都有 → **合并两者**（保留定制行为 + 引入上游新特性）。

---

## 6. 禁止事项（红线）

以下行为**严格禁止**，除非用户明确要求：

1. ❌ 不得将 `onLongPress` 改回 `imageSaveDialog`（恢复封面放大预览）
2. ❌ 不得移除 `pili.repo` 注入机制，或把 URL 改回硬编码
3. ❌ 不得删除 `.gitignore` 中的 `/.keys/`
4. ❌ 不得将 `VideoPopupMenu` 的菜单构造逻辑改回内联（破坏与长按的共用结构）
5. ❌ 不得提交 `.keys/` 目录下的任何文件
6. ❌ 不得在未告知用户的情况下，把本 fork 的定制"清理"为上游原状
7. ❌ 不得在 `lib/scripts/build.ps1` 中把 `pili.repo` 写成空字符串（会导致 URL 错误）
8. ❌ 不得移除 `lib/utils/update.dart` 的镜像回退机制（`_mirror` / `_sources` / `_fetchLatestRelease`），否则大陆网络环境下检查更新会再次失效
9. ❌ 不得移除 `lib/scripts/build.ps1` 的 tag 版本推导逻辑（否则 App 内版本号会退回固定值，与 Release tag 不一致）

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

- **版本名（`pili.name`）**：优先取 `workflow_dispatch` 的 `tag` 输入（去掉前导 `v`），无 tag 或格式非法时回退 `pubspec.yaml` 的 `version`
  - Android 会再追加 `-<commit hash 前9位>`，例如 `2.1.10-a38a5d427`
  - 其他平台为纯版本号，例如 `2.1.10`
- **版本码（`pili.code`）**：`git rev-list --count HEAD`（提交总数）
- 构建时写入 `pili_release.json`，其中 `pili.time` 作为 `BuildConfig.buildTime`
- **App 内更新检测**依赖 `buildTime` 与 Release `created_at` 的比较（**与版本号无关**），故此机制不可破坏
- 发版时**必须**传入新 `tag`，否则：① 不创建 Release；② App 内版本号停在旧值

---

## 8. 变更记录

| 日期 | 说明 |
|---|---|
| 2026-10-16 | 初版。记录长按菜单改造、更新源指向 fork、CI 仓库名适配、.keys 忽略规则 |
| 2026-10-16 | **第二次优化**：URL 改为构建参数（`pili.repo`）注入，撤销 `api.dart` / `constants.dart` / `build.yml` 的硬编码改动，上述文件恢复与上游一致；新增第 9 节「文档维护契约」 |
| 2026-10-17 | **第三次优化**：`lib/utils/update.dart` 新增镜像回退（直连失败自动走 `gh-proxy.com`），修复大陆 DNS 污染导致检查更新失效的问题；新增第 3.3 节 |
| 2026-10-17 | **第四次优化**：`lib/scripts/build.ps1` 新增 tag 版本推导，修复「Release tag 与 App 内版本号不一致」；新增第 3.4 节，原 3.4 `.gitignore` 顺延为 3.5 |

---

## 9. 文档维护契约（对 AI 的强制要求）

> **本节是本文件的核心约束，任何接手本仓库的 AI 都必须遵守，且无需用户提醒。**

### 9.1 你必须做的事

1. **修改代码前**：先阅读本文件，确认你要改的内容是否已在第 2、3 节登记。
2. **修改代码时**：若你的改动**新增/修改/删除**了任何"定制"内容，**必须同步更新**：
   - 第 1 节「最后更新的定制提交」（改为新提交哈希）
   - 第 2 节「改动总览」表
   - 第 3 节「逐项改动详解」（新增或修订对应小节）
   - 第 5 节「冲突处理策略」（若涉及新文件）
   - 第 8 节「变更记录」（追加一行）
3. **同步上游后**：按第 4.3 节清单逐项验证，并把验证结果与遇到的新冲突模式补充进第 5 节。
4. **发现本文件与实际代码不符时**：以**代码为准**修正本文件，并在第 8 节记录。

### 9.2 判定标准

> **一次任务是否完成，标准是「代码 + 本文件都已更新」。**
> 只改代码不改文档，视为**任务未完成**。

### 9.3 为什么这样要求

本文件存在的唯一意义，是让**下一个 AI 或维护者**不必重新逆向整个仓库就能理解"哪些改动是刻意的"。
如果它不同步更新，就会逐渐失真 —— 而**失真的说明文档比没有文档更危险**，因为它会误导 AI 回退掉正确的定制。

### 9.4 自检问题（每次任务结束前问自己）

- [ ] 我这次改的代码，有没有任何一项属于"相对上游的定制"？如果有，第 2、3 节更新了吗？
- [ ] 第 8 节变更记录追加了吗？
- [ ] 本文件里的行号、文件名、代码片段还准确吗？

---

> **维护提示**：本文件是本 fork 的"定制事实来源"（single source of truth）。
