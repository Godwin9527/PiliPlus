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
| Flutter 版本 | `3.47.9`（见 `.fvmrc`，2026-11-20 随上游升级，原 3.47.7） |
| 已同步到的上游版本 | `2.2.1`（上游提交 `217fb54f5`，2026-11-20 合并） |
| 本 fork 当前版本 | `2.2.5`（`pubspec.yaml`；实际发版版本由 Release tag 决定） |
| 本文件最后更新 | 2026-11-22 |
| 最后更新的定制提交 | `d2078937b`（2026-11-22 文档更新随 v2.2.5 提交，见第 8 节） |

---

## 2. 改动总览

本 fork 相对上游的全部改动如下，**共涉及 27 个文件**（2026-11-20 新增「视频卡片菜单定制」一批，见 #9–#15；2026-11-22 新增 #16–#19 与 #20–#27）。

| # | 文件 | 改动类型 | 是否属于"定制"（禁止回退） |
|---|---|---|---|
| 1 | `lib/common/widgets/video_popup_menu.dart` | 重构 + 新增公共函数 + 菜单项可配置 + 弹窗右对齐 | ✅ 是 |
| 2 | `lib/common/widgets/video_card/video_card_v.dart` | 行为修改 | ✅ 是 |
| 3 | `lib/common/widgets/video_card/video_card_h.dart` | 行为修改 | ✅ 是 |
| 4 | `lib/pages/member_video/widgets/video_card_h_member_video.dart` | 行为修改 | ✅ 是 |
| 5 | `lib/utils/update.dart` | 镜像回退 + **Android 应用内下载/安装** | ✅ 是 |
| 6 | `lib/scripts/build.ps1` | 构建脚本：注入仓库标识 + 版本号跟随 Release tag | ✅ 是 |
| 7 | `.gitignore` | 新增忽略规则 | ✅ 是 |
| 8 | `.github/workflows/build.yml` | 3 处 `pull_request` 判断的仓库名改为本 fork | ✅ 是 |
| 9 | `lib/models/common/video_menu_item.dart`（新增） | 菜单项枚举 `VideoMenuItem` | ✅ 是 |
| 10 | `lib/pages/setting/models/video_card_settings.dart`（新增） | 「视频卡片」设置分类内容 | ✅ 是 |
| 11 | `lib/pages/setting/pages/video_menu_sort.dart`（新增） | 菜单项开关 + 拖拽排序页 | ✅ 是 |
| 12 | `lib/models/common/setting_type.dart` | 新增 `videoCardSetting` 分类 | ✅ 是 |
| 13 | `lib/pages/setting/view.dart` + `lib/pages/settings_search/view.dart` | 设置入口与搜索索引接入新分类 | ✅ 是 |
| 14 | `lib/utils/storage_pref.dart` + `lib/utils/storage_key.dart` | 新增 4 个配置键与读取方法 | ✅ 是 |
| 15 | `lib/pages/rcmd/controller.dart` | 推荐流会话内去重 + 刷新保底 20 条 | ✅ 是 |
| 16 | `lib/pages/rcmd/view.dart` | 横屏后回竖屏还原列表滚动位置 | ✅ 是 |
| 17 | `lib/plugin/pl_player/models/landscape_direction.dart`（新增） | 横屏倒向枚举 `LandscapeDirection` | ✅ 是 |
| 18 | `lib/plugin/pl_player/controller.dart` | `changeOrientation` 支持手动全屏时固定倒向 | ✅ 是 |
| 19 | `lib/pages/setting/models/play_settings.dart` | 新增「全屏横屏倒向」设置项 | ✅ 是 |
| 20 | `lib/utils/apk_downloader.dart`（新增） | 应用内 APK 下载：镜像优先、断点续传、重试 | ✅ 是 |
| 21 | `lib/utils/apk_installer.dart`（新增） | `MethodChannel` 封装（权限检查 / 跳设置 / 调起安装器） | ✅ 是 |
| 22 | `lib/common/widgets/update_download_dialog.dart`（新增） | 下载进度弹窗 + 安装权限引导 | ✅ 是 |
| 23 | `android/app/src/main/kotlin/com/example/piliplus/MainActivity.kt` | 注册 `piliplus/apk_installer` 通道 | ✅ 是 |
| 24 | `android/app/src/main/AndroidManifest.xml` | `REQUEST_INSTALL_PACKAGES` + `FileProvider` | ✅ 是 |
| 25 | `android/app/src/main/res/xml/file_paths.xml`（新增） | FileProvider 路径映射（`cache/update`） | ✅ 是 |
| 26 | `android/app/build.gradle.kts` | 显式依赖 `androidx.core:core-ktx` | ✅ 是 |

> **重要变更（2026-10-16 第二次优化）**：原先对 `lib/http/api.dart`、`lib/common/constants.dart` 的**硬编码修改已撤销**，改为「构建参数注入」，这两个文件现已与上游一致（仅多出解释性注释），同步上游时**不会再冲突**。详见第 3.2 节。
>
> **⚠️ 订正（2026-11-20）**：上一版本文档曾声称 `.github/workflows/build.yml` 的硬编码也「已全部撤销」，**与事实不符**。提交 `430d6631b` 的说明里写了「撤销 api.dart / constants.dart / build.yml 的硬编码」，但其 diffstat 中**并不包含** `build.yml`，该文件至今仍保留 3 处 `Godwin9527/PiliPlus`。本次已按「以代码为准」原则订正文档（见第 2 节表 #8、第 3.6 节、第 4.3 清单、第 5 节、第 6 节第 10 条）。
>
> **结论**：`build.yml` **仍属本 fork 定制**，同步上游时**不能直接接受上游版本**，必须保留那 3 处仓库名。

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

### 3.6 `.github/workflows/build.yml`（2026-11-20 补记，此前文档漏记）

**改动内容**：3 处 job 的 `pull_request` 触发条件中的仓库名，由上游的 `bggRGjQaUbCoE/PiliPlus` 改为本 fork 的 `Godwin9527/PiliPlus`。

涉及位置（行号为 2026-11-20 抓取时的状态，上游改动后可能偏移，以 `grep -n 'github.repository'` 为准）：

| job | 位置 | 当前值 |
|---|---|---|
| `android` | 约第 52 行 | `github.repository == 'Godwin9527/PiliPlus'` |
| `ios` | 约第 148 行 | 同上 |
| `win_x64` | 约第 162 行 | 同上 |

```
if: ${{ (github.event_name == 'pull_request' && github.repository == 'Godwin9527/PiliPlus') || github.event.inputs.build_android == 'true' }}
```

**作用范围**：**仅影响「仓库收到 PR 时是否自动构建」这一条触发路径**。`workflow_dispatch` 手动发版（`gh workflow run Build ...`）走的是 `||` 后半段，与此改动无关，改不改都能正常构建。

**为什么要改**：不改的话，本 fork 上开 PR 时因仓库名不匹配，不会触发 CI 构建；改后本 fork 的 PR 也能跑构建。

**为什么这次要专门补记**：此前文档三处（第 2 节、第 4.3 节、第 5 节）都写「该文件已恢复与上游一致」。若照此执行同步上游，会直接把这三行覆盖回上游值，导致上述触发条件失效，并让 `git merge` 时出现无法解释的"文档说有定制、实际被冲掉"的状态。

**合并上游时**：保留这 3 处仓库名，其余上游改动（新增 job、依赖版本、action 版本等）**一律接受上游**。

---

### 3.7 三点菜单项可配置（2026-11-20 新增）

**需求背景**：上游的三点菜单固定 7 项、顺序写死，用户希望能自选显示哪些、并调整顺序。

**新增文件**

| 文件 | 作用 |
|---|---|
| `lib/models/common/video_menu_item.dart` | 枚举 `VideoMenuItem`（7 项，**新增项必须追加到末尾**，因为存储的是 `index`） |
| `lib/pages/setting/models/video_card_settings.dart` | 「视频卡片」设置分类的三项内容 |
| `lib/pages/setting/pages/video_menu_sort.dart` | 开关 + 拖拽排序页，改完即时落盘 |

**存储键**（`lib/utils/storage_key.dart` / `lib/utils/storage_pref.dart`）

| 键 | 类型 | 含义 |
|---|---|---|
| `videoMenuOrder` | `List<int>` | 显示顺序（`VideoMenuItem.index`）；为空 = 默认顺序 |
| `videoMenuOff` | `List<int>` | 被隐藏的项 |
| `videoMenuAlignRight` | `bool` | 长按菜单是否贴屏幕右侧，默认 `true` |
| `longPressShowCover` | `bool` | 长按弹封面预览（上游行为），默认 `false` |

**渲染改造**（`video_popup_menu.dart`）

- `_VideoCustomAction` 增加 `id` 字段，7 个菜单项各自标注 `VideoMenuItem`；
- 原返回语句改为 `return _applyMenuConfig(items, menuItemHeight);`；
- `_applyMenuConfig()` 规则：
  1. `videoMenuOrder` 非空 → 按保存顺序输出；
  2. 未登记进配置的项（上游未来新增）**追加到末尾**，保证升级不丢功能；
  3. `videoMenuOff` 中的项跳过；
  4. 全部被隐藏时**保底保留「不感兴趣」**，避免弹出空菜单。

> ⚠️ 合并上游时若上游新增了菜单项：保留 `_applyMenuConfig` 结构，把新项以 `_VideoCustomAction(.新枚举值, ...)` 形式加进列表，并在 `VideoMenuItem` **末尾**追加枚举值。

---

### 3.8 长按行为可切换 + 菜单贴右（2026-11-20 新增）

**需求背景**：① 长按菜单原本靠左弹出，用户右手单手握持大屏手机时够不着；② 想保留「上游原版的封面预览」作为备选。

**位置计算**（`showVideoPopupMenu`）

```dart
if (Pref.videoMenuAlignRight) {
  // 锚点取「屏幕右边 8dp」，而非卡片边缘：
  // 无论卡片多宽，菜单都稳定出现在右手拇指够得到的位置
  return PageUtils.menuPosition(
    Offset(MediaQuery.sizeOf(context).width - 8, bottom),
  );
}
return PageUtils.menuPosition(
  renderBox.localToGlobal(renderBox.size.bottomLeft(.zero)),
);
```

> ⚠️ 不要改回只用 `bottomLeft`——那就是"靠左"的老行为。

**长按入口统一收敛到 `onLongPressVideoCard()`**（`video_popup_menu.dart`）

```dart
void onLongPressVideoCard(BuildContext context, BaseSimpleVideoItemModel videoItem, {VoidCallback? onRemove}) {
  if (Pref.longPressShowCover) {
    imageSaveDialog(title: videoItem.title, cover: videoItem.cover, bvid: videoItem.bvid);
  } else {
    showVideoPopupMenu(context, videoItem, onRemove: onRemove);
  }
}
```

3 个卡片（`video_card_v` / `video_card_h` / `video_card_h_member_video`）的 `onLongPress` **统一调用此函数**，不再直接调 `showVideoPopupMenu`，也**不再各自 import `image_save.dart`**。

---

### 3.9 推荐流去重 + 刷新保底 20 条（2026-11-20 新增）

**需求背景**：首页推荐频繁重复推送同一视频；且刷新时接口常只回 3–4 条，导致「刷一下就到底」。

**改动文件**：`lib/pages/rcmd/controller.dart`（**仅此一个**）

| 机制 | 实现 |
|---|---|
| 去重集合 | `Set<String> _shown`，本轮运行内出现过的 bvid，上限 3000，超出按插入顺序淘汰 |
| 去重时机 | 首次加载 / 上拉加载走 `handleListResponse()` 的 `_dedupe()`；下拉刷新走 `_collect()` |
| 刷新保底 | `onRefresh()` **自行驱动请求循环**（不经过 `queryData`），直到新增 ≥ **20** 条或已请求 **6** 次 |
| 翻页策略 | `idx=0`（接口按下拉刷新处理）拿第一批，随后 `idx=1,2…` 翻页；翻页连续 2 次无新增则回到 `idx=0` 再要一批新的 |
| 提前终止 | `idx=0` 的全新一批连续 2 次都没有新条目 → 判定推荐池见底，按实际数量显示 |
| 列表合成 | `_publish()`：新内容在前、旧内容（开启「保留首页推荐刷新」时）接在后面，**整表一次性写入** |
| 逐步上屏 | 每拿到一批就 `_publish()` 一次，缩短「只有转圈没有内容」的空等 |
| 提示位置 | `lastRefreshAt` 在刷新开始时置 null、结束时设为**累计新增数**；不再在首批 4 条处就插提示 |
| 防白屏 | 若刷新一条新内容都没拿到，保留现有列表，不清空 |

**副作用（刻意接受）**：一次刷新可能连发 2–6 个请求，耗时增加；推荐池窄时会更快耗尽，此时按实际数量显示，**不提示用户**。

> 🐞 **2026-11-20 修复记录（v2.2.3）**：首版把补拉结果交给 `queryData(false)` 追加，而 `queryData` 一律 `response.addAll(dataList)` —— 新内容被追加到**旧内容之后**（列表最末尾）。表现为「刷新只看到 4 条，转圈 3–4 秒后消失，却没多出新视频」。现改为 `onRefresh` 内部收集 + `_publish` 合成整表，新内容恒在最前。**改这段代码时必须保持「新内容在前」的合成顺序，不要退回 `queryData(false)` 追加方式。**

> ⚠️ 合并上游时：保留 `_shown` / `_collect` / `_dedupe` / `_publish` / `onRefresh` 的补拉循环。若上游重写了 `handleListResponse` 或 `onRefresh`，需把上述逻辑重新套用到新写法上。

---

### 3.10 横屏后回竖屏还原列表滚动位置（2026-11-22 新增）

**需求背景**：推荐列表下滑较深后点进视频、横屏全屏播放，退出返回列表时，位置往往**上移到更靠前的位置**（例如第 8 个跳回第 2 个），且偶发、不稳定。

**根因**：`rcmd/view.dart` 的 `SliverGrid` 用 `maxCrossAxisExtent: Pref.recommendCardWidth`，**列数随可用宽度走**。横屏时列数变多 → 列表总高度骤降到原来的 1/2～1/3 → Flutter 的 `ScrollPosition` 在内容变短时把 `pixels` **夹回** `maxScrollExtent`，且**不会自动恢复**。还能同时触发 `main/view.dart` 的 `useBottomNav` 横竖屏切换，再改变一次可用高度。

**为什么"偶发"**：只有滚动深度超过横屏后的内容高度才会被夹；滚得浅完全正常。

**改动文件**：`lib/pages/rcmd/view.dart`（**仅此一个**，只动 UI 层，不碰数据）

| 机制 | 实现 |
|---|---|
| 位置记录 | `ScrollController` 监听里记录 `_portraitOffset`，**只在竖屏且不在横屏会话中**才写 |
| 横屏判定 | `didChangeMetrics()` 读 `platformDispatcher.views.first.physicalSize`；`build()` 里再用 `MediaQuery.sizeOf` 核对一次（双保险） |
| 冻结 | 进入横屏 → `_landscapeSeen = true`，此后所有位置变化（clamp 结果）一律不记录 |
| 还原时机 | 回到竖屏 → `_pendingRestore` 置为目标值 → `addPostFrameCallback` 中 `jumpTo` |
| 等待布局 | 若 `maxScrollExtent + 1 < target` 说明布局还没回到竖屏尺寸，逐帧重试（上限 20 帧） |
| 视频页遮挡 | 列表被视频页挡住、不参与布局时还原会失败；`build()` 里发现 `_pendingRestore` 非空就再补一次，返回本页时完成 |
| 失败放弃 | 重试超限（列表确实变短）→ 清空 `_pendingRestore`，交还给用户 |
| 防误拉 | 还原期间用 `_restoring` 屏蔽监听回调；`_pendingRestore` 非空时不覆盖记录值，避免布局回弹的小值把目标污染 |

**已知边界**：若列表本身变短（刷新后条数变少），目标位置可能不再可达，此时放弃还原（不会跳到列表最顶）。

> ⚠️ 合并上游时：保留 `_portraitOffset` / `_landscapeSeen` / `_pendingRestore` / `_restoreOffset` 一整套。若上游把 `RcmdPage` 从 `StatefulWidget` 改成别的写法，需把 `WidgetsBindingObserver` 与监听重新接上。

---

### 3.11 全屏横屏倒向可选（2026-11-22 新增）

**需求背景**：右手单手握持时，点全屏后系统把画面转到「手机顶部朝左」的一侧，手腕需要向内拧，握持不顺手；希望能自己选倒向。

**根因**：`pl_player/controller.dart` 的 `changeOrientation` 在 `orientation == null`（手动点全屏、无传感器方向传入）时，Android 一律走 `landscapeLeftMode()`，方向写死，且**设置里没有任何可选项**（「默认全屏方向」只管横/竖/跟随重力）。

**改动文件**：`landscape_direction.dart`（新增）、`pl_player/controller.dart`、`play_settings.dart`、`storage_key.dart`、`storage_pref.dart`

| 环节 | 实现 |
|---|---|
| 枚举 | `LandscapeDirection { auto, topLeft, topRight }`，标签为「跟随重力感应（默认）」「手机顶部朝左」「手机顶部朝右」 |
| 存储键 | `SettingBoxKey.landscapeDirection`；读取 `Pref.landscapeDirection`，越界/缺失一律回落 `.auto` |
| 设置项 | 「音视频设置 → 全屏横屏倒向」，`PopupModel`，仅移动端显示 |
| 生效条件 | 仅 `orientation == null`（手动点全屏）时生效；`auto` 走上游原逻辑；`mode == none/gravity` 已在前面 return，不受影响 |
| 平台映射 | Android：topLeft→`landscapeLeftMode`、topRight→`landscapeRightMode`；iOS 相反（与 `fullscreen_sc.dart` 的处理一致，抵消 flutter/flutter#73651） |

**给用户的说明**：若选中的方向与预期相反，改选另一个即可——两项互为反向，无需改代码。

> ⚠️ 合并上游时：保留 `changeOrientation` 中 `orientation == null` 那一段分支；若上游重写该方法，需把「手动全屏按设置固定倒向」的分支重新插入 `else` 分支的开头。

---

### 3.12 Android 应用内下载并安装更新（2026-11-22 新增）

**需求背景**：上游的更新流程是「弹窗 → 选 GitHub / 镜像 → `launchURL` 跳系统浏览器 → 浏览器下载」。下载进度、保存位置、安装全部在浏览器里，跳转断开后 App 无法感知成功与否。希望改为 App 内完成下载，下载完直接调起安装器。

**改动文件**：`update.dart`、`apk_downloader.dart`（新增）、`apk_installer.dart`（新增）、`update_download_dialog.dart`（新增）、`MainActivity.kt`、`AndroidManifest.xml`、`res/xml/file_paths.xml`（新增）、`build.gradle.kts`

| 环节 | 实现 |
|---|---|
| 入口 | `checkUpdate` 在 `Platform.isAndroid` 时只给一个 `FilledButton('立即更新')`；桌面端保持原有 zip/exe/rpm/deb 按钮不变 |
| 下载顺序 | **镜像优先、直连兜底**（`_downloadUrls`），与探测 release 信息的 `_sources`（直连优先）相反——安装包体积大，国内走镜像更快 |
| 下载器 | `ApkDownloader.download`：`dio` 流式写文件、`Range` 断点续传、单源重试 2 次、全部源失败才报错、支持 `CancelToken` 取消 |
| 落盘位置 | `getTemporaryDirectory()/update/`（= Android `cacheDir`），**无需任何存储权限** |
| 进度 UI | `UpdateDownloadDialog`：百分比 + 已下载/总量 + 速度，120ms 节流刷新；下载中可取消 |
| 安装桥接 | `MethodChannel('piliplus/apk_installer')` → `MainActivity` 用 `FileProvider` 生成 `content://` URI，`Intent.ACTION_VIEW` + `application/vnd.android.package-archive` 调起系统安装器 |
| 权限 | Manifest 声明 `REQUEST_INSTALL_PACKAGES`；运行时用 `packageManager.canRequestPackageInstalls()` 检查，未授权时弹「去设置」跳 `ACTION_MANAGE_UNKNOWN_APP_SOURCES` |
| FileProvider | authority = `${applicationId}.fileprovider`，`cache-path path="update/"`（见 `res/xml/file_paths.xml`） |
| 兜底 | 弹窗底部「网络异常？改用浏览器下载」（走 `onDownload`，镜像前缀）；下载失败页也有「用浏览器下载」 |

**必须知道的行为**：Android 系统会弹「是否安装此应用」确认框，**无法绕过**（非系统签名应用不能静默安装）。所以最终流程是「自动下载 → 自动弹安装框 → 用户点一次安装」。

**背景下载限制**：切后台/锁屏时下载会暂停（Flutter 前台任务限制），弹窗内已提示用户保持前台。后台下载需引入前台服务插件，本次未做。

**不支持的场景**：若设备上已安装的版本与本包签名不同（例如从别处装过第三方重打包版），安装会失败，需先卸载旧版。CI 使用 `.keys/piliplus.jks` 签名，与本 fork 历史版本一致。

> ⚠️ 合并上游时：若上游重写了 `update.dart` 的 `checkUpdate` / `onDownload`，需把 Android 分支（`_startAndroidUpdate` + 单个「立即更新」按钮）重新插入；`MainActivity.kt` 的 `configureFlutterEngine` 必须保留 `super` 调用（AudioService 依赖它），Manifest 的 `REQUEST_INSTALL_PACKAGES` 与 FileProvider 声明不可删。

---

## 4. 上游同步标准流程（AI 执行指引）

> **执行前提**：确认本文件第 2 节的「定制改动」清单已读完。

### 4.1 首次配置 upstream 远程

```bash
git remote add upstream https://github.com/bggRGjQaUbCoE/PiliPlus.git
git remote -v   # 确认 origin=本fork, upstream=上游
```

> **状态（2026-11-20）**：本机已配置完成。`git fetch upstream` 拉到的上游最新提交为 `217fb54f5 Release 2.2.1`，相对本 fork 基点 `bb2d86ca2` 共 **169 个提交、364 个文件**（Flutter `3.47.7` → `3.47.9`）。已于当日以 `git merge --no-ff` 实际合并，**0 冲突**，合并提交 `e8665af2b`；验证记录见第 4.4 节，冲突预判与实测对照见第 5 节。

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
- [ ] `.github/workflows/build.yml` 中 **android / ios / win_x64 三处** `github.repository` 判断仍为 `'Godwin9527/PiliPlus'`（本 fork 定制，**勿改回上游仓库名**；上游其他改动可直接接受）
- [ ] `video_popup_menu.dart` 中仍有 `_applyMenuConfig()`，且 `buildVideoMenuItems` 结尾是 `return _applyMenuConfig(items, menuItemHeight);`
- [ ] `video_popup_menu.dart` 中仍有 `onLongPressVideoCard()`，且 3 个卡片的 `onLongPress` 都调用它
- [ ] `showVideoPopupMenu` 中仍有 `Pref.videoMenuAlignRight` 分支（贴屏幕右缘 8dp）
- [ ] `VideoMenuItem` 枚举仍存在，且新枚举值只追加在末尾
- [ ] `SettingType` 中仍有 `videoCardSetting`，`setting_type.dart` 的 `settings` 分支仍映射到 `videoCardSettings`
- [ ] `lib/pages/rcmd/controller.dart` 中仍有 `_shown` / `_dedupe` / `_minRefreshCount = 20` / `_maxFetchTimes = 6`，且 `onRefresh` 仍是补拉循环
- [ ] `lib/pages/rcmd/view.dart` 中仍有 `_portraitOffset` / `_landscapeSeen` / `_pendingRestore` / `_restoreOffset`，且 `_RcmdPageState` 仍 `with ... WidgetsBindingObserver` 并在 `initState` 里 `addObserver`
- [ ] `lib/plugin/pl_player/models/landscape_direction.dart` 仍存在 `LandscapeDirection` 枚举
- [ ] `pl_player/controller.dart` 的 `changeOrientation` 仍在 `else` 分支开头保留「`orientation == null` 且 `Pref.landscapeDirection != .auto` 时按设置返回 landscape 模式」的分支
- [ ] `play_settings.dart` 中仍有「全屏横屏倒向」的 `PopupModel`，且 `Pref.landscapeDirection` 读取正常（越界回落 `.auto`）
- [ ] `lib/utils/update.dart` 中 `Platform.isAndroid` 分支仍是单个「立即更新」按钮 → `_startAndroidUpdate`，且 `_downloadUrls` 仍是**镜像在前、直连在后**
- [ ] `lib/utils/apk_downloader.dart` / `lib/utils/apk_installer.dart` / `lib/common/widgets/update_download_dialog.dart` 三个文件仍存在
- [ ] `MainActivity.kt` 仍注册 `piliplus/apk_installer` 通道，且 `configureFlutterEngine` **仍有 `super` 调用**
- [ ] `AndroidManifest.xml` 仍含 `REQUEST_INSTALL_PACKAGES` 与 `${applicationId}.fileprovider` 的 `FileProvider`；`res/xml/file_paths.xml` 仍映射 `update/`
- [ ] 全仓搜索 `bggRGjQaUbCoE`，确认**代码与配置中**无残留（注释、issue 链接中的该字样属正常，无需修改）

### 4.4 合并记录：2026-11-20 同步上游 2.2.1

| 项 | 值 |
|---|---|
| 合并命令 | `git merge --no-ff upstream/main` |
| 合并前 HEAD | `4627d8d2b`（tag `backup/pre-sync-2.2.1`） |
| 上游目标 | `217fb54f5` Release 2.2.1（169 提交 / 364 文件） |
| 合并提交 | `e8665af2b` |
| 冲突 | **0 个** |
| 结果版本 | pubspec `2.2.1+1`，Flutter `3.47.9` |

**第 4.3 清单逐项验证结果：全部通过。**

| # | 检查项 | 结果 |
|---|---|---|
| 1 | `buildVideoMenuItems` / `showVideoPopupMenu` 存在（各 2 处引用） | ✅ |
| 2 | `itemBuilder` 第 51 行仍调用 `buildVideoMenuItems` | ✅ |
| 3 | 3 个卡片 `onLongPress` → `showVideoPopupMenu`（`video_card_v:84` / `video_card_h:30` / `member_video:34`） | ✅ |
| 4 | `constants.dart:10` `String.fromEnvironment('pili.repo')` | ✅ |
| 5 | `api.dart:418` 双引号 `"${const String.fromEnvironment('pili.repo', ...)}"` | ✅ |
| 6 | `build.ps1:57` `$env:GITHUB_REPOSITORY` 注入 + 空值省略键 | ✅ |
| 7 | `build.ps1:17-30` `GITHUB_EVENT_PATH` + `^[vV]?(\d+\.\d+\.\d+)` 校验 | ✅ |
| 8 | `update.dart` `_mirror`(26) / `_sources`(36-39，直连在前) / `_fetchLatestRelease`(42) | ✅ |
| 9 | `update.dart` `forceMirror`(173) + `_downloadPrefix` 前缀复用(176) | ✅ |
| 10 | `.gitignore:78` `/.keys/` | ✅ |
| 11 | `build.yml` 3 处 `Godwin9527/PiliPlus` | ✅ |
| 12 | `bggRGjQaUbCoE` 残留：仅在 `constants.dart:11` 默认值（**预期保留**）与若干上游注释中 | ✅ |

**额外接口兼容性检查**（防上游重构打断定制代码）：

- `PageUtils.menuPosition(Offset)` 签名未变，`video_popup_menu.dart` 调用仍有效 ✅
- 5 个定制文件的全部 `package:PiliPlus/...` 内部导入路径均仍存在（合并删除了 `lib/utils/extension/context_ext.dart`，但定制文件未引用）✅

> **未做的验证**：本机无 Flutter SDK（`flutter` / `dart` / `fvm` 均不在 PATH），**未执行 `flutter analyze` 与编译**。代码级正确性依赖提交时的 CI 构建确认。若下次在 CI 构建前发现报错，优先回退 tag `backup/pre-sync-2.2.1` 定位。

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
| `.github/workflows/build.yml` | 🟡 中（2026-11-20 订正） | **保留** android / ios / win_x64 三处 `github.repository == 'Godwin9527/PiliPlus'`；接受上游其他改动。此前误记为「已消除」，勿再按「直接接受上游版本」处理 |
| `.gitignore` | 🟢 低 | 保留 `/.keys/` |
| `lib/pages/rcmd/controller.dart` | 🟡 中（2026-11-20 新增） | 保留 `_shown` / `_dedupe` / 补拉循环；上游若重写刷新逻辑，把去重与补拉套到新写法上 |
| `lib/models/common/video_menu_item.dart` | 🟢 低（新文件） | 上游不会创建同名文件；新枚举值**只追加末尾** |
| `lib/pages/setting/models/video_card_settings.dart` | 🟢 低（新文件） | 同上 |
| `lib/pages/setting/pages/video_menu_sort.dart` | 🟢 低（新文件） | 同上 |
| `lib/models/common/setting_type.dart` | 🟡 中（2026-11-20 新增） | 保留 `videoCardSetting` 枚举值与 `settings` 分支；接受上游新增的其他分类 |
| `lib/pages/setting/view.dart` / `settings_search/view.dart` | 🟡 中 | 保留「视频卡片」入口与 `...videoCardSettings` 搜索索引 |
| `MainActivity.kt` / `AndroidManifest.xml` | 🟡 中（2026-11-22 新增） | 保留 `piliplus/apk_installer` 通道、`super.configureFlutterEngine`、`REQUEST_INSTALL_PACKAGES`、FileProvider 声明；接受上游其他 Android 改动 |
| `android/app/build.gradle.kts` | 🟡 中 | 保留 `androidx.core:core-ktx` 显式依赖；接受上游对 AGP / compileSdk 等的调整 |
| `apk_downloader.dart` / `apk_installer.dart` / `update_download_dialog.dart` / `file_paths.xml` | 🟢 低（新文件） | 上游不会创建同名文件 |

### 冲突解决的**最高原则**

> 当不确定某段冲突属于"上游新改动"还是"本 fork 定制"时，**先查第 2、3 节**。若属于本 fork 定制 → **保留本 fork 版本**；若属于上游新功能 → **接受上游版本**；若两者都有 → **合并两者**（保留定制行为 + 引入上游新特性）。

### 2026-11-20 冲突预判（`bb2d86ca2` → `upstream/main` = `217fb54f5`）

> **执行结果**：已实际合并，**0 冲突**，预判完全成立。合并提交 `e8665af2b`。

上游 169 提交 / 364 文件（Flutter 3.47.7 → 3.47.9）。**逐文件核对结论：5 项定制全部零冲突。** 依据：

| 定制文件 | 上游是否改动 | 说明 |
|---|---|---|
| `video_popup_menu.dart` | ❌ 未动 | 整个文件与上游基点一致，合并必然干净 |
| `lib/utils/update.dart` | ❌ 未动 | 同上 |
| `lib/scripts/build.ps1` | ❌ 未动 | 同上 |
| `lib/common/constants.dart` | ❌ 未动 | 同上 |
| `video_card_h_member_video.dart` | ❌ 未动 | 同上 |
| `.github/workflows/build.yml` | ❌ 未动 | 上游没碰，3 处 `Godwin9527` 安全 |
| `video_card_h.dart` | ⚠️ 改了 1 行 | 第 191 行 `overflow: .clip` → `.ellipsis`，与第 30 行的 `onLongPress` **不同区域**，merge 不冲突 |
| `video_card_v.dart` | ⚠️ 改了 1 行 | 第 204 行同类型改动，与第 84 行 `onLongPress` **不同区域**，merge 不冲突 |
| `lib/http/api.dart` | ⚠️ 末尾新增 29 行 | 仅在文件末尾追加直播相关 API；本 fork 改的 `latestApp`（约 414 行）**未受影响** |
| `.gitignore` | ⚠️ 末尾加 2 行 | 新增 `!/test/`、`!/test/**`；本 fork 的 `/.keys/`（第 78 行）**不受影响** |
| `pubspec.yaml` | ✅ 需接受上游 | 版本 → `2.2.1+1`、Flutter → `3.47.9`、新增 `audio_service_mpris`/`nm`/`webview_all_linux`、`window_manager` 改为 pub 版本。本 fork 未改此文件，**直接接受上游** |

> **注意**：`pubspec.yaml` 与 `.fvmrc` 接受上游后，本地构建需要 Flutter **3.47.9**（当前 `.fvmrc` 为 3.47.7）。CI 的 `flutter-version` 由上游 workflow 指定，无需手工改。

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
10. ❌ 不得把 `.github/workflows/build.yml` 中 3 处 `github.repository == 'Godwin9527/PiliPlus'` 改回上游仓库名（否则本 fork 的 PR 不再触发构建）
11. ❌ 不得移除 `_applyMenuConfig()` 而把菜单项顺序改回写死（会让「视频卡片 → 菜单项与排序」设置失效）
12. ❌ 不得把 `onLongPress` 直接改回 `showVideoPopupMenu`（必须走 `onLongPressVideoCard`，否则「长按弹封面预览」开关失效）
13. ❌ 不得移除 `rcmd/controller.dart` 的 `_shown` / `_dedupe` / 补拉循环（否则重复推荐与「刷几下就到底」两个问题会复发）
14. ❌ 不得把 `VideoMenuItem` 的新枚举值插到中间（存储的是 index，会整体错位）
15. ❌ 不得移除 `MainActivity.configureFlutterEngine` 中的 `super` 调用（AudioService 依赖它，会导致后台播放服务失效）
16. ❌ 不得删除 Manifest 的 `REQUEST_INSTALL_PACKAGES`、`FileProvider` 声明，或 `res/xml/file_paths.xml`（会导致下载完无法安装）
17. ❌ 不得把 `_downloadUrls` 的顺序改回「直连在前」（用户明确要求镜像优先，且安装包体积大，直连在国内易超时）

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
| 2026-11-20 | **文档订正**：发现本文档第 2 / 4.3 / 5 节声称 `.github/workflows/build.yml` 的硬编码「已全部撤销」，实际未撤销（提交 `430d6631b` 的 diffstat 不含该文件）。按「以代码为准」原则订正：第 2 节表格新增 #8 行、新增第 3.6 节、更新第 4.3 验证清单、第 5 节冲突等级由「🟢 已消除」改为「🟡 中」、第 6 节新增第 10 条红线。同时配置 `upstream` 远程用于同步上游 |
| 2026-11-20 | **同步上游 2.2.1**：`git merge --no-ff upstream/main`（169 提交 / 364 文件），**0 冲突**，合并提交 `e8665af2b`。Flutter `3.47.7 → 3.47.9`，pubspec `2.1.6+1 → 2.2.1+1`。5 项定制经 12 项清单逐项验证全部保留，新增第 4.4 节合并记录。合并前锚点 tag `backup/pre-sync-2.2.1`（`4627d8d2b`） |
| 2026-11-20 | **v2.2.2 功能定制**：① 长按菜单改为贴屏幕右缘弹出，并新增「菜单弹出位置」开关；②「不感兴趣」原因弹窗改为整块靠右、单列、文字右对齐（含 web 兜底弹窗）；③ 新增「视频卡片」设置分类，支持菜单项开关与拖拽排序、长按行为切换（弹菜单 / 封面预览）；④ 首页推荐增加会话内 bvid 去重与刷新保底 20 条（最多补拉 6 次）。新增第 3.7 / 3.8 / 3.9 节，第 2 节新增 #9–#15，第 5 / 6 节同步扩充 |
| 2026-11-20 | **v2.2.3 修复**：v2.2.2 的推荐补拉存在合成顺序错误 —— 补拉结果经 `queryData(false)` 追加到**旧内容之后**，导致「刷新只看到 4 条、转圈数秒后消失且无新内容」。重写 `RcmdController.onRefresh`：自行驱动请求循环 + `_publish()` 整表合成（新内容恒在最前）、逐步上屏、翻页空转自动改拉新批次、`lastRefreshAt` 刷新期间置空。详见第 3.9 节 |
| 2026-11-22 | **v2.2.4 定制**：① 修复「横屏全屏播放后返回列表，位置跳到更靠前处」——横屏时列表列数变化导致滚动位置被 clamp 且不恢复，现按「竖直位置记录 + 回竖屏还原」处理；② 新增「全屏横屏倒向」设置（跟随重力 / 手机顶部朝左 / 顶部朝右），解决右手单手握持时全屏方向不顺手。新增第 3.10 / 3.11 节，第 2 节新增 #16–#19 |
| 2026-11-22 | **v2.2.5 定制**：Android 更新流程由「跳浏览器下载」改为「App 内下载 + 自动调起系统安装器」。新增 `ApkDownloader`（镜像优先、断点续传、单源重试 2 次）、`ApkInstaller`（MethodChannel）、`UpdateDownloadDialog`（进度/权限引导）；原生侧新增 `piliplus/apk_installer` 通道 + FileProvider + `REQUEST_INSTALL_PACKAGES`。**本仓库首次修改原生 Android 代码**。新增第 3.12 节，第 2 节新增 #20–#26，第 5 / 6 节同步扩充 |

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
