import 'dart:io';

import 'package:flutter/services.dart';

/// 调起 Android 系统安装器的桥接层。
///
/// 原生侧实现见 `android/app/src/main/kotlin/com/example/piliplus/MainActivity.kt`，
/// 通过 `FileProvider` 把 App 私有目录里的 APK 暴露给系统安装器。
///
/// 非 Android 平台调用任意方法都会抛出 [UnsupportedError]。
abstract final class ApkInstaller {
  static const MethodChannel _channel = MethodChannel(
    'piliplus/apk_installer',
  );

  /// 当前是否已被允许「安装未知应用」。
  ///
  /// Android 8.0 以下始终返回 true（无需授权）。
  static Future<bool> canInstall() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('canInstall') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// 跳到「安装未知应用」授权页。
  static Future<void> openInstallSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('openInstallSettings');
    } on PlatformException {
      // 部分定制 ROM 没有该设置页，忽略即可
    } on MissingPluginException {
      // ditto
    }
  }

  /// 调起系统安装器。
  ///
  /// 返回 false 表示文件不存在或 intent 无法启动。
  static Future<bool> install(String apkPath) async {
    if (!Platform.isAndroid) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('install', {
        'path': apkPath,
      });
      return ok ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
