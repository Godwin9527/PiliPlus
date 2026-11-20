/// 视频卡片「三点菜单」的可配置项。
///
/// 本枚举由本 fork 引入（见 CUSTOMIZATION.md 第 3.7 节）：
/// 上游的菜单项顺序与显隐是写死的，这里改为可配置。
///
/// ⚠️ **新增菜单项时必须追加到末尾**，不要插入中间，
/// 否则用户已保存的顺序（存的是 [index]）会整体错位。
enum VideoMenuItem {
  copyBvid('复制 BV 号'),
  viewLater('稍后再看'),
  aiSummary('AI 总结'),
  gotoMember('访问 UP 主'),
  notInterested('不感兴趣'),
  blockUp('拉黑 UP 主'),
  anonymity('无痕模式');

  /// 设置页展示用名称（运行时菜单标题由各菜单项自行决定，可能与此处不同）
  final String label;
  const VideoMenuItem(this.label);

  static VideoMenuItem? fromIndex(int? index) {
    if (index == null || index < 0 || index >= values.length) return null;
    return values[index];
  }
}
