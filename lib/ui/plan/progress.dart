

import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:sortedmap/sortedmap.dart';


import 'package:bible/ui/page_manager.dart';
import 'package:bible/ui/plan_manager_page.dart';
import 'package:bible/ui/settings.dart';

class ProgressPage extends StatefulWidget {
  final RemoteConfig remoteConfig;
  final Plan plan;

  ProgressPage(this.remoteConfig, this.plan);

  @override
  _ProgressPageState createState() => new _ProgressPageState();
}
class _ProgressPageState extends State<ProgressPage> {


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
    return new WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
      },
      child: new Scaffold(
        body: new SafeArea(
          child: new Stack(
            children: <Widget>[
              new ListView(
                children: <Widget>[
                  new Container(
                    margin: EdgeInsets.only(
                      top: fontSize*4,
                      left: 16.0,
                      right: 16.0,
                      bottom: 16.0,
                    ),
                    child: new Container(
                      alignment: Alignment.bottomCenter,
                      child: new RichText(
                        textDirection: TextDirection.ltr,
                        text: new TextSpan(
                          text: getString('plan_progress'),
                          style: Theme.of(context).textTheme.body1.copyWith(
                            fontSize: fontSize*2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  progressList(),
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
      ),
    );
  }

  progressList() {
    return FutureBuilder(
      future: FirebaseDatabase.instance.reference().child('progress').child(widget.plan.key).once(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        switch(snapshot.connectionState) {
          case ConnectionState.waiting:
            return new Center(
              child: new CircularProgressIndicator(),
            );
          default:
            if(snapshot.data == null)
              return new Container();

            List uids = snapshot.data.value.keys.toList();
            List progress = snapshot.data.value.values.toList();

            List<Widget> result = new List<Widget>();

            var sortedKeys = snapshot.data.value.keys.toList(growable:false)
              ..sort((k1, k2) => trySum(snapshot.data.value[k2])-trySum(snapshot.data.value[k1]));

            LinkedHashMap sortedMap = new LinkedHashMap
                .fromIterable(sortedKeys, key: (k) => k, value: (k) => snapshot.data.value[k]);

            sortedMap.forEach(
              (k, v) => result.add(
                new ListTile(
                  title: new Text(k),
                  trailing: new Text('${((trySum(snapshot.data.value[k])/widget.plan.total())*100).round()}%'),
                )
              )
            );

            return new Column(
              children: result,
            );
        }
      },
    );
  }


  int trySum(var input) {
    try {
      return input.map((a) => a.length).toList().reduce((a, b) => a + b);
    } catch(e) {
      return 0;
    }
  }
}