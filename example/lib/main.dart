import 'package:example/login_page.dart';
import 'package:flt_hc_hud/flt_hc_hud.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final title = 'Rocket Chat WebSocket Demo';

    return MaterialApp(
      title: title,
      home: HCHud(child: LoginPage()),
    );
  }
}
