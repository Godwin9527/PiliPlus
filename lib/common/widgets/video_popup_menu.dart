import 'package:PiliPlus/common/widgets/custom_icon.dart';
import 'package:PiliPlus/common/widgets/image/image_save.dart';
import 'package:PiliPlus/http/user.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/models/common/video_menu_item.dart';
import 'package:PiliPlus/models/home/rcmd/result.dart';
import 'package:PiliPlus/models/model_video.dart';
import 'package:PiliPlus/models_new/space/space_archive/item.dart';
import 'package:PiliPlus/pages/mine/controller.dart';
import 'package:PiliPlus/pages/search/widgets/search_text.dart';
import 'package:PiliPlus/pages/video/ai_conclusion/view.dart';
import 'package:PiliPlus/pages/video/introduction/ugc/controller.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_ui/material_ui.dart';

class _VideoCustomAction {
  final VideoMenuItem id;
  final String title;
  final Widget icon;
  final VoidCallback onTap;
  const _VideoCustomAction(this.id, this.title, this.icon, this.onTap);
}

class VideoPopupMenu extends StatelessWidget {
  final double? iconSize;
  final double menuItemHeight;
  final BaseSimpleVideoItemModel videoItem;
  final VoidCallback? onRemove;

  const VideoPopupMenu({
    super.key,
    required this.iconSize,
    required this.videoItem,
    this.onRemove,
    this.menuItemHeight = 45,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      padding: EdgeInsets.zero,
      icon: Icon(
        Icons.more_vert_outlined,
        color: Theme.of(context).colorScheme.outline,
        size: iconSize,
      ),
      position: PopupMenuPosition.under,
      itemBuilder: (context) => buildVideoMenuItems(
        context,
        videoItem,
        menuItemHeight: menuItemHeight,
        onRemove: onRemove,
      ),
    );
  }
}

/// 构建视频卡片的弹出菜单项。
///
/// 该函数被 [VideoPopupMenu]（右下角三点按钮）与视频卡片的长按手势共同复用，
/// 以保证两条入口弹出完全一致的菜单。
List<PopupMenuEntry<dynamic>> buildVideoMenuItems(
  BuildContext context,
  BaseSimpleVideoItemModel videoItem, {
  double menuItemHeight = 45,
  VoidCallback? onRemove,
}) {
  final items = <_VideoCustomAction>[
        if (videoItem.bvid?.isNotEmpty == true) ...[
          _VideoCustomAction(
            .copyBvid,
            videoItem.bvid!,
            const Icon(CustomIcons.identifier_circle, size: 16),
            () => Utils.copyText(videoItem.bvid!),
          ),
          if (Accounts.main.isLogin)
            _VideoCustomAction(
              .viewLater,
              '稍后再看',
              const Icon(MdiIcons.clockTimeEightOutline, size: 16),
              () => UserHttp.toViewLater(bvid: videoItem.bvid),
            ),
          if (videoItem.cid != null && Pref.enableAi)
            _VideoCustomAction(
              .aiSummary,
              'AI总结',
              const Icon(CustomIcons.ai_circle, size: 16),
              () async {
                final res = await UgcIntroController.getAiConclusion(
                  videoItem.bvid!,
                  videoItem.cid!,
                  videoItem.owner.mid,
                );
                if (res != null && context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      child: Padding(
                        padding: const .symmetric(vertical: 14),
                        child: AiConclusionPanel.buildContent(
                          context,
                          Theme.of(context),
                          res,
                          tap: false,
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
        ],
        if (videoItem is! SpaceArchiveItem) ...[
          _VideoCustomAction(
            .gotoMember,
            '访问：${videoItem.owner.name}',
            const Icon(MdiIcons.accountCircleOutline, size: 16),
            () => Get.toNamed('/member?mid=${videoItem.owner.mid}'),
          ),
          _VideoCustomAction(
            .notInterested,
            '不感兴趣',
            const Icon(MdiIcons.thumbDownOutline, size: 16),
            () {
              final rcmd = Accounts.get(.recommend);
              if (rcmd.accessKey == null || rcmd.accessKey == "") {
                SmartDialog.showToast(
                  rcmd.isLogin ? '请退出账号后重新登录' : '账号未登录',
                );
                return;
              }
              if (videoItem case final RcmdVideoItemAppModel item) {
                ThreePoint? tp = item.threePoint;
                if (tp == null) {
                  SmartDialog.showToast("未能获取threePoint");
                  return;
                }
                if (tp.dislikeReasons == null && tp.feedbacks == null) {
                  SmartDialog.showToast(
                    "未能获取dislikeReasons或feedbacks",
                  );
                  return;
                }
                // 每个选项独占一行、整行可点、文字右对齐：
                // 避免「某个选项文字较长把其他选项顶到左边」，也便于右手单手操作。
                Widget actionButton(Reason? r, Reason? f) {
                  return Padding(
                    padding: const .only(bottom: 6),
                    child: SizedBox(
                      width: double.infinity,
                      child: SearchText(
                        text: r?.name ?? f?.name ?? '未知',
                        textAlign: TextAlign.right,
                        padding: const .symmetric(horizontal: 11, vertical: 7),
                        onTap: (_) async {
                          Get.back();
                          SmartDialog.showLoading(msg: '正在提交');
                          final res = await VideoHttp.feedDislike(
                            reasonId: r?.id,
                            feedbackId: f?.id,
                            id: item.param!,
                            goto: item.goto!,
                          );
                          SmartDialog.dismiss();
                          if (res.isSuccess) {
                            SmartDialog.showToast(
                              r?.toast ?? f!.toast!,
                            );
                            onRemove?.call();
                          } else {
                            res.toast();
                          }
                        },
                      ),
                    ),
                  );
                }

                showDialog(
                  context: context,
                  builder: (context) {
                    final theme = Theme.of(context);
                    return Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const .only(right: 12, top: 24, bottom: 24),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: Material(
                            color: theme.dialogTheme.backgroundColor ??
                                theme.colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(24),
                            clipBehavior: Clip.antiAlias,
                            child: SingleChildScrollView(
                              padding: const .fromLTRB(14, 16, 14, 16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (tp.dislikeReasons != null) ...[
                                    const Text(
                                      '我不想看',
                                      textAlign: TextAlign.right,
                                    ),
                                    const SizedBox(height: 6),
                                    ...tp.dislikeReasons!.map(
                                      (e) => actionButton(e, null),
                                    ),
                                  ],
                                  if (tp.feedbacks != null) ...[
                                    const SizedBox(height: 8),
                                    const Text(
                                      '反馈',
                                      textAlign: TextAlign.right,
                                    ),
                                    const SizedBox(height: 6),
                                    ...tp.feedbacks!.map(
                                      (e) => actionButton(null, e),
                                    ),
                                  ],
                                  const Divider(),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: FilledButton.tonal(
                                      onPressed: () async {
                                        SmartDialog.showLoading(
                                          msg: '正在提交',
                                        );
                                        final res = await VideoHttp
                                            .feedDislikeCancel(
                                              id: item.param!,
                                              goto: item.goto!,
                                            );
                                        SmartDialog.dismiss();
                                        SmartDialog.showToast(
                                          res.isSuccess
                                              ? "成功"
                                              : res.toString(),
                                        );
                                        Get.back();
                                      },
                                      style: FilledButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      child: const Text("撤销"),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              } else {
                showDialog(
                  context: context,
                  builder: (context) {
                    final theme = Theme.of(context);
                    return Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const .only(right: 12, top: 24, bottom: 24),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: Material(
                            color: theme.dialogTheme.backgroundColor ??
                                theme.colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(24),
                            clipBehavior: Clip.antiAlias,
                            child: Padding(
                              padding: const .fromLTRB(14, 16, 14, 16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    "web端暂不支持精细选择",
                                    textAlign: TextAlign.right,
                                  ),
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      alignment: WrapAlignment.end,
                                      children: [
                                        FilledButton.tonal(
                                          onPressed: () async {
                                            Get.back();
                                            SmartDialog.showLoading(
                                              msg: '正在提交',
                                            );
                                            final res = await VideoHttp
                                                .dislikeVideo(
                                                  bvid: videoItem.bvid!,
                                                  type: true,
                                                );
                                            SmartDialog.dismiss();
                                            if (res.isSuccess) {
                                              SmartDialog.showToast('点踩成功');
                                              onRemove?.call();
                                            } else {
                                              res.toast();
                                            }
                                          },
                                          style: FilledButton.styleFrom(
                                            visualDensity: .compact,
                                          ),
                                          child: const Text("点踩"),
                                        ),
                                        FilledButton.tonal(
                                          onPressed: () async {
                                            Get.back();
                                            SmartDialog.showLoading(
                                              msg: '正在提交',
                                            );
                                            final res = await VideoHttp
                                                .dislikeVideo(
                                                  bvid: videoItem.bvid!,
                                                  type: false,
                                                );
                                            SmartDialog.dismiss();
                                            SmartDialog.showToast(
                                              res.isSuccess
                                                  ? '取消踩'
                                                  : res.toString(),
                                            );
                                          },
                                          style: FilledButton.styleFrom(
                                            visualDensity: .compact,
                                          ),
                                          child: const Text("撤销"),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
            },
          ),
          _VideoCustomAction(
            .blockUp,
            '拉黑：${videoItem.owner.name}',
            const Icon(MdiIcons.cancel, size: 16),
            () => showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('提示'),
                  content: Text(
                    '确定拉黑:${videoItem.owner.name}(${videoItem.owner.mid})?'
                    '\n\n注：被拉黑的Up可以在隐私设置-黑名单管理中解除',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Get.back();
                        Pref.setBlackMid(videoItem.owner.mid!);
                        onRemove?.call();
                      },
                      child: const Text('本地屏蔽'),
                    ),
                    TextButton(
                      onPressed: Get.back,
                      child: Text(
                        '取消',
                        style: TextStyle(
                          color: ColorScheme.of(context).outline,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        Get.back();
                        final res = await VideoHttp.relationMod(
                          mid: videoItem.owner.mid!,
                          act: 5,
                          reSrc: 11,
                        );
                        if (res.isSuccess) {
                          onRemove?.call();
                        } else {
                          res.toast();
                        }
                      },
                      child: const Text('确认'),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
        _VideoCustomAction(
          .anonymity,
          "${MineController.anonymity.value ? '退出' : '进入'}无痕模式",
          MineController.anonymity.value
              ? const Icon(MdiIcons.incognitoOff, size: 16)
              : const Icon(MdiIcons.incognito, size: 16),
          MineController.onChangeAnonymity,
        ),
    ];

  return _applyMenuConfig(items, menuItemHeight);
}

/// 按用户配置对菜单项排序与过滤。
///
/// 规则（见 CUSTOMIZATION.md 3.7）：
/// - 已保存顺序 → 按保存顺序排列，未登记的（上游新增）追加到末尾；
/// - 被隐藏的项跳过；
/// - 全部隐藏时保底保留「不感兴趣」，避免弹出空菜单。
List<PopupMenuEntry<dynamic>> _applyMenuConfig(
  List<_VideoCustomAction> items,
  double menuItemHeight,
) {
  final order = Pref.videoMenuOrder;
  final off = Pref.videoMenuOff.toSet();

  List<_VideoCustomAction> ordered;
  if (order.isEmpty) {
    ordered = items;
  } else {
    final byId = {for (final e in items) e.id.index: e};
    final result = <_VideoCustomAction>[];
    for (final index in order) {
      final item = byId.remove(index);
      if (item != null) result.add(item);
    }
    // 新版本新增、尚未登记进配置的菜单项，按默认顺序追加到末尾
    for (final e in items) {
      if (byId.containsKey(e.id.index)) result.add(e);
    }
    ordered = result;
  }

  var visible = ordered.where((e) => !off.contains(e.id.index)).toList();
  if (visible.isEmpty) {
    visible = ordered
        .where((e) => e.id == VideoMenuItem.notInterested)
        .toList();
    if (visible.isEmpty) visible = ordered;
  }

  return visible
      .map(
        (e) => PopupMenuItem(
          height: menuItemHeight,
          onTap: e.onTap,
          child: Row(
            children: [
              e.icon,
              const SizedBox(width: 6),
              Text(e.title, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      )
      .toList();
}

/// 长按视频卡片封面的统一入口（本 fork 定制，见 CUSTOMIZATION.md 3.8）。
///
/// 按用户设置决定行为：
/// - `Pref.longPressShowCover == false`（默认）→ 弹出三点菜单；
/// - `Pref.longPressShowCover == true` → 上游原版的封面放大预览。
void onLongPressVideoCard(
  BuildContext context,
  BaseSimpleVideoItemModel videoItem, {
  VoidCallback? onRemove,
}) {
  if (Pref.longPressShowCover) {
    imageSaveDialog(
      title: videoItem.title,
      cover: videoItem.cover,
      bvid: videoItem.bvid,
    );
  } else {
    showVideoPopupMenu(context, videoItem, onRemove: onRemove);
  }
}

/// 在 [position] 处弹出与 [VideoPopupMenu] 完全一致的三点菜单。
///
/// 供视频卡片的长按手势复用，让长按整张卡片等价于点击右下角三点按钮。
/// [position] 为空时，默认在 [context] 对应的组件下方弹出。
Future<void> showVideoPopupMenu(
  BuildContext context,
  BaseSimpleVideoItemModel videoItem, {
  RelativeRect? position,
  double menuItemHeight = 45,
  VoidCallback? onRemove,
}) {
  return showMenu<dynamic>(
    context: context,
    position:
        position ??
        (() {
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox == null) {
            return const RelativeRect.fromLTRB(0, 0, 0, 0);
          }
          final origin = renderBox.localToGlobal(Offset.zero);
          final bottom = origin.dy + renderBox.size.height;
          if (Pref.videoMenuAlignRight) {
            // 贴屏幕右侧弹出：锚点取「屏幕右边 8dp」而非卡片边缘，
            // 这样无论卡片多宽，菜单都稳定出现在右手拇指够得到的位置。
            return PageUtils.menuPosition(
              Offset(MediaQuery.sizeOf(context).width - 8, bottom),
            );
          }
          return PageUtils.menuPosition(
            renderBox.localToGlobal(renderBox.size.bottomLeft(.zero)),
          );
        })(),
    items: buildVideoMenuItems(
      context,
      videoItem,
      menuItemHeight: menuItemHeight,
      onRemove: onRemove,
    ),
  );
}
