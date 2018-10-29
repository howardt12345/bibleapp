import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:bible/ui/page_manager.dart';
import 'package:bible/ui/settings.dart';

class AboutPage extends StatefulWidget {
  static _AboutPageState of(BuildContext context) => context.ancestorStateOfType(TypeMatcher<_AboutPageState>());

  final RemoteConfig remoteConfig;

  AboutPage(this.remoteConfig);

  @override
  _AboutPageState createState() => new _AboutPageState();
}
class _AboutPageState extends State<AboutPage> with TickerProviderStateMixin {
  AnimationController _controller;
  ListAnimation _listAnimation;

  List<String> _text;

  @override
  void initState() {
    super.initState();
    fetchConfig();

    getFileData("assets/files/about.txt").then((String file) {
      setState(() => _text = file.split('\n'));

      _controller = new AnimationController(
        duration: const Duration(milliseconds: duration*4),
        vsync: this,
      );
      _listAnimation = new ListAnimation(
        controller: _controller,
        items: _text.length,
      );
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
    fetchConfig();
    Widget _buildTextLine(BuildContext context, int index) {
      return Opacity(
        opacity: _listAnimation.animations[index].value,
        child: new Container(
          margin: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.05, right: 20.0),
          child: new RichText(
            text: new TextSpan(
              text: _text[index],
              style: Theme.of(context).textTheme.body1.copyWith(
                fontSize: fontSize,
              ),
            ),
          ),
        ),
      );
    }
    Widget _buildText(BuildContext context, Widget child) {
      List<Widget> list = new List<Widget>();
      list.add(new Container(
        height: fontSize*6,
        margin: EdgeInsets.only(
            top: fontSize*4,
            left: 8.0,
            right: 8.0,
        ),
        child: new Center(
          child: new RichText(
            text: new TextSpan(
              text: widget.remoteConfig.getString('title_about'),
              style: Theme.of(context).textTheme.body1.copyWith(
                fontSize: fontSize*2,
              ),
            ),
          ),
        ),
        color: Theme.of(context).canvasColor,
      ));
      list.addAll(_text.map((String s) => _buildTextLine(context, _text.indexOf(s))).toList());
      list.add(new Container(height: 56.0));
      return new Container(
        child: new ListView(
          children: list,
        ),
      );
    }

    return new Scaffold(
      body: new SafeArea(
        child: new Stack(
          children: <Widget>[
            new AnimatedBuilder(animation: _controller, builder: _buildText),
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
Future<String> getFileData(String path) async => await rootBundle.loadString(path);