import 'dart:typed_data';

import 'package:example/chat_room_page.dart';
import 'package:example/create_room_page.dart';
import 'package:example/login_page.dart';
import 'package:example/utils.dart';
import 'package:flt_hc_hud/flt_hc_hud.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:rocket_chat_connector_flutter/models/filters/room_counters_filter.dart';
import 'package:rocket_chat_connector_flutter/models/message.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart';
import 'package:rocket_chat_connector_flutter/models/room_counters.dart';
import 'package:rocket_chat_connector_flutter/sdk/avatar.dart';
import 'package:rocket_chat_connector_flutter/sdk/im_manager.dart';
import 'package:rocket_chat_connector_flutter/web_socket/notification_fields.dart';

class MyHomePage extends StatefulWidget {
  final String title;

  MyHomePage({Key? key, required this.title}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  final List<Room> _rooms = <Room>[];
  final Map<String, RoomCounters?> _roomCountersMap = <String, RoomCounters>{};
  final Map<String, UserStatus> _userStatuses = <String, UserStatus>{};

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      //进入应用时候不会触发该状态 应用程序处于可见状态，并且可以响应用户的输入事件。它相当于 Android 中Activity的onResume
      case AppLifecycleState.resumed:
        _appEnterForeground();
        break;
      //应用状态处于闲置状态，并且没有用户的输入事件，
      // 注意：这个状态切换到 前后台 会触发，所以流程应该是先冻结窗口，然后停止UI
      case AppLifecycleState.inactive:
        break;
      //当前页面即将退出
      case AppLifecycleState.detached:
        break;
      // 应用程序处于不可见状态
      case AppLifecycleState.paused:
        _appEnterBackground();
        break;
    }
  }

  // app进入前台
  void _appEnterForeground() {
    if (!ImManager().channelManager.isConnecting) {
      ImManager().reconnect();
      _loadRooms();
      Future.delayed(Duration(seconds: 1), () {
        HCHud.of(context)?.showTextAndDismiss(
            text: '正在重连 ${ImManager().channelManager.isConnecting}');
      });
    }
  }

  // app进入后台
  void _appEnterBackground() {}

  @override
  void dispose() {
    ImManager().removeMsgListener(_msgListener);
    ImManager().removeUserStatusListener(_userStatusListener);
    ImManager().clearMemoryCache();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    _initIm();
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  _initIm() async {
    _loadRooms();
    ImManager().addMsgListener(_msgListener);
    ImManager().addUserStatusListener(_userStatusListener);
  }

  _loadRooms() async {
    var rooms = await ImManager().getRooms();
    // 按最后消息时间降序排列
    rooms?.sort((a, b) {
      String ats = a.lastMessage?.ts?.toIso8601String() ?? '';
      String bts = b.lastMessage?.ts?.toIso8601String() ?? '';
      return bts.compareTo(ats);
    });
    _rooms.clear();
    if (rooms != null) {
      _rooms.addAll(rooms);
      setState(() {});
    }
    _setUnreadCount();
    _getUserStatus();
  }

  _setUnreadCount() async {
    List<Room> rooms = List<Room>.from(_rooms);
    for (Room room in rooms) {
      await _updateRoomCounters(room);
    }
    setState(() {});
  }

  _updateRoomCounters(Room room) async {
    RoomCounters? roomCounters =
        await ImManager().counters(RoomCountersFilter(room));
    if (room.id != null && room.id!.isNotEmpty == true) {
      _roomCountersMap[room.id!] = roomCounters;
    }
  }

  _getUserStatus() async {
    for (Room room in _rooms) {
      if (room.hisUid != null) {
        UserStatus? status =
            await ImManager().getUserStatusWithUid(room.hisUid!);
        if (status != null) {
          _userStatuses[room.hisUid!] = status;
        }
      }
    }
    setState(() {});
  }

  _msgListener(Message message) {
    Room? newMsgRoom;
    for (Room room in _rooms) {
      if (message.rid == room.id) {
        newMsgRoom = room;
        newMsgRoom.lastMessage = message;
      }
    }
    if (newMsgRoom != null) {
      _rooms.remove(newMsgRoom);
      _rooms.insert(0, newMsgRoom);
      RoomCounters? roomCounters = _roomCountersMap[newMsgRoom.id];
      if (roomCounters != null) {
        roomCounters.unreads = (roomCounters.unreads ?? 0) + 1;
      }
      setState(() {});
    } else {
      _loadRooms();
    }
  }

  _userStatusListener(UserStatusArgs args) {
    print('_userStatusListener ${args.toString()}');
    _userStatuses[args.userId] = args.status;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: ImManager(),
      child: Consumer(
        builder: (
          BuildContext context,
          ImManager value,
          Widget? child,
        ) {
          if (value.isLogin) {
            return _getScaffold();
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Scaffold _getScaffold() {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          GestureDetector(
            onTap: () {
              _setAvatar();
            },
            child: Container(
              padding: EdgeInsets.only(right: 10),
              child: Icon(Icons.image),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => HCHud(child: CreateRoomPage()),
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.only(right: 10),
              child: Icon(Icons.add),
            ),
          ),
          GestureDetector(
            onTap: () {
              _logout();
            },
            child: Container(
              padding: EdgeInsets.only(right: 10),
              child: Icon(Icons.logout),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView.builder(
          itemCount: _rooms.length,
          itemBuilder: (context, index) {
            Room room = _rooms[index];
            return _buildCell(room);
          },
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Widget _buildCell(Room room) {
    String msg = '';
    if (room.lastMessage != null) {
      String userName = room.lastMessage?.user?.username ?? '';
      if ((room.lastMessage?.msg ?? '').isNotEmpty) {
        msg = userName + '：' + (room.lastMessage?.msg ?? '');
      } else if (msg.isEmpty &&
          room.lastMessage?.attachments?.isNotEmpty == true) {
        String type = '上传了一个文件';
        if (room.lastMessage!.attachments!.first.imageUrl != null) {
          type = '发了一条图片消息';
        } else if (room.lastMessage!.attachments!.first.videoUrl != null) {
          type = '发了一条视频消息';
        }
        msg = userName + '：' + type;
      }
    }
    int unread = 0;
    RoomCounters? roomCounters = _roomCountersMap[room.id];
    if (roomCounters != null) {
      unread = roomCounters.unreads ?? 0;
    }
    return Row(
      children: [
        _buildAvatar(room),
        SizedBox(width: 5),
        Expanded(
          child: ListTile(
            title: Text(room.roomName),
            subtitle: Text(
              msg,
              style:
                  TextStyle(fontSize: 12, color: Colors.grey.withOpacity(0.5)),
            ),
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => HCHud(child: ChatRoomPage(room)),
                ),
              ).then((value) async {
                RoomCounters? roomCounters = _roomCountersMap[room.id];
                roomCounters?.unreads = 0;
                setState(() {});
              });
            },
          ),
        ),
        SizedBox(width: 5),
        if (unread > 0)
          Container(
            height: 22,
            width: unread < 10 ? 22 : null,
            padding: EdgeInsets.only(left: 6, right: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              '$unread',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatar(Room room) {
    String username = room.roomName;
    print('_buildAvatar :: $room');
    String? roomId = (username.isNotEmpty ? null : (room.id ?? ''));
    return FutureBuilder(
        future: ImManager().getAvatar(roomId: roomId, username: username),
        builder: (BuildContext context, AsyncSnapshot<Avatar?> snapshot) {
          Widget child;
          if (snapshot.data is Avatar) {
            if (snapshot.data?.svg != null) {
              child = SvgPicture.string(
                (snapshot.data?.svg ?? '')
                    .replaceAll('100%', '200')
                    .replaceAll('x=\"50%\"', 'x=\"100\"')
                    .replaceAll('y=\"50%\"', 'y=\"140\"'),
              );
            } else {
              child = Image.memory(snapshot.data?.image as Uint8List);
            }
          } else {
            child = Text(
              (room.name ?? ' ').substring(0, 1).toUpperCase(),
              style: TextStyle(fontSize: 15, color: Colors.white),
            );
          }
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey,
                  alignment: Alignment.center,
                  child: child,
                ),
              ),
              if (_userStatuses[room.hisUid] == UserStatus.online)
                Positioned(
                    right: 0,
                    bottom: 0,
                    width: 16,
                    height: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green,
                        border: Border.all(width: 1, color: Colors.white),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    )),
            ],
          );
        });
  }

  Future<void> _setAvatar() async {
    String? path = await Utils.pickOneImage(context);
    if (path == null) return;
    await ImManager().setAvatarWithImageFile(path);
  }

  Future<void> _logout() async {
    HCHud.of(context)?.showLoading(text: '');
    try {
      await ImManager().logout();
      Navigator.of(context, rootNavigator: true)
          .pushReplacement(CupertinoPageRoute(
        builder: (context) => HCHud(child: LoginPage()),
      ));
    } catch (e) {
      HCHud.of(context)?.showErrorAndDismiss(text: '$e');
    }
  }
}
