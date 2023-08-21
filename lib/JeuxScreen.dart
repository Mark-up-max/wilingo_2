import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class JeuxScreen extends StatelessWidget {
  final String url;

  JeuxScreen({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Jeux'),
      ),
      body: WebView(
        initialUrl: url,
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}
