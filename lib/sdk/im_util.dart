import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

class ImUtil {
  // md5 加密
  static String generateMd5(String data) {
    var content = const Utf8Encoder().convert(data);
    var digest = md5.convert(content);
    return digest.toString();
  }

  static Future<Uint8List?> readFileFromCache(String fileName) async {
    Directory dir = await fileCacheDir();
    final filePath = "${dir.path}/$fileName";
    File file = File(filePath);
    if (!file.existsSync()) return null;
    return await file.readAsBytes();
  }

  static Future<String?> writeFileToCache(
      String fileName, List<int>? bytes) async {
    if (bytes == null) return null;
    Directory dir = await fileCacheDir();
    final filePath = "${dir.path}/$fileName";
    File file = File(filePath);
    await file.writeAsBytes(bytes);

    return filePath;
  }

  static Future<Directory> fileCacheDir() async {
    String cachePath = '${(await getTemporaryDirectory()).path}/rockChatCache';
    Directory cacheDir = Directory(cachePath);
    bool isCacheDirExists = await cacheDir.exists();
    if (!isCacheDirExists) {
      await cacheDir.create();
    }
    return cacheDir;
  }

  static String extName(String fileName) {
    var extName =
        fileName.substring(fileName.lastIndexOf('.') + 1, fileName.length);
    return extName;
  }

  static String md5FileName(String uri) {
    String fileName = generateMd5(uri) + '.' + extName(uri);
    return fileName;
  }

  static Future<void> clearFileCache() async {
    Directory dir = await fileCacheDir();
    await dir.delete();
  }
}
