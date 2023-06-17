import 'dart:convert';
import 'dart:typed_data';
import 'package:example/chat_room_view_model.dart';
import 'package:example/utils.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:rocket_chat_connector_flutter/models/message.dart';
import 'package:rocket_chat_connector_flutter/models/message_attachment.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart';
import 'package:rocket_chat_connector_flutter/sdk/avatar.dart';
import 'package:rocket_chat_connector_flutter/sdk/im_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ChatRoomPage extends StatefulWidget {
  final Room room;

  ChatRoomPage(this.room);

  @override
  State<StatefulWidget> createState() {
    return _ChatRoomPage();
  }
}

class _ChatRoomPage extends State<ChatRoomPage> {
  TextEditingController _controller = TextEditingController();
  ScrollController _scrollController = ScrollController();
  late final ChatRoomViewModel _viewModel = ChatRoomViewModel(
    widget.room,
    scrollController: _scrollController,
  );

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _getScaffold();
  }

  Scaffold _getScaffold() {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.room.roomName),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: _buildBody(),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _uploadFile,
            tooltip: 'Select file',
            heroTag: '111',
            child: Icon(Icons.file_copy),
          ),
          SizedBox(width: 10),
          FloatingActionButton(
            onPressed: _sendMessage,
            tooltip: 'Send message',
            heroTag: '222',
            child: Icon(Icons.send),
          ),
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Widget _buildBody() {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer(
        builder: (
          BuildContext context,
          ChatRoomViewModel value,
          Widget? child,
        ) {
          return Padding(
            padding: EdgeInsets.only(
              left: 15,
              right: 15,
              top: 0,
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              children: [
                Expanded(
                    child: SmartRefresher(
                  onLoading: _viewModel.loadMessage,
                  enablePullDown: false,
                  enablePullUp: true,
                  controller: _viewModel.controller,
                  child: ListView.builder(
                    reverse: true,
                    controller: _scrollController,
                    itemCount: value.messages.length,
                    itemBuilder: (context, index) {
                      Message message = value.messages[index];
                      return _buildCell(message);
                    },
                  ), // scroll view
                )),
                Form(
                  child: TextFormField(
                    controller: _controller,
                    decoration: InputDecoration(labelText: 'Send a message'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCell(Message message) {
    late Widget content;
    double screenW = MediaQuery.of(context).size.width;
    double avatarW = 36;
    double padding = 5;
    double contentWidth = screenW * 0.45;
    if (message.attachments != null && message.attachments!.isNotEmpty) {
      MessageAttachment attachment = message.attachments!.first;
      // 图片消息
      if (attachment.imageUrl != null) {
        double height = contentWidth *
            (attachment.imageDimensions?.height ?? 1) /
            (attachment.imageDimensions?.width ?? 1);
        content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: message.user?.id == ImManager().me?.id
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              attachment.description ?? '',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            Container(
              width: contentWidth,
              height: height,
              color: Colors.grey.withOpacity(0.5),
              child: FutureBuilder(
                future: ImManager().getImage(attachment.imageUrl!),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  Uint8List bytes = snapshot.data is Uint8List
                      ? snapshot.data
                      : base64Decode(attachment.imagePreview!);
                  return Image.memory(
                    bytes,
                    width: contentWidth,
                    height: height,
                    fit: BoxFit.cover,
                  );
                },
              ),
            )
          ],
        );
      }
      // 视频或一般文件
      else {
        String text = '文件';
        if (attachment.videoUrl != null) {
          text = '视频';
        }
        content = Container(
          width: contentWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                attachment.description ?? '',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              Text(
                '$text：${attachment.title ?? ''}',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        );
      }
    } else {
      content = Container(
        padding: EdgeInsets.all(5),
        constraints: BoxConstraints(minHeight: 50, maxWidth: contentWidth),
        alignment: message.user?.id == ImManager().me?.id
            ? Alignment.centerRight
            : Alignment.centerLeft,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: Colors.grey.withOpacity(0.5),
        ),
        child: Text(
          message.msg ?? '',
          maxLines: 100,
          textAlign: TextAlign.justify,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 16, color: Colors.black),
        ),
      );
    }

    Widget avatar = FutureBuilder(
        future: ImManager().getAvatarWithUid(message.user?.id),
        builder: (BuildContext context, AsyncSnapshot<Avatar?> snapshot) {
          Widget child;
          if (snapshot.data is Avatar) {
            if (snapshot.data?.svg != null) {
              child = SvgPicture.string(
                (snapshot.data?.svg ?? '')
                    .replaceAll('100%', '200')
                    .replaceAll('x=\"50%\"', 'x=\"100\"')
                    .replaceAll('y=\"50%\"', 'y=\"140\"'),
              );
            } else {
              child = Image.memory(snapshot.data?.image as Uint8List);
            }
          } else {
            child = Text(
              ((message.user?.name ?? message.user?.username) ?? ' ')
                  .substring(0, 1)
                  .toUpperCase(),
              style: TextStyle(fontSize: 15, color: Colors.white),
            );
          }
          return ClipRRect(
            borderRadius: BorderRadius.circular(avatarW * 0.5),
            child: Container(
              width: avatarW,
              height: avatarW,
              color: Colors.grey,
              alignment: Alignment.center,
              child: child,
            ),
          );
        });

    if (message.user?.id == ImManager().me?.id) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 5),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: SizedBox()),
              content,
              SizedBox(width: padding),
              avatar,
            ],
          ),
          SizedBox(height: 5),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 5),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            avatar,
            SizedBox(width: padding),
            content,
            Expanded(child: SizedBox()),
          ],
        ),
        SizedBox(height: 5),
      ],
    );
  }

  Future<void> _uploadFile() async {
    String? path =
        await Utils.pickOneImage(context, source: ImageSource.gallery);
    if (path == null) return;
    ImManager().sendFileMsg(path, widget.room, description: _controller.text);
    _controller.text = '';
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      ImManager().sendTextMsg(_controller.text, widget.room);
      _controller.text = '';
    }
  }
}
