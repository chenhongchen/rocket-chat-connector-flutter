import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rocket_chat_connector_flutter/exceptions/exception.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/filters/room_counters_filter.dart';
import 'package:rocket_chat_connector_flutter/models/filters/room_filter.dart';
import 'package:rocket_chat_connector_flutter/models/filters/room_history_filter.dart';
import 'package:rocket_chat_connector_flutter/models/new/room_new.dart';
import 'package:rocket_chat_connector_flutter/models/response/response.dart';
import 'package:rocket_chat_connector_flutter/models/response/room_new_response.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart';
import 'package:rocket_chat_connector_flutter/models/room_counters.dart';
import 'package:rocket_chat_connector_flutter/models/room_messages.dart';
import 'package:rocket_chat_connector_flutter/services/http_service.dart';
import 'package:http_parser/http_parser.dart';

class RoomService {
  HttpService _httpService;

  RoomService(this._httpService);

  Future<List<Room>> roomsGet(
    Authentication authentication,
  ) async {
    http.Response response = await _httpService.get(
      '/api/v1/rooms.get',
      authentication,
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        Map json = jsonDecode(response.body);
        List update = json['update'] ?? [];
        return update.map((e) => Room.fromMap(e)).toList();
      } else {
        return [];
      }
    }
    throw RocketChatException(response.body);
  }

  Future<RoomNewResponse> create(
    RoomNew roomNew,
    Authentication authentication,
  ) async {
    http.Response response = await _httpService.post(
      '/api/v1/im.create',
      jsonEncode(roomNew.toMap()),
      authentication,
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        return RoomNewResponse.fromMap(jsonDecode(response.body));
      } else {
        return RoomNewResponse();
      }
    }
    throw RocketChatException(response.body);
  }

  Future<RoomMessages> messages(
      Room room, Authentication authentication) async {
    http.Response response = await _httpService.getWithFilter(
      '/api/v1/im.messages',
      RoomFilter(room),
      authentication,
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        return RoomMessages.fromMap(jsonDecode(response.body));
      } else {
        return RoomMessages();
      }
    }
    throw RocketChatException(response.body);
  }

  Future<bool> markAsRead(Room room, Authentication authentication) async {
    Map<String, String?> body = {"rid": room.id};

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

  Future<RoomMessages> history(
      RoomHistoryFilter filter, Authentication authentication) async {
    http.Response response = await _httpService.getWithFilter(
      '/api/v1/im.history',
      filter,
      authentication,
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        return RoomMessages.fromMap(jsonDecode(response.body));
      } else {
        return RoomMessages();
      }
    }
    throw RocketChatException(response.body);
  }

  Future<RoomCounters> counters(
      RoomCountersFilter filter, Authentication authentication) async {
    http.Response response = await _httpService.getWithFilter(
      '/api/v1/im.counters',
      filter,
      authentication,
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        return RoomCounters.fromMap(jsonDecode(response.body));
      } else {
        return RoomCounters();
      }
    }
    throw RocketChatException(response.body);
  }

  /// Upload File to a Room
  Future<String> uploadFile(
    Room room,
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
      '/api/v1/rooms.upload/${room.id}',
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
