import 'package:example/my_home_page.dart';
import 'package:flt_hc_hud/flt_hc_hud.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rocket_chat_connector_flutter/sdk/im_manager.dart';

String serverUrl = "http://192.168.20.181:3000";
String webSocketUrl = "ws://192.168.20.181:3000/websocket";
String username = "chc";
String password = "hc123456";

class LoginPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _LoginPageState();
  }
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController _controllerServiceUrl =
      TextEditingController(text: 'http://192.168.20.181:3000');
  TextEditingController _controllerWebSocketUrl =
      TextEditingController(text: 'ws://192.168.20.181:3000/websocket');
  TextEditingController _controllerName = TextEditingController(text: 'chc');
  TextEditingController _controllerPwd =
      TextEditingController(text: 'hc123456');

  @override
  void dispose() {
    _controllerServiceUrl.dispose();
    _controllerWebSocketUrl.dispose();
    _controllerName.dispose();
    _controllerPwd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('登录'),
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
                controller: _controllerServiceUrl,
                decoration: InputDecoration(labelText: 'serverUrl'),
              ),
            ),
            SizedBox(height: 30),
            Form(
              child: TextFormField(
                controller: _controllerWebSocketUrl,
                decoration: InputDecoration(labelText: 'webSocketUrl'),
              ),
            ),
            SizedBox(height: 30),
            Form(
              child: TextFormField(
                controller: _controllerName,
                decoration: InputDecoration(labelText: 'name'),
              ),
            ),
            SizedBox(height: 30),
            Form(
              child: TextFormField(
                controller: _controllerPwd,
                decoration: InputDecoration(labelText: 'password'),
              ),
            ),
            SizedBox(height: 50),
            GestureDetector(
              onTap: () {
                _configIm();
              },
              child: Container(
                width: 120,
                height: 44,
                color: Colors.blue,
                alignment: Alignment.center,
                child: Text(
                  '登录',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  _configIm() async {
    HCHud.of(context)?.showLoading(text: '登录中。。。');
    serverUrl = _controllerServiceUrl.text;
    webSocketUrl = _controllerWebSocketUrl.text;
    username = _controllerName.text;
    password = _controllerPwd.text;
    ImManager().init(serverUrl, webSocketUrl);
    HCHud.of(context)?.dismiss();
    await ImManager().login(username, password);
    if (ImManager().isLogin) {
      Navigator.of(context, rootNavigator: true)
          .pushReplacement(CupertinoPageRoute(
        builder: (context) => HCHud(child: MyHomePage(title: '聊天列表')),
      ));
    }
  }
}
