import 'dart:async';
import 'dart:core';

import 'package:flutter/material.dart';

import 'package:html2md/html2md.dart' as html2md;
import 'package:sqflite/sqflite.dart';
import 'package:tuple/tuple.dart';

import 'package:bible/ui/settings.dart';
import 'package:bible/ui/versions.dart';
import 'package:bible/parser/parser.dart';


const int THOUSAND = 1000;

const String COLUMN_BOOK = "book";
const String COLUMN_VERSE = "verse";
const String COLUMN_HUMAN = "human";
const String COLUMN_UNFORMATTED = "unformatted";
const String COLUMN_PREVIOUS = "previous";
const String COLUMN_NEXT = "next";
const String COLUMN_CONTENT = "content";
const String COLUMN_OSIS = "osis";
const String COLUMN_CHAPTERS = "chapters";

const String TABLE_VERSES = "verses left outer join books on (verses.book = books.osis)";
const List<String> COLUMNS_VERSES = [
  "id",
  "book",
  "verse",
  "unformatted",
];

const String TABLE_VERSE = "verses";
const List<String> COLUMNS_VERSE = [
  "verse",
];

const String TABLE_CHAPTERS = "chapters";
const List<String> COLUMNS_CHAPTER = [
  "id ",
  "reference_osis as osis",
  "reference_human as human",
  "content",
/*  "previous_reference_osis as previous",
  "next_reference_osis as next",*/
];
const List<String> COLUMNS_CHAPTERS = [
  "count(id) as _count",
];

const String TABLE_BOOKS = "books";
const List<String> COLUMNS_BOOKS = [
  "osis",
  "human",
  "chapters",
];

const String TABLE_ANNOTATIONS = "annotations";
const List<String> COLUMNS_ANNOTATIONS = [
  "link",
  "content",
];

class Bible {
  Map<String, String> /*annotations = new Map<String, String>(),*/
                      osis = new Map<String, String>(),
                      human = new Map<String, String>();
  Map<Tuple2<String, String>, Book> books = new Map<Tuple2<String, String>, Book>();
  Database database;

  Bible();

  Future<Null> setDefaultVersion() async {
    if (defaultVersion.isNotEmpty) {
      print('Default version: $defaultVersion');
      String path = await localPath;
      database = await openDatabase('$path/$defaultVersion.sqlite3');
/*      List<Map> list = await database.query(TABLE_VERSES, columns: ['verse']);
      //list.map((Map<dynamic, dynamic> l) => l['chapters']).toList()
      print(list.map((Map<dynamic, dynamic> l) => l['verse'].runtimeType.toString()));*/
/*      annotations = Map.fromIterable(await database.query(TABLE_ANNOTATIONS, columns: COLUMNS_ANNOTATIONS),
        key: (item) => item['link'],
        value: (item) => item['content'],
      );*/
      int c = 0, v = 0;
      List<Map>/* chapters = await database.query(TABLE_CHAPTERS, columns: COLUMNS_CHAPTER),*/
                verses = await database.query('verses', columns: ['verse', 'unformatted']);
      books = Map.fromIterable(await database.query(TABLE_BOOKS, columns: COLUMNS_BOOKS),
        key: (item) {
          osis[item['osis']] = item['human'];
          human[item['human']] = item['osis'];
          return Tuple2(item['osis'], item['human']);
        },
        value: (item) {
          Book book = new Book(
            osis: item['osis'],
            human: item['human'],
          );
          //print('${item['human']}: ${item['chapters']+1} chapters');
          for(int i = 0; i < item['chapters']; i++) {
            Chapter chapter = new Chapter(
/*              osis: chapters[c]['osis'],
              human: chapters[c]['human'],
              content: chapters[c]['content'],*/
              index: c,
            );
            int currentVerse = ((verses[v]['verse'] * 1000).ceil() % 1000).toInt(),
                nextVerse = ((verses[v+1]['verse'] * 1000).ceil() % 1000).toInt();
            int verse = 0;
            while(currentVerse <= nextVerse) {
              chapter.add(new Verse(
                verse: verse,
                id: v,
                //unformatted: verses[v]['unformatted'],
              ));
              verse++;
              v++;
              currentVerse = ((verses[v]['verse'] * 1000).ceil() % 1000).toInt();
                  nextVerse = (((v < verses.length-1 ? verses[v+1]['verse'] : 0) * 1000).ceil() % 1000).toInt();
            }
            chapter.add(new Verse(
              verse: verse,
              id: v,
            ));
            //print('  ${book.human}(${book.osis}) ${i+1}: ${verse+1} verses ($v)');
            v++;
            book.add(chapter);
            c++;
          }
          return book;
        },
      );
      print('done reading file.');
    } else {
      print('No default version set.');
    }
  }

  void check() {
    try {
      for(int i = 0; i < books.length; i++) {
        print('${books[books.keys.toList()[i]].human}');
      }
    } catch(e) {
      print('Error when checking bible: $e');
    }
  }

  Future<Widget> getPage(BuildContext context, int b, int c, {int start, int end}) async {
    try {
      Tuple2 corrected = new PassageChecker(bible: this).correctChapter(new Tuple2(b, c));

      int book = corrected.item1, chapter = corrected.item2;

      print('getPage: ${books.keys.toList()[book].item1}.${chapter+1}');

      List<Map> data = await database.rawQuery('SELECT content FROM chapters WHERE rowid = ${books[books.keys.toList()[book]].chapters[chapter].index+1}'),
          rawAnnotations = await database.rawQuery("SELECT link,content FROM annotations WHERE osis LIKE '%${books.keys.toList()[book].item1}.${chapter+1}%'");
      Map annotations = Map.fromIterable(rawAnnotations,
        key: (item) => item['link'],
        value: (item) => item['content'],
      );

      return defaultVersion.isNotEmpty
          ? new Column(
        children: <Widget>[
          start == null || end == null ? new Container(
            height: fontSize*8,
            margin: EdgeInsets.only(
              top: fontSize*2,
              bottom: fontSize,
            ),
            child: new Center(
              child: new RichText(
                textAlign: TextAlign.center,
                text: new TextSpan(
                    children: [
                      new TextSpan(
                        text: '${books.keys.toList()[book].item2}',
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
          ) : new Container(
            height: (fontSize*1.25)*2,
            margin: EdgeInsets.only(top: appBarAtTop ? 56.0 : 0.0),
            child: new Center(
              child: new RichText(
                text: new TextSpan(
                  text: '${books.keys.toList()[book].item2} ${chapter+1}:'
                      '${start+1}-'
                      '${end >= books[books.keys.toList()[book]].chapters[chapter].length()
                      ? books[books.keys.toList()[book]].chapters[chapter].length()
                      : end+1}',
                  style: Theme.of(context).textTheme.body1.copyWith(
                    fontSize: fontSize*1.25,
                  ),
                ),
              ),
            ),
          ),
          new Container(
            margin: EdgeInsets.only(
              left: 8.0,
              right: 8.0,
            ),
            child: new Parser(
              context,
              annotations,
              book: b < 3 ? b : b+1,
              chapter: c+1,
              start: start,
              end: end,
              osis: books.keys.toList()[book].item1,
            ).fromHtml(data[0]['content']),
          ),
        ],
      ) : new Center(
        child: new CircularProgressIndicator(),
      );
    } catch(e) {
      print('Error on getPage: $e');
      return new Container();
    }
  }

  Future<Widget> getPageIndex(BuildContext context, int index, {int start, int end}) async {
    try {
      Tuple2 corrected = fromIndex(index);

      int book = corrected.item1, chapter = corrected.item2;

      print('getPage: ${books.keys.toList()[book].item1}.${chapter+1}');

      List<Map> data = await database.rawQuery('SELECT content FROM chapters WHERE rowid = ${books[books.keys.toList()[book]].chapters[chapter].index+1}'),
          rawAnnotations = await database.rawQuery("SELECT link,content FROM annotations WHERE osis LIKE '%${books.keys.toList()[book].item1}.${chapter+1}%'");
      Map annotations = Map.fromIterable(rawAnnotations,
        key: (item) => item['link'],
        value: (item) => item['content'],
      );

      return defaultVersion.isNotEmpty
          ? new Column(
        children: <Widget>[
          start == null || end == null ? new Container(
            height: fontSize*8,
            margin: EdgeInsets.only(
              top: fontSize*2,
              bottom: fontSize,
            ),
            child: new Center(
              child: new RichText(
                textAlign: TextAlign.center,
                text: new TextSpan(
                    children: [
                      new TextSpan(
                        text: '${books.keys.toList()[book].item2}',
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
          ) : new Container(
            height: (fontSize*1.25)*2,
            margin: EdgeInsets.only(top: appBarAtTop ? 56.0 : 0.0),
            child: new Center(
              child: new RichText(
                text: new TextSpan(
                  text: '${books.keys.toList()[book].item2} ${chapter+1}:'
                      '${start+1}-'
                      '${end >= books[books.keys.toList()[book]].chapters[chapter].length()
                      ? books[books.keys.toList()[book]].chapters[chapter].length()
                      : end+1}',
                  style: Theme.of(context).textTheme.body1.copyWith(
                    fontSize: fontSize*1.25,
                  ),
                ),
              ),
            ),
          ),
          new Container(
            margin: EdgeInsets.only(
              left: 8.0,
              right: 8.0,
            ),
            child: new Parser(
              context,
              annotations,
              book: book < 3 ? book : book+1,
              chapter: book+1,
              start: start,
              end: end,
              osis: books.keys.toList()[book].item1,
            ).fromHtml(data[0]['content']),
          ),
        ],
      ) : new Center(
        child: new CircularProgressIndicator(),
      );
    } catch(e) {
      print('Error on getPageIndex: $e');
      return new Container();
    }
  }

  Future<List<Map>> search(String text) async {
    String query = text.trim();
    return await database
        .rawQuery("SELECT book,verse,unformatted "
        "FROM verses "
        "WHERE unformatted LIKE '%$query%' COLLATE NOCASE");
  }

  Future<List<Map>> getVerses(List<Tuple3> verses) async {
    PassageChecker passage = new PassageChecker(bible: this);
    List<Tuple3> corrected = verses.map((v) => passage.correctVerse(v)).toList();
    return await database.rawQuery(getVersesQuery(corrected));
  }

  String getVersesQuery(List<Tuple3> verses) {
    String query = 'SELECT book,verse,unformatted '
        'FROM verses '
        'WHERE id '
        'in (${verses.map((v) => books[books.keys.toList()[v.item1]].chapters[v.item2].verses[v.item3].id+1).toList().join(", ")})';
    return query;
  }

  Future<List<Map>> getAnnotation(String query) async {
    return await database.rawQuery("SELECT content "
        "FROM annotations "
        "WHERE link LIKE '%$query%' COLLATE NOCASE");
  }

  String chapterAsText(Tuple2<int, int> chapter) {
    Tuple2 corrected = new PassageChecker(bible: this).correctChapter(chapter);
    return '${books.keys.toList()[corrected.item1].item2} ${corrected.item2+1}';
  }

  String verseAsText(Tuple3<int, int, int> verse) {
    Tuple3 corrected = new PassageChecker(bible: this).correctVerse(verse);
    return '${books.keys.toList()[corrected.item1].item2} ${corrected.item2+1}:${corrected.item3+1}';
  }

  index(int book, int chapter) => books.values.toList()[book].chapters[chapter].index;

  Tuple2<int, int> fromIndex(int index) {
    int b = 0,
        c = 0,
        i = 0;

    while(i-1 < index) {
      i += books.values.toList()[b].length();
      b++;
    }

    c = books.values.toList()[b-1 < 0 ? 0 : b-1].length()-(i - index);

    return Tuple2(b-1, c);
  }

  length() => books.length;
  chaptersLength() => books.values.toList().last.chapters.last.index+1;
}

class PassageChecker {
  int book = 0, chapter = 0, verse = 0,
      b = 0, c = 0, v = 0;
  Bible bible;

  PassageChecker({this.bible});

  Tuple2<int, int> correctChapter(Tuple2<int, int> input) {
    b = input.item1; c = input.item2;

    checkBook();
    checkChapter();

    return new Tuple2(book, chapter);
  }

  Tuple3<int, int, int> correctVerse(Tuple3<int, int, int> input) {
    b = input.item1; c = input.item2; v = input.item3;

    checkBook();
    checkChapter();
    checkVerse();

    return new Tuple3(book, chapter, verse);
  }

  checkBook() {
    if(b >= bible.length()) {
      book = (b)-bible.length();
      b = book;
    } else if(b < 0) {
      book = bible.length()+(b);
      b = book;
    } else {
      book = b;
    }
    checkChapter();
  }

  checkChapter() {
    if(c >= bible.books[bible.books.keys.toList()[b]].length()) {
      chapter = c-bible.books[bible.books.keys.toList()[b]].length();
      b++;
      c = chapter;
      checkBook();
    } else if(c < 0) {
      chapter = bible.books[bible.books.keys.toList()[b-1]].length()+c;
      b--;
      c = chapter;
      checkBook();
    } else {
      chapter = c;
    }
    checkVerse();
  }
  checkVerse() {
    if(v >= bible.books[bible.books.keys.toList()[b]].chapters[c].length()) {
      verse = v-(bible.books[bible.books.keys.toList()[b]].chapters[c].length());
      c++;
      v = verse;
      checkChapter();
    } else if(v < 0) {
      verse = bible.books[bible.books.keys.toList()[b]].chapters[c].length()+v+1;
      c--;
      v = verse;
      checkChapter();
    } else {
      verse = v;
    }
  }
}

class Book {
  String osis, human;
  List<Chapter> chapters = new List<Chapter>();

  Book({
    this.osis,
    this.human,
  });

  add(Chapter chapter) => chapters.add(chapter);
  length() => chapters.length;
}
class Chapter {
  String osis, human, content;
  int index;
  double offset = 0.0;
  List<Verse> verses = new List<Verse>();

  Chapter({
    this.osis,
    this.human,
    this.content,
    this.index,
  });

  add(Verse verse) => verses.add(verse);

  length() => verses.length;
}
class Verse {
  int verse, id;
  String unformatted;

  Verse({
    this.verse,
    this.id,
    this.unformatted,
  });
}
