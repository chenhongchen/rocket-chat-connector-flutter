import 'package:flutter/material.dart';
import 'package:rocket_chat_connector_flutter/models/filters/room_history_filter.dart';
import 'package:rocket_chat_connector_flutter/models/message.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart';
import 'package:rocket_chat_connector_flutter/sdk/im_manager.dart';

class ChatRoomViewModel extends ChangeNotifier {
  final Room room;
  final ScrollController? scrollController;

  ChatRoomViewModel(this.room, {this.scrollController}) {
    ImManager().addMsgListener(_msgListener);
    loadMessage();
  }

  @override
  void dispose() {
    ImManager().removeMsgListener(_msgListener);
    super.dispose();
  }

  final List<Message> messages = <Message>[];

  _msgListener(Message message) {
    if (message.rid != room.id) return;
    messages.insert(0, message);
    notifyListeners();
    scrollController?.animateTo(
      0,
      duration: Duration(milliseconds: 333),
      curve: Curves.easeInOut,
    );
  }

  loadMessage() async {
    try {
      Message? lastMsg = messages.isNotEmpty ? messages.last : null;
      List<Message>? list = await ImManager()
          .getHistory(RoomHistoryFilter(room, latest: lastMsg?.ts, count: 20));
      ImManager().markAsRead(room);
      if (list != null) {
        messages.addAll(list);
        notifyListeners();
      }
    } catch (e) {
      print('loadMessage::$e');
    }
  }
}
