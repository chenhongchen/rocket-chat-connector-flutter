import 'package:rocket_chat_connector_flutter/models/message.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:rocket_chat_connector_flutter/sdk/im_manager.dart';

class Room {
  String? id; // room id
  String? fname; // channel name
  DateTime? updatedAt;
  Map? customFields;
  bool? broadcast;
  bool? encrypted;
  String? name; // channel name
  String? t;
  int? msgs; // 消息数
  int? usersCount; // 用户数
  User? user;
  DateTime? ts;
  bool? ro;
  bool? def;
  bool? sysMes;
  String? topic; //--
  Message? lastMessage; //--
  DateTime? lm; // --
  List<String>? usernames; // 私聊独有字段 --
  List<String>? uids; //私聊独有字段 --

  String get roomName {
    String title = name ?? '';
    if (title.isEmpty && usernames != null && usernames!.isNotEmpty == true) {
      title = usernames!.first;
      for (String username in usernames!) {
        if (username != ImManager().me?.username) {
          title = username;
          break;
        }
      }
    }
    return title;
  }

  bool get isChannel => (name != null && name!.isNotEmpty);

  Room({
    this.id,
    this.name,
    this.fname,
    this.t,
    this.msgs,
    this.usersCount,
    this.user,
    this.customFields,
    this.broadcast,
    this.encrypted,
    this.ts,
    this.ro,
    this.def,
    this.sysMes,
    this.updatedAt,
    this.topic,
    this.lastMessage,
    this.lm,
    this.usernames,
    this.uids,
  });

  Room.fromMap(Map<String, dynamic>? json) {
    if (json != null) {
      id = json['_id'];
      name = json['name'];
      fname = json['fname'];
      t = json['t'];
      msgs = json['msgs'];
      usersCount = json['usersCount'];
      user = json['u'] != null ? User.fromMap(json['u']) : null;
      customFields = json['customFields'];
      broadcast = json['broadcast'];
      encrypted = json['encrypted'];
      ts = json['ts'] != null ? DateTime.parse(json['ts']) : null;
      ro = json['ro'];
      def = json['default'];
      sysMes = json['sysMes'];
      updatedAt = json['_updatedAt'] != null
          ? DateTime.parse(json['_updatedAt'])
          : null;
      topic = json['topic'];
      lastMessage = json['lastMessage'] != null
          ? Message.fromMap(json['lastMessage'])
          : null;
      lm = json['lm'] != null ? DateTime.parse(json['lm']) : null;
      usernames = json['usernames'] != null
          ? List<String>.from(json['usernames'])
          : null;
      uids = json['uids'] != null ? List<String>.from(json['uids']) : null;
    }
  }

  Map<String, dynamic> toMap() => {
        '_id': id,
        'name': name,
        'fname': fname,
        't': t,
        'msgs': msgs,
        'usersCount': usersCount,
        'u': user != null ? user!.toMap() : null,
        'customFields': customFields,
        'broadcast': broadcast,
        'encrypted': encrypted,
        'ts': ts != null ? ts!.toIso8601String() : null,
        'ro': ro,
        'default': def,
        'sysMes': sysMes,
        '_updatedAt': updatedAt != null ? updatedAt!.toIso8601String() : null,
        'topic': topic,
        'lastMessage': lastMessage != null ? lastMessage!.toMap() : null,
        'lm': lm != null ? lm!.toIso8601String() : null,
        'usernames': usernames,
        'uids': uids,
      };

  @override
  String toString() {
    return toMap().toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Room && toMap() == other.toMap();

  @override
  int get hashCode => toMap().hashCode;
}
