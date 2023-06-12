import 'package:rocket_chat_connector_flutter/models/user.dart';

class Channel {
  // "fname": "testing",
  // "t": "c",
  // "msgs": 0,
  // "usersCount": 2,
  // "u": {
  // "_id": "HKKPmF8rZh45GMHWH",
  // "username": "marcos.defendi"
  // },
  // "customFields": {},
  // "broadcast": false,
  // "encrypted": false,
  // "ts": "2020-05-21T13:14:07.070Z",
  // "ro": false,
  // "default": false,
  // "sysMes": true,
  // "_updatedAt": "2020-05-21T13:14:07.096Z"
  String? id; // room id
  String? name;
  String? fName; // room name
  String? t;
  int? msgs; // 消息数
  int? usersCount; // 用户数
  User? user;
  Map? customFields;
  DateTime? ts;
  DateTime? updatedAt;

  Channel({
    this.id,
    this.name,
    this.fName,
    this.t,
    this.msgs,
    this.usersCount,
    this.user,
    this.customFields,
    this.ts,
    this.updatedAt,
  });

  Channel.fromMap(Map<String, dynamic>? json) {
    if (json != null) {
      id = json['_id'];
      name = json['name'];
      fName = json['fname'];
      t = json['t'];
      msgs = json['msgs'];
      usersCount = json['usersCount'];
      user = json['u'] != null ? User.fromMap(json['u']) : null;
      customFields = json['customFields'];
      ts = DateTime.parse(json['ts']);
      updatedAt = json['_updatedAt'] != null
          ? DateTime.parse(json['_updatedAt'])
          : null;
    }
  }

  Map<String, dynamic> toMap() => {
        '_id': id,
        'name': name,
        'fName': fName,
        't': t,
        'msgs': msgs,
        'usersCount': usersCount,
        'u': user != null ? user!.toMap() : null,
        'customFields': customFields,
        'ts': ts != null ? ts!.toIso8601String() : null,
        '_updatedAt': updatedAt != null ? updatedAt!.toIso8601String() : null,
      };

  @override
  String toString() {
    return 'Channel{_id: $id, name: $name, fName: $fName, t: $t, msgs: $msgs, usersCount: $usersCount, user: $user, ts: $ts, updatedAt: $updatedAt}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Channel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          fName == other.fName &&
          t == other.t &&
          msgs == other.msgs &&
          usersCount == other.usersCount &&
          user == other.user &&
          customFields == other.customFields &&
          ts == other.ts &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      fName.hashCode ^
      t.hashCode ^
      msgs.hashCode ^
      usersCount.hashCode ^
      user.hashCode ^
      customFields.hashCode ^
      ts.hashCode ^
      updatedAt.hashCode;
}
