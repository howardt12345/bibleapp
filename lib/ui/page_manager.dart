import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bible/ui/app.dart';
import 'package:bible/ui/settings.dart';
import 'package:bible/ui/versions.dart';
import 'package:flutter/services.dart';

bool newVersion = false;
bool developerSettings = false;
const int duration = 300;

String changelog =
    '- UPdated code to Flutter 1.17'
    '\n\nKnown Bugs: '
    '\n- Contact the developer if any bugs are found.'
    '\n\nIn Progress:'
    '\n- Bugfixes.'
    '';

class PageManager extends StatefulWidget {
  static _PageManagerState of(BuildContext context) => context.ancestorStateOfType(TypeMatcher<_PageManagerState>());

  final List<Page> pages;

  PageManager({
    @required this.pages,
  });

  @override
  _PageManagerState createState() => _PageManagerState();
}
class _PageManagerState extends State<PageManager> with TickerProviderStateMixin {
  bool fade = true;
  int currentPage = 0;
  AnimationController _controller;
  ListAnimation _listAnimation;

  @override
  void initState() {
    super.initState();
    fetchConfig().then((void v) {
      versionsManager = VersionsManager();
      versionsManager.initialize(remoteConfig.getString('bible_download'));
    });
    _controller = AnimationController(
      duration: const Duration(milliseconds: duration),
      vsync: this,
    );
    _listAnimation = ListAnimation(
      controller: _controller,
      items: widget.pages.length,
    );
    _controller.forward();

    if(!newVersion) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text("What's in version ${versionText()}"),
            content: GestureDetector(
              child: Text(changelog),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('CLOSE'),
                onPressed: () async {
                  Navigator.of(context).pop();
                },
              ),
            ],
          )
        ).then((s) async {
          setState(() => newVersion = true);
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setBool(currentVersion, true);
        });
      });
    }
  }
 
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  toggleFade() {
    setState(() {
      fade = !fade;
    });
    fade ? _controller.forward() : _controller.reverse();
  }

  Widget crossFade({
    @required Widget first,
    @required Widget second,
    @required bool fade
  }) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: duration),
      firstChild: first,
      secondChild: second,
      crossFadeState: fade ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      sizeCurve: fade ? Curves.easeIn : Curves.fastOutSlowIn,
    );
  }

  Future<void> fetchConfig() async {
    await remoteConfig.fetchConfig();
  }

  String getString(String key) => remoteConfig.getString(key);

  @override
  Widget build(BuildContext context) {
    //fetchConfig();

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Container(
              color: Theme.of(context).canvasColor,
              child: AnimatedBuilder(
                  builder: _buildMenu,
                  animation: _controller
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Theme.of(context).canvasColor.withAlpha(0), Theme.of(context).canvasColor],
                    tileMode: TileMode.clamp,
                  ),
                ),
                height: 56.0,
                alignment: Alignment.bottomCenter,
                child: Row(
                  children: [
                    Container(
                      height: 56.0,
                      width: 56.0,
                      child: IconButton(
                        icon: Icon(Icons.info_outline),
                        onPressed: () => test(context),
                      ),
                    ),
                    Expanded(
                      child: Opacity(opacity: 0.0),
                      flex: 9,
                    ),
                    Container(
                      height: 56.0,
                      width: 56.0,
                      child: /*IconButton(
                              icon: Icon(Icons.exit_to_app),
                              onPressed: () => exit(0),
                            )*/Container(),
                    )

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenu(BuildContext context, Widget child) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: widget.pages
            .map((Page p) => _buildMenuItem(p, widget.pages.indexOf(p), context))
            .toList(),
      ),
    );
  }
  Widget _buildMenuItem(Page p, int index, BuildContext context) {
    return GestureDetector(
      onTap: p.isActive ? () => setState(() {
        currentPage = index;
        logEvent('open_page', {'page': index});
        Navigator.of(context).push(
            FadeAnimationRoute(builder: (context) => p.page)
        );
      }) : null,
      child: index == currentPage
        ? Opacity(
          opacity: _listAnimation.animations[index].value,
          child: Column(
            children: <Widget>[
              SizedBox(height: 16.0),
              Text(
                getString(p.key),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.body2.copyWith(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 14.0),
              Container(
                width: 70.0,
                height: 2.0,
                color: Theme.of(context).textTheme.body2.color,
              ),
            ],
          ),
      ) : Opacity(
        opacity: _listAnimation.animations[index].value,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            getString(p.key),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.body2.copyWith(
              fontSize: fontSize,
              fontWeight: FontWeight.w400,
              color: p.isActive
                  ? Theme.of(context).textTheme.body2.color.withAlpha(153)
                  : Theme.of(context).textTheme.body2.color.withAlpha(64),
            ),
          ),
        ),
      ),
    );
  }
  test(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('${getString('test_title')} ${versionText().trim()}.'),
        content: GestureDetector(
          onTap: null,
          child: Text('Changelog: \n$changelog'),
        ),
        actions: <Widget>[
          FlatButton(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context, DialogAction.confirm),
          ),
        ],
      )
    );
  }
}

String versionText() {
  return currentVersion
      //.replaceAll('pre-', ' Pre-')
      .replaceAll('-', ' ')
      .replaceAll('a', 'Alpha ')
      .replaceAll('b', 'Beta ')
      .replaceAll('t', 'Test ')
      .replaceAll('i', 'Internal ')
      .replaceAll('c', 'Candidate ');
}

class ListAnimation {
  final AnimationController controller;
  final List<Animation<double>> animations = List<Animation<double>>();

  ListAnimation({
    this.controller,
    int items,
  }) {
    for(int i = 0; i < items; i++) {
      animations.add(Tween(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(
              i/items,
              (i+1)/items,
              curve: Curves.ease,
            ),
          ),
        ),
      );
    }
  }
}

class Page {
  Widget page;
  String key;
  bool isActive;

  Page({
    this.page,
    this.key,
    this.isActive = true,
  });
}