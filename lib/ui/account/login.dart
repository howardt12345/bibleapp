import 'dart:async';
import 'dart:core';

import 'package:bible/ui/account/auth.dart';
import 'package:bible/ui/account/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

import 'package:bible/ui/app.dart';
import 'package:bible/ui/settings.dart';

import 'auth.dart' as auth;

class LoginPage extends StatefulWidget {

  @override
  _LoginPageState createState() => new _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {


  final TextEditingController _nameController = new TextEditingController();
  final TextEditingController _emailController = new TextEditingController();
  final TextEditingController _passController = new TextEditingController();
  final TextEditingController _confirmPassController = new TextEditingController();

  FocusNode _focusNodeName = new FocusNode();
  FocusNode _focusNodeEmail = new FocusNode();
  FocusNode _focusNodePass = new FocusNode();
  FocusNode _focusNodeConfirmPass = new FocusNode();

  ScrollController scrollController = new ScrollController();

  bool signUp = false;
  String errorMessage = '';

  Future<void> fetchConfig() async {
    await remoteConfig.fetchConfig();
  }

  String getString(String key) => remoteConfig.getString(key);

  googleButton() => new Container(
      height: 40.0,
      decoration: new BoxDecoration(
      borderRadius: new BorderRadius.all(const Radius.circular(4.0)),
      border: new Border.all(color: Colors.grey.withAlpha(125))
    ),
    child: new FlatButton(
      onPressed: () async {
        try {
          Navigator.of(context).push(
              new FadeAnimationRoute(builder: (context) => LoadingScreen(
                SignInMethod.google,
              ))
          ).then((onValue) {
            print(onValue);
            if(onValue == true) {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                  new FadeAnimationRoute(builder: (context) => ProfilePage())
              );
            }
          });
        } catch(e) {
          print(e);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/g-logo.png',
            width: 18.0,
            height: 18.0,
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('LOGIN'),
          )
        ]
      ),
    )
  );
  facebookButton() => new Container(
      height: 40.0,
      decoration: new BoxDecoration(
        borderRadius: new BorderRadius.all(const Radius.circular(4.0)),
        border: new Border.all(color: Colors.grey.withAlpha(125))
    ),
    child: new FlatButton(
      onPressed: () async {
        try {
          Navigator.of(context).push(
              new FadeAnimationRoute(builder: (context) => LoadingScreen(
                SignInMethod.facebook,
              ))
          ).then((onValue) {
            print(onValue);
            if(onValue == true) {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                  new FadeAnimationRoute(builder: (context) => ProfilePage())
              );
            }
          });
        } catch(e) {
          print(e);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/f-logo-${
              AppTheme.values[themeList.indexOf(
                App.of(context).themeData.copyWith(
                  textTheme: App.of(context).themeData.textTheme.apply(
                    fontFamily: defaultFont
                  )
                )
              )] == AppTheme.light ? 'c' : 'w'}.png',
            width: 18.0,
            height: 18.0,
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('LOGIN'),
          )
        ]
      ),
    )
  );

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
                child: new Container(),
                flex: 24,
              ),
            ],
          ),
        ),
      ),
      preferredSize: new Size.fromHeight(56.0),
    );


    return new WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
      },
      child: new Scaffold(
        body: new SafeArea(
          child: new Stack(
            children: <Widget>[
              new ListView(
                controller: scrollController,
                children: <Widget>[
                  new Container(
                    height: fontSize*4,
                    margin: EdgeInsets.only(top: fontSize*4),
                    child: new Center(
                      child: new RichText(
                        text: new TextSpan(
                          text: 'Login',
                          style: Theme.of(context).textTheme.body1.copyWith(
                            fontSize: fontSize*2,
                          ),
                        ),
                      ),
                    ),
                    color: Theme.of(context).canvasColor,
                  ),
                  new Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      new Container(
                        height: 40.0,
                        child: new FlatButton(
                          child: new Text('LOGIN'),
                          onPressed: signUp ? () => setState(() => signUp = false) : null,
                          disabledTextColor: Theme.of(context).textTheme.body1.color,
                          textColor: Theme.of(context).textTheme.body1.color.withAlpha(125),
                        ),
                        decoration: !signUp ? new BoxDecoration(
                            borderRadius: new BorderRadius.all(const Radius.circular(4.0)),
                            border: new Border.all(color: Colors.grey.withAlpha(125))
                        ) : null,
                      ),
                      new Container(
                        height: 40.0,
                        child: new FlatButton(
                          child: new Text('SIGN UP'),
                          onPressed: !signUp ? () => setState(() => signUp = true) : null,
                          disabledTextColor: Theme.of(context).textTheme.body1.color,
                          textColor: Theme.of(context).textTheme.body1.color.withAlpha(125),
                        ),
                        decoration: signUp ? new BoxDecoration(
                            borderRadius: new BorderRadius.all(const Radius.circular(4.0)),
                            border: new Border.all(color: Colors.grey.withAlpha(125))
                        ) : null,
                      ),
                    ],
                  ),
                  new Container(
                    margin: EdgeInsets.all(16.0),
                    child: new Column(
                      children: <Widget>[
                        new Container(
                          child: signUp ? new Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            margin: const EdgeInsets.only(bottom: 8.0),
                            height: 36.0,
                            decoration: new BoxDecoration(
                                borderRadius: new BorderRadius.all(const Radius.circular(4.0)),
                                border: new Border.all(color: Colors.grey.withAlpha(125))
                            ),
                            child: new TextFormField(
                              focusNode: _focusNodeName,
                              controller: _nameController,
                              decoration: new InputDecoration.collapsed(hintText: "Name"),
                              keyboardType: TextInputType.text,
                              style: Theme.of(context).textTheme.body1.copyWith(
                                fontSize: 16.0,
                              ),
                            ),
                          ) : new Container(height: 0.0),
                        ),
                        new Container(
                          child: new Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            margin: const EdgeInsets.only(bottom: 8.0),
                            height: 36.0,
                            decoration: new BoxDecoration(
                                borderRadius: new BorderRadius.all(const Radius.circular(4.0)),
                                border: new Border.all(color: Colors.grey.withAlpha(125))
                            ),
                            child: new TextFormField(
                              focusNode: _focusNodeEmail,
                              controller: _emailController,
                              decoration: new InputDecoration.collapsed(hintText: "Email"),
                              keyboardType: TextInputType.emailAddress,
                              style: Theme.of(context).textTheme.body1.copyWith(
                                fontSize: 16.0,
                              ),
                            ),
                          ),
                        ),
                        new Container(
                          child: new Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            margin: const EdgeInsets.only(bottom: 8.0),
                            height: 36.0,
                            decoration: new BoxDecoration(
                                borderRadius: new BorderRadius.all(const Radius.circular(4.0)),
                                border: new Border.all(color: Colors.grey.withAlpha(125))
                            ),
                            child: new TextFormField(
                              focusNode: _focusNodePass,
                              controller: _passController,
                              decoration: new InputDecoration.collapsed(hintText: "Password"),
                              obscureText: true,
                              autocorrect: false,
                              keyboardType: TextInputType.text,
                              style: Theme.of(context).textTheme.body1.copyWith(
                                fontSize: 16.0,
                              ),
                            ),
                          ),
                        ),
                        new Container(
                          child: signUp ? new Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            margin: const EdgeInsets.only(bottom: 8.0),
                            height: 36.0,
                            decoration: new BoxDecoration(
                                borderRadius: new BorderRadius.all(const Radius.circular(4.0)),
                                border: new Border.all(color: Colors.grey.withAlpha(125))
                            ),
                            child: new TextFormField(
                              focusNode: _focusNodeConfirmPass,
                              controller: _confirmPassController,
                              decoration: new InputDecoration.collapsed(hintText: "Confirm Password"),
                              obscureText: true,
                              autocorrect: false,
                              keyboardType: TextInputType.text,
                              style: Theme.of(context).textTheme.body1.copyWith(
                                fontSize: 16.0,
                              ),
                            ),
                          ) : new Container(height: 0.0),
                        ),
                        errorMessage.isNotEmpty ? new Container(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          height: 16.0,
                          child: new RichText(
                            text: new TextSpan(
                              text: errorMessage,
                              style: Theme.of(context).textTheme.body1.copyWith(
                                fontSize: 14.0,
                                color: Colors.red
                              ),
                            ),
                          ),
                        ) : new Container(height: 8.0),
                        new Container(
                          height: 40.0,
                          child: new FlatButton(
                            onPressed: _confirmPressed,
                            child: new Text(signUp ? 'SIGN UP' : 'LOGIN'),
                          ),
                          decoration: new BoxDecoration(
                              borderRadius: new BorderRadius.all(const Radius.circular(4.0)),
                              border: new Border.all(color: Colors.grey.withAlpha(125))
                          ),
                        ),
                        new Divider(height: 32.0,),
                        new Row(
                          children: <Widget>[
                            new Expanded(
                              child: new Container(
                                child: googleButton(),
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                              ),
                            ),
                            new Expanded(
                              child: new Container(
                                child: facebookButton(),
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        appBar: appBarAtTop ? appBar : null,
        bottomNavigationBar: appBarAtTop ? null : appBar,
      ),
    );
  }

  void _confirmPressed() {
    String p = r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';

    var name = _nameController.text.trim();
    var email = _emailController.text.trim();
    var pass = _passController.text;
    var confirmPass = _confirmPassController.text;

    RegExp exp = new RegExp(p);
    if(!exp.hasMatch(email)) {
      setState(() => errorMessage = 'Email address is invalid');
      return;
    }
    if(pass.length < 6) {
      setState(() => errorMessage = 'Password is too short');
      return;
    }
    if(signUp) {
      if (confirmPass != pass) {
        setState(() => errorMessage = 'Passwords do not match');
        return;
      }
    }

    _nameController.clear();
    _emailController.clear();
    _passController.clear();
    _confirmPassController.clear();

    Navigator.of(context).push(
        new FadeAnimationRoute(builder: (context) => LoadingScreen(
          SignInMethod.email,
          email: email,
          password: pass,
          signUp: signUp,
          name: name,
        ))
    ).then((onValue) {
      print(onValue);
      if(onValue == true) {
        Navigator.of(context).pop();
        Navigator.of(context).push(
            new FadeAnimationRoute(builder: (context) => ProfilePage())
        );
      }
    });
  }
}

class LoadingScreen extends StatelessWidget {

  final String name, email, password;
  final bool signUp;
  final SignInMethod method;
  LoadingScreen(this.method, {
    this.signUp = false,
    this.name,
    this.email,
    this.password,
  });

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Center(
        child: new FutureBuilder<FirebaseUser>(
          future: auth.signInMethod(method, email: email, password: password, signUp: signUp, name: name),
          builder: (BuildContext context, AsyncSnapshot<FirebaseUser> snapshot) {
            switch(snapshot.connectionState) {
              case ConnectionState.waiting:
                return new CircularProgressIndicator();
              default:
                if(snapshot.hasError) {
                  return new Text('Error: ${snapshot.error}');
                } else {
                  Navigator.pop(context, true);
                  return new Container();
                }
            }
          },
        ),
      ),
    );
  }
}