import 'package:rocket_chat_connector_flutter/web_socket/notification_payload.dart';

class NotificationArgs {
  String? title; // channel name
  String? text; // 发消息用户名: 消息内容
  NotificationPayload? payload;

  // 目前没发现有下面字段
  DateTime? ts;

  NotificationArgs({
    this.title,
    this.text,
    this.payload,
  });

  NotificationArgs.fromMap(Map<String, dynamic>? json) {
    if (json != null) {
      title = json['title'];
      text = json['text'];
      ts = DateTime.now();
      payload = json['payload'] != null
          ? NotificationPayload.fromMap(json['payload'])
          : null;
    }
  }

  @override
  String toString() {
    return 'NotificationArgs{title: $title, text: $text, ts: $ts, payload: $payload}';
  }
}
