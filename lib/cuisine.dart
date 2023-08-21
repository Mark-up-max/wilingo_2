import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'allemand.dart';
import 'anglais.dart';
import 'arabe.dart';
import 'chat_screen.dart';
import 'anglisfrancais.dart';
import 'chinois.dart';
import 'conjfrancais.dart';
import 'cuisineafrique.dart';
import 'espagnol.dart';
import 'italien.dart';

class CUISINE extends StatelessWidget {
  final List<String> chats = [
    'Cuisine Africaine',
  ];

  final bool isDarkModeEnabled;
  CUISINE({required this.isDarkModeEnabled});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Conjuguaison'),
      ),
      body: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (BuildContext context, int index) {
          return InkWell(
            onTap: () {
              if (chats[index] == 'Cuisine Africaine') {
                String jeuUrl = 'https://www.cuisineaz.com/recettes/filets-de-poulet-panes-55434.aspx';
                if(isDarkModeEnabled){
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => cuisine(url: jeuUrl, isDarkModeEnabled: true,)),
                  );
                }else{
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => cuisine(url: jeuUrl, isDarkModeEnabled: false,)),
                  );
                }
              }
              if (chats[index] == 'traducteur') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>
                      anglisfrancais(chats[index], chatName: 'Français - Anglais')),
                );
              }
              if (chats[index] == 'Français - Espagnol') {

              }
              if (chats[index] == 'Français - Chinois') {

              }
              if (chats[index] == 'Français - Italien') {

              }
              if (chats[index] == 'Français - Arabe') {

              }
            },
            child: Card(
              elevation: 20,
              child: Container(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: AssetImage('images/OIP (2).jpg'),
                    ),
                    SizedBox(width: 16.0),
                    Container(
                      margin: EdgeInsets.all(16.0), // Marge de 8.0 sur tous les côtés
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width - 16.0, // Largeur maximale avec marges de 16.0
                      ),
                      child: Text(chats[index]),
                    ),

                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class cuisine extends StatelessWidget {
  final String url;
  final bool isDarkModeEnabled;

  cuisine({required this.url, required this.isDarkModeEnabled});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkModeEnabled ? Colors.black54 : Colors.white,
        title: Text('Cuisine Africaine',
            style:
            TextStyle(
              color: isDarkModeEnabled ? Colors.white : Colors.black,
        )),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: isDarkModeEnabled ? AssetImage('images/2emsombre.jpg') : AssetImage('images/sans.jpg'),
            fit: BoxFit.cover, // Pour ajuster l'image à la taille du conteneur
          ),
        ),
        child: WebView(
          initialUrl: url,
          javascriptMode: JavascriptMode.unrestricted,
        ),
      ),
    );
  }
}