import 'dart:io' show Platform;

import 'package:PiliPlus/build_config.dart';
import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/http/api.dart';
import 'package:PiliPlus/http/browser_ua.dart';
import 'package:PiliPlus/http/init.dart';
import 'package:PiliPlus/utils/accounts/account.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:material_ui/material_ui.dart';

abstract final class Update {
  /// GitHub 加速镜像前缀（国内网络环境用）。
  ///
  /// 直连 `api.github.com` 失败时（典型原因：DNS 污染把域名解析到错误 IP），
  /// 会把原始 URL 直接拼在本前缀之后重试，例如：
  /// `https://gh-proxy.com/https://api.github.com/repos/OWNER/REPO/releases`
  ///
  /// 可通过构建参数 `pili.mirror` 覆盖；置为空字符串则禁用镜像回退。
  static const String _mirror = String.fromEnvironment(
    'pili.mirror',
    defaultValue: 'https://gh-proxy.com/',
  );

  /// 本次检查更新中实际可用的地址前缀（空串表示直连 GitHub）。
  /// 供 [onDownload] 复用，避免下载时再踩同样的网络问题。
  static String _downloadPrefix = '';

  /// 更新检查的候选地址：直连优先，镜像兜底。
  static List<(String, String)> get _sources => [
    ('', Api.latestApp),
    if (_mirror.isNotEmpty) (_mirror, '$_mirror${Api.latestApp}'),
  ];

  /// 依次尝试各候选地址，返回最新一个 release 的 JSON；全部失败返回 null。
  static Future<Map?> _fetchLatestRelease() async {
    for (final (prefix, url) in _sources) {
      try {
        final res = await Request().get(
          url,
          options: Options(
            headers: {'user-agent': BrowserUa.mob},
            extra: {'account': const NoAccount()},
          ),
        );
        final resData = res.data;
        if (resData is List && resData.isNotEmpty && resData[0] is Map) {
          _downloadPrefix = prefix;
          return resData[0] as Map;
        }
      } catch (e) {
        if (kDebugMode) debugPrint('check update failed via "$url": $e');
      }
    }
    return null;
  }

  // 检查更新
  static Future<void> checkUpdate([bool isAuto = true]) async {
    if (kDebugMode) return;
    SmartDialog.dismiss();

    final data = await _fetchLatestRelease();
    if (data == null) {
      if (!isAuto) {
        SmartDialog.showToast('检查更新失败，请检查网络或代理设置');
      }
      return;
    }

    try {
      final int latest =
          DateTime.parse(data['created_at']).millisecondsSinceEpoch ~/ 1000;
      if (BuildConfig.buildTime >= latest) {
        if (!isAuto) {
          SmartDialog.showToast('已是最新版本');
        }
      } else {
        SmartDialog.show(
          animationType: SmartAnimationType.centerFade_otherSlide,
          builder: (context) {
            final colorScheme = ColorScheme.of(context);
            Widget downloadBtn(
              String text, {
              String? ext,
              bool mirror = false,
            }) => TextButton(
              onPressed: () =>
                  onDownload(data, ext: ext, forceMirror: mirror),
              child: Text(text),
            );
            return AlertDialog(
              title: const Text('🎉 发现新版本 '),
              content: SizedBox(
                height: 280,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data['tag_name']}',
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 8),
                      Text('${data['body']}'),
                      TextButton(
                        onPressed: () => PageUtils.launchURL(
                          '${Constants.sourceCodeUrl}/commits/main',
                        ),
                        child: Text(
                          "点此查看完整更新(即commit)内容",
                          style: TextStyle(color: colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (isAuto)
                  TextButton(
                    onPressed: () {
                      SmartDialog.dismiss();
                      GStorage.setting.put(SettingBoxKey.autoUpdate, false);
                    },
                    child: Text(
                      '不再提醒',
                      style: TextStyle(color: colorScheme.outline),
                    ),
                  ),
                TextButton(
                  onPressed: SmartDialog.dismiss,
                  child: Text(
                    '取消',
                    style: TextStyle(color: colorScheme.outline),
                  ),
                ),
                if (Platform.isWindows) ...[
                  downloadBtn('zip', ext: 'zip'),
                  downloadBtn('exe', ext: 'exe'),
                ] else if (Platform.isLinux) ...[
                  downloadBtn('rpm', ext: 'rpm'),
                  downloadBtn('deb', ext: 'deb'),
                  downloadBtn('targz', ext: 'tar.gz'),
                ] else ...[
                  downloadBtn('Github'),
                  // 直连下载失败（如国内 DNS 污染）时的备选入口
                  if (_mirror.isNotEmpty) downloadBtn('镜像', mirror: true),
                ],
              ],
            );
          },
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('failed to check update: $e');
    }
  }

  // 下载适用于当前系统的安装包
  //
  // [forceMirror] 为 true 时强制走镜像前缀（用于直连下载失败的手动兜底）。
  // 否则复用 [checkUpdate] 中探测到的可用前缀：直连可用就走直连，否则走镜像。
  static Future<void> onDownload(
    Map data, {
    String? ext,
    bool forceMirror = false,
  }) async {
    SmartDialog.dismiss();
    final prefix = forceMirror && _mirror.isNotEmpty ? _mirror : _downloadPrefix;
    try {
      void download(String plat) {
        if (data['assets'].isNotEmpty) {
          for (Map<String, dynamic> i in data['assets']) {
            final String name = i['name'];
            if (name.contains(plat) &&
                (ext == null || ext.isEmpty ? true : name.endsWith(ext))) {
              PageUtils.launchURL('$prefix${i['browser_download_url']}');
              return;
            }
          }
          throw UnsupportedError('platform not found: $plat');
        }
      }

      if (Platform.isAndroid) {
        // 获取设备信息
        AndroidDeviceInfo androidInfo = await DeviceInfoPlugin().androidInfo;
        // [arm64-v8a]
        download(androidInfo.supportedAbis.first);
      } else {
        download(Platform.operatingSystem);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('download error: $e');
      PageUtils.launchURL('$prefix${Constants.sourceCodeUrl}/releases/latest');
    }
  }
}
