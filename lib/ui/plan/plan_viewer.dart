import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:share/share.dart';
import 'package:tuple/tuple.dart';

import 'package:bible/bible.dart';
import 'package:bible/ui/app.dart';
import 'package:bible/ui/plan_manager_page.dart';
import 'package:bible/ui/settings.dart';
import 'package:bible/ui/versions.dart';


class PlanViewerPage extends StatefulWidget {
  final Day day;
  final int index, dayIndex;
  final bool edit;

  PlanViewerPage({
    this.day,
    this.index,
    this.dayIndex,
    this.edit = false,
  });

  @override
  _PlanViewerPageState createState() => new _PlanViewerPageState();
}

class _PlanViewerPageState extends State<PlanViewerPage> {
  PageController pageController;
  PageView pageView;

  int currentIndex;
  bool canAdvance = true;

  @override
  void initState() {
    super.initState();
    pageController = new PageController(initialPage: widget.index);
    currentIndex = widget.index;

    pageController.addListener(() {
      if(!widget.edit && canAdvance) {
        if(currentIndex < pageController.page.toInt()) {
          widget.day.passages[currentIndex].completed = true;
          planManager.updateProgress(widget.day.key, widget.dayIndex, currentIndex);
        }
        setState(() => currentIndex = pageController.page.toInt());
      } else {
        pageController.jumpToPage(currentIndex);
      }
    });
    pageView = PageView.builder(
      physics: new AlwaysScrollableScrollPhysics(),
      controller: pageController,
      itemCount: widget.day.passages.length,
      itemBuilder: (BuildContext context, int index) => FutureBuilder(
        future: bible.getPage(
          context,
          widget.day.passages[index].start.item1,
          widget.day.passages[index].start.item2,
          start: widget.day.passages[index].start.item3,
          end: widget.day.passages[index].end.item3,
        ),
        initialData: new Center(
          child: new CircularProgressIndicator(),
        ),
        builder: (BuildContext context, AsyncSnapshot<Widget> data) {
          return Scrollbar(
            child: CustomScrollView(
              slivers: <Widget>[
                SliverList(
                  delegate: SliverChildListDelegate([
                    new Container(
                      height: fontSize*2.5,
                      margin: EdgeInsets.only(top: appBarAtTop ? 56.0 : 0.0),
                      child: new Center(
                        child: new RichText(
                          text: new TextSpan(
                            text: '${bible.getBookHuman(widget.day.passages[index].start.item1)} ${widget.day.passages[index].start.item2+1}:'
                                '${widget.day.passages[index].start.item3+1}-'
                                '${widget.day.passages[index].end.item3 >= bible.getBook(widget.day.passages[index].start.item1).chapters[widget.day.passages[index].start.item2].length()
                                ? bible.getBook(widget.day.passages[index].start.item1).chapters[widget.day.passages[index].start.item2].length()
                                : widget.day.passages[index].end.item3+1}',
                            style: Theme.of(context).textTheme.body1.copyWith(
                              fontSize: fontSize*1.25,
                            ),
                          ),
                        ),
                      ),
                    ),
                    data.data
                  ]),
                )
              ],
            ),
          );
        },
      ),
    );
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
                  icon: new Icon(Icons.arrow_back),
                  onPressed: () { Navigator.pop(context); },
                ),
                margin: EdgeInsets.symmetric(horizontal: 4.0),
              ),
              new Expanded(
                child: new Row(
                  children: <Widget>[
/*                    new Expanded(
                      child: new Container(
                        alignment: Alignment.centerRight,
                        child: new IconButton(
                          icon: Icon(Icons.chevron_left),
                          color: Theme.of(context).textTheme.body1.color.withAlpha(80),
                          onPressed: () {
                            pageController.previousPage(duration: Duration(milliseconds: 250), curve: Curves.fastOutSlowIn);
                          },
                        ),
                      ),
                    ),*/
                    new Expanded(
                      child: Container(
                        alignment: appBarAtTop ? Alignment.topCenter : Alignment.bottomCenter,
                        margin: EdgeInsets.all(8.0),
                        child: RichText(
                          textAlign: TextAlign.center,
                          softWrap: false,
                          text: new TextSpan(
                            text: 'Day ${widget.index+1}, ${currentIndex+1}/${widget.day.passages.length}',
                            style: Theme.of(context).textTheme.body1.copyWith(
                              fontSize: fontSize*0.8,
                              color: Theme.of(context).textTheme.body1.color.withAlpha(60),
                            ),
                          ),
                        ),
                      ),
                    ),
                    /*new Expanded(
                      child: new Container(
                        alignment: Alignment.centerLeft,
                        child: new IconButton(
                          icon: Icon(Icons.chevron_right),
                          color: Theme.of(context).textTheme.body1.color.withAlpha(80),
                          onPressed: () {
                            pageController.nextPage(duration: Duration(milliseconds: 250), curve: Curves.fastOutSlowIn);
                          },
                        ),
                      ),
                    ),*/
                  ],
                ),
                flex: 20,
              ),
              new Container(
                child: new Container(
                  child: currentIndex >= (widget.day.passages.length-1) ?
                  new IconButton(
                    icon: new Icon(Icons.check),
                    onPressed: canAdvance ? () {
                      widget.day.passages.last.completed = true;
                      planManager.updateProgress(widget.day.key, widget.dayIndex, currentIndex);
                      Navigator.pop(context);
                    } : null,
                  ) : new IconButton(
                    icon: new Icon(Icons.arrow_forward),
                    onPressed: canAdvance ? () {
                      pageController.nextPage(duration: Duration(milliseconds: 250), curve: Curves.fastOutSlowIn);
                    } : null,
                  ),
                ),
                margin: EdgeInsets.symmetric(horizontal: 4.0),
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
              pageView,
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