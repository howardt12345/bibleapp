import 'dart:async';
import 'dart:core';
import 'dart:io';

import 'package:bible/ui/plan_manager_page.dart';
import 'package:bible/ui/versions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

import 'package:bible/ui/app.dart';
import 'package:bible/ui/settings.dart';

import 'auth.dart' as auth;

class ProfilePage extends StatefulWidget {

  @override
  _ProfilePageState createState() => _ProfilePageState();
}
class _ProfilePageState extends State<ProfilePage> {


  @override
  void initState() {
    super.initState();
  }

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
              new FutureBuilder<FirebaseUser>(
                future: FirebaseAuth.instance.currentUser(),
                builder: (BuildContext context, AsyncSnapshot<FirebaseUser> snapshot) {
                  FirebaseUser user = snapshot.data;

                  return new ListView(
                    children: <Widget>[
                      new Container(height: 28.0),
                      new Container(
                        height: fontSize*2,
                        child: new Align(
                          alignment: Alignment.centerRight,
                          child: new FlatButton(
                            onPressed: () {
                              showDialog<DialogAction>(
                                context: context,
                                builder: (BuildContext context) => new AlertDialog(
                                  title: new Text('Are you sure you want to sign out?'),
                                  content: new Text('All plans will be deleted from this device. '
                                      'Plans associated to your account will remain stored on the cloud.'),
                                  actions: <Widget>[
                                    new FlatButton(
                                      child: new Text('CANCEL'),
                                      onPressed: () => Navigator.pop(context, DialogAction.cancel),
                                    ),
                                    new FlatButton(
                                      child: new Text('OK'),
                                      onPressed: () => Navigator.pop(context, DialogAction.confirm),
                                    ),
                                  ],
                                )
                              ).then((onValue) {
                                switch(onValue) {
                                  case DialogAction.confirm:
                                    planManager.wipePlansFromFile();
                                    auth.signOut();
                                    Navigator.of(context).pop();
                                    break;
                                  default:
                                    break;
                                }
                              });
                            },
                            child: new Text('SIGN OUT'),
                          ),
                        ),
                      ),
                      new Container(
                        margin: EdgeInsets.only(top: fontSize*4, bottom: 16.0),
                        child: new Center(
                          child: new Container(
                            height: 120.0,
                            width: 120.0,
                            child: new FutureBuilder<FileImage>(
                                future: auth.getProfilePic(),
                                builder: (BuildContext context, AsyncSnapshot<FileImage> snapshot) {
                                  switch(snapshot.connectionState) {
                                    case ConnectionState.waiting:
                                      return new CircularProgressIndicator();
                                    default:
                                      return snapshot.data != null
                                          ? new CircleAvatar(
                                        backgroundImage: snapshot.data,
                                      ): new Container(
                                        child: IconButton(
                                          icon: Icon(Icons.add),
                                          onPressed: () {},
                                        ),
                                      );
                                  }
                                }
                            ),
                          ),
                        ),
                        color: Theme.of(context).canvasColor,
                      ),
                      new Container(
                        alignment: Alignment.center,
                        child: new RichText(
                          text: new TextSpan(
                            text: user.displayName != null ? user.displayName : '',
                            style: Theme.of(context).textTheme.body1.copyWith(
                              fontSize: fontSize,
                              fontWeight: FontWeight.w500
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
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
}