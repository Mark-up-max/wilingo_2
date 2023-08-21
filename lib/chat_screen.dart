import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import 'package:image_picker/image_picker.dart';
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
import 'dart:math'; // Importer la classe Random depuis la bibliothèque dart:math
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;


class BaseDeDonne {
  static const dbName = "lingo";
  static const dbVersion = 1;
  static const dbTable = "sms";
  static const columnId = "ide";
  static const columnName = "names";

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

class ChatScreen  extends StatefulWidget {
  final String chatName;
  final int index;
  final bool isDarkModeEnabled;
  ChatScreen ({required this.chatName, required this.index, required this.isDarkModeEnabled});

  @override
  ChatScreenState createState() => ChatScreenState();
}


class ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  CorrectionOrthographique correctionOrthographique = CorrectionOrthographique();
  VoiceSearchManager voiceSearchManager = VoiceSearchManager();

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

  List<String> mots = [
    'A',
    'Avion',
    'Ananas',
    'Arbre',
    'Alligator',
    'Amour',
    'Aspirateur',
    'Automne',
    'Aventure',
    'Ambulance',
    'Astronaute',
    'B',
    'Banane',
    'Ballon',
    'Basket',
    'Bateau',
    'Bonjour',
    'Bougie',
    'Boisson',
    'Bureau',
    'Bouteille',
    'Boulangerie',
    'C',
    'chat',
    'chien',
    'Chat',
    'Chien',
    'Chapeau',
    'Crayon',
    'Canapé',
    'Cuisine',
    'Coeur',
    'Cloche',
    'Cycliste',
    'Cadeaux',
    'D',
    'Drapeau',
    'Diable',
    'Danse',
    'Doigt',
    'Dodo',
    'Dessin',
    'Douceur',
    'Diable',
    'Dune',
    'Départ',
    'E',
    'École',
    'Étoile',
    'Enfant',
    'Éléphant',
    'Eau',
    'Espace',
    'Escalier',
    'Estomac',
    'Énergie',
    'Église',
    'Autres',
    'oiseau',
    'maison',
    'jardin',
    'soleil',
  ];

  // Indicateur pour afficher ou masquer le bouton de défilement
  bool _showFloatingButton = false;

  // Index du dernier message
  int _lastMessageIndex = 1;

  Timer? _bubbleTime; // Timer pour la bulle de discussion

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

  double _buttonPositionX = 300.0; // Position horizontale du bouton flottant
  double _buttonPositionY = 40.0; // Position verticale du bouton flottant


  // Enregistreur vocal
  bool _isRecording = false;
  String _recordedText = '';


  @override
  void initState() {
    super.initState();
    initializeData();


    // Initialisation des contrôleurs de défilement
    _crollController = ItemScrollController();

    _startBubble(); // Appel de la méthode pour démarrer le minuteur de la bulle de discussion

    // Écouteur de défilement pour afficher/masquer le bouton de défilement
    _scrollController.addListener(() {
      setState(() {
        _showFloatingButton = _scrollController.position.pixels > 900;
      });
    });
  }

  String vocal = "";

  Future<void> initializeData() async {
    await BaseDeDonne.instance.initDB(); // Initialisation de la base de données

    String welcomeMessage = "Bienvenue à vous ! 🤗 \nJe suis ici pour vous aider à trouver les définitions des mots. N'hésitez pas à poser vos questions.\nVous pouvez également insérer des phrases, Je vous donnerai la définition de chacun des mots.";

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
    _textController.dispose();
    voiceSearchManager.stopListening();
    super.dispose();
  }






  void _startBubble() {
    _bubbleTime = Timer.periodic(Duration(seconds: 15), (timere) {
      if (timere.isActive) {
        setState(() {
          _showBubbleMessage();
        });
      }
    });
  }



  void _stopBubbleTimer() {
    _bubbleTimer?.cancel();
  }




  VoiceSearchManager vocalmot = VoiceSearchManager();

  void _handleSubmitted(String text) async {
    AudioPlayer audioPlayer = AudioPlayer();
    _textController.clear();


    // Si un texte a été enregistré vocalement, ajoutez-le également
    if (_recordedText.isNotEmpty) {
      _textController.text = vocalmot.retournermot();
    }

    // Réinitialisez le texte enregistré
    setState(() {
      _recordedText = '';
    });


    String message = "😁 Autre chose?";

    ChatMessage additionalMessage = ChatMessage(
      text: message,
      isUserMessage: false,
      time: DateTime.now(),
      soundUrl: "",
    );

    List<String> words = text.split(' '); // Sépare la phrase en mots

    for (String word in words) {
      ChatMessage userMessage = ChatMessage(
        text: word,
        isUserMessage: true,
        time: DateTime.now(),
        soundUrl: "https://www.larousse.fr/dictionnaires/dictionnaires-prononciation/francais/$word",
      );
      await BaseDeDonne.instance.insertMessage(userMessage);

      setState(() {
        _messages.insert(0, userMessage);
        _messages.insert(0, _buildLoadingMessage());
      });

      _playSound(userMessage.soundUrl);
      _animateMessage(userMessage);

      String larousseUrl = "https://www.larousse.fr/dictionnaires/francais/$word";

      try {
        http.Response response = await http.get(Uri.parse(larousseUrl));

        if (response.statusCode == 200) {
          audioPlayer.play('assets/son/son - Copie.mp3', isLocal: true);

          dom.Document document = parser.parse(response.body);

          dom.Element? definitionsElement = document.querySelector('#definition');
          if (definitionsElement != null) {
            String definitionsText = definitionsElement.text;



            // Méthode pour formater le texte du dernier message
            String formatLastMessage(String text) {
              text = text.replaceAll('\n', ' '); // Supprime les retours à la ligne
              return text;
            }
            String nouveu_mot_IA = formatLastMessage(definitionsText);

            DateTime date = DateTime.now();


            setState(() {
              _messages.insert(0,  ChatMessage(
                text: '$date',
                isUserMessage: true,
                time: DateTime.now(),
                soundUrl: "",
              ));
              _scrollToBottom();
            });

            ChatMessage aiMessage = ChatMessage(
              text: nouveu_mot_IA,
              isUserMessage: false,
              time: DateTime.now(),
              soundUrl: "",
            );

            await BaseDeDonne.instance.insertMessage(aiMessage);

            setState(() {
              _messages[0] = aiMessage;
              _scrollToBottom();
            });

            _playSound(aiMessage.soundUrl);
            _animateMessage(aiMessage);

            await Future.delayed(Duration(seconds: 2)); // Attendre quelques secondes avant d'afficher la définition suivante
          }
        } else {
          String errorMessage = "Désolé, mais je ne comprends pas votre mot 😅. Vérifiez-le si possible, je suis beaucoup plus efficace si les mots sont entrés un à un.";
          ChatMessage aiMessage = ChatMessage(
            text: errorMessage,
            isUserMessage: false,
            time: DateTime.now(),
            soundUrl: "https://www.larousse.fr/dictionnaires/francais/$text",
          );

          // Insérer un message dans la base de données
          await BaseDeDonne.instance.insertMessage(aiMessage);

          setState(() {
            // Remplacez le message de chargement par le message attendu à l'index 0
            _messages[0] = aiMessage;
            _scrollToBottom();
          });

          _playSound(aiMessage.soundUrl);
          _animateMessage(aiMessage);
        }
      } catch (e) {
        String errorMessage = "Désolé 😥, veuillez vérifier votre connexion internet s'il vous plaît.";
        ChatMessage aiMessage = ChatMessage(
          text: errorMessage,
          isUserMessage: false,
          time: DateTime.now(),
          soundUrl: "https://www.larousse.fr/dictionnaires/francais/$word",
        );

        await BaseDeDonne.instance.insertMessage(aiMessage);

        setState(() {
          _messages[0] = aiMessage;
          _scrollToBottom();
        });

        _playSound(aiMessage.soundUrl);
        _animateMessage(aiMessage);

        await Future.delayed(Duration(seconds: 4)); // Attendre quelques secondes avant de passer au mot suivant
      }
    };
    setState(() {
      _messages.insert(0, additionalMessage);
      _scrollToBottom();
    });
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




  void _playSound(String? soundUrl) {
    if (soundUrl != null && soundUrl.isNotEmpty) {
      AudioPlayer audioPlayer = AudioPlayer();
      audioPlayer.play(soundUrl);
    }
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



  // Charger 10 mots aléatoires à partir du fichier texte
  Future<List<String>> chargerMotsAleatoires(List<String> listeDeMots) async {
    try {
      if (listeDeMots.length <= 10) {
        return listeDeMots;
      }

      // Mélanger la liste de mots
      listeDeMots.shuffle();

      // Sélectionner les 10 premiers mots
      return listeDeMots.sublist(0, 20);
    } catch (e) {
      print('Erreur lors du chargement des mots : $e');
      return [];
    }
  }




  // Afficher le menu contextuel contenant les mots aléatoires
  void afficherMenuMotsAleatoires(BuildContext context) async {
    List<String> motsAleatoires = await chargerMotsAleatoires(mots);
    if (motsAleatoires.isNotEmpty) {
      final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
      final Offset overlayPosition = overlay.localToGlobal(Offset.zero);

      showMenu(
        context: context,
        position: RelativeRect.fromLTRB(
          overlayPosition.dx,
          overlayPosition.dy,
          overlayPosition.dx + overlay.size.width,
          overlayPosition.dy + overlay.size.height,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0), // Ajuster le rayon selon votre préférence
        ),
        items: [
          PopupMenuItem(
            child: Column(
              children: [
                Text('Suggestions de mots', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                Divider(),
                ...motsAleatoires.map((mot) {
                  return ListTile(
                    title: Text(mot),
                    onTap: () {
                      // Ajouter le mot au chat pour être recherché
                      _textController.text = mot;
                      Navigator.of(context).pop();
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      );
    }
  }




  String _bubbleMessage = ''; // Message de la bulle de discussion
  Timer? _bubbleTimer; // Timer pour la bulle de discussion
  bool _isBubbleMessageAlignedRight = false;

  void _showBubbleMessage() {
    if (mots.isNotEmpty) {
      String randomWord1 = mots[Random().nextInt(mots.length)];
      mots.remove(randomWord1);

      String randomWord2 = mots.isNotEmpty
          ? mots[Random().nextInt(mots.length)]
          : '';

      String randomWord3 = mots.isNotEmpty
          ? mots[Random().nextInt(mots.length)]
          : '';

      bool isAlignedRight = _buttonPositionX > 150; // Ajustez la valeur en fonction de vos besoins

      setState(() {
        _bubbleMessage = '$randomWord1';
        _isBubbleMessageAlignedRight = isAlignedRight;
      });

      Future.delayed(Duration(seconds: 4), () {
        setState(() {
          _bubbleMessage = '$randomWord2';
        });
      });

      Future.delayed(Duration(seconds: 8), () {
        setState(() {
          _bubbleMessage = '$randomWord3';
        });
      });

      Future.delayed(Duration(seconds: 10), () {
        setState(() {
          _bubbleMessage = '';
          _isBubbleMessageAlignedRight = false;
        });
      });
    }
  }



  bool messageSuggestion = false;
  void _showCustomMenu(BuildContext context, double offsetX, double offsetY) {
    final RenderBox overlay = Overlay.of(context)!.context.findRenderObject() as RenderBox;
    final Offset position = Offset(offsetX, offsetY);


    final List<PopupMenuEntry<int>> menuItems = <PopupMenuEntry<int>>[
      PopupMenuItem<int>(
        value: 1,
        child: Row(
          children: [
            GestureDetector(
              onLongPress: _startRecording,
              onLongPressUp: _stopRecording,
              child: IconButton(
                icon: Container(
                  padding: EdgeInsets.all(4),
                  color: Colors.green, child: Icon(Icons.mic)),
                  color: Colors.white,
                onPressed: () {
                  // Exemple d'appel avec des valeurs personnalisées pour la position
                },
              ),
            ),
            Text('Microphone'),
          ],
        ),
      ),
      PopupMenuItem<int>(
        value: 2,
        child: Row(
          children: [
            GestureDetector(
              child: IconButton(
                icon: Container(
                  padding: EdgeInsets.all(4),
                    color: Colors.green,
                    child: Icon(Icons.camera)),
                    color: Colors.white,
                onPressed: () {
                  // Exemple d'appel avec des valeurs personnalisées pour la position
                  _openCamera();
                },
              ),
            ),
            Text('Caméra'),
          ],
        ),
      ),
      // Ajoutez d'autres options de menu si nécessaire
    ];

    showMenu<int>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(
          position,
          position,
        ),
        Offset.zero & overlay.size,
      ),
      items: menuItems,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0), // Ajuster le rayon selon votre préférence
        ),
    ).then((value) {
      if (value == 1) {
        // Appel de la méthode pour démarrer l'enregistrement vocal ici

      } else if (value == 2) {
        // Appel de la méthode pour utiliser la caméra ici

      }
    });
  }




  //Enregistreur
  StreamSubscription<String>? _voiceSubscription; // Déclarez cette variable en haut de votre classe
// ...

  void _startRecording() {
    setState(() {
      _isRecording = true;
    });

    // Assurez-vous de n'ajouter qu'un seul abonnement au flux
    if (_voiceSubscription == null) {
      _voiceSubscription = voiceSearchManager.onResult.listen((result) {
        setState(() {
          _recordedText = result;
          _textController.text = result; // Mettez à jour le texte dans la zone de texte
        });
      });
    }

    voiceSearchManager.startListening();
  }

  // ...

  void _stopRecording() {
    setState(() {
      _textController.text = _recordedText;
      _isRecording = false;
    });

    voiceSearchManager.stopListening();

    String resultatVocal = voiceSearchManager.retournermot();
    _textController.text = resultatVocal;
    _recordedText = '';
  }




  Future<void> _openCamera() async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(source: ImageSource.camera);

    if (pickedImage != null) {
      // Créez un widget Image pour afficher l'image capturée
      final imageWidget = Image.file(File(pickedImage.path));

      // Ajoutez le widget imageWidget à votre interface utilisateur
      // Par exemple, vous pourriez le placer dans un conteneur ou une colonne
      // pour afficher l'image sous le bouton de la caméra
      Container(
        color: Colors.white,
        width: 200,
        height: 200,
        child: imageWidget,
      );
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: widget.isDarkModeEnabled ? Colors.black : Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage('images/avatar.png'),
            ),
            SizedBox(width: 8.0),
            Text('Français',
              style: TextStyle(
                  color: widget.isDarkModeEnabled ? Colors.white : Colors.black
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0), // Ajuster le rayon selon votre préférence
            ),
            color: Colors.green,
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                child: ListTile(
                  leading:Icon(
                    Icons.access_time,
                    color: Colors.white,
                    size: 24,
                  ),
                  title: Text('Historique des discussions',
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
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            color: widget.isDarkModeEnabled ? Colors.black : Colors.white,
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
                              onChanged: (text) {
                                // Lorsque le texte change, appelez la fonction de correction et affichez le menu contextuel
                                // Obtenez les suggestions de correction à chaque changement de texte
                                String texteCorrige = correctionOrthographique.corrigerTexte(text);
                                List<String> suggestions = texteCorrige.split(' ');
                                setState(() {
                                  _filterSuggestions(text);
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Ecrire un mot',
                              ),
                            ),
                          ),
                          GestureDetector(
                            child: IconButton(
                              color: Colors.green,
                              icon: Icon(Icons.add_circle), // Icône d'option
                              onPressed: () {
                                // Exemple d'appel avec des valeurs personnalisées pour la position
                                _showCustomMenu(context, 170.0, 620.0); // Remplacez par les valeurs souhaitées
                              },
                            ),
                          ),
                          IconButton(
                            color: Colors.green,
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
              foregroundColor: Colors.green,
            ),
          ),
          Positioned(
            left: _buttonPositionX,
            top: _buttonPositionY,
            child: Draggable(
              feedback: FloatingActionButton(
                onPressed: () {},
                child: Icon(Icons.lightbulb),
              ),
              child: FloatingActionButton(
                onPressed: () {
                  // Lorsque le bouton est cliqué, appelez la méthode de suggestions
                  afficherMenuMotsAleatoires(context);
                },
                child: Icon(Icons.lightbulb),
                mini: true,
              ),
              onDraggableCanceled: (velocity, offset) {
                // Mettre à jour les positions horizontale et verticale lorsqu'on lâche le bouton
                setState(() {
                  _buttonPositionX = offset.dx;
                  _buttonPositionY = offset.dy;
                });
              },
            ),
          ),
          Positioned(
            left: _isBubbleMessageAlignedRight ? null : _buttonPositionX + 45, // Ajuster la position en fonction de l'icône du bouton
            right: _isBubbleMessageAlignedRight ? (MediaQuery.of(context).size.width - _buttonPositionX ) : null,
            top: _isBubbleMessageAlignedRight ?  _buttonPositionY - 5 : _buttonPositionY - 10, // Ajuster la position en fonction de l'icône du bouton
            child: AnimatedOpacity(
              opacity: _bubbleMessage.isNotEmpty ? 1.0 : 0.0,
              duration: Duration(milliseconds: 300),
              child: Container(
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Text(
                  _bubbleMessage,
                  style: TextStyle(color: Colors.white),
                ),
              ),
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




  // Implémentez la fonction pour afficher le menu contextuel
  void afficherMenuContextuel(BuildContext context) {
    // Obtenez le texte saisi par l'utilisateur
    String texteSaisi = _textController.text;

    // Corrigez le texte en utilisant la classe CorrectionOrthographique
    String texteCorrige = correctionOrthographique.corrigerTexte(texteSaisi);

    // Obtenez les suggestions de correction à partir du texte corrigé
    List<String> suggestions = texteCorrige.split(' ');

    if (suggestions.isNotEmpty) {
      final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
      final Offset overlayPosition = overlay.localToGlobal(Offset.zero);

      showMenu(
        context: context,
        position: RelativeRect.fromLTRB(
          overlayPosition.dx, // left
          overlayPosition.dy, // top
          overlayPosition.dx + overlay.size.width, // right
          overlayPosition.dy + overlay.size.height, // bottom
        ),
        items: suggestions.map((suggestion) {
          return PopupMenuItem<String>(
            child: Text(suggestion),
            onTap: () {
              // Remplacez le texte saisi par l'utilisateur par la suggestion
              _textController.text = texteCorrige;
            },
          );
        }).toList(),
      );
    }
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
        margin: isUserMessage ? EdgeInsets.only(right: 2.5) : EdgeInsets.only(right: 40.0),
        padding: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: isUserMessage ? Colors.white : Colors.green,
          borderRadius: BorderRadius.circular(25.0),
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
            fontSize: 15
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

    final timeWidget =Text(
        isUserMessage ? '   '+DateFormat.Hm().format(time) : '                  '+DateFormat.Hm().format(time)+ '   '+DateFormat.yMMMMd().format(time),
        style: TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      );

    final messageRow = Row(
      mainAxisAlignment:
      isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        isUserMessage ? Container() : Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: CircleAvatar(
            backgroundImage: AssetImage('images/avatar.png'),
            radius: 13.0,
          ),
        ),
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
      margin: EdgeInsets.symmetric(vertical: 0.0),
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
  CorrectionOrthographique correctionOrthographique = CorrectionOrthographique();

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
                    color: Colors.green,
                  ),
                ), ),
              Tab(
                child: Text(
                  'IA',
                  style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.green
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
                ? Icon(Icons.access_time_outlined, color: Colors.green)
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



class CorrectionOrthographique {
  List<String> motsCorrects = [];

  CorrectionOrthographique() {
    // Chargez les mots corrects à partir du fichier texte
    chargerMotsCorrects();
  }

  void chargerMotsCorrects() {
    motsCorrects = [
      'abricot',
      'ananas',
      'avion',
      'aigle',
      'arbre',
      'abeille',
      'argent',
      'agneau',
      'âne',
      'aéroport',
    ];
  }



  String corrigerTexte(String texte) {
    List<String> mots = texte.split(' ');
    List<String> motsCorriges = [];

    for (String mot in mots) {
      String motCorrige = corrigerMot(mot);
      motsCorriges.add(motCorrige);
    }

    return motsCorriges.join(' ');
  }




  String corrigerMot(String mot) {
    String motCorrige = mot;
    String motMinuscule = mot.toLowerCase();

    if (!motsCorrects.contains(motMinuscule)) {
      String suggestion = chercherSuggestion(motMinuscule);
      if (suggestion.isNotEmpty) {
        motCorrige = suggestion;
      }
    }

    return motCorrige;
  }




  String chercherSuggestion(String mot) {
    String suggestion = '';

    for (String motCorrect in motsCorrects) {
      int distance = calculerDistanceLevenshtein(mot, motCorrect);
      if (distance <= 2) {
        suggestion = motCorrect;
        break;
      }
    }

    return suggestion;
  }




  int calculerDistanceLevenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    List<int> preCalcul = List<int>.generate(b.length + 1, (int i) => i);

    for (int i = 0; i < a.length; i++) {
      List<int> currentCalcul = List<int>.generate(b.length + 1, (int i) => 0);
      currentCalcul[0] = i + 1;

      for (int j = 0; j < b.length; j++) {
        int cout = (a[i] == b[j]) ? 0 : 1;
        currentCalcul[j + 1] = [
          currentCalcul[j] + 1,
          preCalcul[j + 1] + 1,
          preCalcul[j] + cout,
        ].reduce((minValue, element) => minValue < element ? minValue : element);
      }

      preCalcul = currentCalcul;
    }

    return preCalcul[b.length];
  }
}



class VoiceSearchManager {
  stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  String moreturn = "";
  String remot = "";
  StreamController<String> _resultStreamController = StreamController<String>();
  Stream<String> get onResult => _resultStreamController.stream;

  VoiceSearchManager() {
    _speechToText = stt.SpeechToText();

    _speechToText.initialize(onError: (error) {
      print('Erreur d\'initialisation : $error');
    });
  }

  startListening() async {
    if (!_isListening) {
      _isListening = true;
      bool available = await _speechToText.initialize();
      if (available) {
        _speechToText.listen(onResult: (result) {
          if (result.finalResult) {
            _handleRecognitionResult(result.recognizedWords);
            remot = result.recognizedWords;
          }
        });
      } else {
        print('Fonction de reconnaissance vocale non disponible');
        stopListening();
      }
    }
  }

  void stopListening() {
    if (_isListening) {
      _speechToText.stop();
      _isListening = false;
    }
  }

  bool isListening() {
    return _isListening;
  }

  _handleRecognitionResult(String result) {
    // Implémentez le traitement du résultat vocal ici
    print('Résultat vocal : $result');
    moreturn = result;
  }

  String retournermot() {
    return remot;
  }
}
