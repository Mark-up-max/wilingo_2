import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'ListeChatsScreen.dart';
import 'chat_screenn.dart';
import 'main.dart';
import 'chat_screen.dart';
import 'anglais.dart';

class Dico extends StatefulWidget {
  final String chatName;

  Dico({required this.chatName});

  @override
  _DicoState createState() => _DicoState();
}

class _DicoState extends State<Dico> {
  List<ChatMessage> _messages = [];
  TextEditingController _textController = TextEditingController();
  ScrollController _scrollController = ScrollController();

  final List<String> chats = [
    'Français',
    'Anglais',
  ];

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

    String url = "https://translate.google.com/?hl=fr&sl=auto&tl=en&text=$text&op=translate";

    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        dom.Document document = parser.parse(response.body);

        dom.Element? definitionElement = document.querySelector('.IRu31');
        String definitionText = definitionElement?.text ?? '';

        ChatMessage definitionMessage = ChatMessage(
          text: definitionText,
          isUserMessage: false,
          time: DateTime.now(),
        );

        setState(() {
          _messages.insert(0, definitionMessage);
        });
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
      backgroundColor: Colors.white, // Fond de la vue en couleur blanche
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage('images/OIP (2).jpg'),
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
                          hintText: 'Entrez un message',
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
    return Container(
      padding: EdgeInsets.all(8.0),
      alignment: isUserMessage ? Alignment.centerLeft : Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUserMessage)
                CircleAvatar(
                  backgroundColor: Colors.grey, // Couleur d'arrière-plan de l'avatar
                  backgroundImage: AssetImage('images/avatar.png'), // Remplacez 'assets/avatar.png' par le chemin de votre fichier PNG d'avatar
                  radius: 12.0, // Rayon de l'avatar
                ),
              SizedBox(width: 8.0),
              Container(
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
              ),
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
    home: Dico(chatName: 'Chat'),
  ));
}
