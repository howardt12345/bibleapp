import 'dart:async';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share/share.dart';
import 'package:tuple/tuple.dart';

import 'package:bible/bible.dart';
import 'package:bible/ui/app.dart';
import 'package:bible/ui/home.dart' as home;
import 'package:bible/ui/plan_manager_page.dart';
import 'package:bible/ui/settings.dart';
import 'package:bible/ui/versions.dart';

const String bookPrefs = 'passage_edit_book';
const String chapterPrefs = 'passage_edit_chapter';
const String radioValuePrefs = 'radio_value';

class PassageEditPage extends StatefulWidget {

  final PlanPassage passage;
  final bool add;
  final RemoteConfig remoteConfig;


  PassageEditPage(
    this.remoteConfig,
    {
      this.passage,
      this.add = false,
    }
  );

  @override
  _PassageEditPageState createState() => new _PassageEditPageState();
}

class _PassageEditPageState extends State<PassageEditPage> {
  FixedExtentScrollController bookController,
      chapterController;
  ListWheelScrollView bookScrollView,
      chapterScrollView;

  PlanPassage tmpPassage;

  int book, chapter,
      tmpBook, tmpChapter,
      radioValue = 1,
      start = -1, end = -1;

  @override
  initState() {
    super.initState();
    getIndex();
  }

  getIndex() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      tmpBook = book = prefs.getInt(bookPrefs) ?? home.book;
      tmpChapter = chapter = ((prefs.getInt(chapterPrefs) ?? 0) >=
          bible.books[bible.books.keys.toList()[book]].length()
          ? bible.books[bible.books.keys.toList()[book]].length() - 1
          : prefs.getInt(chapterPrefs)) ?? home.chapter;

      radioValue = prefs.getInt(radioValuePrefs) ?? 1;

      _onSelect(-1);

      tmpPassage = widget.passage != null ? PlanPassage.clone(widget.passage) : new PlanPassage();

      PassageChecker checker = new PassageChecker(bible: bible);

      if(widget.passage != null) {
        tmpBook = book = tmpPassage.start.item1;
        tmpChapter = chapter = tmpPassage.start.item2;
        start = tmpPassage.start.item3;
        end = checker.correctVerse(tmpPassage.end).item2 != tmpPassage.start.item2
            ? bible.books[bible.books.keys.toList()[book]].chapters[chapter].length()-1
            : tmpPassage.end.item3;
      } else {
        tmpBook = book;
        tmpChapter = chapter;
      }

      bookController = new FixedExtentScrollController(
          initialItem: book
      );
      chapterController = new FixedExtentScrollController(
          initialItem: chapter
      );

      bookScrollView = ListWheelScrollView(
        children: List.generate(bible.length(), (i) => new ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 4.0),
          title: new Text(
            bible.books.keys.toList()[i].item2,
            textAlign: TextAlign.center,
            softWrap: true,
          ),
        )),
        controller: bookController,
        itemExtent: 56.0,
        perspective: double.minPositive,
        onSelectedItemChanged: (int index) => changeBook(index),
        physics: FixedExtentScrollPhysics(),
      );
      chapterScrollView = new ListWheelScrollView(
        children: List.generate(bible.books[bible.books.keys.toList()[book]].length(), (i) => new ListTile(
          contentPadding: EdgeInsets.zero,
          title: new Text(
            "${(i+1)}",
            textAlign: TextAlign.center,
          ),
        )),
        controller: chapterController,
        itemExtent: 56.0,
        perspective: double.minPositive,
        onSelectedItemChanged: (int index) => changeChapter(index),
        physics: FixedExtentScrollPhysics(),
      );
    });

  }

  @override
  dispose() {
    super.dispose();
    bookController.dispose();
    chapterController.dispose();
  }

  Future<void> fetchConfig() async {
    try {
      await widget.remoteConfig.fetch(expiration: const Duration(seconds: 0));
      await widget.remoteConfig.activateFetched();
    } catch (e) {

    }
  }
  String getString(String key) => widget.remoteConfig.getString(key);

  @override
  Widget build(BuildContext context) {
    var appBar = PreferredSize(
      child: new SafeArea(
        child: new Container(
          height: 56.0,
          alignment: Alignment.center,
          child: new Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              new Expanded(
                child: new IconButton(
                  icon: new Icon(Icons.clear),
                  onPressed: () {
                    Navigator.pop(context, null);
                  },
                ),
                flex: 4,
              ),
              new Expanded(
                child: start != -1 && (end != start || end != -1) ? new IconButton(
                  icon: new Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {
                      start = -1;
                      end = -1;
                    });
                  },
                ) : new Container(),
                flex: 4,
              ),
              new Expanded(
                child: new Container(),
                flex: 16,
              ),
              new Expanded(
                child: new IconButton(
                  icon: new Icon(Icons.check),
                  onPressed: start != -1 && end != -1 ? () {
                    tmpPassage.start = new Tuple3(book, chapter, start);
                    tmpPassage.end = new Tuple3(book, chapter, end);
                    try {
                      widget.passage.applyEdit(
                        start: tmpPassage.start,
                        end: tmpPassage.end,
                      );
                    } catch(e) {
                    }
                    logEvent('plan_passage_added', {'start' : bible.verseAsText(tmpPassage.start), 'end': bible.verseAsText(tmpPassage.end)});

                    Navigator.pop(context, tmpPassage);
                  } : null,
                ),
                flex: 4,
              ),
            ],
          ),
        ),
      ),
      preferredSize: new Size.fromHeight(56.0),
    );

    var navigationBar = new Container(
      height: 56.0,
      alignment: Alignment.center,
      child: new Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          new Expanded(
            child: new Container(),
            flex: 4,
          ),
          new Expanded(
            child: new GestureDetector(
              onLongPress: () {
                tmpBook = book;
                tmpChapter = chapter;
                setText();
              },
              onDoubleTap: () {
                showDialog(
                    context: context,
                    builder: (BuildContext context) => new home.BibleNavigation(
                      initialBook: book,
                      initialChapter: chapter,
                    )
                ).then<void>((value) {
                  switch(value.item1) {
                    case DialogAction.confirm:
                      tmpBook = value.item2.item1;
                      tmpChapter = value.item2.item2;
                      setText();
                      break;
                  }
                });
              },
              child: new Row(
                children: <Widget>[
                  new Expanded(
                    child: bookScrollView ?? new Container(),
                    flex: 11,
                  ),
                  new Expanded(
                    child: chapterScrollView ?? new Container(),
                    flex: 4,
                  ),
                ],
              ),
            ),
            flex: 15,
          ),
          new Expanded(
            child: new Container(),
            flex: 4,
          ),
        ],
      ),
    );

    var radioBar = new Container(
      height: 56.0,
      margin: EdgeInsets.symmetric(horizontal: 16.0),
      alignment: Alignment.center,
      child: new Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          new Expanded(
            child: Row(
              children: <Widget>[
                new Radio(
                  value: 0,
                  groupValue: radioValue,
                  onChanged: _onRadioChange,
                ),
                new Text(getString('plan_passage_edit_single')),
              ],
            ),
          ),
          new Expanded(
            child: Row(
              children: <Widget>[
                new Radio(
                  value: 1,
                  groupValue: radioValue,
                  onChanged: _onRadioChange,
                ),
                new Text(getString('plan_passage_edit_range')),
              ],
            ),
          ),
          new Expanded(
            child: Row(
              children: <Widget>[
                new Radio(
                  value: 2,
                  groupValue: radioValue,
                  onChanged: _onRadioChange,
                ),
                new Text(getString('plan_passage_edit_all')),
              ],
            ),
          ),
        ],
      ),
    );

    return new WillPopScope(
      onWillPop: () { Navigator.pop(context); },
      child: new Scaffold(
        body: new SafeArea(
          child: new Stack(
            children: <Widget>[
              new Column(
                children: <Widget>[
                  new Container(
                    height: fontSize*4,
                    margin: EdgeInsets.only(top: fontSize*4),
                    child: new Center(
                      child: new RichText(
                        text: new TextSpan(
                          text: widget.add ? getString('plan_passage_edit_add') : widget.passage != null ? getString('plan_passage_edit_edit') : '',
                          style: Theme.of(context).textTheme.body1.copyWith(
                            fontSize: fontSize*2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  navigationBar,
                  radioBar,
                  new Expanded(
                    child: new GridView.count(
                      crossAxisCount: 5,
                      children: List.generate(bible.books[bible.books.keys.toList()[book]].chapters[chapter].length(),
                            (i) => GridTile(
                          child: new FlatButton(
                            onPressed: () => _onSelect(i),
                            child: new Text(
                              "${(i+1)}",
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.body1.copyWith(
                                  fontSize: fontSize,
                                  color: (start <= i && end >= i)
                                      ? Theme.of(context).accentColor
                                      : Theme.of(context).textTheme.body1.color
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        appBar: appBarAtTop ? appBar : null,
        bottomNavigationBar: appBarAtTop ? null : appBar,
      )
    );
  }

  _onSelect(int index) {
    switch(radioValue) {
      case 0:
        setState(() => start = end = index);
        break;
      case 1:
        if(index < start || start == -1) {
          setState(() => start = end = index);
          break;
        }
        if(index > end || end == -1) {
          setState(() => end = index);
          break;
        }
        break;
      case 2:
        setState(() {
          start = 0;
          end = bible.books[bible.books.keys.toList()[book]].chapters[chapter].length()-1;
        });
        break;
    }
  }

  _onRadioChange(int value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() => radioValue = value);

    prefs.setInt(radioValuePrefs, value);

    _onSelect(-1);
  }

  setText() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      book = tmpBook;
      chapter = tmpChapter >= bible.books[bible.books.keys.toList()[book]].length()
          ? bible.books[bible.books.keys.toList()[book]].length()-1
          : tmpChapter;
    });
    if(bookController.selectedItem != book) {
      bookController.jumpToItem(book);
    }
    if(chapterController.selectedItem != chapter) {
      chapterController.jumpToItem(chapter);
    }

    prefs.setInt(bookPrefs, book);
    prefs.setInt(chapterPrefs, chapter);

    _onSelect(-1);
  }

  isChanged() {
    return book != tmpBook
        || chapter != tmpChapter;
  }

  changeBook(int b) {
    setState(() {
      chapterScrollView = new ListWheelScrollView(
        children: List.generate(bible.books[bible.books.keys.toList()[b]].length(), (i) => new ListTile(
          contentPadding: EdgeInsets.zero,
          title: new Text(
            "${(i+1)}",
            textAlign: TextAlign.center,
          ),
        )),
        controller: chapterController,
        itemExtent: 56.0,
        perspective: double.minPositive,
        onSelectedItemChanged: (int index) => changeChapter(index),
        physics: FixedExtentScrollPhysics(),
      );
      tmpBook = b;
    });
    setText();
  }
  changeChapter(int c) {
    setState(() {
      tmpChapter = c;
    });
    setText();
  }
}