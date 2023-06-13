import 'dart:convert';
import 'package:rocket_chat_connector_flutter/exceptions/exception.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/filters/room_counters_filter.dart';
import 'package:rocket_chat_connector_flutter/models/filters/room_history_filter.dart';
import 'package:rocket_chat_connector_flutter/models/response/response.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart';
import 'package:http_parser/http_parser.dart';
import 'package:rocket_chat_connector_flutter/models/room_counters.dart';
import 'package:rocket_chat_connector_flutter/models/room_messages.dart';
import 'package:rocket_chat_connector_flutter/services/http_service.dart';
import 'package:http/http.dart' as http;

abstract class BaseRoomService {
  HttpService _httpService;

  HttpService get httpService => _httpService;

  BaseRoomService(this._httpService);

  Future<List<Room>> getRooms(Authentication authentication);

  Future<RoomMessages> messages(Room room, Authentication authentication);

  Future<RoomMessages> history(
      RoomHistoryFilter filter, Authentication authentication);

  Future<RoomCounters> counters(
      RoomCountersFilter filter, Authentication authentication);

  /// 标记已读
  Future<bool> markAsRead(Room room, Authentication authentication) async {
    Map<String, String?> body = {"rid": room.id};

    http.Response response = await httpService.post(
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
    http.StreamedResponse response = await httpService.postFile(
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
