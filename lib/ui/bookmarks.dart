

import 'package:bible/ui/app.dart';
import 'package:flutter/material.dart';

import 'package:bible/ui/page_manager.dart';
import 'package:bible/ui/settings.dart';

class BookmarksPage extends StatefulWidget {

  @override
  _BookmarksPageState createState() => new _BookmarksPageState();
}
class _BookmarksPageState extends State<BookmarksPage> {

  Future<void> fetchConfig() async {
    await remoteConfig.fetchConfig();
  }

  String getString(String key) => remoteConfig.getString(key);

  @override
  Widget build(BuildContext context) {
    fetchConfig();
    return new Scaffold(
      body: new SafeArea(
        child: new Stack(
          children: <Widget>[
            new ListView(
              children: <Widget>[
                new Container(
                  height: fontSize*6,
                  margin: EdgeInsets.only(top: fontSize*4),
                  child: new Center(
                    child: new RichText(
                      text: new TextSpan(
                        text: getString('title_bookmarks'),
                        style: Theme.of(context).textTheme.body1.copyWith(
                          fontSize: fontSize*2,
                        ),
                      ),
                    ),
                  ),
                  color: Theme.of(context).canvasColor,
                ),
              ],
            ),
            appBarAtTop ? new Align(
              alignment: Alignment.topCenter,
              child: new Stack(
                children: <Widget>[
                  new IgnorePointer(
                    child: new Align(
                      alignment: Alignment.topCenter,
                      child: new Container(
                        decoration: new BoxDecoration(
                          gradient: new LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Theme.of(context).canvasColor, Theme.of(context).canvasColor.withAlpha(0)],
                            tileMode: TileMode.repeated,
                          ),
                        ),
                        height: 56.0,
                      ),
                    ),
                  ),
                  new Align(
                    alignment: Alignment.topLeft,
                    child: new Container(
                      height: 56.0,
                      width: 56.0,
                      child: new IconButton(
                        icon: new Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ],
              ),
            ) : new Align(
              alignment: Alignment.bottomCenter,
              child: new Stack(
                children: <Widget>[
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
                  new Align(
                    alignment: Alignment.bottomLeft,
                    child: new Container(
                      height: 56.0,
                      width: 56.0,
                      child: new IconButton(
                        icon: new Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
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