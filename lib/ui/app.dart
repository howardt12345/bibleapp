import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:math';

import 'package:bible/ui/FirebaseManager.dart';
import 'package:bible/ui/about.dart';
import 'package:bible/ui/bookmarks.dart';
import 'package:bible/ui/home.dart';
import 'package:bible/ui/plan_manager_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter/scheduler.dart' show timeDilation;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bible/bible.dart';
import 'package:bible/user.dart';
import 'package:bible/ui/page_manager.dart';
import 'package:bible/ui/settings.dart';
import 'package:bible/ui/versions.dart';

Bible bible = new Bible();
FirebaseAnalytics analytics = new FirebaseAnalytics();
FirebaseAnalyticsObserver observer = new FirebaseAnalyticsObserver(analytics: analytics);

RemoteConfigManager remoteConfig;

User user;

String firebaseMessagingToken = '';

String currentVersion = '0.4.2-a';

String ipAddress;

Future<Null> logEvent(String name, Map<String, dynamic> parameters) async {
  await analytics.logEvent(
      name: name,
      parameters: parameters
  );

  print('$name: $parameters');

  return null;
}

class App extends StatefulWidget {
  static _AppState of(BuildContext context) => context.ancestorStateOfType(TypeMatcher<_AppState>());


  @override
  _AppState createState() => new _AppState();
}

class _AppState extends State<App> {
  ThemeData themeData = themeList.first;
  FirebaseMessaging firebaseMessaging = new FirebaseMessaging();

  bool _loadingInProgress;

  @override
  void initState() {
    _loadingInProgress = true;
    super.initState();

    FirebaseAuth.instance.currentUser().then((firebaseUser) {
      if(firebaseUser != null) {
        user = new User(firebaseUser: firebaseUser);
        print(firebaseUser);
      } else {
        print('No user');
      }
    });

    _loadSettings().then((void v) {
      firebaseMessaging.configure(
        onMessage: (Map<String, dynamic> message) {
          print('on message $message');
        },
        onResume: (Map<String, dynamic> message) {
          print('on resume $message');
        },
        onLaunch: (Map<String, dynamic> message) {
          print('on launch $message');
        },
      );
      firebaseMessaging.requestNotificationPermissions(
          const IosNotificationSettings(sound: true, badge: true, alert: true));
      firebaseMessaging.getToken().then((token) async {
        var response = await http.read('https://httpbin.org/ip');
        var ip = json.decode(response)['origin'];

        setState(() => ipAddress = ip);
        
        await logEvent('ip_address', {'ip': ip});

        firebaseMessagingToken = token;
        print(token);
      });
    });
  }
  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      fontFamily = prefs.getString(fontPrefs) ?? defaultFont;
      themeData = themeList[prefs.getInt(themePrefs) ?? 0].copyWith(textTheme: themeList[prefs.getInt(themePrefs) ?? 0].textTheme.apply(fontFamily: fontFamily));
      appBarAtTop = prefs.getInt(appBarLocationPrefs) == 0;
      timeDilation = prefs.getDouble(animationSpeedPrefs) ?? 1.0;
      fontSize = prefs.getDouble(fontSizePrefs) ?? 20.0;
      fontSpacing = prefs.getDouble(fontSpacingPrefs) ?? 1.5;

      newVersion = prefs.getBool(currentVersion) ?? false;
      developerSettings = prefs.getBool('developer_settings') ?? false;
      signInPrompt = prefs.getBool('sign_in_prompt') ?? false;
      tutorialDialog = prefs.getBool(tutorialDialogPrefs) ?? false;

      showPerformanceOverlay = prefs.get('showPerformanceOverlay') ?? false;
      checkerboardOffscreenLayers = prefs.get('checkerboardOffscreenLayers') ?? false;
      checkerboardRasterCacheImages = prefs.get('checkerboardRasterCacheImages') ?? false;

      defaultVersion = prefs.getString(defaultVersionPrefs) ?? '';

    });
    await bible.setDefaultVersion();
    setState(() => _loadingInProgress = false);
    return null;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void changeTheme(ThemeData theme) => setState(() => themeData = theme);
  void changeFont(String font) => setState(() => themeData = themeData.copyWith(textTheme: themeData.textTheme.apply(fontFamily: font)));
  void refresh() => setState(() {});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new Banner(
      message: 'ALPHA',
      location: BannerLocation.topStart,
      textDirection: TextDirection.ltr,
      layoutDirection: TextDirection.ltr,
      child: new MaterialApp(
        showPerformanceOverlay: showPerformanceOverlay,
        checkerboardOffscreenLayers: checkerboardOffscreenLayers,
        checkerboardRasterCacheImages: checkerboardRasterCacheImages,
        title: 'Bible',
        theme: themeData,
        navigatorObservers: [observer],
        home: new FutureBuilder<RemoteConfig>(
          future: setupRemoteConfig(),
          builder: (BuildContext context, AsyncSnapshot<RemoteConfig> snapshot) {
            if(snapshot.hasData) {
              remoteConfig = new RemoteConfigManager(snapshot.data);
            }
            return snapshot.hasData
                ? _loadingInProgress
                ? new Scaffold(
              body: new Center(
                child: new CircularProgressIndicator(),
              ),
            ) : PageManager(
              pages: pages,
            ) : new Container();
          },
        ),
        routes: <String, WidgetBuilder> {
        },
      ),
    );
  }
}

class Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
      onWillPop: () => PageManager.of(context).toggleFade() ?? false,
      child: new Scaffold(
        body: new Align(
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
            alignment: Alignment.bottomCenter,
            child: new Row(
              children: [
                new Expanded(
                    child: new Container(
                      height: 56.0,
                      width: 56.0,
                      child: new IconButton(
                        icon: new Icon(Icons.arrow_back),
                        onPressed: () => PageManager.of(context).toggleFade(),
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
      ),
    );
  }
}

Future<RemoteConfig> setupRemoteConfig() async {
  final RemoteConfig remoteConfig = await RemoteConfig.instance;

  remoteConfig.setConfigSettings(new RemoteConfigSettings(debugMode: true));
  remoteConfig.setDefaults(<String, dynamic>{
    'menu_main': 'Read',
    'menu_bookmarks': 'Bookmarks',
    'menu_settings': 'Settings',
    'menu_about': 'About',
    'title_bookmarks': 'Bookmarks',
    'title_settings': 'Settings',
    'title_about': 'About',
    'settings_theme': 'Theme',
    'settings_theme_hint': 'Select Theme',
    'settings_animationSpeed': 'Animation Speed',
    'settings_animationSpeed_hint': 'Select Animation Speed',
    'settings_font': 'Font',
    'settings_font_hint': 'Select Font',
    'settings_fontSize': 'Font Size',
    'settings_fontSize_hint': 'Select Font Size',
    'settings_fontSize_testText': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. ',
    'settings_cancel': 'CANCEL',
    'settings_save': 'SAVE',
    'bible_download': 'https://github.com/howardt12345/bibledata/raw/master',
    'settings_manage_versions': 'MANAGE VERSIONS',
    'settings_section_lookAndFeel': 'Look and Feel',
    'settings_section_reading': 'Reading',
    'settings_appbar': 'App Bar Location',
    'settings_appbar_hint': 'Select App Bar Location',
    'versions_downloaded': 'Downloaded',
    'search_versions': 'Search Downloaded',
    'no_default_version_title': 'NO DEFAULT VERSION SELECTED',
    'no_default_version_subtitle': 'Tap on the button below to download or select a version.',
    'select_default_version': 'SELECT DEFAULT VERSION',
    'search_bible': 'Search Bible',
    'search_title': 'Search for a Passage or a Keyword.',
    'search_subtitle': 'You can search for multiple queries by separating queries by commas.',
    'search_no_match_1': 'Your search - ',
    'search_no_match_2': ' - did not match anything.',
    'search_adjust': 'Adjust your search and try again.',
    'search_results_for': 'Search results for',
    'test_title': 'Thank you for testing version',
    'menu_plan': 'Plans',
    'title_plan': 'Plans',
    'title_settings_developer': 'Developer Settings',
    'developer_warning_title': 'Use developer setting',
    'developer_warning_content': 'These settings are intended for development use only. They can cause errors and unwanted behaviour in this application.',
    'developer_active_pages': 'Active Pages',
    'developer_debugging': 'Debugging',
    'developer_showPerformanceOverlay': 'Show performance overlay',
    'developer_checkerboardOffscreenLayers': 'Highlight offscreen layers',
    'developer_checkerboardRasterCacheImages': 'Highlight raster cache images',
    'plan_add_plan': 'ADD PLAN',
    'plan_edit_add': 'Add Plan',
    'plan_edit_enter_name': 'Enter plan name',
    'plan_edit_enter_description': 'Add plan description.',
    'plan_edit_days': 'Days:',
    'plan_add_passage': 'ADD PASSAGE',
    'plan_add_day': 'ADD DAY',
    'plan_days_start': 'START',
    'plan_days_continue': 'CONTINUE',
    'plan_days_done': 'DONE',
    'plan_days_edit_add': 'Add Day',
    'plan_days_edit_edit': 'Edit Day',
    'plan_passage_edit_add': 'Add Passage',
    'plan_passage_edit_edit': 'Edit Passage',
    'plan_passage_edit_single': 'Single',
    'plan_passage_edit_range': 'Range',
    'plan_passage_edit_all': 'All',
    'plan_share': 'Share Plan',
    'plan_progress': 'Progress',
    'settings_fontSpacing': 'Font Spacing',
    'settings_fontSpacing_hint': 'Select Font Spacing',

  });

  pages = [
    Page(
      page: MainPage(),
      key: "menu_main",
      isActive: true,
    ),
    Page(
      page: new BookmarksPage(),
      key: "menu_bookmarks",
      isActive: false,
    ),
    Page(
      page: new PlanManagerPage(),
      key: "menu_plan",
      isActive: true,
    ),
    Page(
      page: SettingsPage(),
      key: "menu_settings",
      isActive: true,
    ),
    Page(
      page: new AboutPage(),
      key: "menu_about",
      isActive: false,
    ),
  ];

  SharedPreferences prefs = await SharedPreferences.getInstance();

  for(int i = 0; i < pages.length; i++) {
    pages[i].isActive = prefs.getBool(pages[i].key) ?? pages[i].isActive;
  }

  return remoteConfig;
}