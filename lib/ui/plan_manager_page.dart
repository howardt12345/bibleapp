import 'dart:async';
import 'dart:core';
import 'dart:io';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:bible/ui/account/profile.dart';
import 'package:bible/ui/account/sign_in_prompt.dart';
import 'package:bible/ui/plan/plan_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:firebase_database/ui/firebase_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_permissions/simple_permissions.dart';
import 'package:share/share.dart';
import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';

import 'package:bible/bible.dart';
import 'package:bible/ui/account/login.dart';
import 'package:bible/ui/app.dart';
import 'package:bible/ui/page_manager.dart';
import 'package:bible/ui/plan/plan.dart';
import 'package:bible/ui/plan/plan_days.dart';
import 'package:bible/ui/settings.dart';
import 'package:bible/ui/versions.dart';

bool addButtonFAB = true;
bool signInPrompt = false;

PlanManager planManager = new PlanManager();


class PlanManagerPage extends StatefulWidget {

  final RemoteConfig remoteConfig;

  PlanManagerPage(this.remoteConfig);

  @override
  PlanManagerPageState createState() => new PlanManagerPageState();
}
class PlanManagerPageState extends State<PlanManagerPage> {

  @override
  void initState() {
    super.initState();

    if(!signInPrompt && user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await showDialog<DialogAction>(
            context: context,
            builder: (BuildContext context) => SignInDialog()
        ).then((action) async {
          setState(() => signInPrompt = true);
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setBool('sign_in_prompt', true);
          switch(action) {
            case DialogAction.confirm:
              RemoteConfig _config = widget.remoteConfig;
              Navigator.of(context).push(
                  new FadeAnimationRoute(builder: (context) => LoginPage(_config))
              ).then((onValue) {
                setState(() {
                });
              });
              break;
            default:
              break;
          }
        });
      });
    }
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
                  icon: new Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                flex: 4,
              ),
              new Expanded(
                child: new Container(),
                flex: 16,
              ),
              new Expanded(
                child: !addButtonFAB ? new IconButton(
                  icon: new Icon(Icons.add),
                  onPressed: () {
                    print('add');
                    RemoteConfig _config = widget.remoteConfig;
                    Navigator.of(context).push(
                        new FadeAnimationRoute(builder: (context) => PlanEditPage(_config, add: true))
                    ).then((onValue) {
                      setState(() {
                        if(onValue != null)
                          print('');
                          //plans.add(onValue);
                      });
                    });
                  },
                ) : new Container(),
                flex: 4,
              ),
              new Expanded(
                child: new IconButton(
                  icon: new Icon(Icons.menu),
                  onPressed: () async {
                    print('menu');
                    RemoteConfig _config = widget.remoteConfig;
                    FirebaseUser user = await FirebaseAuth.instance.currentUser();
                    if(user != null) {
                      Navigator.of(context).push(
                          new FadeAnimationRoute(builder: (context) => ProfilePage(_config))
                      ).then((onValue) {
                        setState(() {
                        });
                      });
                    } else {
                      Navigator.of(context).push(
                          new FadeAnimationRoute(builder: (context) => LoginPage(_config))
                      ).then((onValue) {
                        setState(() {
                        });
                      });
                    }
                  },
                ),
                flex: 4,
              ),
            ],
          ),
        ),
      ),
      preferredSize: new Size.fromHeight(56.0),
    );

    return defaultVersion.isNotEmpty
        ?  new Scaffold(
      body: new SafeArea(
        child: new Stack(
          children: <Widget>[
            RefreshIndicator(
              onRefresh: () async {
                setState(() {});
                return null;
              },
              child: new ListView(
                children: <Widget>[
                  new Container(
                    height: fontSize*8,
                    margin: EdgeInsets.only(top: fontSize*4),
                    child: new Center(
                      child: new RichText(
                        text: new TextSpan(
                          text: widget.remoteConfig.getString('title_plan'),
                          style: Theme.of(context).textTheme.body1.copyWith(
                            fontSize: fontSize*2,
                          ),
                        ),
                      ),
                    ),
                    color: Theme.of(context).canvasColor,
                  ),
                  new Container(
                    child: planManager.getPlans(),
                  ),
                  new Container(height: 56.0),
                ],
              ),
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
                    child: appBar,
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
                    alignment: Alignment.bottomCenter,
                    child: appBar,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: addButtonFAB ? FloatingActionButton.extended(
        icon: Icon(Icons.add),
        label: new Text(getString('plan_add_plan')),
        onPressed: () {
          print('add');
          RemoteConfig _config = widget.remoteConfig;

          if(user != null) {
            showDialog<int>(
              context: context,
              builder: (BuildContext context) => new SimpleDialog(
                title: new Text(_config.getString('plan_edit_add')),
                children: <Widget>[
                  new ListTile(
                    onTap: () => Navigator.pop(context, 1),
                    leading: new Icon(Icons.add),
                    title: new RichText(
                      text: new TextSpan(
                        text: 'Create a New Plan',
                        style: Theme.of(context).textTheme.body1.copyWith(
                          fontSize: fontSize,
                        ),
                      ),
                    ),
                  ),
                  new ListTile(
                    onTap: () => Navigator.pop(context, 2),
                    leading: new Icon(Icons.add_a_photo),
                    title: new RichText(
                      text: new TextSpan(
                        text: 'Add from QR Code',
                        style: Theme.of(context).textTheme.body1.copyWith(
                          fontSize: fontSize,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ).then<void>((int value) async {
              switch(value) {
                case 1:
                  planEdit(_config);
                  break;
                case 2:
                  bool res = (await SimplePermissions.requestPermission(Permission.Camera)) == PermissionStatus.authorized;
                  if(res) {
                    String code = await scan();
                    if(code.length <= 22) {
                      List<String> codes = code.split('=');
                      if(codes.length <= 1) {
                        planManager.addPlanFromKey(codes.first);
                      } else {
                        planManager.addPlanFromKey(codes.first, edit: codes.last == '1');
                      }
                    } else {
                      print(code);
                    }
                    setState(() {});
                  }
                  break;
                default:
                  break;
              }
            });
          } else {
            planEdit(_config);
          }
        },
        elevation: 2.0,
        heroTag: null,
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    ) : new Scaffold(
      body: new SafeArea(
        child: new Stack(
          children: <Widget>[
            new Center(
              child: new Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  new Container(
                    padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
                    child: new Center(
                      child: new RichText(
                        textAlign: TextAlign.center,
                        text: new TextSpan(
                          text: getString('no_default_version_title'),
                          style: Theme.of(context).textTheme.body1.copyWith(
                            fontSize: fontSize*1.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                  new Container(
                    padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
                    child: new Center(
                      child: new RichText(
                        textAlign: TextAlign.center,
                        text: new TextSpan(
                          text: '${getString('no_default_version_subtitle')}',
                          style: Theme.of(context).textTheme.body1.copyWith(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    ),
                  ),
                  new FlatButton(
                    onPressed: () {
                      fetchConfig();
                      String url = getString('bible_download');
                      RemoteConfig _config = widget.remoteConfig;
                      Navigator.of(context).push(
                        new FadeAnimationRoute(builder: (context) =>
                          VersionsPage(url, _config))
                      );
                    },
                    child: new Text(
                        getString('select_default_version')
                    ),
                  ),
                  new Container(height: 56.0),
                ],
              ),
            ),
            new Align(
              alignment: Alignment.bottomCenter,
              child: new Container(
                decoration: new BoxDecoration(
                  gradient: new LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Theme.of(context).canvasColor.withAlpha(0), Theme.of(context).canvasColor
                    ],
                    tileMode: TileMode.repeated,
                  ),
                ),
                height: 56.0,
                alignment: Alignment.bottomCenter,
                child: new Row(
                  children: [
                    new Expanded(
                      child: new Container(
                        height: 56.0,
                        width: 56.0,
                        child: new IconButton(
                          icon: new Icon(Icons.arrow_back),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      flex: 2
                    ),
                    new Expanded(
                      child: new Opacity(opacity: 0.0),
                      flex: 11,
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

  planEdit(RemoteConfig config) {
    Navigator.of(context).push(
        new FadeAnimationRoute(builder: (context) => PlanEditPage(config, add: true))
    ).then((onValue) {
      setState(() {
      });
    });
  }



  Future<String> scan() async {
    try {
      String barcode = await BarcodeScanner.scan();
      return barcode;
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.CameraAccessDenied) {
        return 'The user did not grant the camera permission!';
      } else {
        return 'Unknown error: $e';
      }
    } on FormatException{
      return 'null (User returned using the "back"-button before scanning anything. Result)';
    } catch (e) {
      return 'Unknown error: $e';
    }
  }
}

class Plan {
  String name,
         description;
  bool canEdit;
  List<Day> days;
  String key;

  DateTime startingDate;

  Plan({
    this.name = '',
    this.description = '',
    this.canEdit = false,
    this.days,
    this.startingDate,
  }) {
    this.days = this.days != null ? this.days : new List<Day>();
  }

  startPlan() {
    startingDate = DateTime.now();
  }
  getDay(int day) => days[day];

  applyEdit({
    String name,
    String description,
    List<Day> days,
  }) {
    assert(canEdit == true);
    this.name = name;
    this.description = description;
    this.days = days != null ? days : this.days;

    if(key == null) {
      planManager.addPlan(this);
    } else {
      planManager.editPlan(this);
    }
  }

  Plan.clone(Plan source) :
    this.name = source.name,
    this.description = source.description,
    this.canEdit = source.canEdit,
    this.days = new List.from(source.days),
    this.startingDate = source.startingDate;

  Plan.fromJson(String key, Map<dynamic, dynamic> json, var progress) {
    this.key = key;
    name = json['n'];
    description = json['d'];
    startingDate = DateTime.tryParse(json['sd']);
    List<dynamic> jsonDays = json['days'];
    this.days = jsonDays != null ? jsonDays.map((e) => new Day.fromJson(key, e)).toList() : new List<Day>();

    this.canEdit = json['e'] != null ? json['e'].containsKey(user.uid) : true;

    setProgress(progress);
  }

  setProgress(var progress) {
    try {
      for(int i = 0; i < days.length; i++) {
        for(int j = 0; j < days[i].passages.length; j++) {
          days[i].passages[j].setCompleted(progress['$i'][j] != null ? progress['$i'][j] : false);
        }
      }
    } catch(e) {}
  }
  
  total() => days.map((day) => day.total()).toList().reduce((a, b) => a + b);

  toJson({bool file = false}) {
    return file ? {
      '"n"': '"$name"',
      '"d"': '"$description"',
      '"days"': this.days.map((day) => day.toJson(file: file)).toList(),
      '"sd"': '"${startingDate.toString()}"',
    } : {
      "n": name,
      "d": description,
      "days": this.days.map((day) => day.toJson(file: file)).toList(),
      "sd": startingDate.toString(),
    };
  }
}

class Day {
  List<PlanPassage> passages;
  String key;

  Day({
    this.passages,
  }) {
    this.passages = this.passages != null ? this.passages : new List<PlanPassage>();
  }

  toText() => passages.map(
          (passage) => passage.toText())
      .toList().join(', ');

  applyEdit({
    List<PlanPassage> passages
  }) {
    this.passages = passages != null ? passages : this.passages;
  }
  
  total() => passages.length;

  completed() => passages.every((passage) => passage.completed);
  inProgress() => passages.any((passage) => passage.completed);
  firstIncomplete() => passages.indexOf(passages.firstWhere((passage) => !passage.completed));
  
  Day.clone(Day source) : 
      this.passages = new List.from(source.passages);

  Day.fromJson(String key, Map<dynamic, dynamic> json) {
    this.key = key;
    List<dynamic> jsonPassages = json['ps'];
    passages = jsonPassages != null ? jsonPassages.map((p) => PlanPassage.fromJson(key, p)).toList() : new List<PlanPassage>();
  }

  toJson({bool file = false}) {
    return file ? {
      '"ps"': passages.map((passage) => passage.toJson(file: file)).toList()
    } : {
      'ps': passages.map((passage) => passage.toJson(file: file)).toList()
    };
  }
}

class PlanPassage extends Passage {
  bool completed;
  String key;

  PlanPassage({
    Tuple3<int, int, int> start = const Tuple3(0, 0, 0),
    Tuple3<int, int, int> end = const Tuple3(0, 0, 0),
    this.completed = false,
  }) : super(start: start, end: end);


  applyEdit({
    Tuple3<int, int, int> start,
    Tuple3<int, int, int> end,
  }) {
    this.start = start != null ? start : this.start;
    this.end = end != null ? end : this.start;
  }

  PlanPassage.clone(PlanPassage source) : super.clone(source);

  PlanPassage.fromJson(String key, Map<dynamic, dynamic> json) {
    this.key = key;
    start = new Tuple3.fromList(json['s'].split(',').map((s) => int.parse(s)).toList());
    end = new Tuple3.fromList(json['e'].split(',').map((s) => int.parse(s)).toList());
    completed = false;
  }

  setCompleted(bool completed) {
    this.completed = completed;
  }

  PlanPassage.fromSnapshot(DataSnapshot snapshot) {
    key = snapshot.key;
    start = new Tuple3.fromList(snapshot.value['s'].split(',').map((s) => int.parse(s)).toList());
    end = new Tuple3.fromList(snapshot.value['e'].split(',').map((s) => int.parse(s)).toList());
  }
  @override
  toJson({bool file = false}) {
    return file ? {
      '"s"': '"${start.toList().join(",")}"',
      '"e"': '"${end.toList().join(",")}"',
    } : {
      's': '${start.toList().join(",")}',
      'e': '${end.toList().join(",")}',
    };
  }
}

class Passage {
  String key;
  Tuple3<int, int, int> start, end;

  Passage({
    this.start = const Tuple3(0, 0, 0),
    this.end = const Tuple3(0, 0, 0)
  });

  toText() {
    PassageChecker checker = new PassageChecker(bible: bible);
    Tuple3 startCorrected = checker.correctVerse(start), endCorrected = checker.correctVerse(end);
    String firstVerse = (startCorrected.item3 == 0
        && endCorrected.item3 == bible.books[bible.books.keys.toList()[endCorrected.item1]].chapters[endCorrected.item2].length()-1)
        ? bible.chapterAsText(new Tuple2(start.item1, start.item2))
        : bible.verseAsText(start);
    String lastVerse = endCorrected.item2 == startCorrected.item2
        && (endCorrected.item3 == startCorrected.item3
            || (startCorrected.item3 == 0
                && endCorrected.item3 == bible.books[bible.books.keys.toList()[endCorrected.item1]].chapters[endCorrected.item2].length()-1))
            ? ''
            : '-${endCorrected.item1 == startCorrected.item1
            ? ''
            : bible.verseAsText(end).replaceAll(':', ' ').split(' ')[0]+' '}'
            '${endCorrected.item2 == startCorrected.item2
            ? ''
            : '${bible.verseAsText(end).replaceAll(':', ' ').split(' ')[1]}:'}'
            '${bible.verseAsText(end).replaceAll(':', ' ').split(' ').last}';
    return '$firstVerse$lastVerse';

  }
  Passage.clone(Passage source) :
    this.start = new Tuple3(source.start.item1, source.start.item2, source.start.item3),
    this.end = new Tuple3(source.end.item1, source.end.item2, source.end.item3);

  toJson() {
    return {
      '"${new Uuid().v1()}"' : {
        '"s"': "${start.toList().join(",")}",
        '"e"': "${start.toList().join(",")}",
      }
    };
  }
}