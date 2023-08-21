import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'allemand.dart';
import 'anglais.dart';
import 'arabe.dart';
import 'chat_screen.dart';
import 'anglisfrancais.dart';
import 'chinois.dart';
import 'conjallemand.dart';
import 'conjanglaise.dart';
import 'conjespagnol.dart';
import 'conjfrancais.dart';
import 'espagnol.dart';
import 'italien.dart';


class CONJUGUAISON extends StatelessWidget {
  final List<String> chats = [
    '[Conjuguaison - Français]',

    '[Conjuguaison - Allemande]',
    '[Conjuguaison - Espagnole]',

  ];

  final List<String> chatImages = [
    'images/avatar.png',
    'images/imagesconj.jpg',
    'images/imagesconj.jpg',
    'images/avnoir.png',
    'images/avnoir.png',
    'images/télécharger.png',
  ];

  bool isDarkModeEnabled;
  CONJUGUAISON({required this.isDarkModeEnabled});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: isDarkModeEnabled ? Colors.black : Colors.white,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDarkModeEnabled ? Colors.white : Colors.black,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text('Conjuguaison', style: TextStyle(
            color: isDarkModeEnabled ? Colors.white : Colors.black,
          ),
          ),
          centerTitle: true,
        ),
        body:
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: isDarkModeEnabled ? AssetImage('images/2emsombre.jpg') : AssetImage('images/sans.jpg'),
              fit: BoxFit.cover, // Pour ajuster l'image à la taille du conteneur
            ),
          ),

          child: ListView.builder(
            itemCount: chats.length,
            itemBuilder: (BuildContext context, int index) {
              return InkWell(
                onTap: () {
                  // Vos actions au clic sur chaque élément de la liste
                  if (chats[index] == '[Conjuguaison - Français]') {
                    if(isDarkModeEnabled){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>
                            conjfrancais(chatName: 'Conj - Française', index: 0, isDarkModeEnabled: true,)),
                      );
                    }else{
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>
                            conjfrancais(chatName: 'Conj - Française', index: 0, isDarkModeEnabled: false,)),
                      );
                    }
                  }
                  if (chats[index] == '[Conjuguaison - Allemande]') {
                    if(isDarkModeEnabled){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>
                            conjallemand(chatName: 'Conj - Française', index: 0, isDarkModeEnabled: true,)),
                      );
                    }else{
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>
                            conjallemand(chatName: 'Conj - Française', index: 0, isDarkModeEnabled: false,)),
                      );
                    }
                  }
                  if (chats[index] == '[Conjuguaison - Espagnole]') {
                    if(isDarkModeEnabled){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>
                            conjespagnol(chatName: 'Conj - Française', index: 0, isDarkModeEnabled: true,)),
                      );
                    }else{
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>
                            conjespagnol(chatName: 'Conj - Française', index: 0, isDarkModeEnabled: false,)),
                      );
                    }
                  }
                  if (chats[index] == '[Conjuguaison - Anglaise]') {
                    if(isDarkModeEnabled){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>
                            conjanglais(chatName: 'Conj - Française', index: 0, isDarkModeEnabled: true,)),
                      );
                    }else{
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>
                            conjanglais(chatName: 'Conj - Française', index: 0, isDarkModeEnabled: false,)),
                      );
                    }
                  }
                },
                child: Card(
                  margin: EdgeInsets.symmetric(horizontal: 0.0, vertical: 18.0),
                  elevation: 20.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0), // Conteneur légèrement incurvé aux bords
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16.0),
                    leading: CircleAvatar(
                      backgroundImage: AssetImage(chatImages[index]),
                    ),
                    title: Center(
                      child: Text(
                        chats[index],
                        style: TextStyle(
                          fontFamily: AutofillHints.birthday,
                          color: isDarkModeEnabled ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        )
    );
  }
}



