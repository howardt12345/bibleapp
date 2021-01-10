import 'dart:async';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share/share.dart';
import 'package:tuple/tuple.dart';

import 'package:bible/bible.dart';
import 'package:bible/ui/app.dart';
import 'package:bible/ui/plan_manager_page.dart';
import 'package:bible/ui/plan/passage_edit.dart';
import 'package:bible/ui/plan/plan_viewer.dart';
import 'package:bible/ui/settings.dart';
import 'package:bible/ui/versions.dart';


const List months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

class PlanDaysPage extends StatefulWidget {
  final int index;
  final Plan plan;

  PlanDaysPage(
    {
      this.index = 0,
      this.plan,
    }
  );

  @override
  _PlanDaysPageState createState() => _PlanDaysPageState();
}
class _PlanDaysPageState extends State<PlanDaysPage> {
  PageController pageController;
  PageView pageView;

  int currentIndex;

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: widget.index);
    currentIndex = widget.index;
    pageController.addListener(() {
      setState(() => currentIndex = pageController.page.toInt());
    });
  }

  Future<void> fetchConfig() async {
    await remoteConfig.fetchConfig();
  }

  String getString(String key) => remoteConfig.getString(key);

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
              Container(
                child: IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () { Navigator.pop(context); },
                ),
                margin: EdgeInsets.symmetric(horizontal: 4.0),
              ),
              Expanded(
                child: Container(),
              ),
              Container(
                child: IconButton(
                  icon: Icon(Icons.menu),
                  onPressed: () => print('menu'),
                ),
                margin: EdgeInsets.symmetric(horizontal: 4.0),
              ),
            ],
          ),
        ),
      ),
      preferredSize: Size.fromHeight(56.0),
    );

    return OrientationBuilder(
      builder: (context, orientation) => Scaffold(
        body: SafeArea(
          child: Stack(
            children: <Widget>[
              PageView.builder(
                physics: AlwaysScrollableScrollPhysics(),
                controller: pageController,
                itemCount: widget.plan.days.length,
                itemBuilder: (BuildContext context, int index) => DayPage(
                  day: widget.plan.days[index],
                  index: index,
                  startingDate: widget.plan.startingDate,
                ),
              ),
              appBarAtTop ? Align(
                alignment: Alignment.topCenter,
                child: Stack(
                  children: <Widget>[
                    IgnorePointer(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
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
                    Align(
                      alignment: Alignment.topLeft,
                      child: appBar,
                    ),
                  ],
                ),
              ) : Align(
                alignment: Alignment.bottomCenter,
                child: Stack(
                  children: <Widget>[
                    IgnorePointer(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
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
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: appBar,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          icon: widget.plan.days[currentIndex].completed()
              ? Icon(Icons.check)
              : Icon(Icons.play_arrow),
          label: widget.plan.days[currentIndex].completed()
              ? Text(getString('plan_days_done'))
              : widget.plan.days[currentIndex].inProgress()
              ? Text(getString('plan_days_continue'))
              : Text(getString('plan_days_start')),
          onPressed: !widget.plan.days[currentIndex].completed() ? () => Navigator.of(context).push(
              FadeAnimationRoute(builder: (context) => PlanViewerPage(
                day: widget.plan.days[currentIndex],
                index: widget.plan.days[currentIndex].firstIncomplete(),
              ))
          ).then((onValue) => setState(() {})) : null,
          elevation: 2.0,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}

class DayPage extends StatefulWidget {

  final Day day;
  final int index;
  final DateTime startingDate;
  DayPage({
    this.day,
    this.index,
    this.startingDate,
  });

  @override
  _DayPageState createState() => _DayPageState();
}
class _DayPageState extends State<DayPage> {

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) => ListView(
        children: <Widget>[
          Container(
            height: orientation == Orientation.portrait ? fontSize*8 : fontSize*4,
            margin: EdgeInsets.only(
              top: orientation == Orientation.portrait ? fontSize*4 : fontSize*2,
              left: 8.0,
              right: 8.0,
            ),
            child: Center(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: widget.startingDate != null
                      ? '${months[widget.startingDate.add(Duration(days: widget.index)).month-1]} ${widget.startingDate.add(Duration(days: widget.index)).day}'
                      : '',
                  style: Theme.of(context).textTheme.body1.copyWith(
                      fontSize: fontSize,
                      color: widget.startingDate != null && DateTime.now().difference(widget.startingDate).inDays == widget.index
                          ? Theme.of(context).accentColor
                          : Theme.of(context).textTheme.body1.color
                  ),
                  children: [
                    TextSpan(
                      text: '\nDay ${widget.index+1}',
                      style: Theme.of(context).textTheme.body1.copyWith(
                        fontSize: fontSize*2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            color: Theme.of(context).canvasColor,
          ),
          Card(
            child: Column(
              children: widget.day.passages.map(
                      (passage) => ListTile(
                    onTap: () => Navigator.of(context).push(
                        FadeAnimationRoute(builder: (context) => PlanViewerPage(
                          day: widget.day,
                          dayIndex: widget.index,
                          index: widget.day.passages.indexOf(passage),
                        ))
                    ).then((onValue) => setState(() {})),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                    trailing: passage.completed ? Icon(Icons.check) : null,
                    title: RichText(
                      text: TextSpan(
                        text: '${passage.toText()}',
                        style: Theme.of(context).textTheme.body1.copyWith(
                          fontSize: fontSize,
                        ),
                      ),
                    ),
                  )
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class DayEditPage extends StatefulWidget {

  final Day day;
  final bool add;

  DayEditPage(
    {
      this.day,
      this.add = false,
    }
  );

  _DayEditPageState createState() => _DayEditPageState();

}
 class _DayEditPageState extends State<DayEditPage> {

  Day tmpDay;

  @override
  void initState() {
    super.initState();
    tmpDay = widget.day != null ? Day.clone(widget.day) : Day();
  }

  Future<void> fetchConfig() async {
    await remoteConfig.fetchConfig();
  }

  String getString(String key) => remoteConfig.getString(key);

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
              Container(
                child: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    Navigator.pop(context, null);
                  },
                ),
                margin: EdgeInsets.symmetric(horizontal: 4.0),
              ),
              Expanded(
                child: Container(),
                flex: 4,
              ),
              Expanded(
                child: !addButtonFAB ? IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () => Navigator.of(context).push(
                      FadeAnimationRoute(builder: (context) => PassageEditPage(add: true))
                  ).then((onValue) => setState(() {
                    if(onValue != null)
                      tmpDay.passages.add(onValue);
                  })),
                ) : Container(),
                flex: 1,
              ),
              Container(
                child: IconButton(
                  icon: Icon(Icons.check),
                  onPressed: () {
                    try {
                      widget.day.applyEdit(
                        passages: tmpDay.passages,
                      );
                    } catch(e) {
                    }
                    Navigator.pop(context, tmpDay);
                  },
                ),
                margin: EdgeInsets.symmetric(horizontal: 4.0),
              ),
            ],
          ),
        ),
      ),
      preferredSize: Size.fromHeight(56.0),
    );

    return OrientationBuilder(
      builder: (context, orientation) => Scaffold(
        body: SafeArea(
          child: Stack(
            children: <Widget>[
              ListView(
                children: <Widget>[
                  Container(
                    height: orientation == Orientation.portrait ? fontSize*8 : fontSize*4,
                    margin: EdgeInsets.only(
                      top: orientation == Orientation.portrait ? fontSize*4 : fontSize*2,
                      left: 8.0,
                      right: 8.0,
                    ),
                    child: Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          text: widget.add ? getString('plan_days_edit_add') : getString('plan_days_edit_edit'),
                          style: Theme.of(context).textTheme.body1.copyWith(
                            fontSize: fontSize*2,
                          ),
                        ),
                      ),
                    ),
                    color: Theme.of(context).canvasColor,
                  ),
                  tmpDay.passages != null && tmpDay.passages.isNotEmpty ? Card(
                    child: Column(
                      children: tmpDay.passages.map(
                              (passage) => GestureDetector(
                            onDoubleTap: () => Navigator.of(context).push(
                                FadeAnimationRoute(builder: (context) => PlanViewerPage(
                                  day: tmpDay,
                                  index: tmpDay.passages.indexOf(passage),
                                  edit: true,
                                ))
                            ).then((onValue) => setState(() {})),
                            child: ListTile(
                              onTap: () => Navigator.of(context).push(
                                  FadeAnimationRoute(builder: (context) => PassageEditPage(
                                    passage: passage,
                                  ))
                              ).then((onValue) => setState(() {})),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                              trailing: IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: () => showDialog<DialogAction>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Delete This Passage?'),
                                      content: Text('Are you sure you want to delete this passage?'
                                          '\nThis will delete ${passage.toText()} from this plan.'),
                                      actions: <Widget>[
                                        FlatButton(
                                          child: Text('CANCEL'),
                                          onPressed: () => Navigator.pop(context, DialogAction.cancel),
                                        ),
                                        FlatButton(
                                          child: Text('OK'),
                                          onPressed: () => Navigator.pop(context, DialogAction.confirm),
                                        ),
                                      ],
                                    )
                                ).then<void>((DialogAction value) {
                                  switch(value) {
                                    case DialogAction.confirm:
                                      print('Delete confirmed.');
                                      setState(() => tmpDay.passages.remove(passage));
                                      break;
                                    case DialogAction.cancel:
                                      print('Delete cancelled.');
                                      break;
                                  }
                                }),
                              ),
                              title: RichText(
                                text: TextSpan(
                                  text: '${passage.toText()}',
                                  style: Theme.of(context).textTheme.body1.copyWith(
                                    fontSize: fontSize,
                                  ),
                                ),
                              ),
                            ),
                          )
                      ).toList(),
                    ),
                  ) : Container(
                  ),
                  Container(height: 84.0),
                ],
              ),
              appBarAtTop ? Align(
                alignment: Alignment.topCenter,
                child: Stack(
                  children: <Widget>[
                    IgnorePointer(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
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
                    Align(
                      alignment: Alignment.topLeft,
                      child: appBar,
                    ),
                  ],
                ),
              ) : Align(
                alignment: Alignment.bottomCenter,
                child: Stack(
                  children: <Widget>[
                    IgnorePointer(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
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
                    Align(
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
          label: Text(getString('plan_add_passage')),
          onPressed: () => Navigator.of(context).push(
              FadeAnimationRoute(builder: (context) => PassageEditPage(add: true))
          ).then((onValue) => setState(() {
            if(onValue != null)
              tmpDay.passages.add(onValue);
          })),
          elevation: 2.0,
          heroTag: null,
        ) : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}
