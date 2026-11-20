import 'package:PiliPlus/pages/setting/models/model.dart';
import 'package:PiliPlus/pages/setting/pages/video_menu_sort.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

/// 「视频卡片」设置分类（本 fork 新增，见 CUSTOMIZATION.md 3.7 / 3.8）
List<SettingsModel> get videoCardSettings => [
  NormalModel(
    title: '菜单项与排序',
    subtitle: '选择三点菜单里显示哪些项、以及它们的顺序',
    leading: const Icon(Icons.format_list_bulleted),
    onTap: (context, setState) => Get.to(() => const VideoMenuSortPage()),
  ),
  SwitchModel(
    title: '长按弹封面预览',
    subtitle: '关闭（默认）：长按卡片弹出三点菜单；开启：恢复上游原版的封面放大预览',
    leading: const Icon(Icons.touch_app_outlined),
    setKey: SettingBoxKey.longPressShowCover,
    defaultVal: false,
  ),
  SwitchModel(
    title: '菜单贴屏幕右侧',
    subtitle: '便于右手单手操作。关闭后菜单改为跟随卡片左下角展开',
    leading: const Icon(Icons.swap_horiz_outlined),
    setKey: SettingBoxKey.videoMenuAlignRight,
    defaultVal: true,
  ),
];
