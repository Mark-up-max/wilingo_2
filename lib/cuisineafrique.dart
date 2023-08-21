import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import 'package:intl/intl.dart';

import 'ListeChatsScreen.dart';
import 'main.dart';

class cuisineafrique extends StatefulWidget {
  final String chatName;

  cuisineafrique(String chat, {required this.chatName});

  @override
  cuisineafriqueState createState() => cuisineafriqueState();
}

class cuisineafriqueState extends State<cuisineafrique> {
  List<ChatMessage> _messages = [];
  TextEditingController _textController = TextEditingController();
  ScrollController _scrollController = ScrollController();

  List<String> suggestions = [
    'poulet panné',
    'haricot',
    'thank',
    'yes',
    'no',
    'Excusez-moi',
    'Au revoir',
    'Comment ça va ?',
    'Quel est ton nom ?',
    'J\'ai faim'
  ];

  @override
  void initState() {
    super.initState();

    // Message de bienvenue de l'IA
    String welcomeMessage = "Bienvenue à vous  ! "
        "Je suis ici pour vous aider à trouver les définitions des mots. "
        "N'hésitez pas à poser vos questions.";

    ChatMessage welcomeChatMessage = ChatMessage(
      text: welcomeMessage,
      isUserMessage: false,
      time: DateTime.now(),
    );

    setState(() {
      _messages.insert(0, welcomeChatMessage);
    });
  }

  void _handleSubmitted(String text) async {

    _textController.clear();
    ChatMessage userMessage = ChatMessage(
      text: text,
      isUserMessage: true,
      time: DateTime.now(),
    );

    setState(() {
      _messages.insert(0, userMessage);
    });
    _scrollToBottom();

    String url = "https://www.cuisineaz.com/recettes/filets-de-poulet-panes-55434.aspx";

    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        dom.Document document = parser.parse(response.body);

        dom.Element? definitionsElement = document.querySelector('.borderSection instructions');

        if (definitionsElement != null) {
          String definitionsText = definitionsElement.text;
          String mess = "😁 Autre chose?";

          ChatMessage aiMessage = ChatMessage(
            text: definitionsText,
            isUserMessage: false,
            time: DateTime.now(),
          );

          ChatMessage aMessage = ChatMessage(
            text: mess,
            isUserMessage: false,
            time: DateTime.now(),
          );

          setState(() {
            _messages.insert(0, aiMessage);
          });

          setState(() {
            _messages.insert(0, aMessage);
          });
          _scrollToBottom();
        }else {
          String err = "Désolé, mais je ne comprends pas votre mot 😅. Vérifiez le si possible, je suis beaucoup plus efficace si les mots sont entrés un à un.\Il se peut également qu'il y est un problème de connexion.";
          ChatMessage aiMessage = ChatMessage(
            text: err,
            isUserMessage: false,
            time: DateTime.now(),
          );

          setState(() {
            _messages.insert(0, aiMessage);
          });
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildSuggestionBubble(String suggestion) {
    return GestureDetector(
      onTap: () {
        _handleSubmitted(suggestion);
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
    return suggestions.map((suggestion) => _buildSuggestionBubble(suggestion)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage('images/chinois.png'),
            ),
            SizedBox(width: 8.0),
            Text(widget.chatName),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      endDrawer: Drawer(
        child: Container(
          color: Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text(
                  'Options',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.0,
                  ),
                ),
              ),
              ListTile(
                title: Text('Voir l\'historique des discussions'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Dictionnaire()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (BuildContext context, int index) {
                return _messages[index];
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
                        decoration: InputDecoration(
                          hintText: 'Ecrire un mot',
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
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUserMessage;
  final DateTime time;

  ChatMessage({required this.text, required this.isUserMessage, required this.time});

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.8;
    final messageBubble = Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: isUserMessage ? Colors.grey : Colors.blueGrey,
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
          color: Colors.white,
        ),
      ),
    );

    final messageWidget = Container(
      padding: EdgeInsets.all(8.0),
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: messageBubble,
      ),
    );

    return Container(
      padding: EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUserMessage)
                CircleAvatar(
                  backgroundColor: Colors.grey,
                  backgroundImage: AssetImage('images/chinois.png'),
                  radius: 12.0,
                ),
              SizedBox(width: 8.0),
              messageWidget,
            ],
          ),
          SizedBox(height: 4.0),
          Text(
            DateFormat('HH:mm').format(time),
            style: TextStyle(
              fontSize: 12.0,
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: cuisineafrique('Chat', chatName: ''),
  ));
}

class Dictionnaire extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historique des discussions'),
      ),
      body: Center(
        child: Text('Contenu de l\'historique des discussions'),
      ),
    );
  }
}
