import 'dart:convert';
import 'dart:typed_data';

import 'package:example/chat_room_view_model.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:rocket_chat_connector_flutter/models/message.dart';
import 'package:rocket_chat_connector_flutter/models/message_attachment.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart';
import 'package:rocket_chat_connector_flutter/sdk/im_manager.dart';

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
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Expanded(
                    child: ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: value.messages.length,
                  itemBuilder: (context, index) {
                    Message message = value.messages[index];
                    return _buildCell(message);
                  },
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
    double avatarW = 50;
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
                future: ImManager().getFile(attachment.imageUrl!),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  Uint8List bytes = snapshot.hasData
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
          height: 70,
          child: Column(
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

    Widget avatar = Container(
      width: avatarW,
      height: avatarW,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: Colors.grey,
      ),
      child: Text(
        (message.user?.name ?? message.user?.username) ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

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
    String? path = await pickOneImage(context, source: ImageSource.gallery);
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

  static Future<String?> pickOneImage(
    BuildContext context, {
    ImageSource source = ImageSource.gallery,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    final picker = ImagePicker();
    try {
      XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        preferredCameraDevice: preferredCameraDevice,
        imageQuality: imageQuality,
      );
      return pickedFile?.path;
    } catch (e) {
      return null;
    }
  }
}
