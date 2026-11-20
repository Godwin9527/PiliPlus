import 'package:PiliPlus/common/widgets/reorder_mixin.dart';
import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/models/common/video_menu_item.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:material_ui/material_ui.dart';

/// 视频卡片「三点菜单」的显示项与顺序配置页（本 fork 新增）。
///
/// 存储：
/// - `videoMenuOrder` → List<int>，[VideoMenuItem.index]，数组顺序即显示顺序；
/// - `videoMenuOff`   → List<int>，被隐藏的项。
///
/// 每次改动即时落盘，菜单下次弹出即生效，无需重启。
class VideoMenuSortPage extends StatefulWidget {
  const VideoMenuSortPage({super.key});

  @override
  State<VideoMenuSortPage> createState() => _VideoMenuSortPageState();
}

class _VideoMenuSortPageState extends State<VideoMenuSortPage> with ReorderMixin {
  late final List<VideoMenuItem> items;
  late final Set<VideoMenuItem> disabled;

  @override
  void initState() {
    super.initState();
    final savedOrder = Pref.videoMenuOrder;
    final off = Pref.videoMenuOff.toSet();

    // 以保存的顺序为基准，把新版本新增、尚未登记进配置的项追加到末尾
    final ordered = <VideoMenuItem>[];
    for (final index in savedOrder) {
      final item = VideoMenuItem.fromIndex(index);
      if (item != null && !ordered.contains(item)) ordered.add(item);
    }
    for (final item in VideoMenuItem.values) {
      if (!ordered.contains(item)) ordered.add(item);
    }

    items = ordered;
    disabled = {
      for (final item in VideoMenuItem.values)
        if (off.contains(item.index)) item,
    };
  }

  void _save() {
    GStorage.setting.put(
      SettingBoxKey.videoMenuOrder,
      items.map((e) => e.index).toList(),
    );
    GStorage.setting.put(
      SettingBoxKey.videoMenuOff,
      disabled.map((e) => e.index).toList(),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    items.insert(newIndex, items.removeAt(oldIndex));
    setState(() {});
    _save();
  }

  void _toggle(VideoMenuItem item, bool value) {
    setState(() {
      if (value) {
        disabled.remove(item);
      } else {
        disabled.add(item);
      }
    });
    _save();
  }

  Future<void> _onReset() async {
    GStorage.setting.delete(SettingBoxKey.videoMenuOrder);
    GStorage.setting.delete(SettingBoxKey.videoMenuOff);
    SmartDialog.showToast('已恢复默认');
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.viewPaddingOf(context);
    return SimpleScaffold(
      appBar: AppBar(
        title: const Text('菜单项与排序'),
        actions: [
          TextButton(onPressed: _onReset, child: const Text('恢复默认')),
          const SizedBox(width: 8),
        ],
      ),
      body: ReorderableListView(
        onReorderItem: _onReorder,
        proxyDecorator: proxyDecorator,
        footer: Padding(
          padding: EdgeInsets.only(
            top: 16,
            right: padding.right + 34,
            bottom: padding.bottom + 40,
          ),
          child: const Align(
            alignment: Alignment.centerRight,
            child: Text(
              '*长按右侧图标拖动排序；关闭的项不会出现在菜单里\n'
              '（全部关闭时会保底保留「不感兴趣」）',
              textAlign: TextAlign.right,
            ),
          ),
        ),
        children: items
            .map(
              (e) => SwitchListTile(
                key: ValueKey(e.index),
                value: !disabled.contains(e),
                onChanged: (value) => _toggle(e, value),
                title: Text(e.label),
                secondary: const Icon(Icons.drag_indicator_rounded),
              ),
            )
            .toList(),
      ),
    );
  }
}
