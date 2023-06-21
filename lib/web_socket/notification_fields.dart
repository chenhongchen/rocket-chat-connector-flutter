import 'dart:convert';

import 'package:rocket_chat_connector_flutter/web_socket/notification_args.dart';

class NotificationFields {
  String? eventName;
  List<NotificationArgs>? args;
  UserStatusArgs? userStatusArgs;

  NotificationFields({
    this.eventName,
    this.args,
  });

  NotificationFields.fromMap(Map<String, dynamic>? json) {
    if (json != null) {
      eventName = json['eventName'];
      if (eventName == 'user-status') {
        userStatusArgs = UserStatusArgs(
          json['args'][0][0],
          json['args'][0][1],
          json['args'][0][2],
        );
      } else {
        if (json['args'] != null) {
          List<dynamic> jsonList = json['args'].runtimeType == String //
              ? jsonDecode(json['args'])
              : json['args'];
          args = jsonList
              .where((json) => json != null)
              .map((json) => NotificationArgs.fromMap(json))
              .toList();
        } else {
          args = null;
        }
      }
    }
  }

  @override
  String toString() {
    return 'WebSocketMessageFields{eventName: $eventName, args: $args}';
  }
}

class UserStatusArgs {
  String userId;
  String username;
  UserStatus status;

  UserStatusArgs(this.userId, this.username, int status)
      : status = UserStatus.values[status < 0 || status > 3 ? 0 : status];

  @override
  String toString() {
    return 'userId: $userId, username: $username, status: $status';
  }
}

enum UserStatus {
  offline,
  online,
  away,
  busy,
}

extension UserStatusValue on UserStatus {
  String get value {
    switch (this) {
      case UserStatus.offline:
        return 'offline';
      case UserStatus.online:
        return 'online';
      case UserStatus.away:
        return 'away';
      case UserStatus.busy:
        return 'away';
    }
  }
}
