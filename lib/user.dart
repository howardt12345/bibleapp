import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';

final CollectionReference firestoreRef = Firestore.instance.collection('users');
final DatabaseReference databaseRef = FirebaseDatabase.instance.reference().child('users');


class User {
  FirebaseUser firebaseUser;
  //List<dynamic> plans;

  User({
    this.firebaseUser
  }) {
/*    if(firebaseUser != null)
      init();*/
  }

/*  init() async {
    plans = (await firestoreRef.document(firebaseUser.uid).get()).data['plans'] ?? new List<dynamic>();
    print(plans);
  }

  addPlan(String key) {
    plans.add(key);
    firestoreRef.document(firebaseUser.uid).setData({
      'plans': plans,
    });
  }

  removePlan(String key) {
    plans.remove(key);
    firestoreRef.document(firebaseUser.uid).setData({
      'plans': plans,
    });
  }*/


  get uid => firebaseUser.uid ?? '';
  get displayName => firebaseUser.displayName;
  get email => firebaseUser.email;


}
