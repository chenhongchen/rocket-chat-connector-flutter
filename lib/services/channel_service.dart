import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:rocket_chat_connector_flutter/exceptions/exception.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/channel.dart';
import 'package:rocket_chat_connector_flutter/models/channel_counters.dart';
import 'package:rocket_chat_connector_flutter/models/channel_messages.dart';
import 'package:rocket_chat_connector_flutter/models/filters/channel_counters_filter.dart';
import 'package:rocket_chat_connector_flutter/models/filters/channel_filter.dart';
import 'package:rocket_chat_connector_flutter/models/filters/channel_history_filter.dart';
import 'package:rocket_chat_connector_flutter/models/new/channel_new.dart';
import 'package:rocket_chat_connector_flutter/models/response/channel_new_response.dart';
import 'package:rocket_chat_connector_flutter/models/response/response.dart';
import 'package:rocket_chat_connector_flutter/services/http_service.dart';
import 'package:http_parser/http_parser.dart';

class ChannelService {
  HttpService _httpService;

  ChannelService(this._httpService);

  Future<List<Channel>> listJoined(
    Authentication authentication,
  ) async {
    http.Response response = await _httpService.get(
      '/api/v1/channels.list.joined',
      authentication,
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        Map json = jsonDecode(response.body);
        List channels = json['channels'] ?? [];
        return channels.map((e) => Channel.fromMap(e)).toList();
      } else {
        return [];
      }
    }
    throw RocketChatException(response.body);
  }

  Future<ChannelNewResponse> create(
      ChannelNew channelNew, Authentication authentication) async {
    http.Response response = await _httpService.post(
      '/api/v1/channels.create',
      jsonEncode(channelNew.toMap()),
      authentication,
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        return ChannelNewResponse.fromMap(jsonDecode(response.body));
      } else {
        return ChannelNewResponse();
      }
    }
    throw RocketChatException(response.body);
  }

  Future<ChannelMessages> messages(
      Channel channel, Authentication authentication) async {
    http.Response response = await _httpService.getWithFilter(
      '/api/v1/channels.messages',
      ChannelFilter(channel),
      authentication,
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        return ChannelMessages.fromMap(jsonDecode(response.body));
      } else {
        return ChannelMessages();
      }
    }
    throw RocketChatException(response.body);
  }

  Future<bool> markAsRead(
      Channel channel, Authentication authentication) async {
    Map<String, String?> body = {"rid": channel.id};

    http.Response response = await _httpService.post(
      '/api/v1/subscriptions.read',
      jsonEncode(body),
      authentication,
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        return Response.fromMap(jsonDecode(response.body)).success == true;
      } else {
        return false;
      }
    }
    throw RocketChatException(response.body);
  }

  Future<ChannelMessages> history(
      ChannelHistoryFilter filter, Authentication authentication) async {
    http.Response response = await _httpService.getWithFilter(
      '/api/v1/channels.history',
      filter,
      authentication,
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        return ChannelMessages.fromMap(jsonDecode(response.body));
      } else {
        return ChannelMessages();
      }
    }
    throw RocketChatException(response.body);
  }

  Future<ChannelCounters> counters(
    ChannelCountersFilter filter,
    Authentication authentication,
  ) async {
    http.Response response = await _httpService.getWithFilter(
      '/api/v1/channels.counters',
      filter,
      authentication,
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        return ChannelCounters.fromMap(jsonDecode(response.body));
      } else {
        return ChannelCounters();
      }
    }
    throw RocketChatException(response.body);
  }

  /// Upload File to a Room
  Future<String> uploadFile(
    Channel channel,
    String filename,
    Authentication authentication, {
    // A message text
    String? msg,
    // A description of the file
    String? description,
    // The thread message id (if you want upload a file to a thread)
    String? tMid,
    MediaType? mediaType,
  }) async {
    Map<String, String> fields = {};

    if (msg != null) {
      fields['msg'] = msg;
    }
    if (description != null) {
      fields['description'] = description;
    }
    if (tMid != null) {
      fields['tMid'] = tMid;
    }
    if (mediaType == null) {
      var name =
          filename.substring(filename.lastIndexOf('/') + 1, filename.length);
      // 获取文件扩展名
      List<String> fileNameSegments = name.split('.');
      String fileExt = fileNameSegments.last.toLowerCase();
      // 手动指定上传文件的contentType
      if (fileExt == 'gif' ||
          fileExt == 'jpg' ||
          fileExt == 'jpeg' ||
          fileExt == 'bmp' ||
          fileExt == 'png') {
        mediaType = MediaType('image', fileExt);
      } else if (fileExt == 'mp4') {
        mediaType = MediaType("video", fileExt);
      } else {
        mediaType = MediaType("application", "octet-stream");
      }
    }
    http.StreamedResponse response = await _httpService.postFile(
      '/api/v1/rooms.upload/${channel.id}',
      filename,
      authentication,
      fields: fields,
      mediaType: mediaType,
    );

    if (response.statusCode == 200) {
      String responseBody = await response.stream.bytesToString();
      print(responseBody);
      return responseBody;
    }
    throw RocketChatException('${response.statusCode}');
  }
}
