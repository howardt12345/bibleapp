import 'dart:async';

import 'package:flutter/material.dart' hide ExpansionPanel, ExpansionPanelList, ExpansionPanelHeaderBuilder, Page;
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart' show timeDilation;

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/services.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bible/ui/app.dart';
import 'package:bible/ui/about.dart';
import 'package:bible/ui/bookmarks.dart';
import 'package:bible/ui/home.dart';
import 'package:bible/ui/page_manager.dart';
import 'package:bible/ui/plan_manager_page.dart';
import 'package:bible/ui/versions.dart';

import 'package:bible/ui/expansion_panel/expansion_panel.dart';

const String themePrefs = 'appTheme';
const String animationSpeedPrefs = 'animationSpeed';
const String appBarLocationPrefs = 'appBarLocation';
const String fontPrefs = 'font';
const String fontSizePrefs = 'fontSize';
const String fontSpacingPrefs = 'fontSpacing';


typedef Widget SettingsItemBodyBuilder<T>(SettingsItem<T> item);
typedef String ValueToString<T>(T value);

enum AppTheme {
  light,
  dark,
  low_light,
}
enum AnimationSpeed {
  very_fast,
  fast,
  normal,
  slow,
  very_slow,
}
enum AppBarLocation {
  top,
  bottom,
}
enum FontEnum {
  roboto,
  noto,
  dancing_Script,
  rosemary,
  source_Code_Pro,
}

double fontSize = 20.0;
double fontSpacing = 1.5;
String fontFamily;
String defaultFont = 'Roboto';
bool appBarAtTop = false;

bool showPerformanceOverlay = false;
bool checkerboardOffscreenLayers = false;
bool checkerboardRasterCacheImages = false;

bool crossReferences = true;
bool verseNumbers = true;

MaterialColor primarySwatch = Colors.blue;

List<ThemeData> themeList = [
  ThemeData(
    primarySwatch: primarySwatch,
    primaryColor: Colors.white,
    fontFamily: defaultFont,
    brightness: Brightness.light,
    sliderTheme: ThemeData.light().sliderTheme,
  ),
  ThemeData(
    primarySwatch: primarySwatch,
    fontFamily: defaultFont,
    brightness: Brightness.dark,
  ),
  ThemeData(
    primarySwatch: primarySwatch,
    fontFamily: defaultFont,
    brightness: Brightness.dark,
    backgroundColor: Color(0xFF000000),
    canvasColor: Color(0xFF000000),
    cardColor: Color(0xFF000000),
    sliderTheme: ThemeData.dark().sliderTheme.copyWith(
      activeTrackColor: Color(0xFFFFFFFF),
      thumbColor: Color(0xFFFFFFFF),
    ),
  ),
];

List<Page> pages = [];

String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

saveTheme(int index) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setInt(themePrefs, index);
  print("Saved ${AppTheme.values[index].toString().split('.')[1].replaceAll('_', ' ')} as theme.");
}
saveAnimationSpeed(double value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setDouble(animationSpeedPrefs, value);
  print("Saved $value as Animation Speed.");
}
saveAppBarLocation(int value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setInt(appBarLocationPrefs, value);
  print("Saved ${value == 0 ? 'top' : 'bottom'} as App Bar Location.");
}
saveFont(String font) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString(fontPrefs, font);
  print("Saved $font as Font.");
}
saveFontSize(double value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setDouble(fontSizePrefs, value);
  print("Saved $value as Font Size.");
}
saveFontSpacing(double value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setDouble(fontSpacingPrefs, value);
  print("Saved $value as Font Spacing.");
}

class SettingsPage extends StatefulWidget {
  static _SettingsPageState of(BuildContext context) => context.ancestorStateOfType(TypeMatcher<_SettingsPageState>());

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<SettingsItem<dynamic>> _lookAndFeelSettings,
                              _fontSettings;

  @override
  void initState() {
    super.initState();
    fetchConfig();

    //_capitalize(a.toString().split('.')[1].replaceAll('_', ' '));
    AnimationSpeed _getSpeed(double speed) {
      switch((speed*100).round()) {
        case 25:
          return AnimationSpeed.very_fast;
        case 50:
          return AnimationSpeed.fast;
        case 100:
          return AnimationSpeed.normal;
        case 200:
          return AnimationSpeed.slow;
        case 400:
          return AnimationSpeed.very_slow;
      }
      return null;
    }

    _lookAndFeelSettings = <SettingsItem<dynamic>>[
      SettingsItem<AppTheme>(
          name: getString('settings_theme'),
          value: AppTheme.values[themeList.indexOf(App.of(context).themeData.copyWith(textTheme: App.of(context).themeData.textTheme.apply(fontFamily: defaultFont)))],
          hint: getString('settings_theme_hint'),
          valueToString: (AppTheme a) => capitalize(a.toString().split('.')[1].replaceAll('_', ' ')),
          builder: (SettingsItem<AppTheme> item) {
            void close() {
              setState(() {
                item.isExpanded = false;
              });
            }
            return Form(
                child: Builder(
                    builder: (BuildContext context) {
                      return CollapsibleBody(
                        cancel: getString('settings_cancel'),
                        save: getString('settings_save'),
                        onSave: () { Form.of(context).save(); close(); },
                        onCancel: () { Form.of(context).reset(); close(); },
                        child: FormField<AppTheme>(
                            initialValue: AppTheme.values[themeList.indexOf(App.of(context).themeData.copyWith(textTheme: App.of(context).themeData.textTheme.apply(fontFamily: defaultFont)))],
                            onSaved: (AppTheme result) {
                              logEvent('change_setting', {'setting': getString('settings_theme'), 'value': result.toString()});
                              item.value = result;
                              setState(() => App.of(context).changeTheme(themeList[result.index].copyWith(textTheme: themeList[result.index].textTheme.apply(fontFamily: fontFamily))));
                              saveTheme(result.index);
                            },
                            builder: (FormFieldState<AppTheme> field) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: AppTheme.values.map((AppTheme a) => Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Radio<AppTheme>(
                                        value: a,
                                        groupValue: field.value,
                                        onChanged: field.didChange,
                                      ),
                                      Text(capitalize(a.toString().split('.')[1].replaceAll('_', ' ')))
                                    ]
                                )
                                ).toList(),
                              );
                            }
                        ),
                      );
                    }
                )
            );
          }
      ),
      SettingsItem<AnimationSpeed>(
          name: getString('settings_animationSpeed'),
          value: _getSpeed(timeDilation),
          hint: getString('settings_animationSpeed_hint'),
          valueToString: (AnimationSpeed a) => capitalize(a.toString().split('.')[1].replaceAll('_', ' ')),
          builder: (SettingsItem<AnimationSpeed> item) {
            void close() {
              setState(() {
                item.isExpanded = false;
              });
            }
            return Form(
                child: Builder(
                    builder: (BuildContext context) {
                      return CollapsibleBody(
                        cancel: getString('settings_cancel'),
                        save: getString('settings_save'),
                        onSave: () { Form.of(context).save(); close(); },
                        onCancel: () { Form.of(context).reset(); close(); },
                        child: FormField<AnimationSpeed>(
                            initialValue: _getSpeed(timeDilation),
                            onSaved: (AnimationSpeed result) {
                              logEvent('change_setting', {'setting': getString('settings_animationSpeed'), 'value': result.toString()});

                              item.value = result;
                              switch(result) {
                                case AnimationSpeed.very_fast:
                                  setState(() => timeDilation = 0.25);
                                  saveAnimationSpeed(0.25);
                                  break;
                                case AnimationSpeed.fast:
                                  setState(() => timeDilation = 0.5);
                                  saveAnimationSpeed(0.5);
                                  break;
                                case AnimationSpeed.normal:
                                  setState(() => timeDilation = 1.0);
                                  saveAnimationSpeed(1.0);
                                  break;
                                case AnimationSpeed.slow:
                                  setState(() => timeDilation = 2.0);
                                  saveAnimationSpeed(2.0);
                                  break;
                                case AnimationSpeed.very_slow:
                                  setState(() => timeDilation = 4.0);
                                  saveAnimationSpeed(4.0);
                                  break;
                              }
                            },
                            builder: (FormFieldState<AnimationSpeed> field) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: AnimationSpeed.values.map((AnimationSpeed a) => Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Radio<AnimationSpeed>(
                                        value: a,
                                        groupValue: field.value,
                                        onChanged: field.didChange,
                                      ),
                                      Text(capitalize(a.toString().split('.')[1].replaceAll('_', ' ')))
                                    ]
                                )
                                ).toList(),
                              );
                            }
                        ),
                      );
                    }
                )
            );
          }
      ),
      SettingsItem<AppBarLocation>(
          name: getString('settings_appbar'),
          value: appBarAtTop ? AppBarLocation.top : AppBarLocation.bottom,
          hint: getString('settings_appbar_hint'),
          valueToString: (AppBarLocation a) => capitalize(a.toString().split('.')[1].replaceAll('_', ' ')),
          builder: (SettingsItem<AppBarLocation> item) {
            void close() {
              setState(() {
                item.isExpanded = false;
              });
            }
            return Form(
                child: Builder(
                    builder: (BuildContext context) {
                      return CollapsibleBody(
                        cancel: getString('settings_cancel'),
                        save: getString('settings_save'),
                        onSave: () { Form.of(context).save(); close(); },
                        onCancel: () { Form.of(context).reset(); close(); },
                        child: FormField<AppBarLocation>(
                            initialValue: appBarAtTop ? AppBarLocation.top : AppBarLocation.bottom,
                            onSaved: (AppBarLocation result) {
                              item.value = result;
                              setState(() => appBarAtTop = result.index == 0);
                              logEvent('change_setting', {'setting': getString('settings_appbar'), 'value': result.toString()});
                              saveAppBarLocation(result.index);
                            },
                            builder: (FormFieldState<AppBarLocation> field) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: AppBarLocation.values.map((AppBarLocation a) => Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Radio<AppBarLocation>(
                                        value: a,
                                        groupValue: field.value,
                                        onChanged: field.didChange,
                                      ),
                                      Text(capitalize(a.toString().split('.')[1].replaceAll('_', ' ')))
                                    ]
                                )
                                ).toList(),
                              );
                            }
                        ),
                      );
                    }
                )
            );
          }
      ),
    ];
    _fontSettings = <SettingsItem<dynamic>>[
      SettingsItem<FontEnum>(
          name: getString('settings_font'),
          value: FontEnum.values.firstWhere((a) => capitalize(a.toString().split('.')[1].replaceAll('_', '')) == fontFamily),
          hint: getString('settings_font_hint'),
          valueToString: (FontEnum a) => capitalize(a.toString().split('.')[1].replaceAll('_', ' ')),
          builder: (SettingsItem<FontEnum> item) {
            void close() {
              setState(() {
                item.isExpanded = false;
              });
            }
            return Form(
                child: Builder(
                    builder: (BuildContext context) {
                      return CollapsibleBody(
                        cancel: getString('settings_cancel'),
                        save: getString('settings_save'),
                        onSave: () { Form.of(context).save(); close(); },
                        onCancel: () { Form.of(context).reset(); close(); },
                        child: FormField<FontEnum>(
                            initialValue: FontEnum.values.firstWhere((a) => capitalize(a.toString().split('.')[1].replaceAll('_', '')) == fontFamily),
                            onSaved: (FontEnum result) {
                              item.value = result;
                              setState(() {
                                fontFamily = capitalize(result.toString().split('.')[1].replaceAll('_', ''));
                                logEvent('change_setting', {'setting': getString('settings_font'), 'value': result.toString()});
                                App.of(context).changeFont(fontFamily);
                                saveFont(fontFamily);
                              });
                            },
                            builder: (FormFieldState<FontEnum> field) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: FontEnum.values.map((FontEnum a) => Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Radio<FontEnum>(
                                      value: a,
                                      groupValue: field.value,
                                      onChanged: field.didChange,
                                    ),
                                    Text(
                                      capitalize(a.toString().split('.')[1].replaceAll('_', ' ')),
                                      style: TextStyle(
                                          fontFamily: capitalize(a.toString().split('.')[1].replaceAll('_', ''))
                                      ),
                                    ),
                                  ],
                                ),
                                ).toList(),
                              );
                            }
                        ),
                      );
                    }
                )
            );
          }
      ),
      SettingsItem<double>(
          name: getString('settings_fontSize'),
          value: fontSize,
          hint: getString('settings_fontSize_hint'),
          valueToString: (double amount) => '${amount.round()}',
          builder: (SettingsItem<double> item) {
            void close() {
              setState(() {
                item.isExpanded = false;
              });
            }
            return Form(
              child: Builder(
                  builder: (BuildContext context) {
                    return CollapsibleBody(
                      cancel: getString('settings_cancel'),
                      save: getString('settings_save'),
                      onSave: () { Form.of(context).save(); close(); },
                      onCancel: () { Form.of(context).reset(); close(); },
                      child: FormField<double>(
                        initialValue: item.value,
                        onSaved: (double value) {
                          item.value = value;
                          setState(() => fontSize = value);
                          logEvent('change_setting', {'setting': getString('settings_fontSize'), 'value': value});
                          saveFontSize(value);
                        },
                        builder: (FormFieldState<double> field) {
                          return Column(
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Flexible(
                                    child: Slider(
                                      min: 8.0,
                                      max: 32.0,
                                      divisions: 12,
                                      label: '${field.value.round()}',
                                      value: field.value,
                                      onChanged: field.didChange,
                                    ),
                                  ),
                                  Container(
                                    child: Text(
                                      '${field.value}',
                                        style: Theme.of(context).textTheme.caption
                                    ),
                                  ),
                                ],
                              ),
                              RichText(
                                textAlign: TextAlign.left,
                                text: TextSpan(
                                  text: getString('settings_fontSize_testText'),
                                  style: Theme.of(context).textTheme.body1.copyWith(
                                    fontSize: field.value,
                                    height: fontSpacing,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  }
              ),
            );
          }
      ),
      SettingsItem<double>(
          name: getString('settings_fontSpacing'),
          value: fontSpacing,
          hint: getString('settings_fontSpacing_hint'),
          valueToString: (double amount) => '$amount',
          builder: (SettingsItem<double> item) {
            void close() {
              setState(() {
                item.isExpanded = false;
              });
            }
            return Form(
              child: Builder(
                  builder: (BuildContext context) {
                    return CollapsibleBody(
                      cancel: getString('settings_cancel'),
                      save: getString('settings_save'),
                      onSave: () { Form.of(context).save(); close(); },
                      onCancel: () { Form.of(context).reset(); close(); },
                      child: FormField<double>(
                        initialValue: item.value,
                        onSaved: (double value) {
                          item.value = value;
                          setState(() => fontSpacing = value);
                          logEvent('change_setting', {'setting': getString('settings_fontSpacing'), 'value': value});
                          saveFontSpacing(value);
                        },
                        builder: (FormFieldState<double> field) {
                          return Column(
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Flexible(
                                    child: Slider(
                                      min: 1.0,
                                      max: 2.0,
                                      divisions: 8,
                                      label: '${field.value.round()}',
                                      value: field.value,
                                      onChanged: field.didChange,
                                    ),
                                  ),
                                  Container(
                                    child: Text(
                                        '${field.value}',
                                        style: Theme.of(context).textTheme.caption
                                    ),
                                  ),
                                ],
                              ),
                              RichText(
                                textAlign: TextAlign.left,
                                text: TextSpan(
                                  text: getString('settings_fontSize_testText'),
                                  style: Theme.of(context).textTheme.body1.copyWith(
                                    fontSize: fontSize,
                                    height: field.value,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  }
              ),
            );
          }
      ),
    ];
  }

  Future<void> fetchConfig() async {
    await remoteConfig.fetchConfig();
  }

  String getString(String key) => remoteConfig.getString(key);

  @override
  Widget build(BuildContext context) {
    fetchConfig();

    return Scaffold(
      body: OrientationBuilder(
        builder: (context, orientation) => SafeArea(
            child: Stack(
              children: <Widget>[
                ListView(
                  children: <Widget>[
                    Container(height: 28.0),
                    Container(
                      height: fontSize*2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FlatButton(
                          onPressed: () {
                            Navigator.of(context).push(
                                FadeAnimationRoute(builder: (context) => VersionsPage())
                            );
                          },
                          child: Text(
                              getString('settings_manage_versions')
                          ),
                        ),
                      ),
                      color: Theme.of(context).canvasColor,
                    ),
                    Container(
                      height: orientation == Orientation.portrait ? fontSize*6 : fontSize*3,
                      margin: EdgeInsets.only(top: orientation == Orientation.portrait ? fontSize*2 : fontSize),
                      child: Center(
                        child: RichText(
                          text: TextSpan(
                              text: getString('title_settings'),
                              style: Theme.of(context).textTheme.body1.copyWith(
                                fontSize: fontSize*2,
                              ),
                              recognizer: DoubleTapGestureRecognizer()
                                ..onDoubleTap = () {
                                  Navigator.of(context).push(
                                      FadeAnimationRoute(builder: (context) => DeveloperSettingsPage())
                                  ).then((onValue) {
                                    App.of(context).refresh();
                                  });
                                }
                          ),
                        ),
                      ),
                      color: Theme.of(context).canvasColor,
                    ),
                    ListTile(
                      title: Text(getString('settings_section_lookAndFeel')),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: ExpansionPanelList(
                          animationDuration: Duration(milliseconds: duration),
                          expansionCallback: (int index, bool isExpanded) {
                            setState(() {
                              _lookAndFeelSettings[index].isExpanded = !isExpanded;
                            });
                          },
                          children: _lookAndFeelSettings.map((SettingsItem<dynamic> item) {
                            return ExpansionPanel(
                              isExpanded: item.isExpanded,
                              headerBuilder: item.headerBuilder(onTap: () => setState(() => item.isExpanded = !item.isExpanded)),
                              body: item.build(),
                            );
                          }).toList()
                      ),
                      color: Theme.of(context).canvasColor,
                    ),
                    ListTile(
                      title: Text(getString('settings_section_reading')),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: ExpansionPanelList(
                          animationDuration: Duration(milliseconds: duration),
                          expansionCallback: (int index, bool isExpanded) {
                            setState(() {
                              _fontSettings[index].isExpanded = !isExpanded;
                            });
                          },
                          children: _fontSettings.map((SettingsItem<dynamic> item) {
                            return ExpansionPanel(
                              isExpanded: item.isExpanded,
                              headerBuilder: item.headerBuilder(onTap: () => setState(() => item.isExpanded = !item.isExpanded)),
                              body: item.build(),
                            );
                          }).toList()
                      ),
                    ),
                    Container(height: 56.0),
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
                        child: Container(
                          height: 56.0,
                          width: 56.0,
                          child: IconButton(
                            icon: Icon(Icons.arrow_back),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
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
                        alignment: Alignment.bottomLeft,
                        child: Container(
                          height: 56.0,
                          width: 56.0,
                          child: IconButton(
                            icon: Icon(Icons.arrow_back),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
        ),
      ),
    );
  }
}

class SettingsItem<T> {
  SettingsItem({
    this.name,
    this.value,
    this.hint,
    this.builder,
    this.valueToString
  }) : textController = TextEditingController(text: valueToString(value));

  final String name;
  final String hint;
  final TextEditingController textController;
  final SettingsItemBodyBuilder<T> builder;
  final ValueToString<T> valueToString;
  T value;
  bool isExpanded = false;

  ExpansionPanelHeaderBuilder headerBuilder({VoidCallback onTap}) {
    return (BuildContext context, bool isExpanded) {
      return DualHeaderWithHint(
        name: name,
        value: valueToString(value),
        hint: hint,
        showHint: isExpanded,
        onTap: onTap,
      );
    };
  }

  Widget build() => builder(this);
}

class DualHeaderWithHint extends StatelessWidget {
  const DualHeaderWithHint({
    this.name,
    this.value,
    this.hint,
    this.showHint,
    this.onTap,
  });

  final String name;
  final String value;
  final String hint;
  final bool showHint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Container(
              margin: const EdgeInsets.only(left: 24.0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  name,
                  style: textTheme.body1.copyWith(fontSize: 15.0),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              margin: const EdgeInsets.only(left: 24.0),
              child: Text(value, style: textTheme.caption.copyWith(fontSize: 15.0)),
            ),
          ),
        ],
      ),
    );
  }
}

class CollapsibleBody extends StatelessWidget {
  const CollapsibleBody({
    this.margin = EdgeInsets.zero,
    this.child,
    this.onSave,
    this.onCancel,
    this.cancel,
    this.save,
  });

  final String cancel, save;

  final EdgeInsets margin;
  final Widget child;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;

    return Column(
      children: <Widget>[
        Container(
          margin: const EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            bottom: 24.0,
          ) - margin,
          child: Center(
            child: DefaultTextStyle(
              style: textTheme.caption.copyWith(fontSize: 15.0),
              child: child
            )
          )
        ),
        const Divider(height: 1.0),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Container(
                margin: const EdgeInsets.only(right: 8.0),
                child: FlatButton(
                  onPressed: onCancel,
                  child: Text(
                    cancel,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.caption.color,
                      fontSize: 15.0,
                      fontWeight: FontWeight.w500
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 8.0),
                child: FlatButton(
                  onPressed: onSave,
                  textTheme: ButtonTextTheme.accent,
                  child: Text(save)
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Route FadeAnimationRoute({WidgetBuilder builder}) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => Builder(builder: builder),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

class DeveloperSettingsPage extends StatefulWidget {

  @override
  _DeveloperSettingsPageState createState() => _DeveloperSettingsPageState();
}

class _DeveloperSettingsPageState extends State<DeveloperSettingsPage> {

  @override
  void initState() {
    super.initState();
    if(!developerSettings) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await showDialog<String>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: Text(getString('developer_warning_title')),
              content: GestureDetector(
                child: Text(getString('developer_warning_content')),
              ),
              actions: <Widget>[
                FlatButton(
                  child: Text('CLOSE'),
                  onPressed: () async {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            )
        ).then((s) async {
          setState(() => developerSettings = true);
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setBool('developer_settings', true);
        });
      });
    }
  }

  Future<void> fetchConfig() async {
    await remoteConfig.fetchConfig();
  }

  String getString(String key) => remoteConfig.getString(key);

  savePageActiveState(String key, bool value) async {
    String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(key, value);
    print('${_capitalize(key.split('_').last.trim())} set as $value');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () { Navigator.pop(context); },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: <Widget>[
              ListView(
                children: <Widget>[
                  Container(
                    height: fontSize*6,
                    margin: EdgeInsets.only(top: fontSize*4),
                    child: Center(
                      child: RichText(
                        text: TextSpan(
                          text: getString('title_settings_developer'),
                          style: Theme.of(context).textTheme.body1.copyWith(
                            fontSize: fontSize*2,
                          ),
                          recognizer: TapGestureRecognizer()..onTap = () => showDialog<String>(
                              context: context,
                              builder: (BuildContext context) => AlertDialog(
                                title: Text('Firebase Messaging Token'),
                                content: GestureDetector(
                                  child: Text('Your Firebase Messaging Token is: $firebaseMessagingToken. \nTap to copy the token.'),
                                  onTap: () => Clipboard.setData(ClipboardData(text: firebaseMessagingToken)),
                                  onDoubleTap: () => Share.share(firebaseMessagingToken),
                                ),
                                actions: <Widget>[
                                  FlatButton(
                                    child: Text('CLOSE'),
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              )
                          ),
                        ),
                      ),
                    ),
                    color: Theme.of(context).canvasColor,
                  ),
                  ListTile(
                    title: Text(getString('developer_active_pages')),
                  ),
                  Container(
                    padding: EdgeInsets.all(4.0),
                    child: Card(
                      elevation: 1.0,
                      child: Column(
                        children: pages.map((page) => Container(
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                            title: Text(getString(page.key)),
                            trailing: Switch(value: page.isActive, onChanged: (b) {
                              setState(() => page.isActive = b);
                              savePageActiveState(page.key, b);
                            }),
                          ),
                        )).toList(),
                      ),
                    ),
                  ),
                  ListTile(
                    title: Text(getString('developer_debugging')),
                  ),
                  Container(
                    padding: EdgeInsets.all(4.0),
                    child: Card(
                      elevation: 1.0,
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                            title: Text(getString('developer_showPerformanceOverlay')),
                            trailing: Switch(value: showPerformanceOverlay, onChanged: (b) {
                              setState(() => showPerformanceOverlay = b);
                              savePageActiveState('showPerformanceOverlay', b);
                            }),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                            title: Text(getString('developer_checkerboardOffscreenLayers')),
                            trailing: Switch(value: checkerboardOffscreenLayers, onChanged: (b) {
                              setState(() => checkerboardOffscreenLayers = b);
                              savePageActiveState('checkerboardOffscreenLayers', b);
                            }),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                            title: Text(getString('developer_checkerboardRasterCacheImages')),
                            trailing: Switch(value: checkerboardRasterCacheImages, onChanged: (b) {
                              setState(() => checkerboardRasterCacheImages = b);
                              savePageActiveState('checkerboardRasterCacheImages', b);
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    height: 40.0,
                    child: FlatButton(
                      child: Text('CLEAR ALL SETTINGS'),
                      onPressed: () async {
                        showDialog<DialogAction>(
                            context: context,
                            builder: (BuildContext context) => AlertDialog(
                              title: Text('Are you sure you want to clear all settings?'),
                              content: Text(
                                  'All settings will revert to the default. You cannot undo this action.'
                              ),
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
                        ).then<void>((DialogAction value) async {
                          switch(value) {
                            case DialogAction.confirm:
                              (await SharedPreferences.getInstance()).clear();
                              print('Cleared all settings.');
                              break;
                            case DialogAction.cancel:
                              print('Clear all settings cancelled.');
                              break;
                          }
                        });
                      },
                    ),
                  ),
                  Container(height: 56.0),
                ],
              ),
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
              appBarAtTop ? Align(
                alignment: Alignment.topLeft,
                child: Container(
                  height: 56.0,
                  width: 56.0,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ) : Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  height: 56.0,
                  width: 56.0,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}