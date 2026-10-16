# AGENTS.md

> 本文件供 **AI 助手 / 编码代理** 自动读取。人类读者请直接看 `CUSTOMIZATION.md`。

## 你是谁 / 这是什么仓库

这是一个 **Flutter 应用 PiliPlus 的 fork 仓库**。

| 项目 | 值 |
|---|---|
| 上游原仓库 | `https://github.com/bggRGjQaUbCoE/PiliPlus` |
| 本 fork 仓库 | `https://github.com/Godwin9527/PiliPlus` |
| 默认分支 | `main` |
| 技术栈 | Flutter / Dart |

本仓库在上游基础上做了一些**本地定制**。这些定制是**有意为之**的，不是 bug。

---

## 🔴 首要规则：动手前必读 CUSTOMIZATION.md

**在处理本仓库的任何任务之前，你必须先完整阅读 [`CUSTOMIZATION.md`](./CUSTOMIZATION.md)。**

该文件记录了：
- 本 fork 相对上游做过的**全部定制改动**（改了什么、在哪个文件、为什么改）
- 哪些内容**严禁回退或"优化"**
- 同步上游更新时的**标准流程**与**合并后验证清单**
- 冲突处理策略

**不要凭直觉判断某段代码"看起来冗余"就删除它。** 它很可能是刻意保留的定制。

---

## 🔴 第二条规则：改完代码必须同步更新 CUSTOMIZATION.md

这是**强制义务**，不是可选项，且**无需用户提醒**：

- 若你的改动新增/修改/删除了任何「定制」内容 → **必须**更新 `CUSTOMIZATION.md` 的第 1、2、3、5、8 节
- 若你同步了上游更新 → 按 `CUSTOMIZATION.md` 第 4.3 节清单验证，并补充第 5 节
- 若你发现文档与代码不符 → 以代码为准修正文档，并记录在第 8 节

> **一次任务完成的标准 = 代码已改 + `CUSTOMIZATION.md` 已更新。**
> 只改代码不改文档 = **任务未完成**。

详见 `CUSTOMIZATION.md` 第 9 节「文档维护契约」。

---

## 常用命令

### 构建与发布

```bash
# 触发 GitHub Actions 构建（必须提供非空 tag，否则不创建 Release）
gh workflow run Build --repo Godwin9527/PiliPlus \
  -f build_android=true -f build_win_x64=true \
  -f build_ios=false -f build_mac=false -f build_linux_x64=false \
  -f tag=v2.1.8
```

### 同步上游

见 `CUSTOMIZATION.md` 第 4 节。简要流程：

```bash
git remote add upstream https://github.com/bggRGjQaUbCoE/PiliPlus.git  # 首次
git fetch upstream
git checkout main
git merge upstream/main
# 解决冲突（遵循 CUSTOMIZATION.md 第 5 节）
git push origin main
```

### 静态校验（本机若无 Flutter SDK，可用独立 Dart SDK）

```bash
dart run --define=pili.repo=Godwin9527/PiliPlus <脚本>   # 验证 pili.repo 注入逻辑
```

---

## 关键注意事项

1. **构建参数 `pili.repo`**：仓库标识通过构建参数注入（见 `lib/scripts/build.ps1`），源码中**不应出现** `Godwin9527` 硬编码。
2. **镜像回退**：`lib/utils/update.dart` 内置了「直连 GitHub 失败 → 自动走 `gh-proxy.com` 镜像」的逻辑，用于应对国内 DNS 污染。**不要移除**。
3. **签名密钥**：本地 `.keys/` 目录已被 gitignore，**绝不提交**。GitHub Secrets 已配置。
4. **不要提交** `pili_release.json`（构建时生成，已 gitignore）。
5. **`.github/workflows/build.yml` 与上游保持一致** —— 不要在此文件做 fork 定制。

---

## 文件导航

| 文件 | 作用 |
|---|---|
| `CUSTOMIZATION.md` | **本 fork 的定制事实来源**，必读 |
| `lib/scripts/build.ps1` | 构建脚本，注入 `pili.repo` 等构建参数 |
| `lib/build_config.dart` | 构建参数的 Dart 侧读取（`String.fromEnvironment`） |
| `lib/utils/update.dart` | App 内「检查更新」逻辑 |
| `lib/common/widgets/video_popup_menu.dart` | 视频卡片菜单（含本 fork 的长按定制） |
