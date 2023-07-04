import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:rocket_chat_connector_flutter/models/filters/room_history_filter.dart';
import 'package:rocket_chat_connector_flutter/models/message.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart';
import 'package:rocket_chat_connector_flutter/sdk/im_manager.dart';

class ChatRoomViewModel extends ChangeNotifier {
  final Room room;
  final ScrollController? scrollController;
  bool _isLoading = false;
  final RefreshController controller = RefreshController();
  bool enablePullUp = true;

  ChatRoomViewModel(this.room, {this.scrollController}) {
    ImManager().addMsgListener(_msgListener);
    initLoad();
  }

  @override
  void dispose() {
    ImManager().removeMsgListener(_msgListener);
    _markAsRead();
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

  initLoad() {
    messages.clear();
    loadMessage();
  }

  Future<void> loadMessage() async {
    if (_isLoading) return;
    try {
      Message? lastMsg = messages.isNotEmpty ? messages.last : null;
      List<Message>? list = await ImManager().getHistory(
          RoomHistoryFilter(room, latest: lastMsg?.ts, count: 20),
          useCached: true);
      if (list != null && list.isNotEmpty) {
        messages.addAll(list);
        notifyListeners();
      } else {
        enablePullUp = false;
        notifyListeners();
      }
    } catch (e) {
      print('loadMessage::$e');
    }
    _isLoading = false;
    controller.loadComplete();
  }

  _markAsRead() {
    try {
      ImManager().markAsRead(room);
    } catch (e) {
      print('markAsRead::$e');
    }
  }
}
