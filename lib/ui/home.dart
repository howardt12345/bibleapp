import 'dart:async';
import 'dart:math';


import 'package:flutter/material.dart';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuple/tuple.dart';

import 'package:bible/ui/app.dart';
import 'package:bible/ui/arrow.dart';
import 'package:bible/ui/page_manager.dart';
import 'package:bible/ui/search.dart';
import 'package:bible/ui/settings.dart';
import 'package:bible/ui/versions.dart';

const String bookPrefs = 'book';
const String chapterPrefs = 'chapter';
const String versePrefs = 'verse';

bool tutorialDialog = false;
const String tutorialDialogPrefs = 'tutorial_dialog';

int book, tmpBook,
    chapter, tmpChapter/*,
    verse = 0, tmpVerse = 0*/;

FixedExtentScrollController bookController,
    chapterController;
ListWheelScrollView bookScrollView,
    chapterScrollView;

final initialPage = (
    .161251195141521521142025
        * 1e6).round();
final itemCount = bible.chaptersLength();


class MainPage extends StatefulWidget {

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with SingleTickerProviderStateMixin {
  SwiperController swipeController = new SwiperController();

  NavigationBar navigationBar;

  @override
  void initState() {
    super.initState();
    _getIndex();
  }

  @override
  void dispose() {
    super.dispose();
    swipeController.dispose();
  }

  Future<void> fetchConfig() async {
    await remoteConfig.fetchConfig();
  }

  String getString(String key) => remoteConfig.getString(key);

  _getIndex() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      tmpBook = book = prefs.getInt(bookPrefs) ?? 0;
      tmpChapter = chapter = ((prefs.getInt(chapterPrefs) ?? 0) >= bible.books[bible.books.keys.toList()[book]].length()
          ? bible.books[bible.books.keys.toList()[book]].length()-1
          : prefs.getInt(chapterPrefs)) ?? 0;
      /*tmpVerse = verse = ((prefs.getInt(versePrefs) ?? 0) >= bible.books[bible.books.keys.toList()[book]].chapters[chapter].length()
          ? bible.books[bible.books.keys.toList()[book]].chapters[chapter].length()
          : prefs.getInt(versePrefs)) ?? 0;*/

      navigationBar = NavigationBar(
        initialBook: book,
        initialChapter: chapter,
        confirm: (int b, int c) {
          tmpBook = b;
          tmpChapter = c;
          setText();
        },
      );

      print('$book, $chapter');
    });

    if(!tutorialDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(Duration(seconds: 1));
        await showDialog<String>(
            context: context,
            builder: (BuildContext context) => new AlertDialog(
              title: new Text("Gestures:"),
              content: new GestureDetector(
                child: new Text('- Scroll on the bottom bar displaying the book and chapter to pick, and press the OK button to confirm'
                    '\n- Double tap on the bottom bar to open an expanded reference picker'
                    '\n- Swipe left/right to navigate chapters'
                    '\n- Double tap to open the search page'),
              ),
              actions: <Widget>[
                new FlatButton(
                  child: new Text('CLOSE'),
                  onPressed: () async {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            )
        ).then((s) async {
          setState(() => tutorialDialog = true);
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setBool(tutorialDialogPrefs, true);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    fetchConfig();

    if(versionChanged && bible.books.isNotEmpty && defaultVersion.isNotEmpty) {
      _getIndex();
      versionChanged = false;
      changeBook(book);
    }

    var listAppBar = PreferredSize(
      child: new SafeArea(
        child: navigationBar
      ),
      preferredSize: new Size.fromHeight(56.0),
    );

    return OrientationBuilder(
      builder: (context, orientation) => defaultVersion.isNotEmpty
          ? Scaffold(
        body: new SafeArea(
            child: new Stack(
              children: <Widget>[
                new GestureDetector(
                  onDoubleTap: () {
                    Navigator.of(context).push<Tuple2>(
                        new FadeAnimationRoute(builder: (context) => SearchWindow())
                    ).then<void>((Tuple2<dynamic, dynamic> value) {
                      if(value != null) {
                        setState(() {
                          tmpBook = value.item1 ?? book;
                          tmpChapter = value.item2 ?? book;
                        });
                        setText();
                      }
                    });
                  },
                  child: Swiper(
                      controller: swipeController,
                      index: bible.index(book, chapter),
                      itemCount: bible.chaptersLength(),
                      itemBuilder: (BuildContext context, int index) => FutureBuilder(
                        future: bible.getPageIndex(context, index, orientation: orientation),
                        initialData: new Center(
                          child: new CircularProgressIndicator(),
                        ),
                        builder: (BuildContext context, AsyncSnapshot<Widget> data) {
                          switch(data.connectionState) {
                            case ConnectionState.waiting:
                              return new Center(
                                child: new CircularProgressIndicator(),
                              );
                            default:
                              Tuple2<int, int> tmp = bible.fromIndex(index);
                              return new Scrollbar(
                                child: CustomScrollView(
                                  slivers: <Widget>[
                                    SliverList(
                                      delegate: SliverChildListDelegate([
                                        new Container(
                                          height: orientation == Orientation.portrait ? fontSize*8 : fontSize*4,
                                          margin: EdgeInsets.only(
                                            top: orientation == Orientation.portrait ? fontSize*2 : fontSize,
                                            bottom: fontSize,
                                          ),
                                          child: new Center(
                                            child: new RichText(
                                              textAlign: TextAlign.center,
                                              text: new TextSpan(
                                                  children: [
                                                    new TextSpan(
                                                      text: '${bible.getBookHuman(tmp.item1)}',
                                                      style: Theme.of(context).textTheme.body1.copyWith(
                                                        fontSize: fontSize*2,
                                                      ),
                                                    ),
                                                    new TextSpan(
                                                      text: '\n${chapter+1}',
                                                      style: Theme.of(context).textTheme.body1.copyWith(
                                                        fontSize: fontSize*1.6,
                                                        fontWeight: FontWeight.w300,
                                                      ),
                                                    ),
                                                  ]
                                              ),
                                            ),
                                          ),
                                        ),
                                        data.data
                                      ]),
                                    )
                                  ],
                                ),
                              );
                          }
                        },
                      ),
                      onIndexChanged: (index) {
                        setState(() {
                          Tuple2<int, int> tmp = bible.fromIndex(index);
                          tmpBook = tmp.item1;
                          tmpChapter = tmp.item2;
                        });
                        setText();
                      }
                  ),
                ),
              ],
            )
        ),
        appBar: appBarAtTop ? listAppBar : null,
        bottomNavigationBar: appBarAtTop ? null : listAppBar,
      ) : new Scaffold(
        body: new SafeArea(
          child: new Stack(
            children: <Widget>[
              new Center(
                child: new Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    new Container(
                      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
                      child: new Center(
                        child: new RichText(
                          textAlign: TextAlign.center,
                          text: new TextSpan(
                            text: getString('no_default_version_title'),
                            style: Theme.of(context).textTheme.body1.copyWith(
                              fontSize: fontSize*1.6,
                            ),
                          ),
                        ),
                      ),
                    ),
                    new Container(
                      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
                      child: new Center(
                        child: new RichText(
                          textAlign: TextAlign.center,
                          text: new TextSpan(
                            text: '${getString('no_default_version_subtitle')}',
                            style: Theme.of(context).textTheme.body1.copyWith(
                              fontSize: fontSize,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                      ),
                    ),
                    new FlatButton(
                      onPressed: () {
                        Navigator.of(context).push(
                            new FadeAnimationRoute(builder: (context) => VersionsPage())
                        );
                      },
                      child: new Text(getString('select_default_version')),
                    ),
                    new Container(height: 56.0),
                  ],
                ),
              ),
              new Align(
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
                  alignment: Alignment.bottomCenter,
                  child: new Row(
                    children: [
                      new Expanded(
                          child: new Container(
                            height: 56.0,
                            width: 56.0,
                            child: new IconButton(
                              icon: new Icon(Icons.arrow_back),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                          flex: 2
                      ),
                      new Expanded(
                        child: new Opacity(opacity: 0.0),
                        flex: 11,
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  changeBook(int b) {
    print('changeBook');
    setState(() {
      tmpBook = b;
    });
  }

  changeChapter(int c) {
    setState(() => tmpChapter = c);
  }

  setText() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    int b = 0, c = 0;

    if(tmpChapter >= bible.books[bible.books.keys.toList()[tmpBook]].length() && tmpBook+1 >= bible.length()) {

    } else if(tmpBook-1 < 0 && tmpChapter < 0) {
      b = bible.length()-1;
      c = bible.books[bible.books.keys.toList()[bible.length()-1]].length()-1;
    } else {
      if(tmpChapter >= bible.books[bible.books.keys.toList()[tmpBook]].length()) {
        b = tmpBook+1;
        c = tmpChapter-bible.books[bible.books.keys.toList()[tmpBook]].length();
      } else if(tmpChapter < 0) {
        b = tmpBook-1;
        c = bible.books[bible.books.keys.toList()[tmpBook-1]].length()+tmpChapter;
      } else {
        b = tmpBook;
        c = tmpChapter;
      }
    }

    setState(() {
      book = b;
      chapter = c;
      //verse = tmpVerse;
    });
    print('$book, $chapter');

    prefs.setInt(bookPrefs, book);
    prefs.setInt(chapterPrefs, chapter);

    if(bookController.selectedItem != book) {
      bookController.jumpToItem(book);
    }
    if(chapterController.selectedItem != chapter) {
      chapterController.jumpToItem(chapter);
    }

    swipeController.move(bible.index(book, chapter), animation: false);

    logEvent('bible_opened', {'book': book, 'chapter': chapter, 'toText': bible.chapterAsText(new Tuple2(book, chapter))});

    //prefs.setInt(versePrefs, verse);
  }
}

isChanged() {
  return book != tmpBook
      || chapter != tmpChapter
  /*|| verse != tmpVerse*/;
}

class NavigationBar extends StatefulWidget {
  final int initialBook, initialChapter;
  final void Function(int, int) confirm;

  NavigationBar({
    this.initialBook,
    this.initialChapter,
    this.confirm,
  });

  @override
  _NavigationBarState createState() => _NavigationBarState();

  static _NavigationBarState of(BuildContext context) => context.ancestorStateOfType(const TypeMatcher<_NavigationBarState>());

}
class _NavigationBarState extends State<NavigationBar> {

  int _book, _chapter, _tmpBook, _tmpChapter;

  @override
  initState() {
    super.initState();

    _tmpBook = _book = widget.initialBook ?? 0;
    _tmpChapter = _chapter = widget.initialChapter ?? 0;

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
  }
  @override
  dispose() {
    super.dispose();
    bookController.dispose();
    chapterController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).canvasColor,
      height: 56.0,
      alignment: Alignment.center,
      child: new Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          new Container(
            child: new IconButton(
              icon: new Icon(Icons.menu),
              onPressed: () => Navigator.of(context).pop(),
            ),
            margin: EdgeInsets.symmetric(horizontal: 4.0),
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
                    builder: (BuildContext context) => new BibleNavigation(
                      initialBook: tmpBook,
                      initialChapter: tmpChapter,
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
            child: new FlatButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  Navigator.of(context).push(
                      new FadeAnimationRoute(builder: (context) => VersionsPage())
                  );
                },
                child: new Text(
                  defaultVersion.isEmpty ? 'NONE' : defaultVersionFormatted(),
                  textAlign: TextAlign.left,
                )
            ),
            flex: 5,
          ),
          new Expanded(
            child: new FlatButton(
              padding: EdgeInsets.zero,
              onPressed: isChanged() ? setText : null,
              child: new Text("OK"),
            ),
            flex: 4,
          ),
        ],
      ),
    );
  }

  setText() async {
    setState(() {
      book = tmpBook;
      chapter = tmpChapter >= bible.books[bible.books.keys.toList()[book]].length()
          ? bible.books[bible.books.keys.toList()[book]].length()-1
          : tmpChapter;
    });

    widget.confirm(book, chapter);
  }

/*  isChanged() {
    return _book != _tmpBook
        || _chapter != _tmpChapter;
  }*/

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
      var tmp = tmpChapter;
      chapterController.jumpToItem(bible.books[bible.books.keys.toList()[tmpBook]].length()-1);
      if(tmp < bible.books[bible.books.keys.toList()[tmpBook]].length()) {
        chapterController.jumpToItem(tmp);
      }
    });
  }
  changeChapter(int c) {
    setState(() {
      tmpChapter = c;
    });
  }
}

class BibleNavigation extends StatefulWidget {
  final int initialBook, initialChapter;
  BibleNavigation({
    this.initialBook,
    this.initialChapter
  });

  @override
  _BibleNavigationState createState() => _BibleNavigationState();
}
class _BibleNavigationState extends State<BibleNavigation> {
  FixedExtentScrollController bookController,
      chapterController/*,
      verseController*/;
/*  ListWheelScrollView chapterScrollView*//*,
      verseScrollView*//*;*/

  List<Widget> chapters = [];

  int _book, _chapter, _tmpBook, _tmpChapter;

  TextEditingController textEditingController = new TextEditingController();

  bool search = false;

  @override
  initState() {
    super.initState();

    _tmpBook = _book = widget.initialBook ?? 0;
    _tmpChapter = _chapter = widget.initialChapter ?? 0;

    bookController = new FixedExtentScrollController(
        initialItem: _book
    );
    chapterController = new FixedExtentScrollController(
        initialItem: _chapter
    );

    chapters = List.generate(bible.books[bible.books.keys.toList()[_book]].length(), (i) => new ListTile(
      contentPadding: EdgeInsets.zero,
      title: new Text(
        "${(i+1)}",
        textAlign: TextAlign.center,
      ),
    ));

/*    verseScrollView = new ListWheelScrollView(
      children: List.generate(bible.books[bible.books.keys.toList()[book]].chapters[chapter].length(), (i) => new ListTile(
        contentPadding: EdgeInsets.zero,
        title: new Text(
          "${(i+1)}",
          textAlign: TextAlign.center,
        ),
      )),
      controller: chapterController,
      itemExtent: 56.0,
      perspective: double.minPositive,
      onSelectedItemChanged: (int index) => changeVerse(index),
      physics: FixedExtentScrollPhysics(),
    );*/
  }
  @override
  dispose() {
    super.dispose();
    bookController.dispose();
    chapterController.dispose();
    textEditingController.dispose();
  }

  someMethod() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return new AlertDialog(
      title: !search ? Row(
        children: <Widget>[
          Expanded(
            child: GestureDetector(
              child: new Text('${bible.books.keys.toList()[_tmpBook].item2} ${_tmpChapter+1}'),
              onTap: toggleSearch,
            ),
          ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: toggleSearch,
          ),
        ],
      ) : Row(
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: toggleSearch,
          ),
          new Expanded(
            child: new TextField(
              controller: textEditingController,
              decoration: new InputDecoration(
                  hintText: 'Search',
                  border: InputBorder.none
              ),
              onSubmitted: (s) => searchChapter(s),
            ),
          ),
          new IconButton(
            icon: new Icon(Icons.cancel),
            onPressed: () {
              textEditingController.clear();
              setState(() {});
            },
          ),
        ],
      ),
      content: Stack(
        children: <Widget>[
          new Row(
            children: <Widget>[
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  childDelegate: ListWheelChildBuilderDelegate(
                      childCount: bible.length(),
                      builder: (BuildContext context, int index) => new ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 4.0),
                        title: new Text(
                          bible.books.keys.toList()[index].item2,
                          textAlign: TextAlign.center,
                          softWrap: true,
                        ),
                      )
                  ),
                  controller: bookController,
                  itemExtent: 56.0,
                  perspective: double.minPositive,
                  onSelectedItemChanged: (int index) => changeBook(index),
                  physics: FixedExtentScrollPhysics(),
                ),
                flex: 11,
              ),
              Expanded(
                child: ListWheelScrollView(
                  children: chapters,
                  controller: chapterController,
                  itemExtent: 56.0,
                  perspective: double.minPositive,
                  onSelectedItemChanged: (int index) => changeChapter(index),
                  physics: FixedExtentScrollPhysics(),
                ),
                flex: 4,
              ),
/*              Expanded(
                child: verseScrollView,
                flex: 4,
              ),*/
            ],
          ),
          new IgnorePointer(
            child: new Align(
              alignment: Alignment.bottomCenter,
              child: new Container(
                decoration: new BoxDecoration(
                  gradient: new LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Theme.of(context).dialogBackgroundColor.withAlpha(0), Theme.of(context).dialogBackgroundColor],
                    tileMode: TileMode.repeated,
                  ),
                ),
                height: 56.0,
              ),
            ),
          ),
          new IgnorePointer(
            child: new Align(
              alignment: Alignment.topCenter,
              child: new Container(
                decoration: new BoxDecoration(
                  gradient: new LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Theme.of(context).dialogBackgroundColor, Theme.of(context).dialogBackgroundColor.withAlpha(0)],
                    tileMode: TileMode.repeated,
                  ),
                ),
                height: 56.0,
              ),
            ),
          ),
        ],
      ),
      actions: <Widget>[
        new FlatButton(
          child: new Text('CANCEL'),
          onPressed: () => Navigator.pop(context, new Tuple2(DialogAction.confirm, null)),
        ),
        new FlatButton(
          child: new Text('OK'),
          onPressed: _isChanged() ? () => Navigator.pop(context, new Tuple2(DialogAction.confirm, new Tuple2(_tmpBook, _tmpChapter))) : null,
        ),
      ],
    );
  }

  toggleSearch() {
    setState(() => search = !search);
  }

  searchChapter(String query) {
    if(isChapter(query)){
      var result = getChapter(query);
      print(result);
      changeBook(result.item1);
      changeChapter(result.item2);
      bookController.jumpToItem(result.item1);
      chapterController.jumpToItem(result.item2);
    }
  }

  changeBook(int b) {
    setState(() {
      _tmpBook = b;
      chapters = List.generate(bible.books[bible.books.keys.toList()[_tmpBook]].length(), (i) => new ListTile(
        contentPadding: EdgeInsets.zero,
        title: new Text(
          "${(i+1)}",
          textAlign: TextAlign.center,
        ),
      ));
      var tmp = _tmpChapter;
      chapterController.jumpToItem(chapters.length-1);
      if(tmp < chapters.length) {
        chapterController.jumpToItem(tmp);
      }
    });
  }
  changeChapter(int c) {
    setState(() {
      /*verseScrollView = new ListWheelScrollView(
        children: List.generate(bible.books[bible.books.keys.toList()[tmpBook]].chapters[c].length(), (i) => new ListTile(
          contentPadding: EdgeInsets.zero,
          title: new Text(
            "${(i+1)}",
            textAlign: TextAlign.center,
          ),
        )),
        controller: chapterController,
        itemExtent: 56.0,
        perspective: double.minPositive,
        onSelectedItemChanged: (int index) => changeVerse(index),
        physics: FixedExtentScrollPhysics(),
      );*/
      _tmpChapter = c;
    });
  }
/*  changeVerse(int v) {
    setState(() => tmpVerse = v);
  }*/

  _isChanged() {
    return _book != _tmpBook
        || _chapter != _tmpChapter
    /*|| verse != tmpVerse*/;
  }
}


class TutorialSequence extends StatefulWidget {


  @override
  _TutorialSequenceState createState() => _TutorialSequenceState();
}
class _TutorialSequenceState extends State<TutorialSequence> {

  @override
  Widget build(BuildContext context) {
    return new Column(
      children: <Widget>[
        new Expanded(
          child: new Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              new Expanded(
                child: new Container(),
                flex: 7,
              ),
              new Expanded(
                child: new Container(
                  height: 210.0,
                  child: new Arrow(
                    length: 7.0,
                    color: Theme.of(context).textTheme.title.color,
                    repeat: true,
                  ),
                ),
                flex: 4,
              ),
              new Expanded(
                child: new Container(),
                flex: 4,
              ),
              new Expanded(
                child: new Container(
                  height: 210.0,
                  child: new Arrow(
                    length: 7.0,
                    color: Theme.of(context).textTheme.title.color,
                    repeat: true,
                  ),
                ),
                flex: 4,
              ),
              new Expanded(
                child: new Container(),
                flex: 5,
              ),
              new Expanded(
                child: new Container(
                  height: 150.0,
                  child: new Arrow(
                    length: 5.0,
                    color: Theme.of(context).textTheme.title.color,
                    repeat: true,
                  ),
                ),
                flex: 4,
              )
            ],
          ),
        ),
      ],
    );
  }
}
