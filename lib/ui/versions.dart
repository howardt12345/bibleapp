import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bible/ui/app.dart';
import 'package:bible/ui/page_manager.dart';
import 'package:bible/ui/settings.dart';

const String defaultVersionPrefs = 'defaultVersion';
String defaultVersion = '';
bool versionChanged = false;

VersionsManager versionsManager = new VersionsManager();
final _changeNotifier = new StreamController.broadcast();

class VersionsPage extends StatefulWidget {
  static _VersionsPageState of(BuildContext context) => context.ancestorStateOfType(TypeMatcher<_VersionsPageState>());

  @override
  _VersionsPageState createState() => new _VersionsPageState();
}
class _VersionsPageState extends State<VersionsPage> {
  List<Widget> _searchResult = [];

  TextEditingController textEditingController = new TextEditingController();
  ScrollController scrollController = new ScrollController();

  bool _loadingInProgress = false;

  @override
  void initState() {
    super.initState();
    _loadingInProgress = true;
    initialize();
  }
  initialize() async {
    await versionsManager.initialize(getString('bible_download')).then((void v) {
      setState(() => _loadingInProgress = false);
      print('Done initializing VersionManager');
    });
  }

  Future<void> fetchConfig() async {
    await remoteConfig.fetchConfig();
  }

  String getString(String key) => remoteConfig.getString(key);

  @override
  Widget build(BuildContext context) {
    fetchConfig();
    return new WillPopScope(
      onWillPop: () { Navigator.pop(context); },
      child: new Scaffold(
/*        appBar: new AppBar(
          leading: appBarAtTop ? new IconButton(
            icon: new Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ) : new Icon(Icons.search),
          title: new TextField(
            controller: textEditingController,
            decoration: new InputDecoration(
                hintText: getString('search_versions'),
                border: InputBorder.none
            ),
            onChanged: onSearchTextChanged,
          ),
          actions: <Widget>[
            new IconButton(
              icon: new Icon(Icons.cancel),
              onPressed: () {
                textEditingController.clear();
                onSearchTextChanged('');
              },
            ),
          ],
        ),*/
        body: new SafeArea(
          child: new Stack(
            children: <Widget>[
              _loadingInProgress/* || versionsManager.versions == null*/ ? new Center(
                child: new CircularProgressIndicator(),
              ) : RefreshIndicator(
                onRefresh: checkDownloaded,
                child: new CustomScrollView(
                  controller: scrollController,
                  slivers: <Widget>[
                    new SliverAppBar(
                      leading: appBarAtTop ? new IconButton(
                        icon: new Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ) : new Container(),
                      pinned: true,
                      flexibleSpace: new FlexibleSpaceBar(
                        centerTitle: true,
                        title: new ListTile(
                          leading: appBarAtTop ? new Container(width: 40.0) : new Icon(Icons.search),
                          title: new TextField(
                            controller: textEditingController,
                            decoration: new InputDecoration(
                                hintText: getString('search_versions'),
                                border: InputBorder.none
                            ),
                            onChanged: onSearchTextChanged,
                          ),
                          trailing: new IconButton(
                            icon: new Icon(Icons.cancel),
                            onPressed: () {
                              textEditingController.clear();
                              onSearchTextChanged('');
                            },
                          ),
                        ),
                      ),
                    ),
                    versionsManager.versions == null ? new SliverFixedExtentList(
                        itemExtent: MediaQuery.of(context).size.height,
                        delegate: new SliverChildListDelegate(
                            <Widget>[
                              new IconButton(
                                icon: new Icon(Icons.refresh),
                                onPressed: checkDownloaded,
                              ),
                            ]
                        )
                    ) : new SliverList(
                      delegate: new SliverChildListDelegate(
                          _searchResult.length != 0 || textEditingController.text.isNotEmpty
                              ? _searchResult
                              : versionsManager.generate(
                              context,
                              this,
                              languageCode: Platform.localeName.toLowerCase().contains('zh')
                                  ? Platform.localeName.replaceAll('_', '-')
                                  : Platform.localeName.split('_')[0],
                              headings: true
                          )
                      )
                    ),
                    new SliverPadding(
                      padding: EdgeInsets.all(28.0),
                    ),
                  ],
                ),
/*                child: new ListView(
                  controller: scrollController,
                  children: _searchResult.length != 0 || textEditingController.text.isNotEmpty
                      ? _searchResult
                      : versionsManager.generate(
                      context,
                      this,
                      languageCode: Platform.localeName.toLowerCase().contains('zh')
                          ? Platform.localeName.replaceAll('_', '-')
                          : Platform.localeName.split('_')[0],
                      headings: true
                  ),
                ),*/
              ),
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
              appBarAtTop ? _loadingInProgress ? new Align(
                alignment: Alignment.topLeft,
                child: new Container(
                  height: 56.0,
                  width: 56.0,
                  child: new IconButton(
                    icon: new Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ) : new Container() : new Align(
                alignment: Alignment.bottomLeft,
                child: new Container(
                  height: 56.0,
                  width: 56.0,
                  child: new IconButton(
                    icon: new Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              new Align(
                alignment: Alignment.bottomCenter,
                child: new Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    new IconButton(
                      icon: new Icon(Icons.keyboard_arrow_up),
                      onPressed: () => scrollController.animateTo(
                        0.0,
                        curve: Curves.decelerate,
                        duration: Duration(milliseconds: (scrollController.offset/10).floor()),
                      ),
                    ),
                    new IconButton(
                      icon: new Icon(Icons.keyboard_arrow_down),
                      onPressed: () {
                        scrollController.animateTo(
                          scrollController.position.maxScrollExtent,
                          curve: Curves.decelerate,
                          duration: Duration(milliseconds: ((scrollController.position.maxScrollExtent-scrollController.offset)/10).floor()),
                        );
                      },
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<Null> checkDownloaded() async {
    await versionsManager.checkDownloaded();
    _changeNotifier.sink.add(null);
    setState(() {});
    return null;
  }
  refresh() => setState(() {});

  onSearchTextChanged(String text) {
    _searchResult.clear();
    if (text.isEmpty) {
      setState(() {});
      return;
    }
    setState(() => _searchResult = versionsManager.search(context, this, text));
  }
}

Future<File> getFile(String file) async {
  final path = await localPath;
  return File('$path/$file');
}
Future<String> get localPath async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}
Future<bool> isDownloaded(String file) async {
  File f = await getFile(file);
  return f.exists();
}


enum DialogAction{
  cancel,
  confirm,
}

// ignore: must_be_immutable
class Version extends StatefulWidget {

  final String code, lang, name, url;
  bool downloaded = false;

  final Stream shouldTriggerChange;

  Version({
    this.code,
    this.lang,
    this.name,
    this.url,
    this.shouldTriggerChange,
  });

  factory Version.fromJson(Map<String, dynamic> json, String url, Stream shouldTriggerChange) {
    return new Version(
      code: json['code'],
      lang: json['lang'],
      name: json['name'],
      url: url,
      shouldTriggerChange: shouldTriggerChange,
    );
  }

  @override
  _VersionState createState() => new _VersionState();
}
class _VersionState extends State<Version> with AutomaticKeepAliveClientMixin {
  CancelToken token = new CancelToken();

  bool downloading = false;
  bool keepAlive = false;

  double progress = 0.0;

  StreamSubscription streamSubscription;

  @override
  initState() {
    super.initState();
    streamSubscription = widget.shouldTriggerChange.listen((_) => setState(() {}));
  }

  @override
  bool get wantKeepAlive => keepAlive;

  @override
  didUpdateWidget(Version old) {
    super.didUpdateWidget(old);
    // in case the steam instance changed, subscribe to the new one
    if (widget.shouldTriggerChange != old.shouldTriggerChange) {
      streamSubscription.cancel();
      streamSubscription = widget.shouldTriggerChange.listen((_) => setState(() {}));
    }
  }

  @override
  dispose() {
    super.dispose();
    streamSubscription.cancel();
  }


  @override
  Widget build(BuildContext context) {
    return new ListTile(
      title: new RichText(
        text: new TextSpan(
          text: '${widget.code.toUpperCase()}',
          style: Theme.of(context).textTheme.body1.copyWith(
              fontSize: fontSize,
              color: widget.code.compareTo(defaultVersion) == 0 ? Theme.of(context).accentColor : Theme.of(context).textTheme.body1.color
          ),
        ),
      ),
      subtitle: downloading
          ? new LinearProgressIndicator(value: progress == 0 ? null : progress)
          : new RichText(
        text: new TextSpan(
          text: widget.name,
          style: Theme.of(context).textTheme.body1.copyWith(
              fontSize: fontSize*2/3,
              fontWeight: FontWeight.w300,
              color: widget.code.compareTo(defaultVersion) == 0 ? Theme.of(context).accentColor : Theme.of(context).textTheme.body1.color
          ),
        ),
      ),
      onTap: () {
        print('${widget.name} (${widget.code.toUpperCase()})');
        if(widget.downloaded) {
          if(defaultVersion.compareTo(widget.code) != 0)
            setDefaultVersion(widget.code);
        } else {
          showDialog<DialogAction>(
              context: context,
              builder: (BuildContext context) => _confirmDownload(context)
          ).then<void>((DialogAction value) {
            switch(value) {
              case DialogAction.confirm:
                print('Download confirmed.');
                _downloadVersion(widget.url, 'bibledata-${widget.lang}-${widget.code}.zip');
                break;
              case DialogAction.cancel:
                print('Download cancelled.');
                break;
            }
          });
        }
      },
      trailing: new Container(
        height: 56.0,
        width: 56.0,
        child: widget.downloaded ? new IconButton(
          icon: new Icon(Icons.delete),
          onPressed: () => showDialog<DialogAction>(
              context: context,
              builder: (BuildContext context) => _confirmDelete(context)
          ).then<void>((DialogAction value) {
            switch(value) {
              case DialogAction.confirm:
                print('Delete confirmed.');
                logEvent('delete_version', {'version': '${widget.code} (${widget.name})'});
                _deleteFile('${widget.code}.sqlite3');
                break;
              case DialogAction.cancel:
                print('Delete cancelled.');
                break;
            }
          }),
        ) : downloading ? new IconButton(
          icon: new Icon(Icons.cancel),
          onPressed: () {
            token.cancel('Cancelled');
            logEvent('download_cancelled', {'version': '${widget.code} (${widget.name})'});
            setState(() {
              downloading = false;
              progress = 0.0;
              token = new CancelToken();
            });
            VersionsPage.of(context).checkDownloaded();
          },
        ) : new IconButton(
          icon: new Icon(Icons.file_download),
          onPressed: () => showDialog<DialogAction>(
              context: context,
              builder: (BuildContext context) => _confirmDownload(context)
          ).then<void>((DialogAction value) {
            switch(value) {
              case DialogAction.confirm:
                print('Download confirmed.');
                logEvent('download_version', {'version': '${widget.code} (${widget.name})'});
                _downloadVersion(widget.url, 'bibledata-${widget.lang}-${widget.code}.zip');
                break;
              case DialogAction.cancel:
                print('Download cancelled.');
                break;
            }
          }),
        ),
      ),
    );
  }

  setDefaultVersion(String version) async {
    showDialog<DialogAction>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => new AlertDialog(
          title: new Text('${version.isNotEmpty
              ? 'Setting'
              : 'Removing'}'
              ' ${widget.name} (${widget.code.toUpperCase()})'
              ' as the default version.'),
          content: new LinearProgressIndicator(),
        )
    ).then<void>((DialogAction value) {
    });
    defaultVersion = version;
    setState(() {
      versionChanged = true;
    });
    saveDefaultVersion(version).then((n) async {
      await VersionsPage.of(context).checkDownloaded().then((void v) {
        Navigator.pop(context);
      });
    });
  }
  Future<Null> saveDefaultVersion(String version) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(defaultVersionPrefs, version);
    await bible.setDefaultVersion();
  }

  Future<Null> _downloadFile(String url, String filename) async {

    String dir = await localPath;
    Dio dio = new Dio();

    setState(() => downloading = true);
    keepAlive = true;
    updateKeepAlive();
    try {
      await dio.download(
        "$url/$filename",
        '$dir/$filename',
        cancelToken: token,
        onProgress: (received, total) {
          setState(() => progress = received/total);
          print(progress);
        },
      );
      print('Downloaded $url/$filename to $dir/$filename');
    } catch (e) {
      print(e);
      if (CancelToken.isCancel(e)) {
        print('Download cancelled.');
      } else {
        print('Cannot download $filename from $url');
        showDialog<DialogAction>(
            context: context,
            builder: (BuildContext context) => _cannotDownload(context)
        ).then<void>((DialogAction value) {
          switch (value) {
            case DialogAction.confirm:
              print('Download retried.');
              _downloadVersion(url, filename);
              break;
            case DialogAction.cancel:
              print('Download cancelled.');
              setState(() => downloading = false);
              break;
          }
        });
      }
    }
  }
  Future<Null> _downloadVersion(String url, String filename) async {
    await _downloadFile(url, filename).then((void v) async {
      try {
        final file = await getFile(filename);
        String dir = await localPath;
        List<int> bytes = file.readAsBytesSync();
        Archive archive = new ZipDecoder().decodeBytes(bytes);
        for (ArchiveFile file in archive) {
          String filename = file.name;
          if (file.isFile) {
            List<int> data = file.content;
            new File('$dir/$filename')
              ..createSync(recursive: true)
              ..writeAsBytesSync(data);
          } else {
            new Directory('$dir/$filename')
              ..create(recursive: true);
          }
          print('Extracted $filename');
        }
        file.delete();
        print('Deleted $filename');
        setState(() {
          widget.downloaded = true;
          downloading = false;
          progress = 0.0;
        });
        keepAlive = false;
        updateKeepAlive();
        if(defaultVersion.isEmpty)
          await setDefaultVersion(widget.code);
        await VersionsPage.of(context).checkDownloaded().then((void v) {
          print('Finished downloading $filename');
        });
      } catch(e) {
        /*print('Cannot download $filename from $url');
        showDialog<DialogAction>(
            context: context,
            builder: (BuildContext context) => _cannotDownload(context)
        ).then<void>((DialogAction value) {
          switch (value) {
            case DialogAction.confirm:
              print('Download retried.');
              _downloadVersion(url, filename);
              break;
            case DialogAction.cancel:
              print('Download cancelled.');
              setState(() => downloading = false);
              break;
          }
        });*/
      }
    });
  }

  Future<Null> _deleteFile(String file) async {
    _delete(file).then((void v) async {
      setState(() => widget.downloaded = false);
      if(widget.code.compareTo(defaultVersion) == 0)
        setDefaultVersion('');
      setState(() {});
      await VersionsPage.of(context).checkDownloaded().then((void v) {
        print('Finished deleting $file');
      });
    });
  }
  Future<Null> _delete(String file) async {
    File f = await getFile(file);
    await f.delete();
  }

  refresh() => setState(() {});

  AlertDialog _confirmDownload(BuildContext context) => new AlertDialog(
    title: new Text('Download ${widget.name}?'),
    content: new Text('Are you sure you want to download ${widget.name} (${widget.code.toUpperCase()})?\nDownloading may cost you data usage.'),
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
  AlertDialog _cannotDownload(BuildContext context) => new AlertDialog(
    title: new Text('Cannot download ${widget.name} (${widget.code.toUpperCase()})'),
    content: new Text('Please check your network connection and try again.'),
    actions: <Widget>[
      new FlatButton(
        child: new Text('CANCEL'),
        onPressed: () => Navigator.pop(context, DialogAction.cancel),
      ),
      new FlatButton(
        child: new Text('RETRY'),
        onPressed: () => Navigator.pop(context, DialogAction.confirm),
      ),
    ],
  );
  AlertDialog _confirmDelete(BuildContext context) => new AlertDialog(
    title: new Text('Delete ${widget.name} (${widget.code.toUpperCase()})?'),
    content: new Text('Are you sure you want to delete ${widget.name} (${widget.code.toUpperCase()})?'),
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

class VersionsManager {

  Map<String, String> languages = new Map<String, String>();
  List<Version> versions;
  String url;

  Future<Null> initialize(String url) async {
    this.url = url;
    await _downloadJson(url);
  }

  Future<Null> _downloadJson(String url) async {
    try {
      String dir = (await getApplicationDocumentsDirectory()).path;
      Dio dio = new Dio();
      await dio.download(
          "$url/versions.json",
          '$dir/versions.json',
          onProgress: (received, total) {
            print(received/total);
          }
      );
      print('Downloaded $url/versions.json to $dir/versions.json');
    } on DioError catch(e) {
      print(e);
      print('Cannot download versions.json from $url');
      await _doneLoading();
    }
    await _doneLoading();
  }
  _doneLoading() async {
    await _readJson('versions.json');
  }
  Future<Null> _readJson(String name) async {
    try {
      final file = await getFile(name);
      String contents = await file.readAsString();

      List<String> langs = json.decode(contents)['languages'].toString().replaceAll('{', '').replaceAll('}', '').split(', ');
      langs.forEach((String s) =>
      languages[s.split(':')[0]] = s.split(': ')[1]
      );

      List tmp = json.decode(contents)['versions'];
      versions = tmp.map((dynamic json) =>
          Version.fromJson(json, url, _changeNotifier.stream)
      ).toList();
    } catch(e) {
      print(e);
    }
    await checkDownloaded();
  }
  Future<Null> checkDownloaded() async {
    await Future.wait(versions.map((version) => isDownloaded('${version.code}.sqlite3').then((bool b) {
      versions[versions.indexOf(version)].downloaded = b;
      print('${version.code}.sqlite3 ${b ? 'is' : 'is not'} downloaded');
    }
    ))).then((response) => print('Checked downloaded.'));
  }
  List<Widget> generate(BuildContext context, _VersionsPageState page, {String languageCode, bool headings = false}) {
    List<Widget> tmp = new List<Widget>();

    if(headings) {
      tmp.add(new ListTile(
          title: new RichText(
            textAlign: TextAlign.center,
            text: new TextSpan(
              text: page.getString('versions_downloaded'),
              style: Theme.of(context).textTheme.body1.copyWith(
                fontSize: fontSize,
              ),
            ),
          )
      ));
    }

    versions.forEach((Version v) {
      if(v.downloaded) {
        tmp.add(v);
      }
    });
    tmp.add(new Divider());

    if(headings) {
      tmp.add(new ListTile(
          title: new RichText(
            textAlign: TextAlign.center,
            text: new TextSpan(
              text: '${versionsManager.languages[languageCode.toLowerCase()]}',
              style: Theme
                  .of(context)
                  .textTheme
                  .body1
                  .copyWith(
                fontSize: fontSize,
              ),
            ),
          )
      ));
    }
    versions.forEach((Version v) {
      if(v.lang.compareTo(languageCode.toLowerCase()) == 0/* && !tmp.contains(v)*/) {
        tmp.add(v);
      }
    });
    String tmpLang = 'aa';
    versions.forEach((Version v) {
      if(v.lang.compareTo(tmpLang) == 1 && v.lang.compareTo(languageCode.toLowerCase()) != 0/* && !tmp.contains(v)*/) {
        if(headings)
          tmp.add(new ListTile(
              title: new RichText(
                textAlign: TextAlign.center,
                text: new TextSpan(
                  text: '${versionsManager.languages[v.lang]}',
                  style: Theme.of(context).textTheme.body1.copyWith(
                    fontSize: fontSize,
                  ),
                ),
              )
          ));
        tmpLang = v.lang;
      }
      if(v.lang.compareTo(languageCode.toLowerCase()) != 0/* && !tmp.contains(v)*/)
        tmp.add(v);
    });
    return tmp;
  }
  List<Widget> search(BuildContext context, _VersionsPageState page, String text) {
    List<Widget> tmp = new List<Widget>();
    versions.forEach((version) {
      if(version.code.toLowerCase().contains(text.toLowerCase()))
        tmp.add(version);
    });
    versions.forEach((version) {
      if(version.name.toLowerCase().contains(text.toLowerCase())
          && !tmp.contains(version))
        tmp.add(version);
    });
    versions.forEach((version) {
      if(version.lang.toLowerCase().contains(text.toLowerCase())
          || versionsManager.languages[version.lang].toLowerCase().contains(text.toLowerCase())
              && !tmp.contains(version))
        tmp.add(version);
    });
    return tmp;
  }
}

String defaultVersionFormatted() {
  try {
    RegExp exp = new RegExp(r'(\d+)');
    Iterable<Match> matches = exp.allMatches(defaultVersion);
    if(matches.elementAt(0).group(0).length == 4) {
      return defaultVersion.replaceAll(matches.elementAt(0).group(0), '').toUpperCase();
    }
  } catch(e) {
    return defaultVersion.toUpperCase();
  }
  return defaultVersion.toUpperCase();
}

bool isNumeric(String s) {
  if(s == null) {
    return false;
  }
  return double.parse(s) != null;
}