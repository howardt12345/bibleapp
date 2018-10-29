import 'dart:async';
import 'dart:core';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';

import 'package:share/share.dart';
import 'package:tuple/tuple.dart';

import 'package:bible/bible.dart';
import 'package:bible/ui/app.dart';
import 'package:bible/ui/settings.dart';
import 'package:bible/ui/versions.dart';

class SearchWindow extends StatefulWidget {
  static _SearchWindowState of(BuildContext context) => context.ancestorStateOfType(TypeMatcher<_SearchWindowState>());

  final RemoteConfig remoteConfig;
  SearchWindow(this.remoteConfig);

  @override
  _SearchWindowState createState() => new _SearchWindowState();
}
class _SearchWindowState extends State<SearchWindow> {
  FocusNode focusNode = new FocusNode();

  TextEditingController textEditingController = new TextEditingController();
  ScrollController scrollController = new ScrollController();

  Future<void> fetchConfig() async {
    try {
      await widget.remoteConfig.fetch(expiration: const Duration(seconds: 0));
      await widget.remoteConfig.activateFetched();
    } catch (e) {

    }
  }
  String getString(String key) => widget.remoteConfig.getString(key);

  Widget searchView() => new CustomScrollView(
    controller: scrollController,
    slivers: <Widget>[
      new SliverAppBar(
        leading: appBarAtTop ? new IconButton(
          icon: new Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ) : new Container(),
        pinned: true,
        flexibleSpace: new FlexibleSpaceBar(
          centerTitle: true,
          title: new ListTile(
            leading: appBarAtTop ? new Container(width: 40.0) : new Icon(Icons.search),
            title: new TextField(
              focusNode: focusNode,
              controller: textEditingController,
              decoration: new InputDecoration(
                  hintText: getString('search_bible'),
                  border: InputBorder.none
              ),
              onSubmitted: (s) => setState(() {}),
              //onChanged: onSearchTextChanged,
            ),
            trailing: new IconButton(
              icon: new Icon(Icons.cancel),
              onPressed: () {
                textEditingController.clear();
                setState(() {});
              },
            ),
          ),
        ),
      ),
      textEditingController.text.isNotEmpty ? FutureBuilder(
        future: search(context, textEditingController.text, resultTitles: true, goToChapter: true),
        initialData: [
          new Container(
            height: MediaQuery.of(context).size.height-56.0,
            child: new Center(
              child: new CircularProgressIndicator(),
            ),
          ),
        ],
        builder: (BuildContext context,
            AsyncSnapshot<List<Widget>> widgets) {
          return new SliverList(
            delegate: new SliverChildListDelegate(
              (widgets.data != null ? widgets.data.isNotEmpty : false) ? widgets.data : [
                new Container(
                  height: MediaQuery.of(context).size.height-56.0,
                  child: new Center(
                    child: new RichText(
                      textAlign: TextAlign.center,
                      text: new TextSpan(
                        children: [
                          new TextSpan(
                            text: getString('search_no_match_1'),
                            style: Theme.of(context).textTheme.body1.copyWith(
                              fontSize: fontSize,
                            ),
                          ),
                          new TextSpan(
                            text: textEditingController.text,
                            style: Theme.of(context).textTheme.body1.copyWith(
                              fontSize: fontSize,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          new TextSpan(
                            text: getString('search_no_match_2'),
                            style: Theme.of(context).textTheme.body1.copyWith(
                              fontSize: fontSize,
                            ),
                          ),
                          new TextSpan(
                            text: '\n\n${getString('search_adjust')}',
                            style: Theme.of(context).textTheme.body1.copyWith(
                              fontSize: fontSize,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ) : new SliverList(
        delegate: new SliverChildListDelegate(
          [
            new Container(
              height: MediaQuery.of(context).size.height-56.0,
              child: new Center(
                child: new RichText(
                  textAlign: TextAlign.center,
                  text: new TextSpan(
                      children: [
                        new TextSpan(
                          text: getString('search_title'),
                          style: Theme.of(context).textTheme.body1.copyWith(
                            fontSize: fontSize,
                          ),
                        ),
                        new TextSpan(
                          text: '\n\n${getString('search_subtitle')}',
                          style: Theme.of(context).textTheme.body1.copyWith(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ]
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      new SliverPadding(
        padding: EdgeInsets.all(28.0),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).requestFocus(focusNode);
    return new WillPopScope(
      onWillPop: () { Navigator.pop(context); },
      child: new Scaffold(
        body: new SafeArea(
          child: new Stack(
            children: <Widget>[
              searchView(),
              new IgnorePointer(
                child: new Align(
                  alignment: Alignment.bottomCenter,
                  child: new Container(
                    decoration: new BoxDecoration(
                      gradient: new LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Theme.of(context).canvasColor.withAlpha(0), Theme.of(context).canvasColor],
                        tileMode: TileMode.repeated,
                      ),
                    ),
                    height: 56.0,
                  ),
                ),
              ),
              appBarAtTop ? new Align(
                alignment: Alignment.topLeft,
                child: new Container(
                  height: 56.0,
                  width: 56.0,
                  child: new IconButton(
                    icon: new Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ) : new Align(
                alignment: Alignment.bottomLeft,
                child: new Container(
                  height: 56.0,
                  width: 56.0,
                  child: new IconButton(
                    icon: new Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              new Align(
                alignment: Alignment.bottomCenter,
                child: new Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    new IconButton(
                      icon: new Icon(Icons.keyboard_arrow_up),
                      onPressed: () => scrollController.animateTo(
                        0.0,
                        curve: Curves.decelerate,
                        duration: Duration(milliseconds: (scrollController.offset/10).floor()),
                      ),
                    ),
                    new IconButton(
                      icon: new Icon(Icons.keyboard_arrow_down),
                      onPressed: () {
                        scrollController.animateTo(
                          scrollController.position.maxScrollExtent,
                          curve: Curves.decelerate,
                          duration: Duration(milliseconds: ((scrollController.position.maxScrollExtent-scrollController.offset)/10).floor()),
                        );
                      },
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Widget>> search(BuildContext context, String queries, {bool resultTitles = false, goToChapter = false}) async {
    Widget toCard(Map<dynamic, dynamic> item) {
      String verse = '${bible.osis[item['book']]} ${item['verse'].floor()}:${((item['verse'] * 1000).ceil() % 1000).toInt()}',
          passage = item['unformatted'];
      return new Card(
        elevation: 0.0,
        child: new Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            new ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              onTap: () => Navigator.pop(context, new Tuple2(bible.osis.keys.toList().indexOf(item['book']), item['verse'].floor()-1)),
              title: new RichText(
                text: new TextSpan(
                  text: verse,
                  style: Theme.of(context).textTheme.body1.copyWith(
                    fontSize: fontSize,
                  ),
                ),
              ),
              subtitle: new RichText(
                text: new TextSpan(
                  text: passage,
                  style: Theme.of(context).textTheme.body1.copyWith(
                    fontSize: fontSize*0.8,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
            new ButtonTheme.bar(
              child: new ButtonBar(
                children: <Widget>[
/*              new FlatButton(
                child: const Text('BOOKMARK'),
                onPressed: () {
                },
              ),*/
                  new FlatButton(
                      child: const Text('SHARE'),
                      onPressed: () => Share.share('$passage'
                          '\n$verse, ${defaultVersionFormatted()}')
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget passageToCard(List<Map> verses) {
      Map first = verses.first, last = verses.last;
      String firstVerse = '${bible.osis[first['book']]} ${first['verse'].floor()}:${((first['verse'] * 1000).ceil() % 1000).toInt()}',
          lastVerse = ((last['verse'] * 1000).ceil() % 1000).toInt() == ((first['verse'] * 1000).ceil() % 1000).toInt() && last['verse'].floor() == first['verse'].floor()
              ? ''
              : '-${last['book'].compareTo(first['book']) == 0
              ? ''
              : bible.osis[last['book']]+' '}'
              '${last['verse'].floor() == first['verse'].floor()
              ? ''
              : '${last['verse'].floor()}:'}'
              '${((last['verse'] * 1000).ceil() % 1000).toInt()}';

      String passage = verses.map((verse) => verse['unformatted']).toList().join(' ');

      return new Card(
        elevation: 1.0,
        child: new Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            new ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              onTap: () => Navigator.pop(context, new Tuple2(bible.osis.keys.toList().indexOf(first['book']), first['verse'].floor()-1)),
              title: new RichText(
                text: new TextSpan(
                  text: '$firstVerse$lastVerse',
                  style: Theme.of(context).textTheme.body1.copyWith(
                    fontSize: fontSize,
                  ),
                ),
              ),
              subtitle: new RichText(
                text: new TextSpan(
                  text: passage,
                  style: Theme.of(context).textTheme.body1.copyWith(
                    fontSize: fontSize*0.8,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
            new ButtonTheme.bar(
              child: new ButtonBar(
                children: <Widget>[
/*              new FlatButton(
                child: const Text('BOOKMARK'),
                onPressed: () {
                },
              ),*/
                  new IconButton(
                    icon: new Icon(Icons.share),
                      onPressed: () => Share.share('$passage'
                          '\n$firstVerse$lastVerse, ${defaultVersionFormatted()}'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    List<Widget> widgets = new List<Widget>();
    List<String> items = queries.split(',');

    await Future.forEach(items, (item) async {
      String text = item.trim();
      List<Widget> queryResult = new List<Widget>();
      if (isChapter(text)) {
        Tuple2<int, int> chapter = new PassageChecker(bible: bible).correctChapter(getChapter(text));
        if(goToChapter) {
          queryResult.add(
            new Card(
              elevation: 1.0,
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                onTap: () => Navigator.pop(context, new Tuple2(chapter.item1, chapter.item2)),
                title: new RichText(
                  text: new TextSpan(
                    text: 'Go to ${bible.chapterAsText(new Tuple2(chapter.item1, chapter.item2))}',
                    style: Theme.of(context).textTheme.body1.copyWith(
                      fontSize: fontSize,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        Tuple3 isPassage = isPassages(text);
        if(isPassage.item1 || isPassage.item2 || isPassage.item3) {
          List<Map> results = await bible.getVerses(getPassage(text));
          queryResult.add(passageToCard(results));
        }
      } else {
        List<Map> results = await bible.search(text);
        List<Widget> tmpWidgets = results.map((item) => toCard(item)).toList();
        tmpWidgets.forEach((widget) => queryResult.add(widget));
      }
      if(queryResult.isNotEmpty) {
        if(resultTitles) {
          widgets.add(
            new ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              title: new RichText(
                text: new TextSpan(
                  text: '${queryResult.length} ${getString('search_results_for')} "$text"',
                  style: Theme.of(context).textTheme.body1.copyWith(
                    fontSize: fontSize,
                  ),
                ),
              ),
            ),
          );
        }
        queryResult.forEach((widget) => widgets.add(widget));
        widgets.add(new Divider());
      }
    });
    return widgets;
  }
}

bool isChapter(String text) {
  try {
    List<String> input = text.toLowerCase().trim().split(':');
    if (isNumeric(input[0].split(' ').last) ?? false) {
      List<String> s = input[0].split(' ');
      s.removeLast();
      String book = '${capitalize(s.first)}${s.length>1 ? ' ${capitalize(s.last)}' : ''}';
      if (bible.osis.containsKey(book) || bible.human.containsKey(book)) {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  } catch(e) {
    return false;
  }
}

Tuple3<bool, bool, bool> isPassages(String text) {
  try {
    List<String> input = text.toLowerCase().trim().split('-');
    return new Tuple3(isPassage(input.first),
                     (input.first.compareTo(input.last) == 0) ? false : isNumeric(input.last),
                     (input.first.compareTo(input.last) == 0) ? false : isPassage(input.last));
  } catch(e) {
    return Tuple3(false, false, false);
  }
}

bool isPassage(String text) {
  try {
    List<String> first = text.toLowerCase().trim().split(':');
    if ((isChapter(first.first) && (isNumeric(first.last)))) {
      return true;
    } else {
      return false;
    }
  } catch(e) {
    return false;
  }
}

Tuple2<int, int> getChapter(String text) {
  try {
    List<String> input = text.toLowerCase().trim().split(':');
    List<String> s = input[0].split(' ');
    s.removeLast();
    String book = '${capitalize(s.first)}${s.length>1 ? ' ${capitalize(s.last)}' : ''}';
    if(bible.osis.containsKey(book)) {
      return new Tuple2(bible.osis.keys.toList().indexOf(book), int.parse(input[0].split(' ').last)-1);
    } else if(bible.human.containsKey(book)) {
      return new Tuple2(bible.human.keys.toList().indexOf(book), int.parse(input[0].split(' ').last)-1);
    } else {
      return null;
    }
  } catch(e) {
    return null;
  }
}
List<Tuple3<int, int, int>> getPassage(String text) {
  try {
    Tuple3 isPassage = isPassages(text);
    if(isPassage.item3) {
      print('...');
      PassageChecker passage = new PassageChecker(bible: bible);

      List<String> input = text.trim().split('-');

      List<String> first = input.first.trim().split(':'),
                   last = input.last.trim().split(':');

      Tuple2<int, int> chapter1 = getChapter(input.first),
             chapter2 = getChapter(input.last);

      Tuple3<int, int, int> start = passage.correctVerse(new Tuple3(chapter1.item1, chapter1.item2, int.parse(first.last)-1)),
             end = passage.correctVerse(new Tuple3(chapter2.item1, chapter2.item2, int.parse(last.last)));

      print(start);
      print(end);

      List<Tuple3<int, int, int>> output = new List<Tuple3<int, int, int>>();

      int i = 0;
      Tuple3<int, int, int> tmp = new Tuple3(start.item1, start.item2, start.item3);

      while(end.item1 != tmp.item1 || end.item2 != tmp.item2 || end.item3 != tmp.item3) {
        print(i);
        print(tmp);
        output.add(tmp);
        i++;
        tmp = passage.correctVerse(new Tuple3(start.item1, start.item2, start.item3+i));
      }
      return output;
    } else {
      List<String> input = text.trim().split(':');
      List<String> s = input[0].split(' '), verses = input[1].split('-');
      s.removeLast();

      String book = s.join(" ");
      List<Tuple3<int, int, int>> output = new List<Tuple3<int, int, int>>();
      if(bible.osis.containsKey(book)) {
        int first = int.parse(verses.first), last = int.parse(verses.last);
        for(int i = first; i <= last; i++) {
          output.add(new Tuple3(bible.osis.keys.toList().indexOf(book), int.parse(input[0].split(' ').last)-1, i-1));
        }
        return output;
      } else if(bible.human.containsKey(book)) {
        int first = int.parse(verses.first), last = int.parse(verses.last);
        for(int i = first; i <= last; i++) {
          output.add(new Tuple3(bible.human.keys.toList().indexOf(book), int.parse(input[0].split(' ').last)-1, i-1));
        }
        return output;
      } else {
        print('$text is not a passage');
        return null;
      }
    }
  } catch(e) {
    print(e);
    return null;
  }
}

bool isNumeric(String s) {
  if(s == null) {
    return false;
  }
  try {
    return double.parse(s) != null;
  } catch(e) {
    return false;
  }
}
