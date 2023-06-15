import 'package:example/chat_room_page.dart';
import 'package:flt_hc_hud/flt_hc_hud.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rocket_chat_connector_flutter/models/filters/room_counters_filter.dart';
import 'package:rocket_chat_connector_flutter/models/message.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart';
import 'package:rocket_chat_connector_flutter/models/room_counters.dart';
import 'package:rocket_chat_connector_flutter/sdk/im_manager.dart';

class MyHomePage extends StatefulWidget {
  final String title;

  MyHomePage({Key? key, required this.title}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<Room> _rooms = <Room>[];
  final Map<String, RoomCounters?> _roomCountersMap = <String, RoomCounters>{};

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    _initIm();
    super.initState();
  }

  _initIm() async {
    _loadRooms();
    ImManager().addMsgListener(_msgListener);
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
            child: Container(
              padding: EdgeInsets.only(right: 10),
              child: Icon(Icons.image),
            ),
          )
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
}
