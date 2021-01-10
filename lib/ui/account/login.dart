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
  _LoginPageState createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {


  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  FocusNode _focusNodeName = FocusNode();
  FocusNode _focusNodeEmail = FocusNode();
  FocusNode _focusNodePass = FocusNode();
  FocusNode _focusNodeConfirmPass = FocusNode();

  ScrollController scrollController = ScrollController();

  bool signUp = false;
  String errorMessage = '';

  Future<void> fetchConfig() async {
    await remoteConfig.fetchConfig();
  }

  String getString(String key) => remoteConfig.getString(key);

  googleButton() => Container(
      height: 40.0,
      decoration: BoxDecoration(
      borderRadius: BorderRadius.all(const Radius.circular(4.0)),
      border: Border.all(color: Colors.grey.withAlpha(125))
    ),
    child: FlatButton(
      onPressed: () async {
        try {
          Navigator.of(context).push(
              FadeAnimationRoute(builder: (context) => LoadingScreen(
                SignInMethod.google,
              ))
          ).then((onValue) {
            print(onValue);
            if(onValue == true) {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                  FadeAnimationRoute(builder: (context) => ProfilePage())
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
  facebookButton() => Container(
      height: 40.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(const Radius.circular(4.0)),
        border: Border.all(color: Colors.grey.withAlpha(125))
    ),
    child: FlatButton(
      onPressed: () async {
        try {
          Navigator.of(context).push(
              FadeAnimationRoute(builder: (context) => LoadingScreen(
                SignInMethod.facebook,
              ))
          ).then((onValue) {
            print(onValue);
            if(onValue == true) {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                  FadeAnimationRoute(builder: (context) => ProfilePage())
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
      child: SafeArea(
        child: Container(
          height: 56.0,
          alignment: Alignment.center,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    Navigator.pop(context, null);
                  },
                ),
                flex: 4,
              ),
              Expanded(
                child: Container(),
                flex: 24,
              ),
            ],
          ),
        ),
      ),
      preferredSize: Size.fromHeight(56.0),
    );


    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: <Widget>[
              ListView(
                controller: scrollController,
                children: <Widget>[
                  Container(
                    height: fontSize*4,
                    margin: EdgeInsets.only(top: fontSize*4),
                    child: Center(
                      child: RichText(
                        text: TextSpan(
                          text: 'Login',
                          style: Theme.of(context).textTheme.body1.copyWith(
                            fontSize: fontSize*2,
                          ),
                        ),
                      ),
                    ),
                    color: Theme.of(context).canvasColor,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        height: 40.0,
                        child: FlatButton(
                          child: Text('LOGIN'),
                          onPressed: signUp ? () => setState(() => signUp = false) : null,
                          disabledTextColor: Theme.of(context).textTheme.body1.color,
                          textColor: Theme.of(context).textTheme.body1.color.withAlpha(125),
                        ),
                        decoration: !signUp ? BoxDecoration(
                            borderRadius: BorderRadius.all(const Radius.circular(4.0)),
                            border: Border.all(color: Colors.grey.withAlpha(125))
                        ) : null,
                      ),
                      Container(
                        height: 40.0,
                        child: FlatButton(
                          child: Text('SIGN UP'),
                          onPressed: !signUp ? () => setState(() => signUp = true) : null,
                          disabledTextColor: Theme.of(context).textTheme.body1.color,
                          textColor: Theme.of(context).textTheme.body1.color.withAlpha(125),
                        ),
                        decoration: signUp ? BoxDecoration(
                            borderRadius: BorderRadius.all(const Radius.circular(4.0)),
                            border: Border.all(color: Colors.grey.withAlpha(125))
                        ) : null,
                      ),
                    ],
                  ),
                  Container(
                    margin: EdgeInsets.all(16.0),
                    child: Column(
                      children: <Widget>[
                        Container(
                          child: signUp ? Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            margin: const EdgeInsets.only(bottom: 8.0),
                            height: 36.0,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(const Radius.circular(4.0)),
                                border: Border.all(color: Colors.grey.withAlpha(125))
                            ),
                            child: TextFormField(
                              focusNode: _focusNodeName,
                              controller: _nameController,
                              decoration: InputDecoration.collapsed(hintText: "Name"),
                              keyboardType: TextInputType.text,
                              style: Theme.of(context).textTheme.body1.copyWith(
                                fontSize: 16.0,
                              ),
                            ),
                          ) : Container(height: 0.0),
                        ),
                        Container(
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            margin: const EdgeInsets.only(bottom: 8.0),
                            height: 36.0,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(const Radius.circular(4.0)),
                                border: Border.all(color: Colors.grey.withAlpha(125))
                            ),
                            child: TextFormField(
                              focusNode: _focusNodeEmail,
                              controller: _emailController,
                              decoration: InputDecoration.collapsed(hintText: "Email"),
                              keyboardType: TextInputType.emailAddress,
                              style: Theme.of(context).textTheme.body1.copyWith(
                                fontSize: 16.0,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            margin: const EdgeInsets.only(bottom: 8.0),
                            height: 36.0,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(const Radius.circular(4.0)),
                                border: Border.all(color: Colors.grey.withAlpha(125))
                            ),
                            child: TextFormField(
                              focusNode: _focusNodePass,
                              controller: _passController,
                              decoration: InputDecoration.collapsed(hintText: "Password"),
                              obscureText: true,
                              autocorrect: false,
                              keyboardType: TextInputType.text,
                              style: Theme.of(context).textTheme.body1.copyWith(
                                fontSize: 16.0,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          child: signUp ? Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            margin: const EdgeInsets.only(bottom: 8.0),
                            height: 36.0,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(const Radius.circular(4.0)),
                                border: Border.all(color: Colors.grey.withAlpha(125))
                            ),
                            child: TextFormField(
                              focusNode: _focusNodeConfirmPass,
                              controller: _confirmPassController,
                              decoration: InputDecoration.collapsed(hintText: "Confirm Password"),
                              obscureText: true,
                              autocorrect: false,
                              keyboardType: TextInputType.text,
                              style: Theme.of(context).textTheme.body1.copyWith(
                                fontSize: 16.0,
                              ),
                            ),
                          ) : Container(height: 0.0),
                        ),
                        errorMessage.isNotEmpty ? Container(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          height: 16.0,
                          child: RichText(
                            text: TextSpan(
                              text: errorMessage,
                              style: Theme.of(context).textTheme.body1.copyWith(
                                fontSize: 14.0,
                                color: Colors.red
                              ),
                            ),
                          ),
                        ) : Container(height: 8.0),
                        Container(
                          height: 40.0,
                          child: FlatButton(
                            onPressed: _confirmPressed,
                            child: Text(signUp ? 'SIGN UP' : 'LOGIN'),
                          ),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(const Radius.circular(4.0)),
                              border: Border.all(color: Colors.grey.withAlpha(125))
                          ),
                        ),
                        Divider(height: 32.0,),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Container(
                                child: googleButton(),
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                              ),
                            ),
                            Expanded(
                              child: Container(
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

    RegExp exp = RegExp(p);
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
        FadeAnimationRoute(builder: (context) => LoadingScreen(
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
            FadeAnimationRoute(builder: (context) => ProfilePage())
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
    return Scaffold(
      body: Center(
        child: FutureBuilder<FirebaseUser>(
          future: auth.signInMethod(method, email: email, password: password, signUp: signUp, name: name),
          builder: (BuildContext context, AsyncSnapshot<FirebaseUser> snapshot) {
            switch(snapshot.connectionState) {
              case ConnectionState.waiting:
                return CircularProgressIndicator();
              default:
                if(snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  Navigator.pop(context, true);
                  return Container();
                }
            }
          },
        ),
      ),
    );
  }
}