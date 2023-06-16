import 'package:example/chat_room_page.dart';
import 'package:flt_hc_hud/flt_hc_hud.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart';
import 'package:rocket_chat_connector_flutter/sdk/im_manager.dart';

class CreateRoomPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _CreateRoomPageState();
  }
}

class _CreateRoomPageState extends State<CreateRoomPage> {
  TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('创建立即聊天'),
      ),
      body: _buildBody(),
    );
  }

  _buildBody() {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Container(
        color: Colors.transparent,
        padding: EdgeInsets.only(left: 20, right: 20),
        child: Column(
          children: [
            SizedBox(height: 60),
            Form(
              child: TextFormField(
                controller: _controller,
                decoration: InputDecoration(labelText: 'username'),
              ),
            ),
            SizedBox(height: 50),
            GestureDetector(
              onTap: () {
                _createRoom();
              },
              child: Container(
                width: 120,
                height: 44,
                color: Colors.blue,
                alignment: Alignment.center,
                child: Text(
                  '创建',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  _createRoom() async {
    if (_controller.text.isEmpty ||
        _controller.text == (ImManager().me?.username ?? '')) return;
    try {
      HCHud.of(context)?.showLoading(text: '');
      Room? room = await ImManager().createRoom(_controller.text);
      HCHud.of(context)?.dismiss();
      if (room == null) return;
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => HCHud(child: ChatRoomPage(room)),
        ),
      );
    } catch (e) {
      HCHud.of(context)?.showErrorAndDismiss(text: '$e');
    }
  }
}
