import 'dart:async';
import 'dart:io';

import 'package:bible/user.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import 'package:bible/ui/app.dart' as app;
import 'package:bible/ui/plan_manager_page.dart' as plan;

final _facebookSignIn = new FacebookLogin();
final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn _googleSignIn = new GoogleSignIn();
final DatabaseReference userRef = FirebaseDatabase.instance.reference().child('users');

List<StorageUploadTask> _tasks = <StorageUploadTask>[];

enum SignInMethod {
  google,
  facebook,
  email,
}

Future<FirebaseUser> signInMethod(SignInMethod method, {
    bool signUp = false,
    String name,
    String email,
    String password,
  }) {
  switch(method) {
    case SignInMethod.email:
      return signInWithEmail(email: email, password: password, signUp: signUp, displayName: name);
    case SignInMethod.google:
      return signInWithGoogle();
    case SignInMethod.facebook:
      return signInWithFacebook();
    default:
      return null;
  }
}

Future<FirebaseUser> signInWithGoogle() async {
  // Attempt to get the currently authenticated user
  GoogleSignInAccount currentUser = _googleSignIn.currentUser;
  if (currentUser == null) {
    // Attempt to sign in without user interaction
    currentUser = await _googleSignIn.signInSilently();
  }
  if (currentUser == null) {
    // Force the user to interactively sign in
    currentUser = await _googleSignIn.signIn();
  }

  final GoogleSignInAuthentication googleSignInAuthentication = await currentUser.authentication;

  final AuthCredential credential = GoogleAuthProvider.getCredential(
    accessToken: googleSignInAuthentication.accessToken,
    idToken: googleSignInAuthentication.idToken,
  );

  final AuthResult authResult = await _auth.signInWithCredential(credential);
  final FirebaseUser user = authResult.user;

  assert(user != null);
  assert(!user.isAnonymous);

  await saveUser(user, SignInMethod.google);

  print(user);

  return user;
}
Future<Null> signOutWithGoogle() async {
  // Sign out with firebase
  await _auth.signOut();
  // Sign out with google
  await _googleSignIn.signOut();
}

Future<FirebaseUser> signInWithFacebook() async {

  final FacebookLoginResult result = await _facebookSignIn.logIn(['email']);

  final accessToken = result.accessToken.token;
  if (result.status == FacebookLoginStatus.loggedIn) {
    final facebookAuthCred = FacebookAuthProvider.getCredential(
        accessToken: accessToken);

    final AuthResult authResult = await _auth.signInWithCredential(facebookAuthCred);

    final FirebaseUser user = authResult.user;

    assert(user != null);
    assert(!user.isAnonymous);

    await saveUser(user, SignInMethod.facebook);

    print(user);

    return user;
  } else {
    return null;
  }

}
Future<Null> signOutWithFacebook() async {
  await _auth.signOut();
  await _facebookSignIn.logOut();
}

Future<FirebaseUser> signInWithEmail({
    String displayName,
    String email,
    String password,
    bool signUp = false
  }) async {

  FirebaseUser user;

  if(!signUp) {
    AuthResult result = await _auth.signInWithEmailAndPassword(email: email, password: password);
    user = result.user;
  } else {
    AuthResult result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    user = result.user;
  }

  saveUser(user, SignInMethod.email, displayName: displayName);

  return user;
}
Future<Null> signOutWithEmail() async {
  await _auth.signOut();
}

Future<Null> signOut() async {
  FirebaseUser user = await _auth.currentUser();

  try {
    await (await getFile('${user.uid}.jpg')).delete();
  } catch(e) {}

  app.user = null;

  signOutWithEmail();
  signOutWithGoogle();
  signOutWithFacebook();
}

Future<Null> saveUser(FirebaseUser user, SignInMethod method, {String displayName = ''}) async {
  await Firestore.instance.collection('users').document(user.uid).get().then((onValue) async {
    if(!onValue.exists) {
      switch(method) {
        case SignInMethod.google:
        case SignInMethod.facebook:
          await downloadProfilePic(user, method);

          File file = await getFile('${user.uid}.jpg');

          StorageReference ref = FirebaseStorage.instance
              .ref()
              .child('users')
              .child('${user.uid}.jpg');

          StorageUploadTask uploadTask = ref.putFile(file);

          _tasks.add(uploadTask);

          Firestore.instance.collection('users').document(user.uid).setData({
            'email': user.email,
            'displayName': user.displayName,
            'photoUrl': ref.getDownloadURL(),
            'signUpDate': DateTime.now().toString(),
            'signInMethod': method.toString().split('.')[1],
          });
          break;
        case SignInMethod.email:
          UserUpdateInfo userUpdateInfo = new UserUpdateInfo();
          userUpdateInfo.displayName = displayName;
          
          (await _auth.currentUser()).updateProfile(userUpdateInfo);

          Firestore.instance.collection('users').document(user.uid).setData({
            'email': user.email,
            'displayName': displayName,
            'photoUrl': null,
            'signUpDate': DateTime.now().toString(),
            'signInMethod': method.toString().split('.')[1],
          });
          break;
      }
    } else {
      bool exists = await fileExists('${user.uid}.jpg');
      if (!exists) {
        if (onValue.data['photoUrl'] == null || onValue.data['photoUrl'].isEmpty) {
          switch(method) {
            case SignInMethod.google:
            case SignInMethod.facebook:
              downloadProfilePic(user, method);
              break;
            default:
              break;
          }
        } else {
          try {
            String dir = (await getApplicationDocumentsDirectory()).path;
            Dio dio = new Dio();
            await dio.download(
                '${onValue.data['photoUrl']}',
                '$dir/${user.uid}.jpg',
                onReceiveProgress: (received, total) {
                  print(received / total);
                }
            );
          } on DioError catch (e) {
            print(e);
          }
        }
      } else {

      }
      UserUpdateInfo userUpdateInfo = new UserUpdateInfo();
      userUpdateInfo.displayName = onValue.data['displayName'];
      userUpdateInfo.photoUrl = onValue.data['photoUrl'];

      (await _auth.currentUser()).updateProfile(userUpdateInfo);

    }
    app.user = new User(firebaseUser: user);

    plan.planManager.syncPlansFromFile();
  });
}

Future<Null> downloadProfilePic(FirebaseUser user, SignInMethod method) async {
  switch(method) {
    case SignInMethod.google:
      try {
        String dir = (await getApplicationDocumentsDirectory()).path;
        Dio dio = new Dio();
        await dio.download(
            '${user.photoUrl}?sz=200',
            '$dir/${user.uid}.jpg',
            onReceiveProgress: (received, total) {
              print(received/total);
            }
        );
      } on DioError catch(e) {
        print(e);
      }
      break;
    case SignInMethod.facebook:
      try {
        String dir = (await getApplicationDocumentsDirectory()).path;
        Dio dio = new Dio();
        await dio.download(
            '${user.photoUrl}?type=large',
            '$dir/${user.uid}.jpg',
            onReceiveProgress: (received, total) {
              print(received / total);
            }
        );
      } on DioError catch (e) {
        print(e);
      }
      break;
    default:
      break;
  }
  return null;
}

Future<FileImage> getProfilePic() async {
  FirebaseUser user = await _auth.currentUser();
  if(await fileExists('${user.uid}.jpg')) {
    File image = await getFile('${user.uid}.jpg');
    return new FileImage(image);
  } else {
    return null;
  }
}

Future<Null> updateProfilePic(File newPic) async {
  FirebaseUser user = await _auth.currentUser();

  StorageReference ref = FirebaseStorage.instance
      .ref()
      .child('users')
      .child('${user.uid}.jpg');

  StorageUploadTask uploadTask = ref.putFile(newPic);

  _tasks.add(uploadTask);

  Firestore.instance.collection('users').document(user.uid).setData({
    'photoUrl': ref.getDownloadURL(),
  });
}


Future<File> getFile(String file) async {
  final path = await localPath;
  return File('$path/$file');
}
Future<String> get localPath async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}
Future<bool> fileExists(String file) async {
  File f = await getFile(file);
  return f.exists();
}