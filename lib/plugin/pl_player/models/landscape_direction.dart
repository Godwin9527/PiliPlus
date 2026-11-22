import 'package:PiliPlus/models/common/enum_with_label.dart';

/// 手动点全屏按钮时的横屏倒向（本 fork 定制，见 CUSTOMIZATION.md 3.11）。
///
/// 用户右手单手握持时，希望按自己顺手的一侧倒手机，因此把「手机顶部朝哪边」
/// 开放为设置项。注意 Flutter 在 Android 与 iOS 上对
/// `DeviceOrientation.landscapeLeft / landscapeRight` 的语义是相反的
/// （见 flutter/flutter#73651），平台差异在
/// `PlayerController.changeOrientation` 内部抵消，此处只表达物理倒向。
enum LandscapeDirection with EnumWithLabel {
  /// 保持上游行为（由传感器方向或默认那一侧决定）
  auto('跟随重力感应（默认）'),

  /// 横屏时手机顶部朝左
  topLeft('手机顶部朝左'),

  /// 横屏时手机顶部朝右
  topRight('手机顶部朝右');

  const LandscapeDirection(this.label);

  @override
  final String label;
}
