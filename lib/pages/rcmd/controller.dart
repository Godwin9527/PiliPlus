import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/models/common/rcmd_source.dart';
import 'package:PiliPlus/models/model_video.dart';
import 'package:PiliPlus/pages/common/common_controller.dart'
    show RefreshImplMixin;
import 'package:PiliPlus/pages/common/common_list_controller.dart';
import 'package:PiliPlus/utils/extension/scroll_controller_ext.dart';
import 'package:PiliPlus/utils/storage_pref.dart';

class RcmdController extends CommonListController with RefreshImplMixin {
  late bool enableSaveLastData = Pref.enableSaveLastData;

  /// 可在设置页切换后立即生效，无需重启
  RcmdSource rcmdSource = Pref.rcmdSource;

  int? lastRefreshAt;
  late bool savedRcmdTip = Pref.savedRcmdTip;

  // ------- 本 fork 定制：会话内去重 + 刷新保底条数（见 CUSTOMIZATION.md 3.9） -------

  /// 本次运行期间出现过的 bvid，用于过滤重复推荐。
  final Set<String> _shown = <String>{};

  /// [_shown] 上限，超出按插入顺序淘汰最早的，避免无限增长
  static const int _maxShown = 3000;

  /// 下拉刷新后至少凑够多少条「没出现过」的视频
  static const int _minRefreshCount = 20;

  /// 刷新时最多请求几次（含首次），防止极端情况一直拉
  static const int _maxFetchTimes = 6;

  /// 本轮刷新累计新增（去重后）的条数
  int _newSinceRefresh = 0;

  /// 过滤掉已出现过的条目，并把剩余条目的 bvid 记入 [_shown]。
  int _dedupe(List dataList) {
    if (dataList.isEmpty) return 0;
    dataList.removeWhere((e) {
      final bvid = e is BaseSimpleVideoItemModel ? e.bvid : null;
      return bvid != null && bvid.isNotEmpty && _shown.contains(bvid);
    });
    for (final e in dataList) {
      final bvid = e is BaseSimpleVideoItemModel ? e.bvid : null;
      if (bvid == null || bvid.isEmpty) continue;
      if (_shown.length >= _maxShown) _shown.remove(_shown.first);
      _shown.add(bvid);
    }
    return dataList.length;
  }

  @override
  bool get isEnd => false;

  @override
  void onInit() {
    super.onInit();
    page = 0;
    queryData();
  }

  @override
  Future<LoadingState> customGetData() {
    return switch (rcmdSource) {
      RcmdSource.app => VideoHttp.rcmdVideoListApp(freshIdx: page),
      // 桌面端：与官方 Windows 客户端一致，每次请求 30 条
      RcmdSource.desktop => VideoHttp.rcmdVideoList(
        freshIdx: page,
        ps: 30,
        desktop: true,
      ),
      RcmdSource.web => VideoHttp.rcmdVideoList(freshIdx: page, ps: 20),
    };
  }

  @override
  bool handleError(String? errMsg) {
    return enableSaveLastData;
  }

  @override
  void handleListResponse(List dataList) {
    // 先去掉本轮运行中已经出现过的视频
    final added = _dedupe(dataList);
    _newSinceRefresh += added;

    if (enableSaveLastData && page == 0) {
      if (loadingState.value case Success(:final response)) {
        if (response != null && response.isNotEmpty) {
          if (savedRcmdTip) {
            lastRefreshAt = dataList.length;
          }
          if (response.length > 200) {
            dataList.addAll(response.take(50));
          } else {
            dataList.addAll(response);
          }
        }
      }
    } else if (page == 0 && dataList.isEmpty) {
      // 首次刷新回来的全是重复项（已被去重清空）→ 不要把列表清空成白屏，
      // 继续显示现有内容，后面由补拉逻辑再尝试获取新视频
      if (loadingState.value case Success(:final response)) {
        if (response != null && response.isNotEmpty) dataList.addAll(response);
      }
    }
  }

  @override
  Future<void> onRefresh() async {
    page = 0;
    isEnd = false;
    _newSinceRefresh = 0;
    await queryData();
    if (loadingState.value is! Success) return;

    // 接口常只回几条，导致「刷一下就到底」。这里补拉到保底条数。
    var times = 1;
    while (_newSinceRefresh < _minRefreshCount && times < _maxFetchTimes) {
      final before = _newSinceRefresh;
      await queryData(false);
      times++;
      // 这次没带来任何新东西 → 再拉也是白费，直接停
      if (_newSinceRefresh <= before) break;
    }

    if (enableSaveLastData && savedRcmdTip && _newSinceRefresh > 0) {
      lastRefreshAt = _newSinceRefresh;
    }
  }

  void toTopAndRefresh() {
    scrollController.jumpToTop();
    showRefresh();
  }
}
