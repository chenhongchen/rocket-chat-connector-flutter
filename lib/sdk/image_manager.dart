import 'dart:convert';
import 'dart:typed_data';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/message_attachment.dart';
import 'package:rocket_chat_connector_flutter/sdk/avatar.dart';
import 'package:rocket_chat_connector_flutter/sdk/im_util.dart';
import 'package:rocket_chat_connector_flutter/services/message_service.dart';
import 'package:rocket_chat_connector_flutter/services/http_service.dart'
    as rocket_http_service;
import 'package:rocket_chat_connector_flutter/services/room_service.dart';
import 'package:rocket_chat_connector_flutter/services/user_service.dart';
import 'package:synchronized/synchronized.dart';

class ImageManager {
  final Map<String, _ImageMemory> _imageMemories = <String, _ImageMemory>{};
  final int _cacheMaxMemoryNum = 30;

  final Lock _freeUpMemoryLock = Lock();
  final Lock _imAvatarLock = Lock();

  // 已网络加载的头像的key
  final List _loadedAvatarKeys = [];

  /// 获取图片
  Future<Uint8List?> getImage(
      MessageAttachment attachment,
      bool rawImage,
      rocket_http_service.HttpService _rocketHttpService,
      Authentication _authentication) async {
    String fileUri =
        (rawImage ? attachment.titleLink : attachment.imageUrl) ?? '';
    if (fileUri.isEmpty) return null;
    String fileName = ImUtil.md5FileName(fileUri);
    Uint8List? uList = _imageMemories[fileName]?.image;
    if (uList == null) {
      uList = await ImUtil.readFileFromCache(fileName);
      if (uList != null) {
        _addImageMemories(fileName: fileName, image: uList);
      }
    }
    if (uList == null) {
      uList = await MessageService(_rocketHttpService)
          .getFile(fileUri, _authentication);
      _addImageMemories(fileName: fileName, image: uList);
      ImUtil.writeFileToCache(fileName, uList);
    }
    return uList;
  }

  /// 获取内存中的图片
  Uint8List? getImageFromMemory(
    MessageAttachment attachment,
    bool rawImage,
  ) {
    String fileUri =
        (rawImage ? attachment.titleLink : attachment.imageUrl) ?? '';
    if (fileUri.isEmpty) return null;
    String fileName = ImUtil.md5FileName(fileUri);
    Uint8List? uList = _imageMemories[fileName]?.image;
    return uList;
  }

  /// 获取room 或者 user 头像
  /// rid 和 username 不能全为空
  Future<Avatar?> getAvatar(
    rocket_http_service.HttpService _rocketHttpService,
    Authentication _authentication, {
    String? roomId,
    String? username,
    int? size,
  }) async {
    if (roomId == null && username == null) return null;
    String key =
        (roomId ?? username)! + (size != null && size > 0 ? '_size$size' : '');
    Uint8List? uList = _imageMemories[key]?.image;
    if (uList == null && _loadedAvatarKeys.contains(key)) {
      uList = await ImUtil.readFileFromCache(key);
      _addImageMemories(fileName: key, image: uList);
    }
    if (uList == null) {
      uList = await RoomService(_rocketHttpService)
          .getAvatar(roomId, username, _authentication, size: size);
      _addImageMemories(fileName: key, image: uList);
      if (!_loadedAvatarKeys.contains(key)) {
        _loadedAvatarKeys.add(key);
      }
      await ImUtil.writeFileToCache(key, uList);
    }
    Avatar? avatar;
    if (uList != null) {
      avatar = Avatar();
      try {
        avatar.svg = Utf8Decoder().convert(uList);
      } catch (e) {
        avatar.image = uList;
      }
    }
    return avatar;
  }

  /// 获取内存中的头像
  /// rid 和 username 不能全为空
  Avatar? getAvatarFromMemory({
    String? roomId,
    String? username,
    int? size,
  }) {
    if (roomId == null && username == null) return null;
    String key =
        (roomId ?? username)! + (size != null && size > 0 ? '_size$size' : '');
    Uint8List? uList = _imageMemories[key]?.image;
    Avatar? avatar;
    if (uList != null) {
      avatar = Avatar();
      try {
        avatar.svg = Utf8Decoder().convert(uList);
      } catch (e) {
        avatar.image = uList;
      }
    }
    return avatar;
  }

  /// 通过uid获取头像
  Future<Avatar?> getAvatarWithUid(
    String? userId,
    rocket_http_service.HttpService _rocketHttpService,
    Authentication _authentication,
  ) async {
    if (userId == null) return null;
    Uint8List? uList = _imageMemories[userId]?.image;
    if (uList == null && _loadedAvatarKeys.contains(userId)) {
      uList = await ImUtil.readFileFromCache(userId);
      _addImageMemories(fileName: userId, image: uList);
    }
    if (uList == null) {
      // 确保只有一个线程可以访问该代码块
      await _imAvatarLock.synchronized(() async {
        uList = _imageMemories[userId]?.image;
        if (uList == null && _loadedAvatarKeys.contains(userId)) {
          uList = await ImUtil.readFileFromCache(userId);
          _addImageMemories(fileName: userId, image: uList);
        }
        if (uList == null) {
          uList = await UserService(_rocketHttpService)
              .getAvatarWithUid(userId, _authentication);
          _addImageMemories(fileName: userId, image: uList);
          if (!_loadedAvatarKeys.contains(userId)) {
            _loadedAvatarKeys.add(userId);
          }
          await ImUtil.writeFileToCache(userId, uList);
        }
      });
    }
    Avatar? avatar;
    if (uList != null) {
      avatar = Avatar();
      try {
        avatar.svg = Utf8Decoder().convert(uList!);
      } catch (e) {
        avatar.image = uList;
      }
    }
    return avatar;
  }

  /// 通过用户名获取头像
  Future<Avatar?> getAvatarWithUsername(
    String? username,
    rocket_http_service.HttpService _rocketHttpService,
    Authentication _authentication,
  ) async {
    if (username == null) return null;
    Uint8List? uList = _imageMemories[username]?.image;
    if (uList == null && _loadedAvatarKeys.contains(username)) {
      uList = await ImUtil.readFileFromCache(username);
      _addImageMemories(fileName: username, image: uList);
    }
    if (uList == null) {
      // 确保只有一个线程可以访问该代码块
      await _imAvatarLock.synchronized(() async {
        uList = _imageMemories[username]?.image;
        if (uList == null && _loadedAvatarKeys.contains(username)) {
          uList = await ImUtil.readFileFromCache(username);
          _addImageMemories(fileName: username, image: uList);
        }
        if (uList == null) {
          uList = await UserService(_rocketHttpService)
              .getAvatarWithUsername(username, _authentication);
          _addImageMemories(fileName: username, image: uList);
          if (!_loadedAvatarKeys.contains(username)) {
            _loadedAvatarKeys.add(username);
          }
          await ImUtil.writeFileToCache(username, uList);
        }
      });
    }
    Avatar? avatar;
    if (uList != null) {
      avatar = Avatar();
      try {
        avatar.svg = Utf8Decoder().convert(uList!);
      } catch (e) {
        avatar.image = uList;
      }
    }
    return avatar;
  }

  void clear() {
    _imageMemories.clear();
  }

  _addImageMemories({required String fileName, Uint8List? image}) {
    if (image == null) return;
    _imageMemories[fileName] = _ImageMemory(image: image);
    _freeUpMemory();
  }

  _freeUpMemory() async {
    if (_imageMemories.length <= _cacheMaxMemoryNum) return;
    // 确保只有一个线程可以访问该代码块
    await _freeUpMemoryLock.synchronized(() async {
      if (_imageMemories.length <= _cacheMaxMemoryNum) return;
      // 按index升序排序
      List<MapEntry<String, _ImageMemory>> list =
          _imageMemories.entries.toList();
      list.sort((a, b) => a.value.time.compareTo(b.value.time));
      int le = list.length - _cacheMaxMemoryNum;
      if (le > 0) {
        for (int i = 0; i < le; i++) {
          _imageMemories.remove(list[i].key);
        }
      }
    });
  }
}

class _ImageMemory {
  final Uint8List image;
  final int time = DateTime.now().microsecondsSinceEpoch;

  _ImageMemory({required this.image});
}
