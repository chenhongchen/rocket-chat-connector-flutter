import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/filters/room_counters_filter.dart';
import 'package:rocket_chat_connector_flutter/models/filters/room_history_filter.dart';
import 'package:rocket_chat_connector_flutter/models/message.dart';
import 'package:rocket_chat_connector_flutter/models/new/channel_new.dart';
import 'package:rocket_chat_connector_flutter/models/new/room_new.dart';
import 'package:rocket_chat_connector_flutter/models/new/user_new.dart';
import 'package:rocket_chat_connector_flutter/models/response/message_new_response.dart';
import 'package:rocket_chat_connector_flutter/models/response/room_new_response.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart';
import 'package:rocket_chat_connector_flutter/models/room_counters.dart';
import 'package:rocket_chat_connector_flutter/models/room_messages.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:rocket_chat_connector_flutter/sdk/avatar.dart';
import 'package:rocket_chat_connector_flutter/sdk/im_util.dart';
import 'package:rocket_chat_connector_flutter/services/authentication_service.dart';
import 'package:rocket_chat_connector_flutter/services/channel_service.dart';
import 'package:rocket_chat_connector_flutter/services/message_service.dart';
import 'package:rocket_chat_connector_flutter/services/room_service.dart';
import 'package:rocket_chat_connector_flutter/services/user_service.dart';
import 'package:rocket_chat_connector_flutter/web_socket/notification_args.dart';
import 'package:rocket_chat_connector_flutter/web_socket/notification_type.dart';
import 'package:rocket_chat_connector_flutter/web_socket/web_socket_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:rocket_chat_connector_flutter/services/http_service.dart'
    as rocket_http_service;
import 'package:rocket_chat_connector_flutter/web_socket/notification.dart'
    as rocket_notification;
import 'package:synchronized/synchronized.dart';

class ImManager extends ChangeNotifier {
  // 工厂模式
  factory ImManager() => _getInstance();

  static ImManager get instance => _getInstance();
  static ImManager? _instance;

  ImManager._internal() {
    // 初始化
  }

  static ImManager _getInstance() {
    _instance ??= ImManager._internal();
    return _instance!;
  }

  User? me;
  ChannelManager channelManager = ChannelManager();

  bool get isLogin => _authentication != null;

  late String _webSocketUrl;
  late rocket_http_service.HttpService _rocketHttpService;

  Authentication? _authentication;

  List<MsgListener?> _msgListeners = <MsgListener?>[];

  // 已网络加载的头像的key
  final List _loadedAvatarKeys = [];

  final _msgAvatarLock = new Lock();

  final _roomAvatarLock = new Lock();

  @override
  void dispose() {
    _msgListeners.clear();
    channelManager.dispose();
    super.dispose();
  }

  /// 初始化配置
  void init(String serverUrl, String webSocketUrl) {
    _webSocketUrl = webSocketUrl;
    _rocketHttpService = rocket_http_service.HttpService(Uri.parse(serverUrl));
  }

  /// 注册用户（频繁调用会失败）
  Future<User> register(UserNew userNew) async {
    User user = await UserService(_rocketHttpService).register(userNew);
    return user;
  }

  /// 创建用户
  Future<User?> create(UserNew userNew, Authentication authentication) async {
    if (_authentication == null) return null;
    User user =
        await UserService(_rocketHttpService).create(userNew, _authentication!);
    return user;
  }

  /// 更新用户信息
  Future<User?> updateUser(String userId, UserNew userNew) async {
    if (_authentication == null) return null;
    User user = await UserService(_rocketHttpService)
        .updateUser(userId, userNew, _authentication!);
    return user;
  }

  /// 登录rock.chat
  Future<void> login(String username, String password) async {
    _authentication = await AuthenticationService(_rocketHttpService)
        .login(username, password);
    me = _authentication!.data?.me;
    channelManager.setChannel(_webSocketUrl, _authentication!, _onChannelEvent);
  }

  /// 登出rock.chat
  Future<void> logout() async {
    if (_authentication == null) return null;
    await UserService(_rocketHttpService).logout(_authentication!);
    channelManager.unsetChannel();
  }

  /// 创建channel
  Future<Room?> createChannel(String name) async {
    if (_authentication == null) return null;
    RoomNewResponse response = await ChannelService(_rocketHttpService)
        .create(ChannelNew(name: name), _authentication!);
    return response.room;
  }

  /// 创建room
  Future<Room?> createRoom(String username) async {
    if (_authentication == null) return null;
    RoomNewResponse response = await RoomService(_rocketHttpService)
        .create(RoomNew(username: username), _authentication!);
    return response.room;
  }

  /// 发送文本消息
  void sendTextMsg(String text, Room room) {
    channelManager.sendTextMsg(text, room);
  }

  /// 发送文件消息
  Future<void> sendFileMsg(String path, Room room,
      {String? description}) async {
    if (_authentication == null) return;
    final RoomService roomService = RoomService(_rocketHttpService);
    Message message = await roomService.uploadFile(room, path, _authentication!,
        description: description);
    for (MsgListener? msgListener in _msgListeners) {
      msgListener?.call(message);
      channelManager.notify();
    }
  }

  /// 获取房间列表
  Future<List<Room>?> getRooms() async {
    if (_authentication == null) return null;
    return await RoomService(_rocketHttpService).getRooms(_authentication!);
  }

  /// 获取历史消息
  Future<List<Message>?> getHistory(RoomHistoryFilter filter) async {
    if (filter.room.isChannel) {
      return getChannelHistory(filter);
    } else {
      return getRoomHistory(filter);
    }
  }

  /// 获取channel历史消息
  Future<List<Message>?> getChannelHistory(RoomHistoryFilter filter) async {
    if (_authentication == null) return null;
    RoomMessages roomMessages = await ChannelService(_rocketHttpService)
        .history(filter, _authentication!);
    return roomMessages.messages;
  }

  /// 获取room历史消息
  Future<List<Message>?> getRoomHistory(RoomHistoryFilter filter) async {
    if (_authentication == null) return null;
    RoomMessages roomMessages =
        await RoomService(_rocketHttpService).history(filter, _authentication!);
    return roomMessages.messages;
  }

  ///  获取计数
  Future<RoomCounters?> counters(RoomCountersFilter filter) async {
    if (filter.room.isChannel) {
      return channelCounters(filter);
    } else {
      return roomCounters(filter);
    }
  }

  /// 获取channel计数
  Future<RoomCounters?> channelCounters(RoomCountersFilter filter) async {
    if (_authentication == null) return null;
    RoomCounters roomCounters = await ChannelService(_rocketHttpService)
        .counters(filter, _authentication!);
    return roomCounters;
  }

  /// 获取room计数
  Future<RoomCounters?> roomCounters(RoomCountersFilter filter) async {
    if (_authentication == null) return null;
    RoomCounters roomCounters = await RoomService(_rocketHttpService)
        .counters(filter, _authentication!);
    return roomCounters;
  }

  /// 标记已读
  Future<bool> markAsRead(Room room) async {
    if (_authentication == null) return false;
    return await RoomService(_rocketHttpService)
        .markAsRead(room, _authentication!);
  }

  /// 获取文件数据
  Future<Uint8List?> getFile(String fileUri, {String? fileName}) async {
    fileName = fileName ?? ImUtil.md5FileName(fileUri);
    Uint8List? uList = await ImUtil.readFileFromCache(fileName);
    if (uList == null) {
      uList = await MessageService(_rocketHttpService)
          .getFile(fileUri, _authentication!);
      ImUtil.writeFileToCache(fileName, uList);
    }
    return uList;
  }

  /// 设置头像文件
  Future<String> setAvatarWithImageFile(String imageFileName) async {
    String str = await UserService(_rocketHttpService)
        .setAvatarWithImageFile(imageFileName, _authentication!);
    return str;
  }

  /// 设置头像url
  Future<String> setAvatarWithImageUrl(String imageUrl) async {
    String str = await UserService(_rocketHttpService)
        .setAvatarWithImageUrl(imageUrl, _authentication!);
    return str;
  }

  /// 通过uid获取头像
  Future<Avatar?> getAvatarWithUid(String? userId) async {
    if (userId == null) return null;
    Uint8List? uList;
    if (_loadedAvatarKeys.contains(userId)) {
      uList = await ImUtil.readFileFromCache(userId);
    }
    if (uList == null) {
      // 确保只有一个线程可以访问该代码块
      await _msgAvatarLock.synchronized(() async {
        if (_loadedAvatarKeys.contains(userId)) {
          uList = await ImUtil.readFileFromCache(userId);
        }
        if (uList == null) {
          uList = await UserService(_rocketHttpService)
              .getAvatarWithUid(userId, _authentication!);
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
  Future<Avatar?> getAvatarWithUsername(String? username) async {
    if (username == null) return null;
    Uint8List? uList;
    if (_loadedAvatarKeys.contains(username)) {
      uList = await ImUtil.readFileFromCache(username);
    }
    if (uList == null) {
      // 确保只有一个线程可以访问该代码块
      await _msgAvatarLock.synchronized(() async {
        if (_loadedAvatarKeys.contains(username)) {
          uList = await ImUtil.readFileFromCache(username);
        }
        if (uList == null) {
          uList = await UserService(_rocketHttpService)
              .getAvatarWithUsername(username, _authentication!);
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

  /// 获取room 头像
  /// rid 和 username 不能全为空
  Future<Avatar?> getRoomAvatar(String? rid, String? username) async {
    if (rid == null && username == null) return null;
    String key = 'room_' + (rid ?? username)!;
    Uint8List? uList;
    if (_loadedAvatarKeys.contains(key)) {
      uList = await ImUtil.readFileFromCache(key);
    }
    if (uList == null) {
      // 确保只有一个线程可以访问该代码块
      await _roomAvatarLock.synchronized(() async {
        if (_loadedAvatarKeys.contains(key)) {
          uList = await ImUtil.readFileFromCache(key);
        }
        if (uList == null) {
          uList = await RoomService(_rocketHttpService)
              .getAvatar(rid, username, _authentication!);
          if (!_loadedAvatarKeys.contains(key)) {
            _loadedAvatarKeys.add(key);
          }
          await ImUtil.writeFileToCache(key, uList);
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

  /// 刷新所有头像（调用后，在获取头像时会重新从网络加载）
  void refreshAllAvatar() {
    _loadedAvatarKeys.clear();
  }

  /// 刷新头像（调用后，在获取头像时会重新从网络加载）
  /// key 是用户id 或 用户名
  void refreshAvatar(String key) {
    _loadedAvatarKeys.remove(key);
  }

  /// 清除缓存
  Future<void> clearCache() async {
    await ImUtil.clearFileCache();
  }

  /// 添加消息监听者
  void addMsgListener(MsgListener listener) {
    _msgListeners.add(listener);
  }

  /// 移除消息监听者
  void removeMsgListener(MsgListener listener) {
    _msgListeners.remove(listener);
  }

  void _onChannelEvent(event) async {
    if (_authentication == null) return;
    var map = jsonDecode('$event');
    rocket_notification.Notification? notification =
        rocket_notification.Notification.fromMap(map);
    print(notification);
    // 收到的他人发送的消息
    if (notification.msg == NotificationType.CHANGED) {
      if (notification.fields?.args == null) return;
      for (NotificationArgs args in notification.fields!.args!) {
        if (args.payload?.id == null) continue;
        // 通过id获取消息
        try {
          MessageNewResponse? response =
              await MessageService(_rocketHttpService)
                  .getMessage(args.payload!.id!, _authentication!);
          if (response?.message == null) continue;
          for (MsgListener? msgListener in _msgListeners) {
            msgListener?.call(response!.message!);
            channelManager.notify();
          }
        } catch (e) {
          print('onChannelEvent error::$e');
        }
      }
    }
    // 收到的自己发送text消息的结果
    else if (notification.msg == NotificationType.RESULT) {
      var result = map['result'];
      if (result == null) return;
      for (MsgListener? msgListener in _msgListeners) {
        Message message = Message.fromMap(result!);
        if (message.id != null) {
          msgListener?.call(Message.fromMap(result!));
          channelManager.notify();
        }
      }
    }
  }
}

typedef MsgListener = Function(Message);

class ChannelManager extends ChangeNotifier {
  WebSocketService _webSocketService = WebSocketService();
  WebSocketChannel? _webSocketChannel;
  Authentication? _authentication;

  @override
  void dispose() {
    unsetChannel();
    super.dispose();
  }

  void notify() {
    notifyListeners();
  }

  setChannel(String webSocketUrl, Authentication authentication,
      Function(dynamic event) onChannelEvent) {
    _authentication = authentication;
    _webSocketChannel =
        _webSocketService.connectToWebSocket(webSocketUrl, authentication);
    if (_authentication?.data?.me != null) {
      _webSocketService.streamNotifyUserSubscribe(
          _webSocketChannel!, _authentication!.data!.me!);
    }
    _webSocketChannel!.stream.listen((event) {
      if (_webSocketChannel != null && _authentication?.data?.me != null) {
        _webSocketService.streamNotifyUserSubscribe(
            _webSocketChannel!, _authentication!.data!.me!);
      }
      onChannelEvent.call(event);
    });
  }

  unsetChannel() {
    _webSocketChannel?.sink.close();
  }

  sendTextMsg(String text, Room room) {
    if (text.isNotEmpty && _webSocketChannel != null) {
      _webSocketService.sendMessageOnRoom(text, _webSocketChannel!, room);
    }
  }
}
