import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/filters/room_counters_filter.dart';
import 'package:rocket_chat_connector_flutter/models/filters/room_history_filter.dart';
import 'package:rocket_chat_connector_flutter/models/message.dart';
import 'package:rocket_chat_connector_flutter/models/new/channel_new.dart';
import 'package:rocket_chat_connector_flutter/models/new/message_new.dart';
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
import 'package:rocket_chat_connector_flutter/sdk/image_manager.dart';
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
  ImageManager imageManager = ImageManager();

  bool get isLogin => _authentication != null;

  late String _webSocketUrl;
  late rocket_http_service.HttpService _rocketHttpService;

  Authentication? _authentication;

  List<MsgListener?> _msgListeners = <MsgListener?>[];

  // 已网络加载的头像的key
  final List _loadedAvatarKeys = [];

  @override
  void dispose() {
    _msgListeners.clear();
    channelManager.dispose();
    imageManager.clear();
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

  /// 发送自定义消息(自定义字段路径MessageNew.attachments.fields)
  Future<void> postMessage(MessageNew message) async {
    if (_authentication == null) return;
    MessageNewResponse response = await MessageService(_rocketHttpService)
        .postMessage(message, _authentication!);
    if (response.message != null) {
      for (MsgListener? msgListener in _msgListeners) {
        msgListener?.call(response.message!);
        channelManager.notify();
      }
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

  /// 获取图片数据
  Future<Uint8List?> getImage(String fileUri, {String? fileName}) async {
    if (_authentication == null) return null;
    Uint8List? uList = await imageManager.getImage(
        fileUri, _rocketHttpService, _authentication!);
    return uList;
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
    if (_authentication == null) return null;
    return imageManager.getAvatarWithUid(
        userId, _rocketHttpService, _authentication!);
  }

  /// 通过用户名获取头像
  Future<Avatar?> getAvatarWithUsername(String? username) async {
    if (_authentication == null) return null;
    return imageManager.getAvatarWithUsername(
        username, _rocketHttpService, _authentication!);
  }

  /// 获取room 头像
  /// rid 和 username 不能全为空
  Future<Avatar?> getRoomAvatar(String? rid, String? username) async {
    if (_authentication == null) return null;
    return imageManager.getRoomAvatar(
        rid, username, _rocketHttpService, _authentication!);
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

  /// 清除磁盘缓存
  Future<void> clearDiskCache() async {
    await ImUtil.clearFileCache();
  }

  /// 清除内存缓存
  void clearMemoryCache() {
    imageManager.clear();
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
