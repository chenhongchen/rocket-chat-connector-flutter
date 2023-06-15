import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:rocket_chat_connector_flutter/models/mention.dart';
import 'package:rocket_chat_connector_flutter/models/message_attachment.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';

class Message {
  String? id;
  String? rid;
  String? msg;
  DateTime? ts;
  User? user;
  DateTime? updatedAt;
  Map? urls;
  List<Mention>? mentions;
  List<String>? channels;
  List<MessageAttachment>? attachments;

  Message({
    this.id,
    this.rid,
    this.msg,
    this.ts,
    this.user,
    this.updatedAt,
    this.urls,
    this.mentions,
    this.channels,
    this.attachments,
  });

  Message.fromMap(Map<String, dynamic>? json) {
    if (json != null) {
      id = json['_id'];
      rid = json['rid'];
      msg = json['msg'];
      if (json['ts'] != null) {
        // change
        if (json['ts'] is String) {
          ts = DateTime.parse(json['ts']);
        }
        // result
        else if (json['ts'] is Map) {
          int timeStamp = json['ts']['\$date'];
          ts = DateTime.fromMillisecondsSinceEpoch(timeStamp);
        }
      }
      user = json['u'] != null ? User.fromMap(json['u']) : null;
      if (json['_updatedAt'] != null) {
        // change
        if (json['_updatedAt'] is String) {
          updatedAt = DateTime.parse(json['_updatedAt']);
        }
        // result
        else if (json['_updatedAt'] is Map) {
          int timeStamp = json['_updatedAt']['\$date'];
          updatedAt = DateTime.fromMillisecondsSinceEpoch(timeStamp);
        }
      }
      urls = json['urls'] is Map ? Map.from(json['urls']) : null;

      if (json['mentions'] != null) {
        List<dynamic> jsonList = json['mentions'].runtimeType == String //
            ? jsonDecode(json['mentions'])
            : json['mentions'];
        mentions = jsonList
            .where((json) => json != null)
            .map((json) => Mention.fromMap(json))
            .toList();
      }
      channels =
          json['channels'] != null ? List<String>.from(json['channels']) : null;

      if (json['attachments'] != null) {
        List<dynamic> jsonList = json['attachments'].runtimeType == String //
            ? jsonDecode(json['attachments'])
            : json['attachments'];
        attachments = jsonList
            .where((json) => json != null)
            .map((json) => MessageAttachment.fromMap(json))
            .toList();
      }
    }
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {};
    map['_id'] = id;
    map['rid'] = rid;
    map['msg'] = msg;
    map['ts'] = ts != null ? ts!.toIso8601String() : null;
    map['u'] = user != null ? user!.toMap() : null;
    map['_updatedAt'] = updatedAt != null ? updatedAt!.toIso8601String() : null;
    map['urls'] = urls;
    if (mentions != null) {
      map['mentions'] = mentions!.map((mention) => mention.toMap()).toList();
    }
    if (channels != null) {
      map['channels'] = channels;
    }
    if (attachments != null) {
      map['attachments'] =
          attachments!.map((attachment) => attachment.toMap()).toList();
    }

    return map;
  }

  @override
  String toString() {
    return 'Message{_id: $id, rid: $rid, msg: $msg, ts: $ts, u: $user, _updatedAt: $updatedAt, urls: $urls, mentions: $mentions, channels: $channels, attachments: $attachments}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          rid == other.rid &&
          msg == other.msg &&
          ts == other.ts &&
          user == other.user &&
          updatedAt == other.updatedAt &&
          DeepCollectionEquality().equals(urls, other.urls) &&
          DeepCollectionEquality().equals(mentions, other.mentions) &&
          DeepCollectionEquality().equals(channels, other.channels) &&
          DeepCollectionEquality().equals(attachments, other.attachments);

  @override
  int get hashCode =>
      id.hashCode ^
      rid.hashCode ^
      msg.hashCode ^
      ts.hashCode ^
      user.hashCode ^
      updatedAt.hashCode ^
      urls.hashCode ^
      mentions.hashCode ^
      channels.hashCode ^
      attachments.hashCode;
}
