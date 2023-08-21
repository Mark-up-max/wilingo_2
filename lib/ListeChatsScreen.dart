import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_statusbarcolor_ns/flutter_statusbarcolor_ns.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'CONJUGUAISON.dart';
import 'DICTIONNAIRE.dart';
import 'anglais.dart';
import 'chat_screen.dart';
import 'chat_screenn.dart';
import 'anglisfrancais.dart';
import 'cuisine.dart';
import 'dico.dart';

class BasesDeDonne {
  static const dbName = "wilingomode";
  static const dbVersion = 1;
  static const dbTableMessages = "darkmode";
  static const dbTableSettings = "settings";
  static const columnId = "id";
  static const columnName = "name";
  static const columnIsDarkModeEnabled = "isDarkModeEnabled";

  static final BasesDeDonne instance = BasesDeDonne._();
  late Database _database;

  BasesDeDonne._() {
    initDB();
  }

  Future<Database> get database async {
    if (_database != null && _database.isOpen) return _database;
    _database = await initDB();
    return _database;
  }

  Future<Database> initDB() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String path = join(directory.path, dbName);
    _database = await openDatabase(path, version: dbVersion, onCreate: onCreate);
    return _database;
  }

  Future<void> onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $dbTableSettings (
        $columnId INTEGER PRIMARY KEY,
        $columnIsDarkModeEnabled INTEGER
      )
    ''');
  }

  Future<void> setDarkModeEnabled(bool isEnabled) async {
    final db = await database;
    await db.insert(dbTableSettings, {
      columnId: 1,
      columnIsDarkModeEnabled: isEnabled ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<bool> isDarkModeEnabled() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(dbTableSettings);
    if (result.isNotEmpty) {
      return result.first[columnIsDarkModeEnabled] == 1;
    }
    return false;
  }
}

class ListeChatsScreen extends StatefulWidget {
  @override
  _ListeChatsScreenState createState() => _ListeChatsScreenState();
}

class _ListeChatsScreenState extends State<ListeChatsScreen> with SingleTickerProviderStateMixin {
  final List<String> chats = [
    '[Dictionnaire Français]',
    '[Dictionnaire Bilingue]',
    '[Conjugaison]',
    '[Traducteur]',
    '[Jeux]',
    '[Cuisine]',
  ];

  final List<String> chatImages = [
    'images/avatar.png',
    'images/ima.jpg',
    'images/dico.jpg',
    'images/dictionnaire.jpg',
    'images/ima.jpg',
    'images/OIP (2).jpg',
    'images/param1.jpg',
  ];

  late TabController _tabController;
  bool isDarkModeEnabled = false;
  final String email = 'markmbala027@gmail.com'; // Remplacez par votre adresse e-mail

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    initDarkMode(); // Utilisez await pour attendre la fin de l'initialisation
  }


  Future<void> initDarkMode() async {
    await BasesDeDonne.instance.initDB(); // Initialisation de la base de données
    bool darkModeEnabled = await BasesDeDonne.instance.isDarkModeEnabled();
    setState(() {
      isDarkModeEnabled = darkModeEnabled;
    });
  }

  void toggleDarkMode() async {
    bool darkModeEnabled = !isDarkModeEnabled;
    await BasesDeDonne.instance.setDarkModeEnabled(darkModeEnabled);
    setState(() {
      isDarkModeEnabled = darkModeEnabled;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Rendre la barre d'état transparente avec des icônes noires
    FlutterStatusbarcolor.setStatusBarColor(Colors.transparent);
    isDarkModeEnabled ? FlutterStatusbarcolor.setStatusBarWhiteForeground(true) : FlutterStatusbarcolor.setStatusBarWhiteForeground(false);
    isDarkModeEnabled ? FlutterStatusbarcolor.setNavigationBarColor(Colors.black) : FlutterStatusbarcolor.setNavigationBarColor(Colors.white);
    isDarkModeEnabled ? FlutterStatusbarcolor.setNavigationBarWhiteForeground(true) : FlutterStatusbarcolor.setNavigationBarWhiteForeground(false);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: isDarkModeEnabled ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: isDarkModeEnabled ? Colors.grey[900] : Colors.white.withOpacity(0.6),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: isDarkModeEnabled ? AssetImage('images/fondclair.jpg') : AssetImage('images/lima.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundImage: isDarkModeEnabled ? AssetImage('images/fondclair.jpg') : AssetImage('images/ima.jpg'),
              ),
              SizedBox(width: 8.0),
              Text(
                'Wilingo',
                style: TextStyle(
                  fontSize: 30.0,
                  fontWeight: FontWeight.bold,
                  color: isDarkModeEnabled ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                child: Text(
                  'Discussions',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: isDarkModeEnabled ? Colors.white54 : Colors.black54,
                  ),
                ),
              ),
              Tab(
                child: Text(
                  'Paramètres',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: isDarkModeEnabled ? Colors.white54 : Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: isDarkModeEnabled ? AssetImage('images/themsombre.jpg') : AssetImage('images/themclair.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            TabBarView(
              controller: _tabController,
              children: [
                ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 18.0),
                  itemCount: chats.length,
                  itemBuilder: (BuildContext context, int index) {
                    return InkWell(
                      onTap: () {
                        if (chats[index] == '[Dictionnaire Bilingue]') {
                          if(isDarkModeEnabled){
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => DICTIONNAIRE(isDarkModeEnabled: true,)),
                            );
                          }else{
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => DICTIONNAIRE(isDarkModeEnabled: false,)),
                            );
                          }
                        }

                        else if (chats[index] == '[Cuisine]') {
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

                        else if (chats[index] == '[Conjugaison]') {
                          if(isDarkModeEnabled){
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => CONJUGUAISON(isDarkModeEnabled: true,)),
                            );
                          }else{
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => CONJUGUAISON(isDarkModeEnabled: false,)),
                            );
                          }
                        }

                        else if (chats[index] == '[Dictionnaire Français]') {
                          if(isDarkModeEnabled){
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(chatName: 'Français', index: 0, isDarkModeEnabled: true,),
                              ),
                            );
                          }else{
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(chatName: 'Français', index: 0, isDarkModeEnabled: false,),
                              ),
                            );
                          }
                        }

                        else if (chats[index] == '[Traducteur]') {
                          String jeuUrl = 'https://www.deepl.com/translator';
                          if(isDarkModeEnabled){
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => TraducteurScreen(url: jeuUrl, isDarkModeEnabled: true,)),
                            );
                          }else{
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => TraducteurScreen(url: jeuUrl, isDarkModeEnabled: false,)),
                            );
                          }
                        }

                        else if (chats[index] == '[Jeux]') {
                          String jeuUrl = 'https://jeux.larousse.fr/';
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

                        else if (chats[index] == '[Paramètre 1]') {
                          toggleDarkMode();
                        }
                      },
                      child: Card(
                        margin: EdgeInsets.symmetric(horizontal: 0.0, vertical: 18.0),
                        elevation: 20.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.0),
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
                                fontWeight: FontWeight.bold,
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
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: isDarkModeEnabled ? AssetImage('images/fondclair.jpg') : AssetImage('images/lima.jpg'),
                    ),
                  ),
                  alignment: Alignment.center,
                  padding: EdgeInsets.only(top: 80.0),
                  child: Column(
                    children: [
                      SizedBox(height: 16.0),
                      CircleAvatar(
                        backgroundImage: isDarkModeEnabled ? AssetImage('images/fondclair.jpg') : AssetImage('images/ima.jpg'),
                        radius: 50.0,
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        'Wilingo',
                        style: TextStyle(
                          fontSize: 25.0,
                          fontWeight: FontWeight.bold,
                          color: isDarkModeEnabled ? Colors.white : Colors.black,
                        ),
                      ),
                      SizedBox(height: 16.0),
                      Card(
                        margin: EdgeInsets.symmetric(horizontal: 32.0),
                        elevation: 8.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        child: ListTile(
                          onTap: toggleDarkMode,
                          leading: Icon(
                            isDarkModeEnabled ? Icons.check_box : Icons.check_box_outline_blank,
                            color: isDarkModeEnabled ? Colors.blueAccent : Colors.grey,
                          ),
                          title: Text(
                            isDarkModeEnabled ? 'Désactiver le mode sombre' : 'Activer le mode sombre',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: isDarkModeEnabled ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.0),
                      Card(
                        margin: EdgeInsets.symmetric(horizontal: 32.0),
                        elevation: 8.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        child: ListTile(
                          onTap: _launchEmailApp, // Appel de la fonction pour ouvrir l'application de messagerie
                          leading: Icon(
                            Icons.email,
                            color: isDarkModeEnabled ? Colors.white : Colors.grey,
                          ),
                          title: Text(
                            'Contactez-nous',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: isDarkModeEnabled ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _launchEmailApp() async {
    final Uri params = Uri(
      scheme: 'mailto',
      path: email,
    );

    if (await canLaunch(params.toString())) {
      await launch(params.toString());
    } else {
      throw 'Impossible de lancer l\'application de messagerie';
    }
  }
}

class TraducteurScreen extends StatelessWidget {
  final String url;
  final bool isDarkModeEnabled;

  TraducteurScreen ({required this.url, required this.isDarkModeEnabled});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkModeEnabled ? Colors.black54 : Colors.white,
        title: Text('Traducteur',
            style:
            TextStyle(
              color: isDarkModeEnabled ? Colors.white : Colors.black,
            )),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDarkModeEnabled ? Colors.white : Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: WebView(
        initialUrl: url,
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}


class JeuxScreen extends StatelessWidget {
  final String url;
  final bool isDarkModeEnabled;

  JeuxScreen ({required this.url, required this.isDarkModeEnabled});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkModeEnabled ? Colors.black54 : Colors.white,
        title: Text('Jeux',
            style:
            TextStyle(
              color: isDarkModeEnabled ? Colors.white : Colors.black,
            )),
      ),
      body: WebView(
        initialUrl: url,
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}