

import 'package:bible/ui/account/login.dart';
import 'package:bible/ui/versions.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';

import 'package:bible/ui/page_manager.dart';
import 'package:bible/ui/settings.dart';

class SignInDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new AlertDialog(
      title: new Text('Sign in to get the most out of this app'),
      content: new Text('You will be able to sync your plans and bookmarks to your account.'),
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
    );
  }
}
