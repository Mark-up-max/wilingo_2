import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import 'package:intl/intl.dart';

import 'ListeChatsScreen.dart';
import 'main.dart';

class anglisfrancais extends StatefulWidget {
  final String chatName;

  anglisfrancais(String chat,  {required this.chatName});

  @override
  _anglisfrancaisState createState() => _anglisfrancaisState();
}

class _anglisfrancaisState extends State<anglisfrancais> {
  List<ChatMessage> _messages = [];
  TextEditingController _textController = TextEditingController();
  ScrollController _scrollController = ScrollController();

  List<String> suggestions = [
    'Good',
    'Thank',
    'yes',
    'No',
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

        dom.Element? definitionElement = document.querySelector('.Texte source');
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
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.chatName),
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
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: isUserMessage ? Colors.blue : Colors.grey,
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


