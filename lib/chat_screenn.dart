import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MyWebView extends StatefulWidget {
  @override
  chatscrenn createState() => chatscrenn();
}

class chatscrenn extends State<MyWebView> {
  final String websiteUrl = 'https://www.example.com'; // URL du site complet
  final String targetElementId = 'my-target-element'; // ID de l'élément cible à afficher

  final Completer<WebViewController> _controller =
  Completer<WebViewController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WebView'),
      ),
      body: WebView(
        initialUrl: websiteUrl,
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController webViewController) {
          _controller.complete(webViewController);
        },
        onPageFinished: (String url) {
          // Une fois la page chargée, exécutez le code JavaScript pour extraire et afficher la partie souhaitée
          _controller.future.then((WebViewController webViewController) {
            webViewController.evaluateJavascript(
                "document.getElementById('$targetElementId').innerHTML")
                .then((result) {
              // Affichez le résultat dans la console pour vérification
              print(result);

              // Mettez à jour l'interface utilisateur avec le contenu extrait
              setState(() {
                // Utilisez le contenu extrait dans votre interface utilisateur
                // par exemple, vous pouvez l'affecter à une variable et l'afficher dans un Text Widget
              });
            });
          });
        },
      ),
    );
  }
}
