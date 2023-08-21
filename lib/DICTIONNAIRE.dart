import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'allemand.dart';
import 'anglais.dart';
import 'arabe.dart';
import 'chat_screen.dart';
import 'anglisfrancais.dart';
import 'chinois.dart';
import 'espagnol.dart';
import 'italien.dart';
import 'package:sqflite/sqflite.dart';



class BaseDeDonne {
  static const dbName = "allemand";
  static const dbVersion = 1;
  static const dbTable = "smsallemand";
  static const columnId = "ideallemand";
  static const columnName = "namesallemand";

  static final BaseDeDonne instance = BaseDeDonne._();
  late Database _database;

  BaseDeDonne._() {
    initDB();
  }

  // Récupère la base de données, en la créant si nécessaire
  Future<Database> get database async {
    if (_database != null && _database.isOpen) return _database;
    _database = await initDB();
    return _database;
  }

  // Initialise la base de données en créant le fichier et en ouvrant la connexion
  Future<Database> initDB() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String path = join(directory.path, dbName);
    _database = await openDatabase(path, version: dbVersion, onCreate: onCreate);
    return _database;
  }

  // Méthode appelée lors de la création de la base de données
  Future<void> onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $dbTable (
        text TEXT,
        isUserMessage BOOL,
        time INTEGER,
        soundUrl TEXT
      )
    ''');
  }

  // Lit le texte du dernier message de la base de données
  Future<String> readLastMessageText() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      dbTable,
      columns: ['text'], // Sélectionne uniquement la colonne 'text'
      orderBy: 'time DESC',
      limit: 1, // Limite la requête à un seul résultat (le dernier message)
    );

    if (maps.isNotEmpty) {
      return maps[0]['text'] as String;
    } else {
      // Retourne une chaîne vide si la base de données est vide
      return '';
    }
  }

// ... Autres méthodes de la classe ...
}




class DICTIONNAIRE extends StatelessWidget {
  final List<String> chats = [
    '[Français - Chinois]',
    '[Français - Anglais]',
    '[Français - Allemand]',
    '[Français - Espagnol]',
    '[Français - Italien]',
    '[Français - Arabe]'
  ];

  final List<String> chatImages = [
    'images/chinois.png',
    'images/télécharger.jpg',
    'images/imana.jpg',
    'images/avnoir.png',
    'images/avnoir.png',
    'images/télécharger.png',
  ];

  bool isDarkModeEnabled;
  DICTIONNAIRE({required this.isDarkModeEnabled});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: isDarkModeEnabled? Colors.black : Colors.white,
          leading: IconButton(
            icon: Icon(
                Icons.arrow_back,
                color: isDarkModeEnabled? Colors.white : Colors.black
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text('Dictionnaire Bilingue',  style: TextStyle(
            color: isDarkModeEnabled ? Colors.white : Colors.black,
          ),
          ),
          centerTitle: true, // Centrer le texte dans la AppBar
        ),
        body: Container(
          color: Colors.white,
          child: ListView.builder(
            itemCount: chats.length,
            itemBuilder: (BuildContext context, int index) {
              return InkWell(
                onTap: () {
                  if (chats[index] == '[Français - Allemand]') {
                    if(isDarkModeEnabled){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>
                            allemand(chatName: 'Français - Italien', index: 0, isDarkModeEnabled: true,)),
                      );
                    }else{
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>
                            allemand(chatName: 'Français - Italien', index: 0, isDarkModeEnabled: false,)),
                      );
                    }
                  }
                  if (chats[index] == '[Français - Anglais]') {
                    if(isDarkModeEnabled){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>
                            anglais(chatName: 'Français - Italien', index: 0, isDarkModeEnabled: true,)),
                      );
                    }else{
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>
                            anglais(chatName: 'Français - Italien', index: 0, isDarkModeEnabled: false,)),
                      );
                    }
                  }
                  if (chats[index] == '[Français - Espagnol]') {
                    if(isDarkModeEnabled){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>
                            espagnol(chatName: 'Français - Italien', index: 0, isDarkModeEnabled: true,)),
                      );
                    }else{
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>
                            espagnol(chatName: 'Français - Italien', index: 0, isDarkModeEnabled: false,)),
                      );
                    }
                  }
                  if (chats[index] == '[Français - Chinois]') {
                    if(isDarkModeEnabled){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>
                            chinois(chatName: 'Français - Italien', index: 0, isDarkModeEnabled: true,)),
                      );
                    }else{
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>
                            chinois(chatName: 'Français - Italien', index: 0, isDarkModeEnabled: false,)),
                      );
                    }
                  }
                  if (chats[index] == '[Français - Italien]') {
                    if(isDarkModeEnabled){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>
                            italien(chatName: 'Français - Italien', index: 0, isDarkModeEnabled: true,)),
                      );
                    }else{
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>
                            italien(chatName: 'Français - Italien', index: 0, isDarkModeEnabled: false,)),
                      );
                    }
                  }
                  if (chats[index] == '[Français - Arabe]') {
                    if(isDarkModeEnabled){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>
                            arabe(chatName: 'Français - Italien', index: 0, isDarkModeEnabled: true,)),
                      );
                    }else{
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>
                            arabe(chatName: 'Français - Italien', index: 0, isDarkModeEnabled: false,)),
                      );
                    }
                  }
                },
                child: Card(
                  // ... Autres propriétés du Card ...
                  margin: EdgeInsets.symmetric(horizontal: 0.0, vertical: 10.0),
                  elevation: 0.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0), // Conteneur légèrement incurvé aux bords
                  ),
                  child: ListTile(
                    // ... Autres propriétés du ListTile ...
                    contentPadding: EdgeInsets.all(16.0),
                    leading: CircleAvatar(
                      backgroundImage: AssetImage(chatImages[index]),
                    ),
                    title: Center(
                      child: Text(
                        chats[index],
                        style: TextStyle(
                          fontFamily: AutofillHints.birthday,
                          fontWeight: FontWeight.bold,
                          color: isDarkModeEnabled ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    subtitle: FutureBuilder<String>(
                      future: BaseDeDonne.instance.readLastMessageText(), // Utilisez la méthode pour obtenir le dernier message
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          // Affiche un indicateur de chargement pendant que la valeur est en cours de récupération
                          return CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          // Affiche un message d'erreur si une erreur survient lors de la récupération de la valeur
                          return Text('Erreur de récupération du dernier message');
                        } else {
                          // Affiche la valeur récupérée du dernier message
                          return Text(
                            snapshot.data ?? '', // Utilisez snapshot.data pour obtenir la valeur
                            style: TextStyle(
                              fontFamily: AutofillHints.birthday,
                              fontWeight: FontWeight.bold,
                              color: isDarkModeEnabled ? Colors.white : Colors.black,
                            ),
                          );
                        }
                      },
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

