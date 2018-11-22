

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'package:html/dom.dart' as html;
import 'package:html/parser.dart' as html show parse;
import 'package:tuple/tuple.dart';

import 'package:bible/bible.dart';
import 'package:bible/ui/settings.dart';
import 'package:bible/ui/versions.dart';

class Parser {
  final BuildContext context;
  final Map annotations;

  TextStyle _style;

  int verse = 1;

  final int start, end, book, chapter;
  final String osis;

  bool debug = false;

  List<Widget> _widgets = [];
  List<TextSpan> _currentTextSpans = [];

  Parser(
    this.context,
    this.annotations,
    {
      this.start,
      this.end,
      this.book,
      this.chapter,
      this.osis,
    }
  ) : _style = Theme.of(context).textTheme.body1.copyWith(
    fontSize: fontSize,
  );


  Widget fromHtml(String htmlStr) {
    final html.Node body = html.parse(htmlStr).body;
    _parseNode(body);
    _tryCloseCurrentTextSpan();

    /*return new Container(
      padding: const EdgeInsets.all(8.0),
      child: new RichText(
        text: new TextSpan(
          text: '',
          children: _widgets,
        ),
      ),
    );*/
    return new Wrap(
      children: _widgets
    );
  }

  void _parseNode(html.Node node, {FontStyle style = FontStyle.normal, FontWeight weight = FontWeight.w400, int script = 0}) {
    // print('--- _parseNode');
    if(debug)
      print(node.toString());

    switch(node.nodeType) {
      case html.Node.ELEMENT_NODE:
        _parseElement(node as html.Element);
        return;
      case html.Node.TEXT_NODE:
        if(node.text.runes.toSet().difference(new Set.from([new Runes('\n').first])).isEmpty) {
          _tryCloseCurrentTextSpan();
          return;
        }
        _appendToCurrentTextSpans(node.text, style: style, weight: weight, script: script);
        return;
      default:
        break;
    }
  }
  void _parseElement(html.Element element) {
    // print('--- _parseElement');
    if (debug) {
      print(element.toString());
      print(element.attributes['class']);
    }

    switch(element.localName) {
      case 'div':
        element.nodes.forEach((subNode) => _parseNode(subNode));
        return;
      case 'p':
      case 'body':
        if((start == null && end == null) || (start) < verse && (verse-1) <= (end)) {
          String c = element.attributes['class'];
          if(c != null) {
            if(element.attributes['class'].startsWith('q') || element.attributes['class'].startsWith('b')) {
              double indent = 0.0;
              switch(element.attributes['class'].replaceAll('q', '').trim()) {
                case 'a':
                  break;
                case '1':
                  indent = 8.0;
                  break;
                case '2':
                  indent = 24.0;
                  break;
                default:
                  break;
              }
              element.nodes.forEach((subNode) => _parseNode(subNode));
              _tryCloseCurrentTextSpan(left: indent);
            } else {
              element.nodes.forEach((subNode) => _parseNode(subNode));
              if(start != null && end != null) {
                _tryCloseCurrentTextSpan(newLine: ((start) < verse && (verse-1) <= (end)));
              } else {
                _tryCloseCurrentTextSpan(newLine: true);
              }
            }
          } else {
            element.nodes.forEach((subNode) => _parseNode(subNode));
            _tryCloseCurrentTextSpan(newLine: false);
          }
        } else {
          element.nodes.forEach((subNode) => _parseNode(subNode));
        }
        return;
      case 'br':
        _tryCloseCurrentTextSpan();
        return;
      case 'h3':
      case 'h4':
        _style = Theme.of(context).textTheme.body1.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        );
        element.nodes.forEach((subNode) => _parseNode(subNode));
        _tryCloseCurrentTextSpan(newLine: true);
        _style = Theme.of(context).textTheme.body1.copyWith(
          fontSize: fontSize,
        );
        return;
      case 'i':
        element.nodes.forEach((subNode) => _parseNode(subNode, style: FontStyle.italic));
        return;
      case 'sup':
        if(debug)
          print(element.attributes['class']);
        if(element.hasContent() && (element.nodes.length == 1)/* && (element.firstChild.nodeType == html.Node.TEXT_NODE)*/) {
          final text = element.text.trim();
          final c = element.attributes['class'];
          if(c.contains('v') && verseNumbers) {
            _appendToCurrentTextSpans(new TextSpan(
              text: Script.superScript(text)+' ',
              style: _style.copyWith(
                fontFamily: capitalize(FontEnum.roboto.toString().split('.')[1].replaceAll('_', ' '))
              ),
            ));
          }
          return;
        } /*else if (element.attributes['class'].compareTo('crossreference') == 0 && crossReferences) {
          print(element.attributes['value']);
          _parseNode(html.parse(element.attributes['value'].replaceAll('(', '').replaceAll(')', '')).body, style: FontStyle.italic);
        }*/
        element.nodes.forEach((subNode) => _parseNode(subNode));
        return;
      case 'span':
        if(start != null && end != null) {
          if(element.attributes['class'].compareTo('v${book}_${chapter}_$verse') == 0
          || element.attributes['class'].replaceAll('text ', '').compareTo('$osis-$chapter-$verse') == 0) {
            if(debug)
              print(element.attributes['class']);
            verse++;
          }
          if((start+1) < verse && (verse-1) <= (end+1)) {
            //print(verse);
            element.nodes.forEach((subNode) => _parseNode(subNode));
            return;
          }
        } else {
          if(element.attributes['class'].split('-')[0].compareTo('indent') == 0
          && !element.attributes['class'].contains('breaks')) {
            double indent = 0.0;
            switch(element.attributes['class'].replaceAll('indent-', '').trim()) {
              case 'a':
                break;
              case '1':
                indent = 24.0;
                break;
              case '2':
                indent = 24.0;
                break;
              default:
                break;
            }
            element.nodes.forEach((subNode) => _parseNode(subNode));
            _tryCloseCurrentTextSpan(left: indent);
          } else {
            if(!element.attributes['class'].contains('breaks'))
              element.nodes.forEach((subNode) => _parseNode(subNode));
          }
        }
        return;
      case 'strong':
      element.nodes.forEach((subNode) => _parseNode(subNode, weight: FontWeight.w500));
        return;
      case 'a':
        if(debug)
          print(element.attributes['href']);

        if(element.hasContent()/* && element.attributes['href'].startsWith('#fen-')*/) {
          final text = element.text.trim();
          final href = element.attributes['href'];

          String annotation = annotations != null ? annotations[href.replaceFirst('#', '')] : '';

          _appendToCurrentTextSpans(new TextSpan(
            text: text,
            style: _style.copyWith(
              color: annotation.isNotEmpty ? Theme.of(context).accentColor : null,
              fontWeight: annotation.isNotEmpty ? FontWeight.w400 : FontWeight.w500,
            ),
            recognizer: annotation.isNotEmpty ? (new TapGestureRecognizer()..onTap = () => showDialog<DialogAction>(
              context: context,
              builder: (BuildContext context) => new AlertDialog(
                content: new Parser(context, null).fromHtml(annotation),
                actions: <Widget>[
                  new FlatButton(
                    child: new Text('CLOSE'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ).then<void>((DialogAction value) {
              switch (value) {
                case DialogAction.confirm:
                  break;
                default:
                  break;
              }
            })) : null,
          ));
          return;
        }
        // still traverse down the tree
        element.nodes.forEach((subNode) => _parseNode(subNode));
        return;
      default:
        if(debug)
          print('=== MET UNSUPPORTED TAG: ${element.localName}');
        // still traverse down the tree
        element.nodes.forEach((subNode) => _parseNode(subNode));
        return;
    }
  }

  void _tryCloseCurrentTextSpan({
    FontStyle style = FontStyle.normal,
    FontWeight weight = FontWeight.normal,
    double left = 0.0,
    bool newLine = false,
  }) {
    //print('=== closingCurrentTextSpan ===' + _currentTextSpans.length.toString());
    if(newLine) {
      _appendToCurrentTextSpans('\n');
    }

    if (_currentTextSpans.isEmpty)
      return;
    _widgets.add(
      new Container(
        alignment: Alignment.topLeft,
        padding: EdgeInsets.only(
          left: 0.0 + left,
          right: 0.0,
        ),
        child: new RichText(
          text: new TextSpan(
            style: _style,
            children: new List.from(_currentTextSpans)
          )
        )
      )
/*        new TextSpan(
            style: _style,
            children: new List.from(_currentTextSpans)
        )*/
    );

    _currentTextSpans.clear();
  }

  void _appendToCurrentTextSpans(dynamic stringOrTextSpan, {
    FontStyle style = FontStyle.normal, 
    FontWeight weight = FontWeight.normal, 
    int script = 0
  }) {
    // print('=== appending to _currentTextSpan: ' + textOrLink.toString());
    switch (stringOrTextSpan.runtimeType) {
      case String:
      // NOTE if the widget to be added, and the current last widget, are both Text, then we should append the text instead of widgets.
        if (_currentTextSpans.length > 0 && _currentTextSpans.last.runtimeType == Text) {
          final String originalText = _currentTextSpans.last.text;
          final String mergedText = originalText + stringOrTextSpan;
          _currentTextSpans[_currentTextSpans.length-1] = new TextSpan(
            text: mergedText,
            style: _style.copyWith(
              fontStyle: style,
            ),
          );
        } else {
          _currentTextSpans.add(new TextSpan(
            text: stringOrTextSpan,
            style:_style.copyWith(
              fontStyle: style,
            ),
          ));
        }
        break;
      case TextSpan:
        _currentTextSpans.add(stringOrTextSpan);
        break;
      default:
        throw "Not a valid type.";
    }
  }
}

class Script {
  static const int NORMAL = 0;
  static const int SUPERSCRIPT = 1;
  static const int SUBSCRIPT = 2;

  static Map<String, Tuple2<String, String>> unicode = {
    '0'         : Tuple2('\u2070', '\u2080'),
    '1'         : Tuple2('\u00B9', '\u2081'),
    '2'         : Tuple2('\u00B2', '\u2082'),
    '3'         : Tuple2('\u00B3', '\u2083'),
    '4'         : Tuple2('\u2074', '\u2084'),
    '5'         : Tuple2('\u2075', '\u2085'),
    '6'         : Tuple2('\u2076', '\u2086'),
    '7'         : Tuple2('\u2077', '\u2087'),
    '8'         : Tuple2('\u2078', '\u2088'),
    '9'         : Tuple2('\u2079', '\u2089'),
    'a'         : Tuple2('\u1d43', '\u2090'),
    'b'         : Tuple2('\u1d47', '?'),
    'c'         : Tuple2('\u1d9c', '?'),
    'd'         : Tuple2('\u1d48', '?'),
    'e'         : Tuple2('\u1d49', '\u2091'),
    'f'         : Tuple2('\u1da0', '?'),
    'g'         : Tuple2('\u1d4d', '?'),
    'h'         : Tuple2('\u02b0', '\u2095'),
    'i'         : Tuple2('\u2071', '\u1d62'),
    'j'         : Tuple2('\u02b2', '\u2c7c'),
    'k'         : Tuple2('\u1d4f', '\u2096'),
    'l'         : Tuple2('\u02e1', '\u2097'),
    'm'         : Tuple2('\u1d50', '\u2098'),
    'n'         : Tuple2('\u207f', '\u2099'),
    'o'         : Tuple2('\u1d52', '\u2092'),
    'p'         : Tuple2('\u1d56', '\u209a'),
    'q'         : Tuple2('?',      '?'),
    'r'         : Tuple2('\u02b3', '\u1d63'),
    's'         : Tuple2('\u02e2', '\u209b'),
    't'         : Tuple2('\u1d57', '\u209c'),
    'u'         : Tuple2('\u1d58', '\u1d64'),
    'v'         : Tuple2('\u1d5b', '\u1d65'),
    'w'         : Tuple2('\u02b7', '?'),
    'x'         : Tuple2('\u02e3', '\u2093'),
    'y'         : Tuple2('\u02b8', '?'),
    'z'         : Tuple2('?',      '?'),
    'A'         : Tuple2('\u1d2c', '?'),
    'B'         : Tuple2('\u1d2e', '?'),
    'C'         : Tuple2('?',      '?'),
    'D'         : Tuple2('\u1d30', '?'),
    'E'         : Tuple2('\u1d31', '?'),
    'F'         : Tuple2('?',      '?'),
    'G'         : Tuple2('\u1d33', '?'),
    'H'         : Tuple2('\u1d34', '?'),
    'I'         : Tuple2('\u1d35', '?'),
    'J'         : Tuple2('\u1d36', '?'),
    'K'         : Tuple2('\u1d37', '?'),
    'L'         : Tuple2('\u1d38', '?'),
    'M'         : Tuple2('\u1d39', '?'),
    'N'         : Tuple2('\u1d3a', '?'),
    'O'         : Tuple2('\u1d3c', '?'),
    'P'         : Tuple2('\u1d3e', '?'),
    'Q'         : Tuple2('?',      '?'),
    'R'         : Tuple2('\u1d3f', '?'),
    'S'         : Tuple2('?',      '?'),
    'T'         : Tuple2('\u1d40', '?'),
    'U'         : Tuple2('\u1d41', '?'),
    'V'         : Tuple2('\u2c7d', '?'),
    'W'         : Tuple2('\u1d42', '?'),
    'X'         : Tuple2('?',      '?'),
    'Y'         : Tuple2('?',      '?'),
    'Z'         : Tuple2('?',      '?'),
    '+'         : Tuple2('\u207A', '\u208A'),
    '-'         : Tuple2('\u207B', '\u208B'),
    '='         : Tuple2('\u207C', '\u208C'),
    '('         : Tuple2('\u207D', '\u208D'),
    ')'         : Tuple2('\u207E', '\u208E'),
    ':alpha'    : Tuple2('\u1d45', '?'),
    ':beta'     : Tuple2('\u1d5d', '\u1d66'),
    ':gamma'    : Tuple2('\u1d5e', '\u1d67'),
    ':delta'    : Tuple2('\u1d5f', '?'),
    ':epsilon'  : Tuple2('\u1d4b', '?'),
    ':theta'    : Tuple2('\u1dbf', '?'),
    ':iota'     : Tuple2('\u1da5', '?'),
    ':pho'      : Tuple2('?',      '\u1d68'),
    ':phi'      : Tuple2('\u1db2', '?'),
    ':psi'      : Tuple2('\u1d60', '\u1d69'),
    ':chi'      : Tuple2('\u1d61', '\u1d6a'),
    ':coffee'   : Tuple2('\u2615', '\u2615'),
    ' '         : Tuple2(' ',      ' '),
    '['         : Tuple2('[',      '['),
    ']'         : Tuple2(']',      ']')
  };

  static String superScript(String input) => input.runes.map((int rune) => unicode[new String.fromCharCode(rune)].item1).toList().join();
  static String subScript(String input) => input.runes.map((int rune) => unicode[new String.fromCharCode(rune)].item2).toList().join();
}