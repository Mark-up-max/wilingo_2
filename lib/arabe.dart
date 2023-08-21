import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:marquee/marquee.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/widgets.dart';
import 'package:gesture_zoom_box/gesture_zoom_box.dart';

class BaseDeDonne {
  static const dbName = "arabe";
  static const dbVersion = 1;
  static const dbTable = "smsarabe";
  static const columnId = "idearabe";
  static const columnName = "namesarabe";

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

  // Insère un message dans la base de données
  Future<int> insertMessage(ChatMessage message) async {
    final db = await BaseDeDonne.instance.database;
    return await db.insert(dbTable, {
      'text': message.text,
      'isUserMessage': message.isUserMessage,
      'time': message.time.millisecondsSinceEpoch,
      'soundUrl': message.soundUrl,
    });
  }

  // Lit tous les messages de la base de données
  Future<List<ChatMessage>> readMessages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(dbTable, orderBy: 'time DESC');
    return List.generate(maps.length, (i) {
      return ChatMessage(
        text: maps[i]['text'],
        isUserMessage: maps[i]['isUserMessage'] == 1 ? true : false,
        time: DateTime.fromMillisecondsSinceEpoch(maps[i]['time']),
        soundUrl: maps[i]['soundUrl'],
      );
    });
  }

  // Supprime un message de la base de données en fonction de son horodatage
  Future<int> deleteMessage(DateTime messageTime) async {
    final db = await database;
    return await db.delete(dbTable, where: 'time = ?', whereArgs: [messageTime.millisecondsSinceEpoch]);
  }
}


class arabe extends StatefulWidget {
  final String chatName;
  final int index;
  final bool isDarkModeEnabled;
  arabe({required this.chatName, required this.index, required this.isDarkModeEnabled});

  @override
  arabeState createState() => arabeState();
}

class arabeState extends State<arabe> with SingleTickerProviderStateMixin {
  // Liste des messages
  List<ChatMessage> _messages = [];

  // Contrôleur de texte pour le champ de saisie
  TextEditingController _textController = TextEditingController();

  // Contrôleur de défilement pour la liste de messages
  ScrollController _scrollController = ScrollController();

  // Contrôleur de défilement pour l'élément spécifique dans la liste
  ItemScrollController _crollController = ItemScrollController();

  // Contrôleur d'animation pour les animations des messages
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Indicateur pour le mode de traduction (français-italien ou italien-français)
  bool isFrancaisItalien = true;

  // Clé pour la liste de messages
  GlobalKey _listKey = GlobalKey();

  // Liste des suggestions filtrées
  List<String> _filteredSuggestions = [];

  // Indicateur pour le mode sombre


  // Indicateur pour afficher ou masquer le bouton de défilement
  bool _showFloatingButton = false;

  // Index du dernier message
  int _lastMessageIndex = 1;

  // Liste des suggestions de mots
  List<String> suggestions = [
    'Bonjour',
    'Merci',
    'Oui',
    'Non',
    'S\'il vous plaît',
    'Excusez-moi',
    'Au revoir',
    'Comment ça va ?',
    'Quel est ton nom ?',
    'J\'ai faim'
  ];

  @override
  void initState() {
    super.initState();
    initializeData();

    // Initialisation des contrôleurs de défilement
    _crollController = ItemScrollController();

    // Écouteur de défilement pour afficher/masquer le bouton de défilement
    _scrollController.addListener(() {
      setState(() {
        _showFloatingButton = _scrollController.position.pixels > 900;
      });
    });
  }

  Future<void> initializeData() async {
    await BaseDeDonne.instance.initDB(); // Initialisation de la base de données

    String welcomeMessage = "Bienvenue à vous ! Je suis ici pour vous aider à trouver les définitions des mots. N'hésitez pas à poser vos questions.";

    ChatMessage welcomeChatMessage = ChatMessage(
      text: welcomeMessage,
      isUserMessage: false,
      time: DateTime.now(),
      soundUrl: "",
    );

    setState(() {
      _messages.insert(0, welcomeChatMessage);
      _scrollToBottom();
    });

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);

    _playSound(welcomeChatMessage.soundUrl);
    _animateMessage(welcomeChatMessage);

    // Lecture de tous les messages
    List<ChatMessage> messages = await BaseDeDonne.instance.readMessages();
    List<ChatMessage> chatMessages = messages.map((message) => ChatMessage(
      text: message.text,
      isUserMessage: message.isUserMessage,
      time: message.time,
      soundUrl: message.soundUrl,
    )).toList();

    setState(() {
      _messages.insertAll(0, chatMessages);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _playSound(String? soundUrl) {
    if (soundUrl != null && soundUrl.isNotEmpty) {
      AudioPlayer audioPlayer = AudioPlayer();
      audioPlayer.play(soundUrl);
    }
  }

  void _handleSubmitted(String text) async {
    AudioPlayer audioPlayer = AudioPlayer();
    audioPlayer.play('assets/son/son.wav'); // Remplacez le chemin du fichier audio par le vôtre
    _textController.clear();

    ChatMessage userMessage = ChatMessage(
      text: text,
      isUserMessage: true,
      time: DateTime.now(),
      soundUrl: "https://www.larousse.fr/dictionnaires/francais-allemand/$text",
    );
    await BaseDeDonne.instance.insertMessage(userMessage);  // Sauvegarde du message dans la base de données

    setState(() {
      _messages.insert(0, userMessage);
    });

    setState(() {
      _messages.insert(0, _buildLoadingMessage());
    });

    _playSound(userMessage.soundUrl);
    _animateMessage(userMessage);

    String url = isFrancaisItalien
        ? "https://www.larousse.fr/dictionnaires/francais-arabe/$text"
        : "https://www.larousse.fr/dictionnaires/arabe-francais/$text";

    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        audioPlayer.play('assets/son/son.wav'); // Remplacez le chemin du fichier audio par le vôtre
        dom.Document document = parser.parse(response.body);

        dom.Element? definitionsElement = document.querySelector('.article_bilingue');
        if (definitionsElement != null) {
          String definitionsText = definitionsElement.text;
          String message = "😁 Autre chose?";

          ChatMessage additionalMessage = ChatMessage(
            text: message,
            isUserMessage: false,
            time: DateTime.now(),
            soundUrl: "",
          );

          ChatMessage aiMessage = ChatMessage(
            text: definitionsText,
            isUserMessage: false,
            time: DateTime.now(),
            soundUrl: "",
          );

          // Insérer un message dans la base de données
          await BaseDeDonne.instance.insertMessage(aiMessage);

          // Simulated delay for getting the answer
          setState(() {
            _messages[0] = ChatMessage(
              text: definitionsText,
              isUserMessage: false,
              time: DateTime.now(),
              soundUrl: "",
            );
            _messages.insert(0, additionalMessage);
            _scrollToBottom();
          });

          _playSound(aiMessage.soundUrl);
          _playSound(additionalMessage.soundUrl);
          _animateMessage(aiMessage);
          _animateMessage(additionalMessage);
        } else {
          String errorMessage = "Désolé, mais je ne comprends pas votre mot 😅. \n -Vérifiez-le si possible, je suis beaucoup plus efficace si les mots sont entrés un à un. \n -Il peut également s'agir d'un dysfonctionnement lié à mes services. Dans ce cas, veuillez patienter.";
          String errorMessageAra = "آسف، لكنني لا أفهم كلمتك 😅. \n -تحقق منها إذا كان ذلك ممكنًا، فأنا أكثر فعالية إذا تم إدخال الكلمات بشكل فردي. \n  😅 -قد يكون ذلك ناتجًا عن عطل في خدماتي. في هذه الحالة، يرجى الانتظار.";
          ChatMessage aiMessage = ChatMessage(
            text: isFrancaisItalien ? errorMessage : errorMessageAra,
            isUserMessage: false,
            time: DateTime.now(),
            soundUrl: "https://www.larousse.fr/dictionnaires/francais/$text",
          );

          // Insérer un message dans la base de données
          await BaseDeDonne.instance.insertMessage(aiMessage);

          setState(() {
            // Remplacez le message de chargement par le message attendu à l'index 0
            _messages[0] = aiMessage;
          });

          _playSound(aiMessage.soundUrl);
          _animateMessage(aiMessage);
        }
      }
    } catch (e) {
      String errorMessage = "Désolé 😥, veuillez vérifier votre connexion internet s'il vous plaît.";
      String errorMessageAra = "آسف 😥، يرجى التحقق من اتصالك بالإنترنت.";
      ChatMessage aiMessage = ChatMessage(
        text: isFrancaisItalien ? errorMessage : errorMessageAra,
        isUserMessage: false,
        time: DateTime.now(),
        soundUrl: "https://www.larousse.fr/dictionnaires/francais/$text",
      );

      // Insérer un message dans la base de données
      await BaseDeDonne.instance.insertMessage(aiMessage);

      setState(() {
        // Remplacez le message de chargement par le message attendu à l'index 0
        _messages[0] = aiMessage;
      });

      _playSound(aiMessage.soundUrl);
      _animateMessage(aiMessage);
    }
  }

  void _filterSuggestions(String keyword) {
    // Filtrer les mots de la base de données de l'utilisateur
    List<String> filteredWords = _messages
        .where((message) =>
    message.isUserMessage &&
        message.text.toLowerCase().startsWith(keyword.toLowerCase()))
        .map((message) => message.text)
        .toList();

    setState(() {
      _filteredSuggestions = filteredWords;
    });
  }

  void _scrollToSuggestion(String suggestion) {
    final int index = _messages.indexWhere((message) =>
    message.isUserMessage &&
        message.text.toLowerCase() == suggestion.toLowerCase());
    if (index != -1) {
      _scrollToIndex(index);
    }
  }

  void _scrollToIndex(int index) {
    _crollController.scrollTo(
      index: index,
      duration: Duration(milliseconds: 1000),
      curve: Curves.easeOut,
    );
  }

  Widget _buildMessage(ChatMessage message) {
    return ChatMessage(
      text: message.text,
      isUserMessage: message.isUserMessage,
      time: message.time,
      soundUrl: message.soundUrl,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      if (_crollController != null) {
        _crollController.scrollTo(
          index: 0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  ChatMessage _buildLoadingMessage() {
    return ChatMessage(
      text: '.....',
      isUserMessage: false,
      time: DateTime.now(),
      soundUrl: "",
    );
  }

  void _animateMessage(ChatMessage message) {
    _animationController.forward(from: 0.0); // Démarre l'animation depuis le début
  }

  Widget _buildSuggestionBubble(String suggestion) {
    return GestureDetector(
      onTap: () {
        _scrollToSuggestion(suggestion); // Défiler jusqu'au message correspondant
      },
      child: Container(
        padding: EdgeInsets.all(8.0),
        margin: EdgeInsets.only(right: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: Offset(0, 2),
              blurRadius: 4.0,
            ),
          ],
        ),
        child: Text(
          suggestion,
          style: TextStyle(
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSuggestionBubbles() {
    return _filteredSuggestions
        .map((suggestion) => _buildSuggestionBubble(suggestion))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.isDarkModeEnabled ? Colors.black54 : Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage('images/télécharger.png'),
            ),
            SizedBox(width: 8.0),
            Text(isFrancaisItalien ? 'Français - Arabe' : '..بية - الفرنسية',
              style: TextStyle(color: widget.isDarkModeEnabled ? Colors.white : Colors.black
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: widget.isDarkModeEnabled ? Colors.white : Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          PopupMenuButton(
            color: Colors.deepPurpleAccent,
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                child: ListTile(
                  leading:Icon(
                    Icons.access_time,
                    color: Colors.white,
                    size: 24,
                  ),
                  title: Text(isFrancaisItalien ? 'Historique des discussions' : 'سجل المحادثات',
                    style: TextStyle(
                        color: Colors.white),
                  ),
                  onTap: () async {
                    Navigator.pop(context); // Fermer le menu contextuel
                    if(widget.isDarkModeEnabled){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Dicoitalien(userMessages: _messages, isDarkModeEnabled: true,)),
                      );
                    }else{
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Dicoitalien(userMessages: _messages, isDarkModeEnabled: false,)),
                      );
                    }
                  },
                ),
              ),
              PopupMenuItem(
                child: ListTile(
                  leading:Icon(
                    isFrancaisItalien ? Icons.arrow_forward : Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                  title: Text(isFrancaisItalien ?  'العربية - الفرنسية' : 'Français - Arabe',
                    style: TextStyle(
                        color: Colors.white),
                  ),
                  onTap: () {
                    setState(() {
                      isFrancaisItalien = !isFrancaisItalien;
                    });
                    Navigator.pop(context); // Fermer le menu contextuel
                    isFrancaisItalien ?
                    setState(() {
                      _messages[0] = ChatMessage(
                        text: "Super ! 😁 Nous passons à nouveau au français. je vais vous aider à trouver les définitions des mots en français-arabe. \nN'hésitez pas à poser vos questions.",
                        isUserMessage: false,
                        time: DateTime.now(),
                        soundUrl: "",
                      );
                      _scrollToBottom();
                    }) : setState(() {
                      _messages[0] = ChatMessage(
                        text: "Super ! 😁 Nous passons à présent à l'arabe. \nسأساعدك في إيجاد تعريفات الكلمات باللغة العربية-الفرنسية. \nلا تتردد في طرح أسئلتك.",
                        isUserMessage: false,
                        time: DateTime.now(),
                        soundUrl: "",
                      );
                      _scrollToBottom();
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: widget.isDarkModeEnabled ? AssetImage('images/2emsombre.jpg') : AssetImage('images/sans.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ScrollablePositionedList.builder(
                    reverse: true,
                    itemScrollController: _crollController,
                    itemCount: _messages.length,
                    itemBuilder: (BuildContext context, int index) {
                      final message = _messages[index];
                      return FadeTransition(
                        opacity: _animation,
                        child: SlideTransition(
                          position: _animation.drive(
                            Tween(begin: Offset(0.0, 0.5), end: Offset.zero).chain(
                              CurveTween(curve: Curves.easeOut),
                            ),
                          ),
                          child: GestureZoomBox(
                            maxScale: 3.0,
                            child: _buildMessage(message),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _buildSuggestionBubbles(),
                        ),
                      ),
                      SizedBox(height: 8.0),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              onSubmitted: _handleSubmitted,
                              onChanged: _filterSuggestions,
                              decoration: InputDecoration(
                                hintText: isFrancaisItalien ? 'Ecrire un mot en français' : 'اكتب كلمة باللغة العربية',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.send),
                            onPressed: () {
                              _handleSubmitted(_textController.text);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 66.0,
            right: 16.0,
            child: FloatingActionButton(
              onPressed: _scrollToLastMessage,
              child: Icon(Icons.arrow_downward),
              mini: true,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToLastMessage() {
    _crollController.scrollTo(
      index: 0,
      duration: Duration(milliseconds: 1000),
      curve: Curves.easeOut,
    );
  }
}


class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUserMessage;
  final DateTime time;
  final String soundUrl;

  ChatMessage({
    required this.text,
    required this.isUserMessage,
    required this.time,
    required this.soundUrl,
  });

  void playSound() {
    if (soundUrl.isNotEmpty) {
      AudioPlayer audioPlayer = AudioPlayer();
      audioPlayer.play(soundUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth= MediaQuery.of(context).size.width != null ? MediaQuery.of(context).size.width * 0.8 : 0.0;

    final messageBubble = GestureDetector(
      onTap: playSound,
      onLongPress: () {
        _showMessageOptions(context, ChatMessage);
      },
      child: Container(
        padding: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: isUserMessage ? Colors.white : Colors.deepPurpleAccent,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: Offset(0, 2),
              blurRadius: 4.0,
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUserMessage ? Colors.black : Colors.white,
          ),
        ),
      ),
    );

    final messageWidget = Container(
      padding: EdgeInsets.all(8.0),
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
        ),
        child: messageBubble,
      ),
    );

    final timeWidget = Text(
      DateFormat.Hm().format(time),
      style: TextStyle(
        fontSize: 12.0,
        color: Colors.grey,
      ),
    );

    final messageRow = Row(
      mainAxisAlignment:
      isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        isUserMessage ? Container() : Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundImage: AssetImage('images/télécharger.png'),
            radius: 10.0,
          ),
        ),
        SizedBox(width: 8.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            messageWidget,
            SizedBox(height: 2.0),
            timeWidget,
          ],
        ),
      ],
    );

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: messageRow,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUserMessage': isUserMessage ? 1 : 0,
      'time': time.millisecondsSinceEpoch,
      'soundUrl': soundUrl,
    };
  }

  void _showMessageOptions(BuildContext context, Type chatMessage) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.content_copy),
                title: Text('Copier'),
                onTap: () {
                  _copyMessageToClipboard(context, text);
                  Navigator.pop(context); // Fermer le menu contextuel
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _copyMessageToClipboard(BuildContext context, String message) {
    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Message copié !')),
    );
  }
}


class Dicoitalien extends StatefulWidget {
  final List<ChatMessage> userMessages;
  bool isDarkModeEnabled;
  Dicoitalien({required this.userMessages, required this.isDarkModeEnabled});

  @override
  DicoitalienState createState() => DicoitalienState();
}

class DicoitalienState extends State<Dicoitalien> {
  List<ChatMessage> _userMessages = [];

  @override
  void initState() {
    super.initState();
    _userMessages = widget.userMessages;
  }

  @override
  Widget build(BuildContext context) {
    List<ChatMessage> filteredUserMessages =
    _userMessages.where((message) => message.isUserMessage == true).toList();

    List<ChatMessage> filteredIAMessages =
    _userMessages.where((message) => message.isUserMessage == false).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: widget.isDarkModeEnabled ? Colors.black54 : Colors.white,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: widget.isDarkModeEnabled ? Colors.white : Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text('Historique des discussions',
            style: TextStyle(
                color: widget.isDarkModeEnabled ? Colors.white : Colors.black
            ),
          ),
          bottom: TabBar(
            tabs: [
              Tab(
                child: Text(
                  'Utilisateur',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.purpleAccent,
                  ),
                ), ),
              Tab(
                child: Text(
                  'IA',
                  style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.purpleAccent
                  ),
                ),
              )
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUserMessagesList(filteredUserMessages),
            _buildIAMessagesList(filteredIAMessages),
          ],
        ),
      ),
    );
  }

  Widget _buildUserMessagesList(List<ChatMessage> messages) {
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (BuildContext context, int index) {
        ChatMessage message = messages[index];

        return _buildMessageCard(context, message);
      },
    );
  }

  Widget _buildIAMessagesList(List<ChatMessage> messages) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: messages.length,
      itemBuilder: (BuildContext context, int index) {
        ChatMessage message = messages[index];

        return Container(
          width: 300, // Largeur du widget ListView horizontal
          child: Card(
            elevation: 2.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: GestureDetector(
              onLongPress: () {
                showMenu(
                  context: context,
                  position: RelativeRect.fromLTRB(0, 0, 0, 0),
                  items: <PopupMenuEntry>[
                    PopupMenuItem(
                      child: ListTile(
                        leading: Icon(Icons.content_copy),
                        title: Text('Copier'),
                        onTap: () {
                          _copyMessageToClipboard(context, message.text);
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    PopupMenuItem(
                      child: ListTile(
                        leading: Icon(Icons.delete),
                        title: Text('Supprimer'),
                        onTap: () {
                          _deleteMessage(context, message);
                          // Supprimer le message de la liste des messages
                          Navigator.of(context).pop();
                          setState(() {}); // Mettre à jour l'interface utilisateur
                        },
                      ),
                    ),
                  ],
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(message.time),
                      style: TextStyle(
                        fontSize: 12.0,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          message.text,
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageCard(BuildContext context, ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Card(
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: GestureDetector(
          onLongPress: () {
            showMenu(
              context: context,
              position: RelativeRect.fromLTRB(0, 0, 0, 0),
              items: <PopupMenuEntry>[
                PopupMenuItem(
                  child: ListTile(
                    leading: Icon(Icons.content_copy),
                    title: Text('Copier'),
                    onTap: () {
                      _copyMessageToClipboard(context, message.text);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                PopupMenuItem(
                  child: ListTile(
                    leading: Icon(Icons.delete),
                    title: Text('Supprimer'),
                    onTap: () {
                      _deleteMessage(context, message);
                      // Supprimer le message de la liste des messages
                      setState(() {}); // Mettre à jour l'interface utilisateur
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            );
          },
          child: ListTile(
            leading: message.isUserMessage
                ? Icon(Icons.access_time_outlined, color: Colors.deepPurpleAccent)
                : Icon(Icons.android, color: Colors.green),
            title: Text(
              message.text,
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              DateFormat('dd/MM/yyyy HH:mm').format(message.time),
              style: TextStyle(
                fontSize: 12.0,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _copyMessageToClipboard(BuildContext context, String message) {
    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Message copié !')),
    );
  }

  void _deleteMessage(BuildContext context, ChatMessage message) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Supprimer le message ?'),
          content: Text('Êtes-vous sûr de vouloir supprimer ce message ?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                _performMessageDeletion(context, message);
                _userMessages.removeWhere((m) => m.time == message.time);
                setState(() {}); // Mettre à jour l'interface utilisateur
                Navigator.of(dialogContext).pop();
              },
              child: Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  void _performMessageDeletion(BuildContext context, ChatMessage message) async {
    // Supprimer le message de la base de données
    await BaseDeDonne.instance.deleteMessage(message.time);

    // Supprimer le message de la liste des messages
    _userMessages.removeWhere((m) => m.time == message.time);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Message supprimé !')),
    );
  }
}
