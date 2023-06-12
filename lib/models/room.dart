import 'package:rocket_chat_connector_flutter/models/channel.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';

class Room extends Channel {
  Room({
    String? id,
    String? name,
    String? fName,
    String? t,
    int? msgs,
    int? usersCount,
    User? user,
    Map? customFields,
    DateTime? ts,
    DateTime? updatedAt,
  }) : super(
          id: id,
          name: name,
          fName: fName,
          t: t,
          msgs: msgs,
          usersCount: usersCount,
          user: user,
          customFields: customFields,
          ts: ts,
          updatedAt: updatedAt,
        );

  Room.fromMap(Map<String, dynamic>? json) : super.fromMap(json);
}
