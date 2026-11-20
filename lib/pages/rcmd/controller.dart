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

  /// 刷新时最多请求几次，防止极端情况一直拉
  static const int _maxFetchTimes = 6;

  @override
  bool get isEnd => false;

  @override
  void onInit() {
    super.onInit();
    page = 0;
    queryData();
  }

  /// 请求指定 idx 的一页推荐（idx == 0 时接口按「下拉刷新」处理）
  Future<List<dynamic>?> _fetchPage(int idx) async {
    final LoadingState res = await switch (rcmdSource) {
      RcmdSource.app => VideoHttp.rcmdVideoListApp(freshIdx: idx),
      // 桌面端：与官方 Windows 客户端一致，每次请求 30 条
      RcmdSource.desktop => VideoHttp.rcmdVideoList(
        freshIdx: idx,
        ps: 30,
        desktop: true,
      ),
      RcmdSource.web => VideoHttp.rcmdVideoList(freshIdx: idx, ps: 20),
    };
    if (res is Success) {
      final data = res.response;
      if (data is List) return data;
    }
    return null;
  }

  /// 把 [list] 中没出现过的条目收进 [sink]，返回新增条数
  int _collect(List list, List<dynamic> sink) {
    var added = 0;
    for (final e in list) {
      final String? bvid = e is BaseSimpleVideoItemModel ? e.bvid : null;
      if (bvid != null && bvid.isNotEmpty) {
        if (_shown.contains(bvid)) continue;
        if (_shown.length >= _maxShown) _shown.remove(_shown.first);
        _shown.add(bvid);
      }
      sink.add(e);
      added++;
    }
    return added;
  }

  /// 就地过滤掉已经出现过的条目（供首次加载与上拉加载使用）
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

  /// 把「新内容 + 旧内容」整体写回列表。新内容永远在最前面。
  void _publish(List<dynamic> collected, List<dynamic>? old) {
    final merged = List<dynamic>.of(collected);
    if (old != null && old.isNotEmpty) merged.addAll(old);
    loadingState.value = Success(merged);
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
    // 首次加载 / 上拉加载：先去掉本次运行中已经出现过的视频
    _dedupe(dataList);

    if (page == 0 && dataList.isEmpty) {
      // 拉回来的全是重复项 → 别把列表清空成白屏，继续显示现有内容
      if (loadingState.value case Success(:final response)) {
        if (response != null && response.isNotEmpty) dataList.addAll(response);
      }
    }
  }

  @override
  Future<void> onRefresh() async {
    isEnd = false;
    lastRefreshAt = null;

    // 开启「保留首页推荐刷新」时，旧内容接在新内容后面
    List<dynamic>? old;
    if (enableSaveLastData && loadingState.value is Success) {
      final data = (loadingState.value as Success).response;
      if (data is List && data.isNotEmpty) {
        old = data.length > 200 ? data.take(50).toList() : data;
      }
    }

    final collected = <dynamic>[];
    isLoading = true;
    try {
      var idx = 0; // 当前请求的 idx，0 表示重新拉一批
      var requests = 0;
      var idle = 0; // 连续无新增的请求数
      var emptyPull = 0; // 全新一批也无新增的次数
      while (collected.length < _minRefreshCount && requests < _maxFetchTimes) {
        final list = await _fetchPage(idx);
        requests++;
        // 接口报错：保留已拿到的部分，不整页失败
        if (list == null) break;

        if (_collect(list, collected) > 0) {
          idle = 0;
          emptyPull = 0;
          idx++;
          // 已有内容先上屏，避免长时间只有转圈动画
          _publish(collected, old);
        } else if (idx == 0) {
          // 全新一批也没新内容：允许再试一次，仍为空则判定推荐池见底
          if (++emptyPull >= 2) break;
        } else {
          idle++;
          if (idle >= 2) {
            // 翻页连续空转 → 换一轮「下拉刷新」要一批新的
            idx = 0;
            idle = 0;
          } else {
            idx++;
          }
        }
      }
      page = idx == 0 ? 1 : idx; // 后续上拉从这里接着翻
    } finally {
      isLoading = false;
    }

    if (collected.isNotEmpty) {
      _publish(collected, old);
      lastRefreshAt = (enableSaveLastData && savedRcmdTip)
          ? collected.length
          : null;
    } else if (loadingState.value is! Success) {
      loadingState.value = Success(<dynamic>[]);
    }
  }

  void toTopAndRefresh() {
    scrollController.jumpToTop();
    showRefresh();
  }
}
