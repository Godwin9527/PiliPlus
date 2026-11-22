import 'package:PiliPlus/utils/apk_downloader.dart';
import 'package:PiliPlus/utils/apk_installer.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:material_ui/material_ui.dart';

/// 应用内「下载 APK → 调起系统安装器」的进度弹窗。
///
/// 仅在 Android 上使用；桌面端仍走浏览器下载。
class UpdateDownloadDialog extends StatefulWidget {
  const UpdateDownloadDialog({
    super.key,
    required this.urls,
    required this.fileName,
    required this.fallbackUrl,
  });

  /// 候选下载地址，**按优先级排列**（调用方把镜像放最前）。
  final List<String> urls;

  /// 保存的文件名（取自 release asset 的 name）。
  final String fileName;

  /// 兜底：用系统浏览器下载的地址。
  final String fallbackUrl;

  @override
  State<UpdateDownloadDialog> createState() => _UpdateDownloadDialogState();
}

enum _Stage { downloading, needPermission, launched, failed }

class _UpdateDownloadDialogState extends State<UpdateDownloadDialog> {
  _Stage _stage = _Stage.downloading;

  int _received = 0;
  int _total = -1;
  int _speed = 0;
  String? _error;
  String? _apkPath;

  CancelToken? _cancelToken;
  DateTime _ticker = DateTime.now();
  int _tickBytes = 0;
  DateTime _lastPaint = DateTime.now();

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _stage = _Stage.downloading;
      _received = 0;
      _total = -1;
      _speed = 0;
      _error = null;
      _apkPath = null;
      _cancelToken = CancelToken();
    });
    _ticker = DateTime.now();
    _tickBytes = 0;

    try {
      final file = await ApkDownloader.download(
        urls: widget.urls,
        fileName: widget.fileName,
        cancelToken: _cancelToken,
        onProgress: _onProgress,
      );
      if (!mounted) return;
      _apkPath = file.path;
      await _install();
    } on DioException catch (e) {
      if (!mounted) return;
      if (CancelToken.isCancel(e)) return;
      setState(() {
        _stage = _Stage.failed;
        _error = '下载中断：${e.message ?? e.type.name}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.failed;
        _error = '$e';
      });
    }
  }

  void _onProgress(int received, int total) {
    if (!mounted) return;
    final now = DateTime.now();
    // 每 120ms 刷新一次，避免 chunk 级 setState 拖慢下载
    if (now.difference(_lastPaint).inMilliseconds < 120) return;
    _lastPaint = now;

    final dt = now.difference(_ticker).inMilliseconds;
    var speed = _speed;
    if (dt >= 400) {
      speed = ((received - _tickBytes) * 1000 / dt).round();
      _ticker = now;
      _tickBytes = received;
    }
    setState(() {
      _received = received;
      if (total > 0) _total = total;
      _speed = speed;
    });
  }

  Future<void> _install() async {
    final path = _apkPath;
    if (path == null) {
      setState(() {
        _stage = _Stage.failed;
        _error = '安装包已丢失，请重新下载';
      });
      return;
    }
    final allowed = await ApkInstaller.canInstall();
    if (!mounted) return;
    if (!allowed) {
      setState(() => _stage = _Stage.needPermission);
      return;
    }
    final launched = await ApkInstaller.install(path);
    if (!mounted) return;
    setState(() {
      _stage = launched ? _Stage.launched : _Stage.failed;
      if (!launched) {
        _error = '无法调起系统安装器。文件已保存到：\n$path';
      }
    });
  }

  static String _fmtSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  String get _title => switch (_stage) {
    _Stage.downloading => '正在下载更新',
    _Stage.needPermission => '需要安装权限',
    _Stage.launched => '安装器已打开',
    _Stage.failed => '下载失败',
  };

  Widget _content(ColorScheme colorScheme) => switch (_stage) {
    _Stage.downloading => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: _total > 0 ? (_received / _total).clamp(0.0, 1.0) : null,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _total > 0
                  ? '${(_received / _total * 100).toStringAsFixed(0)}%'
                  : '下载中',
              style: const TextStyle(fontSize: 13),
            ),
            Text(
              _total > 0
                  ? '${_fmtSize(_received)} / ${_fmtSize(_total)}'
                  : _fmtSize(_received),
              style: TextStyle(fontSize: 13, color: colorScheme.outline),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _speed > 0 ? '${_fmtSize(_speed)}/s' : '正在连接…',
          style: TextStyle(fontSize: 12, color: colorScheme.outline),
        ),
        const SizedBox(height: 8),
        Text(
          '请保持 App 在前台，切到后台或锁屏会暂停下载',
          style: TextStyle(fontSize: 11, color: colorScheme.outline),
        ),
      ],
    ),
    _Stage.needPermission => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('系统安全设置要求手动允许一次「安装未知应用」。'),
        const SizedBox(height: 8),
        Text(
          '点下面的按钮跳到设置页，打开「允许安装未知应用」后返回，再点「继续安装」。',
          style: TextStyle(fontSize: 12, color: colorScheme.outline),
        ),
      ],
    ),
    _Stage.launched => const Text(
      '系统安装器已打开，请点击「安装」完成更新。\n\n'
      '安装完成后 App 会自动重启为新版本。',
    ),
    _Stage.failed => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_error ?? '未知错误'),
        const SizedBox(height: 8),
        Text(
          '已尝试镜像与直连地址。可重试，或用浏览器下载。',
          style: TextStyle(fontSize: 12, color: colorScheme.outline),
        ),
      ],
    ),
  };

  List<Widget> _actions(ColorScheme colorScheme) => switch (_stage) {
    _Stage.downloading => <Widget>[
      TextButton(
        onPressed: () {
          _cancelToken?.cancel();
          SmartDialog.dismiss();
        },
        child: Text('取消', style: TextStyle(color: colorScheme.outline)),
      ),
    ],
    _Stage.needPermission => <Widget>[
      TextButton(
        onPressed: () => ApkInstaller.openInstallSettings(),
        child: const Text('去设置'),
      ),
      FilledButton(
        onPressed: _install,
        child: const Text('继续安装'),
      ),
    ],
    _Stage.launched => <Widget>[
      FilledButton(
        onPressed: SmartDialog.dismiss,
        child: const Text('关闭'),
      ),
    ],
    _Stage.failed => <Widget>[
      TextButton(
        onPressed: () {
          SmartDialog.dismiss();
          PageUtils.launchURL(widget.fallbackUrl);
        },
        child: Text(
          '用浏览器下载',
          style: TextStyle(color: colorScheme.outline),
        ),
      ),
      FilledButton(
        onPressed: _start,
        child: const Text('重试'),
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return AlertDialog(
      title: Text(_title),
      content: SizedBox(width: 320, child: _content(colorScheme)),
      actions: _actions(colorScheme),
    );
  }
}
