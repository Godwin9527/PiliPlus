import 'dart:io';

import 'package:PiliPlus/http/browser_ua.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/// 应用内下载 APK。
///
/// 特点：
/// - **镜像优先**：按传入的 [urls] 顺序依次尝试（调用方把镜像地址放在最前）；
/// - **断点续传**：保留 `.part` 残片，重试时用 `Range` 头续传；
/// - **单个源重试 2 次**，全部源失败才抛出异常；
/// - 支持通过 [CancelToken] 中途取消。
abstract final class ApkDownloader {
  /// 下载目录：`<cache>/update`。
  ///
  /// 放在 App 私有缓存目录，由 `FileProvider`（`cache-path`）暴露给系统安装器，
  /// 因此**不需要任何存储权限**。
  static Future<Directory> _workDir() async {
    final base = await getTemporaryDirectory();
    final dir = Directory('${base.path}/update');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 下载 [fileName]，返回落盘的 APK 文件。
  ///
  /// [onProgress] 的 `total` 在服务端未返回 `Content-Length` 时为 -1。
  static Future<File> download({
    required List<String> urls,
    required String fileName,
    required void Function(int received, int total) onProgress,
    CancelToken? cancelToken,
  }) async {
    final dir = await _workDir();
    final safeName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final part = File('${dir.path}/$safeName.part');
    final target = File('${dir.path}/$safeName');

    if (await target.exists()) {
      await target.delete();
    }

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 60),
        followRedirects: true,
        maxRedirects: 8,
        validateStatus: (s) => s != null && s >= 200 && s < 400,
      ),
    );

    Object? lastError;
    try {
      for (final url in urls) {
        for (var attempt = 0; attempt < 2; attempt++) {
          try {
            await _fetch(
              dio: dio,
              url: url,
              part: part,
              onProgress: onProgress,
              cancelToken: cancelToken,
            );
            if (await target.exists()) {
              await target.delete();
            }
            return await part.rename(target.path);
          } on DioException catch (e) {
            if (CancelToken.isCancel(e)) rethrow;
            // 416：残片长度已超出远端文件（换过发布包 / 远端截断），丢掉残片重来
            if (e.response?.statusCode == 416) {
              try {
                if (await part.exists()) await part.delete();
              } catch (_) {
                // 删除失败时下一次仍会以 write 模式覆盖
              }
            }
            lastError = e;
          } catch (e) {
            lastError = e;
          }
        }
      }
    } finally {
      dio.close(force: true);
    }

    throw DownloadException(
      lastError == null ? '下载失败' : '下载失败：$lastError',
    );
  }

  static Future<void> _fetch({
    required Dio dio,
    required String url,
    required File part,
    required void Function(int received, int total) onProgress,
    CancelToken? cancelToken,
  }) async {
    final existing = await part.exists() ? await part.length() : 0;

    final response = await dio.get<ResponseBody>(
      url,
      options: Options(
        responseType: ResponseType.stream,
        headers: {
          'user-agent': BrowserUa.mob,
          if (existing > 0) 'range': 'bytes=$existing-',
        },
      ),
      cancelToken: cancelToken,
    );

    final statusCode = response.statusCode ?? 0;
    final body = response.data;
    if (body == null) {
      throw const DownloadException('响应为空');
    }

    final contentLength =
        int.tryParse(
          response.headers.value(Headers.contentLengthHeader) ?? '',
        ) ??
        -1;

    // 服务端不支持 Range（返回 200 而非 206）时只能整份重下，
    // 否则 append 会把文件写坏。
    var start = existing;
    if (start > 0 && statusCode != 206) {
      start = 0;
      await part.delete();
    }

    final total = contentLength > 0 ? start + contentLength : -1;
    var received = start;
    onProgress(received, total);

    final sink = part.openWrite(
      mode: start > 0 ? FileMode.append : FileMode.write,
    );
    try {
      await for (final chunk in body.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress(received, total);
      }
    } finally {
      await sink.flush();
      await sink.close();
    }

    if (total > 0 && received != total) {
      throw DownloadException('文件不完整（$received / $total 字节）');
    }
    if (received == 0) {
      throw const DownloadException('下载内容为空');
    }
  }

  /// 清理下载目录（安装完成或用户放弃更新后调用）。
  static Future<void> clean() async {
    try {
      final dir = await _workDir();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {
      // 清理失败不影响主流程
    }
  }
}

class DownloadException implements Exception {
  final String message;
  const DownloadException(this.message);

  @override
  String toString() => message;
}
