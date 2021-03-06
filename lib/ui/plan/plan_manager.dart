import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:math';

import 'package:bible/ui/plan/qr.dart';
import 'package:flutter/material.dart';

import 'package:firebase_database/firebase_database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tuple/tuple.dart';

import 'package:bible/ui/app.dart';
import 'package:bible/ui/plan_manager_page.dart';
import 'package:bible/ui/plan/plan.dart';
import 'package:bible/ui/plan/plan_days.dart';
import 'package:bible/ui/settings.dart';

class PlanManager {

  List<Plan> plans = [];

  DatabaseReference planRef, userRef, progressRef;

  PlanManager() {
    planRef = FirebaseDatabase.instance.reference().child('plans');
    userRef = FirebaseDatabase.instance.reference().child('users');
    progressRef = FirebaseDatabase.instance.reference().child('progress');
  }

  Widget getPlans() {
    return user == null ? FutureBuilder(
      future: getPlansFromFile(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if(snapshot.data == null) {
          return Container();
        } else {
          return planWidget(context);
        }
      },
    ) : FutureBuilder(
        future: FirebaseDatabase.instance.reference().child('users').child(user.uid).once(),
        builder: (BuildContext context, AsyncSnapshot<DataSnapshot> snapshot) {
          switch(snapshot.connectionState) {
            case ConnectionState.waiting:
              return Center(
                child: CircularProgressIndicator(),
              );
            default:
              if(!snapshot.hasData || snapshot.data.value == null)
                return Container();

              List planIds = snapshot.data.value.keys.toList();
              plans = [];

              return FutureBuilder(
                future: /*Future.wait(planIds.map((id) async => await planRef.child(id).once().then((onValue) async {
                  print('${onValue.key}, ${onValue.value}');

                  var progress = (await progressRef.child(onValue.key).child(user.uid).once()).value;

                  Plan plan = Plan.fromJson(onValue.key, onValue.value, progress);
                  await getProgress(plan);
                  plans.add(plan);
                })))*/Future.forEach(planIds, (id) async => await planRef.child(id).once().then((onValue) async {
                  print('${onValue.key}, ${onValue.value}');

                  var progress = (await progressRef.child(onValue.key).child(user.uid).once()).value;

                  Plan plan = Plan.fromJson(onValue.key, onValue.value, progress);
                  await getProgress(plan);
                  plans.add(plan);
                })),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  switch(snapshot.connectionState) {
                    case ConnectionState.waiting:
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    default:
                      return planWidget(context);
                  }
                },
              );
          }
        }
    );
  }

  Widget planWidget(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      child: plans != null && plans.isNotEmpty ? Column(
        children: plans.map(
                (plan) => Card(
              elevation: 1.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    onTap: () {
                      Navigator.of(context).push(
                          FadeAnimationRoute(builder: (context) => PlanInfoPage(plan: plan))
                      );
                    },
                    title: RichText(
                      text: TextSpan(
                        text: plan.name,
                        style: Theme.of(context).textTheme.body1.copyWith(
                          fontSize: fontSize,
                        ),
                      ),
                    ),
                    subtitle: plan.description.isEmpty ? null : RichText(
                      text: TextSpan(
                        text: plan.description,
                        style: Theme.of(context).textTheme.body1.copyWith(
                          fontSize: fontSize*0.8,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      plan.days.isNotEmpty
                          ? plan.startingDate != null && DateTime.now().difference(plan.startingDate).inDays < plan.days.length
                          ? FlatButton(
                          child: Text('DAY ${DateTime.now().difference(plan.startingDate).inDays+1} OF ${plan.days.length}'),
                          onPressed: () {
                            Navigator.of(context).push(
                                FadeAnimationRoute(
                                    builder: (context) => PlanDaysPage(
                                        plan: plan,
                                        index: DateTime.now().difference(plan.startingDate).inDays
                                    )
                                )
                            );
                          }
                      ) : FlatButton(
                        child: Text('START'),
                        onPressed: () {
                          plan.startPlan();
                          Navigator.of(context).push(
                              FadeAnimationRoute(builder: (context) => PlanDaysPage(plan: plan, index: 0))
                          );
                        },
                      ) : Container(),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            plan.canEdit ? IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                Navigator.of(context).push(
                                    FadeAnimationRoute(builder: (context) => PlanEditPage(plan: plan))
                                );
                              },
                            ) : Container(),
                            user != null ? IconButton(
                              icon: Icon(Icons.share),
                              onPressed: () {
                                sharePlan(plan, context);
                              },
                            ) : Container(),
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            )
        ).toList(),
      ) : Container(
      ),
    );
  }

  addPlan(Plan plan) {
    if(user != null) {
      var key = plan.key == null ? planRef.push().key : plan.key;

      userRef.child('${user.uid}/$key').set(true);

      var value = plan.toJson();
      value['users'] = Map();
      value['users'][user.uid] = true;
      value['e'] = Map();
      value['e'][user.uid] = true;

      planRef.child(key).set(value);
      logEvent('add_plan', {'key': key, 'user': user.uid});
    } else {
      plans.add(plan);
      logEvent('add_plan', {'key': plan.key, 'user': ipAddress});
      writePlansToFile();
    }
  }

  addPlanFromKey(String key, {bool edit = false}) async {
    if(user != null) {
      var value = (await planRef.child(key).once()).value;
      if(value != null) {
        if(value['users'] == null)
          value['users'] = Map();
        value['users'][user.uid] = true;
        if(edit) {
          if(value['e'] == null)
            value['e'] = Map();
          value['e'][user.uid] = true;
        }

        userRef.child('${user.uid}/$key').set(true);

        planRef.child(key).set(value);
        logEvent('add_plan_from_key', {'key': key, 'user': user.uid});
      }
    } else {

    }
  }

  editPlan(Plan plan) async {
    if(user != null) {
      var value = (await planRef.child(plan.key).once()).value;

      var planValue = plan.toJson();
      planValue['users'] = value['users'];
      planValue['e'] = value['e'];

      planRef.child(plan.key).set(planValue);
      logEvent('edit_plan', {'key': plan.key, 'user': user.uid});
    } else {
      logEvent('edit_plan', {'key': plan.key, 'user': ipAddress});
      writePlansToFile();
    }
  }

  removePlan(Plan plan) async {
    if(user != null) {
      userRef.child('${user.uid}/${plan.key}').remove();
      progressRef.child(plan.key).remove();

      var value = (await planRef.child(plan.key).once()).value;
      value['users'].remove(user.uid);
      value['e'].remove(user.uid);

      if(value['users'].isEmpty && value['e'].isEmpty) {
        planRef.child(plan.key).remove();
      } else {
        planRef.child(plan.key).set(value);
      }
      logEvent('remove_plan', {'key': plan.key, 'user': user.uid});
    } else {
      plans.remove(plans.singleWhere((e) => e.key.compareTo(plan.key) == 0));
      logEvent('remove_plan', {'key': plan.key, 'user': ipAddress});
      await writePlansToFile();
    }
  }

  syncPlansFromFile() async {
    final file = await getFile('plans.json');
    if(file == null) {
      file.create();
    }
    String contents = await file.readAsString();

    var tmpPlans = json.decode(contents)['plans'];

    tmpPlans.forEach((plan) => addPlan(Plan.fromJson(plan.keys.toList()[0], plan[plan.keys.toList()[0]], json.decode(contents)['progress'])));
  }


  deletePlansFromFile() async {
    final file = await getFile('plans.json');

    await file.delete();
    await file.create();

    print('wiped plans');
  }

  getProgress(Plan plan, {List json}) async {
    if(user != null) {
      var value = (await progressRef.child(plan.key).child(user.uid).once()).value;

      print(value);

      for(int i = 0; i < plan.days.length; i++) {
        for(int j = 0; j < plan.days[i].passages.length; j++) {
          try {
            plan.days[i].passages[j].setCompleted(value[i][j] != null ? value[i][j] : false);
            print(plan.days[i].passages[j].completed);
          } catch(e) {}
        }
      }
      return null;
    } else {

    }
  }

  updateProgress(String key, int day, int passage) {
    if(user != null && day != null && passage != null) {
      progressRef.child(key).child(user.uid).child('$day').child('$passage').set(true);
      logEvent('update_progress', {'key': key, 'user': user.uid, 'day': day, 'passage': passage});
    } else {
      writePlansToFile();
    }
  }
  
  sharePlan(Plan plan, BuildContext context) {
    return showDialog<Tuple2>(
      context: context,
      builder: (BuildContext context) => SharePlanDialog(),
    ).then<void>((Tuple2 value) async {
      switch(value.item1) {
        case 1:
          print('Share as a link.');
          break;
        case 2:
          showDialog(
            context: context,
            builder: (BuildContext context) => QRDialog('${plan.key}=${value.item2 ? '1' : '0'}')
          );
          break;
        default:
          break;
      }
    });
  }

  Future<int> getPlansFromFile() async {
    try {
      final file = await getFile('plans.json');
      if(file == null) {
        file.create();
      }
      String contents = await file.readAsString();

      if(contents.isNotEmpty) {
        var tmpPlans = json.decode(contents)['plans'];

        print('plans: $contents');

        plans.clear();
        tmpPlans.forEach((plan) => plans.add(Plan.fromJson(plan.keys.toList()[0], plan[plan.keys.toList()[0]], json.decode(contents)['progress'])));

/*        var tmpProgress = json.decode(contents)['progress'];

        for(int i = 0; i < plans.length; i++) {
          for(int j = 0; j < plans[i].days.length; j++) {
            for(int k = 0; k < plans[i].days[j].passages.length; k++) {
              try {
                plans[i].days[j].passages[k].completed = tmpProgress[plans[i].key][j][k] != null ? tmpProgress[plans[i].key][j][k] : false;
              } catch(e) {}
            }
          }
        }*/
      }
      return 0;
    } catch(e) {
      print(e);
      return null;
    }
  }

  writePlansToFile() async {
    final file = await getFile('plans.json');

    for(int i = 0; i < plans.length; i++) {
      plans[i].key = plans[i].key == null || plans[i].key.isEmpty ? '-${randomString(19)}-' : plans[i].key;
    }

    file.writeAsString({
      '"plans"': plans.map((plan) => {'"${plan.key}"': plan.toJson(file: true)}).toList(),
      '"progress"': plans.map((plan) => {'"${plan.key}"': plan.days.map((day) => day.passages.map((passage) => passage.completed).toList()).toList().asMap()}).toList()
    }.toString());
  }

  Future<File> getFile(String file) async {
    final path = await localPath;
    return File('$path/$file');
  }
  Future<String> get localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

}


String randomString(int length) {
  const chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

  Random rnd = Random(DateTime.now().millisecondsSinceEpoch);
  String result = "";
  for (var i = 0; i < length; i++) {
    result += chars[rnd.nextInt(chars.length)];
  }
  return result;
}

class SharePlanDialog extends StatefulWidget {

  @override
  _SharePlanDialogState createState() => _SharePlanDialogState();
}
class _SharePlanDialogState extends State<SharePlanDialog> {
  bool edit = false;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text(remoteConfig.getString('plan_edit_add')),
      children: <Widget>[
        ListTile(
          title: RichText(
            text: TextSpan(
              text: 'Allow editing: ',
              style: Theme.of(context).textTheme.body1.copyWith(
                fontSize: fontSize,
              ),
            ),
          ),
          trailing: Switch(
            value: edit,
            onChanged: (value) => setState(() => edit = value),
          ),
        ),
        ListTile(
          //onTap: () => Navigator.pop(context, 1),
          leading: Icon(Icons.share),
          title: RichText(
            text: TextSpan(
              text: 'Share as a link (not supported)',
              style: Theme.of(context).textTheme.body1.copyWith(
                fontSize: fontSize,
              ),
            ),
          ),
        ),
        ListTile(
          onTap: () => Navigator.pop(context, Tuple2(2, edit)),
          leading: Icon(Icons.add_photo_alternate),
          title: RichText(
            text: TextSpan(
              text: 'Share as QR Code',
              style: Theme.of(context).textTheme.body1.copyWith(
                fontSize: fontSize,
              ),
            ),
          ),
        ),
      ],
    );
  }
}