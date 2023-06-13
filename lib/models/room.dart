import 'package:rocket_chat_connector_flutter/models/user.dart';

class Room {
  // "name": "testing",
  // "fname": "testing",
  // "usersCount": 2,
  // "u": {
  // "_id": "HKKPmF8rZh45GMHWH",
  // "username": "marcos.defendi"
  // },
  // "customFields": {},
  // "broadcast": false,
  // "encrypted": false,
  // "ro": false,
  // "default": false,
  // "sysMes": true,
  // "_updatedAt": "2020-05-21T13:14:07.096Z"
  String? id; // room id
  String? name;
  String? fname; // channel name
  String? t;
  int? msgs; // 消息数
  int? usersCount; // 用户数
  User? user;
  Map? customFields;
  bool? broadcast;
  bool? encrypted;
  DateTime? ts;
  bool? ro;
  bool? def;
  bool? sysMes;
  DateTime? updatedAt;

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
