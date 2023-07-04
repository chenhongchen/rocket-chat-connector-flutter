import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/filters/room_counters_filter.dart';
import 'package:rocket_chat_connector_flutter/models/filters/room_history_filter.dart';
import 'package:rocket_chat_connector_flutter/models/message.dart';
import 'package:rocket_chat_connector_flutter/models/message_attachment.dart';
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
import 'package:rocket_chat_connector_flutter/web_socket/notification_fields.dart';
import 'package:rocket_chat_connector_flutter/web_socket/notification_type.dart';
import 'package:rocket_chat_connector_flutter/web_socket/web_socket_service.dart';
import 'package:synchronized/synchronized.dart';
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
  List<UserStatusListener?> _userStatusListeners = <UserStatusListener?>[];

  // 已网络加载的头像的key
  final List _loadedAvatarKeys = [];

  // 缓存房间的消息，key是房间id
  final Map<String, List<Message>> _messageLists = <String, List<Message>>{};

  @override
  void dispose() {
    _msgListeners.clear();
    _userStatusListeners.clear();
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
  Future<User> register(UserNew userNew) {
    return UserService(_rocketHttpService).register(userNew);
  }

  /// 创建用户
  Future<User?> create(UserNew userNew, Authentication authentication) {
    if (_authentication == null) return Future.value(null);
    return UserService(_rocketHttpService).create(userNew, _authentication!);
  }

  /// 更新用户信息
  Future<User?> updateUser(String userId, UserNew userNew) {
    if (_authentication == null) return Future.value(null);
    return UserService(_rocketHttpService)
        .updateUser(userId, userNew, _authentication!);
  }

  /// 用户名、密码登录
  Future<void> login(String username, String password) async {
    _authentication = await AuthenticationService(_rocketHttpService)
        .login(username, password);
    me = _authentication!.data?.me;
    channelManager.setChannel(_webSocketUrl, _authentication!, _onChannelEvent);
    notifyListeners();
  }

  /// 第三方请求登录
  Future<void> loginWithRequest(
      Future<Authentication> Function() request) async {
    _authentication = await request();
    me = _authentication!.data?.me;
    channelManager.setChannel(_webSocketUrl, _authentication!, _onChannelEvent);
    notifyListeners();
  }

  /// 登出rock.chat
  Future<void> logout() async {
    if (_authentication == null) return null;
    await UserService(_rocketHttpService).logout(_authentication!);
    channelManager.unsetChannel();
    _authentication = null;
    me = null;
    notifyListeners();
  }

  void reconnect() {
    if (_authentication == null) return null;
    _messageLists.clear();
    channelManager.setChannel(_webSocketUrl, _authentication!, _onChannelEvent);
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
  void sendTextMsg(String text, String roomId) {
    channelManager.sendTextMsg(text, roomId);
  }

  /// 发送文件消息
  Future<Message?> sendFileMsg(
    String path,
    String roomId, {
    String? description,
    Function(double progress)? onProgress,
    List<MsgListener>? forbidMsgListeners, // 自己发送图片消息时禁止该消息监听的监听者
  }) async {
    if (_authentication == null) return null;
    final RoomService roomService = RoomService(_rocketHttpService);
    Message message = await roomService.uploadFile(
      roomId,
      path,
      _authentication!,
      description: description,
      onProgress: onProgress,
    );
    _handelReceiveMessage(message, forbidMsgListeners: forbidMsgListeners);
    return message;
  }

  /// 发送自定义消息(自定义字段路径MessageNew.attachments.fields)
  Future<void> postMessage(MessageNew message) async {
    if (_authentication == null) return;
    MessageNewResponse response = await MessageService(_rocketHttpService)
        .postMessage(message, _authentication!);
    if (response.message != null) {
      _handelReceiveMessage(response.message!);
    }
  }

  /// 获取房间列表
  Future<List<Room>?> getRooms() async {
    if (_authentication == null) return null;
    List<Room> rooms =
        await RoomService(_rocketHttpService).getRooms(_authentication!);
    // 订阅用户状态
    for (Room room in rooms) {
      if (!room.isChannel) {
        var uids = (room.hisUid != null ? <String>[room.hisUid!] : <String>[]);
        ImManager().subscribeUsersStatus(uids);
      }
    }
    return rooms;
  }

  /// 获取历史消息
  Future<List<Message>?> getHistory(RoomHistoryFilter filter,
      {bool useCached = false}) async {
    if (_authentication == null) return null;
    if (filter.room.id == null) return null;
    List<Message>? cachedList = _messageLists[filter.room.id];
    if (useCached) {
      List<Message>? list;
      if (filter.inclusive == null &&
          filter.offset == null &&
          filter.unreads == null &&
          cachedList != null) {
        for (Message msg in cachedList) {
          if (list != null && list.length >= (filter.count ?? 20)) {
            break;
          }
          if (msg.ts == null) {
            continue;
          }
          if (filter.latest != null &&
              msg.ts!.millisecondsSinceEpoch >=
                  filter.latest!.millisecondsSinceEpoch) {
            continue;
          }
          if (filter.oldest != null &&
              msg.ts!.millisecondsSinceEpoch <=
                  filter.oldest!.millisecondsSinceEpoch) {
            break;
          }
          if (list == null) {
            list = <Message>[];
          }
          list.add(msg);
        }
      }
      if (list != null) return list;
    }

    List<Message>? newMsgs;
    if (filter.room.isChannel) {
      newMsgs = await getChannelHistory(filter);
    } else {
      newMsgs = await getRoomHistory(filter);
    }

    if (newMsgs != null) {
      if (cachedList == null) {
        cachedList = <Message>[];
        _messageLists[filter.room.id!] = cachedList;
      }
      cachedList.addAll(newMsgs);
      cachedList.sort((a, b) =>
          b.ts!.millisecondsSinceEpoch.compareTo(a.ts!.millisecondsSinceEpoch));
    }

    return newMsgs;
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

  /// 清理room历史消息(要配置"清理频道历史记录"权限)
  Future<String?> cleanRoomHistory(RoomHistoryFilter filter) {
    if (_authentication == null) return Future.value(null);
    return RoomService(_rocketHttpService)
        .cleanRoomHistory(filter, _authentication!);
  }

  ///  获取计数
  Future<RoomCounters?> counters(RoomCountersFilter filter) {
    if (filter.room.isChannel) {
      return channelCounters(filter);
    } else {
      return roomCounters(filter);
    }
  }

  /// 获取channel计数
  Future<RoomCounters?> channelCounters(RoomCountersFilter filter) {
    if (_authentication == null) return Future.value(null);
    return ChannelService(_rocketHttpService)
        .counters(filter, _authentication!);
  }

  /// 获取room计数
  Future<RoomCounters?> roomCounters(RoomCountersFilter filter) {
    if (_authentication == null) return Future.value(null);
    return RoomService(_rocketHttpService).counters(filter, _authentication!);
  }

  ///  删除channel
  Future<String?> deleteChannel(Room room) {
    if (room.id == null || room.id!.isEmpty) return Future.value(null);
    return ChannelService(_rocketHttpService)
        .delete(room.id!, _authentication!);
  }

  ///  离开room或channel(暂时试了无效，应该是是权限问题)
  Future<String?> leave(Room room) {
    if (room.id == null || room.id!.isEmpty) return Future.value(null);
    if (room.isChannel) {
      return leaveChannel(room.id!);
    } else {
      return leaveRoom(room.id!);
    }
  }

  /// 离开room(暂时试了无效，应该是是权限问题)
  Future<String?> leaveChannel(String roomId) {
    if (_authentication == null) return Future.value(null);
    return ChannelService(_rocketHttpService).leave(roomId, _authentication!);
  }

  /// 离开channel(暂时试了无效，应该是是权限问题)
  Future<String?> leaveRoom(String roomId) {
    if (_authentication == null) return Future.value(null);
    return RoomService(_rocketHttpService).leave(roomId, _authentication!);
  }

  /// 删除私聊(要配置"删除私聊消息"权限)
  Future<String?> deleteIm(String roomId) async {
    if (_authentication == null) return Future.value(null);
    String body = await MessageService(_rocketHttpService)
        .delete(roomId, _authentication!);
    _messageLists.remove(roomId);
    return body;
  }

  /// 标记已读
  Future<bool> markAsRead(Room room) {
    if (_authentication == null) return Future.value(false);
    return RoomService(_rocketHttpService).markAsRead(room, _authentication!);
  }

  /// 获取图片数据
  Future<Uint8List?> getImage(MessageAttachment attachment,
      {bool rawImage = false}) {
    if (_authentication == null) return Future.value(null);
    return imageManager.getImage(
        attachment, rawImage, _rocketHttpService, _authentication!);
  }

  Uint8List? getImageFromMemory(MessageAttachment attachment,
      {bool rawImage = false}) {
    if (_authentication == null) return null;
    return imageManager.getImageFromMemory(attachment, rawImage);
  }

  /// 获取文件数据
  Future<Uint8List?> getFile(MessageAttachment attachment) async {
    String fileUri = attachment.titleLink ?? '';
    if (fileUri.isEmpty) return null;
    String fileName = ImUtil.md5FileName(fileUri);
    Uint8List? uList = await ImUtil.readFileFromCache(fileName);
    if (uList == null) {
      uList = await MessageService(_rocketHttpService)
          .getFile(fileUri, _authentication!);
      ImUtil.writeFileToCache(fileName, uList);
    }
    return uList;
  }

  /// 设置头像文件
  Future<String?> setAvatarWithImageFile(String imageFileName) {
    if (_authentication == null) return Future.value(null);
    return UserService(_rocketHttpService)
        .setAvatarWithImageFile(imageFileName, _authentication!);
  }

  /// 设置头像url
  Future<String?> setAvatarWithImageUrl(String imageUrl) {
    if (_authentication == null) return Future.value(null);
    return UserService(_rocketHttpService)
        .setAvatarWithImageUrl(imageUrl, _authentication!);
  }

  /// 获取room 或者 user 头像
  /// rid 和 username 不能全为空
  Future<Avatar?> getAvatar({String? roomId, String? username}) {
    if (_authentication == null) return Future.value(null);
    return imageManager.getAvatar(
      _rocketHttpService,
      _authentication!,
      roomId: roomId,
      username: username,
    );
  }

  /// 获取内存中的头像
  /// rid 和 username 不能全为空
  Avatar? getAvatarFromMemory({
    String? roomId,
    String? username,
  }) {
    if (_authentication == null) return null;
    return imageManager.getAvatarFromMemory(roomId: roomId, username: username);
  }

  /// 通过uid获取头像(有频率限制)
  Future<Avatar?> getAvatarWithUid(String? userId) {
    if (_authentication == null) return Future.value(null);
    return imageManager.getAvatarWithUid(
        userId, _rocketHttpService, _authentication!);
  }

  /// 通过用户名获取头像(有频率限制)
  Future<Avatar?> getAvatarWithUsername(String? username) {
    if (_authentication == null) return Future.value(null);
    return imageManager.getAvatarWithUsername(
        username, _rocketHttpService, _authentication!);
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

  /// 用户id获取用户状态
  Future<UserStatus?> getUserStatusWithUid(String userId) {
    if (_authentication == null) return Future.value(null);
    return UserService(_rocketHttpService)
        .getUserStatusWithUid(userId, _authentication!);
  }

  /// 用户名获取用户状态
  Future<UserStatus?> getUserStatusWithUsername(
      String username, Authentication authentication) {
    if (_authentication == null) return Future.value(null);
    return UserService(_rocketHttpService)
        .getUserStatusWithUsername(username, _authentication!);
  }

  /// 用户id获取用户信息
  Future<User?> getUserInfoWithUid(String userId) {
    if (_authentication == null) return Future.value(null);
    return UserService(_rocketHttpService)
        .getUserInfoWithUid(userId, _authentication!);
  }

  /// 用户名获取用户信息
  Future<User?> getUserUserInfoWithUsername(String username) {
    if (_authentication == null) return Future.value(null);
    return UserService(_rocketHttpService)
        .getUserUserInfoWithUsername(username, _authentication!);
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

  /// 添加用户状态监听者
  void addUserStatusListener(UserStatusListener listener) {
    _userStatusListeners.add(listener);
  }

  /// 移除用户状态监听者
  void removeUserStatusListener(UserStatusListener listener) {
    _userStatusListeners.remove(listener);
  }

  void subscribeUsersStatus(List<String> userIds) {
    channelManager.subscribeUsersStatus(userIds);
  }

  void _onChannelEvent(event) async {
    if (_authentication == null) return;
    var map = jsonDecode('$event');
    rocket_notification.Notification? notification =
        rocket_notification.Notification.fromMap(map);
    print(notification);
    // 收到的他人发送的消息
    if (notification.collection == 'stream-notify-user' &&
        notification.fields?.eventName?.contains('/notification') == true &&
        notification.msg == NotificationType.CHANGED) {
      if (notification.fields?.args == null) return;
      for (NotificationArgs args in notification.fields!.args!) {
        if (args.payload?.id == null) continue;
        // 通过id获取消息
        try {
          MessageNewResponse? response =
              await MessageService(_rocketHttpService)
                  .getMessage(args.payload!.id!, _authentication!);
          if (response?.message == null) continue;
          _handelReceiveMessage(response!.message!);
        } catch (e) {
          print('onChannelEvent error::$e');
        }
      }
    }
    // 收到的自己发送text消息的结果
    else if (notification.msg == NotificationType.RESULT &&
        notification.id == '42') {
      var result = map['result'];
      if (result == null) return;
      Message message = Message.fromMap(result!);
      _handelReceiveMessage(message);
    }
    // 用户更新消息
    else if (notification.collection == 'stream-notify-logged') {
      if (notification.fields?.eventName == 'user-status' &&
          notification.fields?.userStatusArgs != null) {
        for (UserStatusListener? listener in _userStatusListeners) {
          listener?.call(notification.fields!.userStatusArgs!);
        }
      }
    }
  }

  _handelReceiveMessage(Message message,
      {List<MsgListener>? forbidMsgListeners}) {
    if (message.id == null) return;
    if (message.rid != null) {
      List<Message>? cachedList = _messageLists[message.rid];
      if (cachedList != null) {
        cachedList.insert(0, message);
      }
    }
    for (MsgListener? msgListener in _msgListeners) {
      if (forbidMsgListeners?.contains(msgListener) == true) {
        continue;
      }
      msgListener?.call(message);
      channelManager.notify();
    }
  }
}

typedef MsgListener = Function(Message);
typedef UserStatusListener = Function(UserStatusArgs);

class ChannelManager extends ChangeNotifier {
  WebSocketService _webSocketService = WebSocketService();
  WebSocketChannel? _webSocketChannel;
  Authentication? _authentication;
  Timer? reconnectTimer;
  int reconnectInterval = 6; // 重连间隔时间（秒）

  bool isConnecting = false;
  final Lock _lock = Lock();

  @override
  void dispose() {
    unsetChannel();
    super.dispose();
  }

  void notify() {
    notifyListeners();
  }

  setChannel(String webSocketUrl, Authentication authentication,
      Function(dynamic event) onChannelEvent) async {
    await _lock.synchronized(() async {
      if (_webSocketChannel != null) {
        _webSocketChannel?.sink.close();
      }
      _authentication = authentication;
      _webSocketChannel =
          _webSocketService.connectToWebSocket(webSocketUrl, authentication);
      if (_authentication?.data?.me != null) {
        _webSocketService.streamNotifyUserSubscribe(
            _webSocketChannel!, _authentication!.data!.me!);
      }
      _webSocketChannel!.stream.listen(
        (event) {
          isConnecting = true;
          if (_webSocketChannel != null && _authentication?.data?.me != null) {
            _webSocketService.streamNotifyUserSubscribe(
                _webSocketChannel!, _authentication!.data!.me!);
          }
          onChannelEvent.call(event);
        },
        onDone: () {
          // 连接关闭时的处理
          isConnecting = false;
          reconnect(webSocketUrl, authentication, onChannelEvent);
        },
        onError: (error) {
          // 连接错误时的处理
          isConnecting = false;
          reconnect(webSocketUrl, authentication, onChannelEvent);
        },
      );
    });
  }

  void reconnect(String webSocketUrl, Authentication authentication,
      Function(dynamic event) onChannelEvent) {
    if (reconnectTimer == null || !reconnectTimer!.isActive) {
      reconnectTimer = Timer(Duration(seconds: reconnectInterval), () {
        if (isConnecting) return;
        setChannel(webSocketUrl, authentication, onChannelEvent);
        ImManager()._messageLists.clear();
      });
    }
  }

  unsetChannel() {
    _webSocketChannel?.sink.close();
    _webSocketChannel = null;
  }

  sendTextMsg(String text, String roomId) {
    if (text.isNotEmpty && _webSocketChannel != null) {
      _webSocketService.sendMessageOnRoom(text, _webSocketChannel!, roomId);
    }
  }

  void subscribeUsersStatus(List<String> userIds) {
    if (_webSocketChannel == null) return;
    for (String userId in userIds) {
      WebSocketService()
          .streamNotifyUserStatusSubscribe(_webSocketChannel!, userId);
    }
  }
}
