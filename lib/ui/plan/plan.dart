import 'dart:async';

import 'package:bible/ui/plan/progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:meta/meta.dart';
import 'package:share/share.dart';
import 'package:tuple/tuple.dart';

import 'package:bible/bible.dart';
import 'package:bible/ui/app.dart';
import 'package:bible/ui/plan_manager_page.dart';
import 'package:bible/ui/plan/plan_days.dart';
import 'package:bible/ui/settings.dart';
import 'package:bible/ui/versions.dart';

class PlanInfoPage extends StatefulWidget {

  final Plan plan;
  PlanInfoPage(
    {
      this.plan
    }
  );

  @override
  _PlanInfoPageState createState() => new _PlanInfoPageState();
}
class _PlanInfoPageState extends State<PlanInfoPage> {

  Future<void> fetchConfig() async {
    await remoteConfig.fetchConfig();
  }

  String getString(String key) => remoteConfig.getString(key);

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
              new Container(
                child: new IconButton(
                  icon: new Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                margin: EdgeInsets.symmetric(horizontal: 4.0),
              ),
              new Expanded(
                child: new Container(),
              ),
              user != null ? Container(
                child: new IconButton(
                  icon: new Icon(Icons.menu),
                  onPressed: () {
                    Navigator.of(context).push(
                        new FadeAnimationRoute(builder: (context) => ProgressPage(widget.plan))
                    ).then((onValue) {
                      setState(() {
                      });
                    });
                  },
                ),
                margin: EdgeInsets.symmetric(horizontal: 4.0),
              ) : new Container(),
            ],
          ),
        ),
      ),
      preferredSize: new Size.fromHeight(56.0),
    );

    return new OrientationBuilder(
      builder: (context, orientation) => new Scaffold(
        body: new SafeArea(
          child: new Stack(
            children: <Widget>[
              new ListView(
                children: <Widget>[
                  new Container(
                    margin: EdgeInsets.only(
                      top: orientation == Orientation.portrait ? fontSize*4 : fontSize*2,
                      left: 16.0,
                      right: 16.0,
                      bottom: 8.0,
                    ),
                    child: new Container(
                      alignment: Alignment.bottomCenter,
                      child: new RichText(
                        textDirection: TextDirection.ltr,
                        text: new TextSpan(
                          text: widget.plan.name,
                          style: Theme.of(context).textTheme.body1.copyWith(
                            fontSize: fontSize*2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  new Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      widget.plan.days.isNotEmpty
                          ? widget.plan.startingDate != null && DateTime.now().difference(widget.plan.startingDate).inDays < widget.plan.days.length
                            ? new FlatButton(
                                child: new Text('DAY ${DateTime.now().difference(widget.plan.startingDate).inDays+1} OF ${widget.plan.days.length}'),
                                onPressed: () {
                                  Navigator.of(context).push(
                                      new FadeAnimationRoute(
                                          builder: (context) => PlanDaysPage(
                                            plan: widget.plan,
                                            index: DateTime.now().difference(widget.plan.startingDate).inDays
                                          )
                                      )
                                  ).then((onValue) => setState(() {}));
                                }
                            ) : new FlatButton(
                              child: new Text('START'),
                              onPressed: () {
                                widget.plan.startPlan();
                                Navigator.of(context).push(
                                    new FadeAnimationRoute(builder: (context) => PlanDaysPage(plan: widget.plan, index: 0))
                                ).then((onValue) => setState(() {}));
                              },
                      ) : new Container(),
                      new Expanded(
                        child: new Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            widget.plan.canEdit ? new IconButton(
                              icon: new Icon(Icons.edit),
                              onPressed: () => Navigator.of(context).push(
                                  new FadeAnimationRoute(builder: (context) => PlanEditPage(plan: widget.plan))
                              ).then((onValue) => setState(() {})),
                            ) : new Container(),
                            new IconButton(
                              icon: new Icon(Icons.delete),
                              onPressed: () => showDialog<DialogAction>(
                                  context: context,
                                  builder: (context) => new AlertDialog(
                                    title: new Text('Delete ${widget.plan.name}?'),
                                    content: new Text('Are you sure you want to delete ${widget.plan.name}?'
                                        '\n'),
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
                              ).then<void>((DialogAction value) {
                                switch(value) {
                                  case DialogAction.confirm:
                                    print('Delete confirmed.');
                                    planManager.removePlan(widget.plan);
                                    Navigator.pop(context);
                                break;
                                  case DialogAction.cancel:
                                    print('Delete cancelled.');
                                    break;
                                }
                              }),
                            ),
                            user != null ? new IconButton(
                              icon: new Icon(Icons.share),
                              onPressed: () => planManager.sharePlan(widget.plan, context),
                            ) : new Container(),
                          ],
                        ),
                      )
                    ],
                  ),
                  new Container(
                    margin: EdgeInsets.symmetric(
                      vertical: widget.plan.description.isNotEmpty ? 8.0 : 0.0,
                      horizontal: 16.0,
                    ),
                    child: widget.plan.description.isNotEmpty ? new RichText(
                      textDirection: TextDirection.ltr,
                      text: new TextSpan(
                        text: widget.plan.description,
                        style: Theme.of(context).textTheme.body1.copyWith(
                          fontSize: fontSize,
                        ),
                      ),
                    ) : new Container(),
                  ),
                  new Container(
                    margin: EdgeInsets.only(
                      top: 8.0,
                      left: 16.0,
                      right: 16.0,
                    ),
                    child: new RichText(
                      text: new TextSpan(
                        text: getString('plan_edit_days'),
                        style: Theme.of(context).textTheme.body1.copyWith(
                          fontSize: fontSize*1.25,
                        ),
                      ),
                    ),
                  ),
                  widget.plan.days != null ? new Container(
                    margin: EdgeInsets.only(
                      top: 8.0,
                    ),
                    child: new Column(
                      children: widget.plan.days.map(
                            (day) => new ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                          onTap: () => Navigator.of(context).push(
                              new FadeAnimationRoute(builder: (context) => PlanDaysPage(
                                plan: widget.plan,
                                index: widget.plan.days.indexOf(day),
                              ))
                          ).then((onValue) => setState(() {})),
                          trailing: day.completed()
                              ? Icon(Icons.check)
                              : widget.plan.startingDate != null && DateTime.now().difference(widget.plan.startingDate).inDays > widget.plan.days.indexOf(day)
                              ? Icon(Icons.priority_high)
                              : null,
                          title: new RichText(
                            text: new TextSpan(
                              text: 'Day ${widget.plan.days.indexOf(day)+1}',
                              style: Theme.of(context).textTheme.body1.copyWith(
                                  fontSize: fontSize,
                                  color: widget.plan.startingDate != null
                                      && new DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).difference(widget.plan.startingDate).inDays == widget.plan.days.indexOf(day)
                                      ? Theme.of(context).accentColor
                                      : Theme.of(context).textTheme.body1.color
                              ),
                            ),
                          ),
                          subtitle: new RichText(
                            text: new TextSpan(
                              text: day.toText(),
                              style: Theme.of(context).textTheme.body1.copyWith(
                                fontSize: fontSize*0.8,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                        )
                      ).toList(),
                    ),
                  ) : new Container(),
                  new Container(height: 84.0),
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
      ),
    );
  }
}

class PlanEditPage extends StatefulWidget {

  final Plan plan;
  final bool add;
  PlanEditPage(
    {
      this.plan,
      this.add = false,
    }
  );

  @override
  _PlanEditPageState createState() => new _PlanEditPageState();
}
class _PlanEditPageState extends State<PlanEditPage> {
  TextEditingController titleController,
      descriptionController;

  Plan tmpPlan;
  bool schedule,
       progress = true;

  @override
  void initState() {
    super.initState();
    tmpPlan = widget.plan != null && !widget.add ? new Plan.clone(widget.plan) : new Plan(canEdit: true);
    titleController = new TextEditingController(text: tmpPlan.name);
    descriptionController = new TextEditingController(text: tmpPlan.description);
    schedule = tmpPlan.startingDate != null;
  }

  Future<void> fetchConfig() async {
    await remoteConfig.fetchConfig();
  }

  String getString(String key) => remoteConfig.getString(key);

  @override
  void dispose() {
    print('dispose');
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

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
              new Container(
                child: new IconButton(
                  icon: new Icon(Icons.clear),
                  onPressed: () {
                    Navigator.pop(context, null);
                  },
                ),
                margin: EdgeInsets.symmetric(horizontal: 4.0),
              ),
              new Expanded(
                child: new IconButton(
                  icon: new Icon(Icons.refresh),
                  onPressed: () {
                    try {
                      setState(() => tmpPlan.applyEdit(
                        name: widget.plan.name,
                        description: widget.plan.description,
                        days: widget.plan.days,
                        startingDate: widget.plan.startingDate,
                      ));
                    } catch(e) {
                      setState(() => tmpPlan = new Plan(canEdit: true));
                    }
                  },
                ),
                flex: 1,
              ),
              new Expanded(
                child: new Container(),
                flex: 3,
              ),
              new Expanded(
                child: !addButtonFAB ? new IconButton(
                  icon: new Icon(Icons.add),
                  onPressed: () => Navigator.of(context).push(
                      new FadeAnimationRoute(builder: (context) => DayEditPage(add: true))
                  ).then((onValue) => setState(() {
                    if(onValue != null)
                      tmpPlan.days.add(onValue);
                  })),
                ) : new Container(),
                flex: 1,
              ),
              new Container(
                child: new IconButton(
                  icon: new Icon(Icons.check),
                  onPressed: () {
                    try {
                      widget.plan.applyEdit(
                        name: titleController.text,
                        description: descriptionController.text,
                        days: tmpPlan.days,
                        startingDate: tmpPlan.startingDate
                      );
                    } catch(e) {
                      tmpPlan.applyEdit(
                        name: titleController.text,
                        description: descriptionController.text,
                      );
                    }
                    Navigator.pop(context, tmpPlan);
                  },
                ),
                margin: EdgeInsets.symmetric(horizontal: 4.0),
              ),
            ],
          ),
        ),
    ),
      preferredSize: new Size.fromHeight(56.0),
    );

    return new OrientationBuilder(
      builder: (context, orientation) => new Scaffold(
        body: new SafeArea(
          child: new Stack(
            children: <Widget>[
              new ListView(
                children: <Widget>[
                  new Container(
                    margin: EdgeInsets.only(top: orientation == Orientation.portrait ? fontSize*2 : fontSize),
                    child: new Center(
                      child: new RichText(
                        text: new TextSpan(
                          text: widget.add ? getString('plan_edit_add') : '',
                          style: Theme.of(context).textTheme.body1.copyWith(
                            fontSize: fontSize*2,
                          ),
                        ),
                      ),
                    ),
                    color: Theme.of(context).canvasColor,
                  ),
                  new Container(
                    margin: EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                    ),
                    child: new Container(
                        alignment: Alignment.bottomCenter,
                        child: TextFormField(
                          controller: titleController,
                          style: Theme.of(context).textTheme.body1.copyWith(
                            fontSize: fontSize*2,
                          ),
                          decoration: new InputDecoration(
                              hintText: getString('plan_edit_enter_name'),
                              border: InputBorder.none
                          ),
                          maxLines: null,
                          inputFormatters: [
                            BlacklistingTextInputFormatter(RegExp("[\n]")),
                          ],
                          autovalidate: true,
                          validator: (value) {
                          },
                        )
                    ),
                  ),
                  new Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: 16.0,
                    ),
                    child: new Container(
                      child: TextFormField(
                        controller: descriptionController,
                        style: Theme.of(context).textTheme.body1.copyWith(
                          fontSize: fontSize,
                        ),
                        decoration: new InputDecoration(
                            hintText: getString('plan_edit_enter_description'),
                            border: InputBorder.none
                        ),
                        maxLines: null,
                      ),
                    ),
                  ),
                  new Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: 16.0,
                    ),
                    child: new Column(
                      children: <Widget>[
                        new Row(
                          children: [
                            new Expanded(
                              child: schedule ? new DateItem(
                                dateTime: tmpPlan.startingDate,
                                onChanged: (dateTime) => setState(() => tmpPlan.startingDate = dateTime),
                              ) : new RichText(
                                text: new TextSpan(
                                  text: 'Schedule Plan:',
                                  style: Theme.of(context).textTheme.body1.copyWith(
                                    fontSize: fontSize,
                                  ),
                                ),
                              ),
                            ),
                            new Switch(value: schedule, onChanged: (value) {
                              setState(() {
                                schedule = value;
                                if(schedule == true && tmpPlan.startingDate == null)
                                  tmpPlan.startingDate = DateTime.now();
                              });
                            })
                          ],
                        ),
                        /*new Row(
                          children: [
                            new Expanded(
                              child: new RichText(
                                text: new TextSpan(
                                  text: 'Show Progress:',
                                  style: Theme.of(context).textTheme.body1.copyWith(
                                    fontSize: fontSize,
                                  ),
                                ),
                              ),
                            ),
                            new Switch(value: progress, onChanged: (value) => setState(() => progress = value))
                          ],
                        ),*/
                      ],
                    )
                  ),
                  new Container(
                    margin: EdgeInsets.only(
                      top: 8.0,
                      left: 16.0,
                      right: 16.0,
                    ),
                    child: new RichText(
                      text: new TextSpan(
                        text: getString('plan_edit_days'),
                        style: Theme.of(context).textTheme.body1.copyWith(
                          fontSize: fontSize*1.25,
                        ),
                      ),
                    ),
                  ),
                  tmpPlan.days != null && tmpPlan.days.isNotEmpty ? new Container(
                    margin: EdgeInsets.only(
                      top: 8.0,
                    ),
                    child: new Column(
                      children: tmpPlan.days.map(
                        (day) => new ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                          onTap: () => Navigator.of(context).push(
                              new FadeAnimationRoute(builder: (context) => DayEditPage(day: day))
                          ).then((onValue) => setState(() {})),
                          trailing: IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () => showDialog<DialogAction>(
                                context: context,
                                builder: (context) => new AlertDialog(
                                  title: new Text('Delete Day ${tmpPlan.days.indexOf(day)+1}?'),
                                  content: new Text('Are you sure you want to delete Day ${tmpPlan.days.indexOf(day)+1}?'
                                      '\nThis will delete ${day.toText()} from this plan.'),
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
                            ).then<void>((DialogAction value) {
                              switch(value) {
                                case DialogAction.confirm:
                                  print('Delete confirmed.');
                                  setState(() => tmpPlan.days.remove(day));
                                  break;
                                case DialogAction.cancel:
                                  print('Delete cancelled.');
                                  break;
                              }
                            }),
                          ),
                          title: new RichText(
                            text: new TextSpan(
                              text: 'Day ${tmpPlan.days.indexOf(day)+1}',
                              style: Theme.of(context).textTheme.body1.copyWith(
                                  fontSize: fontSize,
                                  color: tmpPlan.startingDate != null
                                      && new DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).difference(tmpPlan.startingDate).inDays == tmpPlan.days.indexOf(day)
                                      ? Theme.of(context).accentColor
                                      : Theme.of(context).textTheme.body1.color
                              ),
                            ),
                          ),
                          subtitle: new RichText(
                            text: new TextSpan(
                              text: day.toText(),
                              style: Theme.of(context).textTheme.body1.copyWith(
                                fontSize: fontSize*0.8,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                        )
                      ).toList(),
                    ),
                  ) : new Container(
                  ),
                  new Container(height: 84.0),
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
          label: Text(getString('plan_add_day')),
          onPressed: () => Navigator.of(context).push(
              new FadeAnimationRoute(builder: (context) => DayEditPage(add: true))
          ).then((onValue) => setState(() {
            if(onValue != null)
              tmpPlan.days.add(onValue);
          })),
          elevation: 2.0,
        ) : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}

class DateItem extends StatelessWidget {
  DateItem({Key key, DateTime dateTime, @required this.onChanged})
      : assert(onChanged != null),
        date = dateTime == null
            ? new DateTime.now()
            : new DateTime(dateTime.year, dateTime.month, dateTime.day),
        super(key: key);

  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return new InkWell(
      onTap: (() => _showDatePicker(context)),
      child: new Padding(
          padding: new EdgeInsets.symmetric(vertical: 8.0),
          child: new RichText(
            text: new TextSpan(
              text: new intl.DateFormat('EEEE, MMMM d').format(date),
              style: Theme.of(context).textTheme.body1.copyWith(
                fontSize: fontSize,
              ),
            ),
          ),
      ),
    );
  }

  Future _showDatePicker(BuildContext context) async {
    DateTime dateTimePicked = await showDatePicker(
        context: context,
        initialDate: date,
        firstDate: date.subtract(const Duration(days: 20000)),
        lastDate: date.add(const Duration(days: 20000)));

    if (dateTimePicked != null) {
      onChanged(new DateTime(dateTimePicked.year, dateTimePicked.month,
          dateTimePicked.day));
    }
  }
}
