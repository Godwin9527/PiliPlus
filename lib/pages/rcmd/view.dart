import 'package:PiliPlus/common/skeleton/video_card_v.dart';
import 'package:PiliPlus/common/sliver_single_child_delegate.dart';
import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/common/widgets/video_card/video_card_v.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/pages/rcmd/controller.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class RcmdPage extends StatefulWidget {
  const RcmdPage({super.key});

  @override
  State<RcmdPage> createState() => _RcmdPageState();
}

class _RcmdPageState extends State<RcmdPage>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final controller = Get.put(RcmdController());

  // ------- 本 fork 定制：横屏后回到竖屏时还原滚动位置（见 CUSTOMIZATION.md 3.10） -------

  /// 竖屏下最后一次真实的滚动位置
  double? _portraitOffset;

  /// 当前是否竖屏
  bool _isPortrait = true;

  /// 期间是否进过横屏；为 true 时冻结位置记录，回到竖屏后触发还原
  bool _landscapeSeen = false;

  /// 待还原的目标位置；成功还原或用户主动滚动后清空
  double? _pendingRestore;

  /// 正在执行 jumpTo，此时监听回调不是用户滚动
  bool _restoring = false;

  /// 本帧是否已经排过还原任务
  bool _restoreScheduled = false;

  int _restoreTries = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller.scrollController.addListener(_onScrollForRestore);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.scrollController.removeListener(_onScrollForRestore);
    super.dispose();
  }

  /// 只记录「竖屏且不在横屏会话中」的位置。
  /// 横屏时列表列数变多、内容变短，ScrollPosition 会把 pixels 夹回
  /// maxScrollExtent，这个被夹过的值不能覆盖记录值。
  void _onScrollForRestore() {
    if (_restoring) return;
    if (!_isPortrait || _landscapeSeen) return;
    if (!controller.scrollController.hasClients) return;
    final pos = controller.scrollController.position;
    if (!pos.hasContentDimensions) return;
    final pixels = pos.pixels;
    if (pixels <= 0 || pixels.isNaN || pixels.isInfinite) return;
    // 等待还原期间，位置变化来自「布局回竖屏」的回弹，不能覆盖记录值
    if (_pendingRestore != null) return;
    _portraitOffset = pixels;
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return;
    final size = views.first.physicalSize;
    if (size.width <= 0 || size.height <= 0) return;
    _syncOrientation(size.height >= size.width);
  }

  void _syncOrientation(bool isPortrait) {
    if (isPortrait == _isPortrait) return;
    _isPortrait = isPortrait;
    if (!isPortrait) {
      _landscapeSeen = true;
    } else if (_landscapeSeen) {
      _landscapeSeen = false;
      _scheduleRestoreOffset();
    }
  }

  void _scheduleRestoreOffset() {
    final target = _portraitOffset;
    if (target == null || target <= 0) return;
    _pendingRestore = target;
    _restoreTries = 0;
    _requestRestore(target);
  }

  void _requestRestore(double target) {
    if (_restoreScheduled) return;
    _restoreScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreScheduled = false;
      _restoreOffset(target);
    });
  }

  void _restoreOffset(double target) {
    if (!mounted) return;
    final sc = controller.scrollController;
    if (!sc.hasClients) {
      _retryRestore(target);
      return;
    }
    final pos = sc.position;
    if (!pos.hasContentDimensions || pos.maxScrollExtent <= 0) {
      _retryRestore(target);
      return;
    }
    // 布局还没回到竖屏尺寸时 maxScrollExtent 偏小，等下一帧再试
    if (pos.maxScrollExtent + 1 < target) {
      _retryRestore(target);
      return;
    }
    if ((pos.pixels - target).abs() > 8) {
      _restoring = true;
      sc.jumpTo(target);
      _restoring = false;
      _portraitOffset = target;
    }
    _pendingRestore = null;
  }

  void _retryRestore(double target) {
    if (_restoreTries++ >= 20) {
      // 等太久仍无法还原（列表确实变短了），放弃，交还给用户
      _pendingRestore = null;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreOffset(target));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // didChangeMetrics 之外的双保险：布局时再核对一次方向
    final size = MediaQuery.sizeOf(context);
    if (size.width > 0 && size.height > 0) {
      _syncOrientation(size.height >= size.width);
    }
    // 横屏期间列表被视频页挡住、不参与布局时，还原会延后到返回本页再补一次
    final pendingRestore = _pendingRestore;
    if (pendingRestore != null) {
      _restoreTries = 0;
      _requestRestore(pendingRestore);
    }
    final colorScheme = ColorScheme.of(context);
    final child = Container(
      clipBehavior: .hardEdge,
      margin: const .symmetric(horizontal: Style.safeSpace),
      decoration: const BoxDecoration(borderRadius: Style.mdRadius),
      child: refreshIndicator(
        key: controller.refreshKey,
        onRefresh: controller.onRefresh,
        child: CustomScrollView(
          controller: controller.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const .only(top: Style.cardSpace, bottom: 100),
              sliver: Obx(
                () => _buildBody(colorScheme, controller.loadingState.value),
              ),
            ),
          ],
        ),
      ),
    );
    if (PlatformUtils.isDesktop && Pref.showRefreshFAB) {
      return ScaffoldLayout(
        body: child,
        fab: Padding(
          padding: const .only(
            right: kFloatingActionButtonMargin,
            bottom: 80 + kFloatingActionButtonMargin,
          ),
          child: FloatingActionButton(
            tooltip: '刷新',
            onPressed: controller.toTopAndRefresh,
            backgroundColor: colorScheme.secondaryContainer,
            foregroundColor: colorScheme.onSecondaryContainer,
            child: const Icon(Icons.refresh),
          ),
        ),
      );
    }
    return child;
  }

  late final gridDelegate = SliverGridDelegateWithExtentAndRatio(
    mainAxisSpacing: Style.cardSpace,
    crossAxisSpacing: Style.cardSpace,
    maxCrossAxisExtent: Pref.recommendCardWidth,
    childAspectRatio: Style.aspectRatio,
    mainAxisExtent: MediaQuery.textScalerOf(context).scale(90),
  );

  Widget _buildBody(
    ColorScheme colorScheme,
    LoadingState<List<dynamic>?> loadingState,
  ) {
    return switch (loadingState) {
      Loading() => _buildSkeleton,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: gridDelegate,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    controller.onLoadMore();
                  }
                  if (controller.lastRefreshAt != null) {
                    if (controller.lastRefreshAt == index) {
                      return GestureDetector(
                        onTap: () => controller
                          ..animateToTop()
                          ..onRefresh(),
                        child: Card(
                          child: Container(
                            alignment: Alignment.center,
                            padding: const .symmetric(horizontal: 10),
                            child: Text(
                              '上次看到这里\n点击刷新',
                              textAlign: .center,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    final actualIndex = index > controller.lastRefreshAt!
                        ? index - 1
                        : index;
                    return VideoCardV(
                      videoItem: response[actualIndex],
                      onRemove: () {
                        if (controller.lastRefreshAt != null &&
                            actualIndex < controller.lastRefreshAt!) {
                          controller.lastRefreshAt =
                              controller.lastRefreshAt! - 1;
                        }
                        controller.loadingState
                          ..value.data!.removeAt(actualIndex)
                          ..refresh();
                      },
                    );
                  } else {
                    return VideoCardV(
                      videoItem: response[index],
                      onRemove: () => controller.loadingState
                        ..value.data!.removeAt(index)
                        ..refresh(),
                    );
                  }
                },
                itemCount: controller.lastRefreshAt != null
                    ? response.length + 1
                    : response.length,
              )
            : HttpError(onReload: controller.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: controller.onReload,
      ),
    };
  }

  Widget get _buildSkeleton => SliverGrid(
    gridDelegate: gridDelegate,
    delegate: const SliverSingleChildDelegate(
      count: 10,
      child: VideoCardVSkeleton(),
    ),
  );
}
