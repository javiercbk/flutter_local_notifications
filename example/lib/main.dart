import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications/initialization_settings.dart';
import 'package:flutter_local_notifications/notification_details.dart';
import 'package:flutter_local_notifications/platform_specifics/android/initialization_settings_android.dart';
import 'package:flutter_local_notifications/platform_specifics/android/notification_details_android.dart';
import 'package:flutter_local_notifications/platform_specifics/android/styles/big_text_style_information.dart';
import 'package:flutter_local_notifications/platform_specifics/android/styles/default_style_information.dart';
import 'package:flutter_local_notifications/platform_specifics/android/styles/inbox_style_information.dart';
import 'package:flutter_local_notifications/platform_specifics/ios/initialization_settings_ios.dart';
import 'package:flutter_local_notifications/platform_specifics/ios/notification_details_ios.dart';

void main() {
  runApp(
    new MaterialApp(home: new MyApp()),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  @override
  initState() {
    super.initState();
    // initialise the plugin
    InitializationSettingsAndroid initializationSettingsAndroid =
        new InitializationSettingsAndroid('app_icon');
    InitializationSettingsIOS initializationSettingsIOS =
        new InitializationSettingsIOS();
    InitializationSettings initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        selectNotification: onSelectNotification);
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: new Text('Plugin example app'),
        ),
        body: new Padding(
          padding: new EdgeInsets.all(8.0),
          child: new Center(
            child: new Column(
              children: <Widget>[
                new Padding(
                  padding: new EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 8.0),
                  child: new Text(
                      'Tap on a notification when it appears to trigger navigation'),
                ),
                new Padding(
                    padding: new EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 8.0),
                    child: new RaisedButton(
                        child: new Text('Show plain notification with payload'),
                        onPressed: () async {
                          await _showNotification();
                        })),
                new Padding(
                    padding: new EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 8.0),
                    child: new RaisedButton(
                        child: new Text('Cancel notification'),
                        onPressed: () async {
                          await _cancelNotification();
                        })),
                new Padding(
                    padding: new EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 8.0),
                    child: new RaisedButton(
                        child: new Text(
                            'Schedule notification to appear in 5 seconds, custom sound'),
                        onPressed: () async {
                          await _scheduleNotification();
                        })),
                new Padding(
                    padding: new EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 8.0),
                    child: new RaisedButton(
                        child: new Text('Repeat notification every minute'),
                        onPressed: () async {
                          await _repeatNotification();
                        })),
                new Padding(
                    padding: new EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 8.0),
                    child: new RaisedButton(
                        child: new Text('Show notification with no sound'),
                        onPressed: () async {
                          await _showNotificationWithNoSound();
                        })),
                new Padding(
                    padding: new EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 8.0),
                    child: new RaisedButton(
                        child: new Text('Show big text notification [Android]'),
                        onPressed: () async {
                          await _showBigTextNotification();
                        })),
                new Padding(
                    padding: new EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 8.0),
                    child: new RaisedButton(
                        child: new Text('Show inbox notification [Android]'),
                        onPressed: () async {
                          await _showInboxNotification();
                        })),
                new Padding(
                    padding: new EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 8.0),
                    child: new RaisedButton(
                        child: new Text('Show grouped notifications [Android]'),
                        onPressed: () async {
                          await _showGroupedNotifications();
                        })),
                new Padding(
                    padding: new EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 8.0),
                    child: new RaisedButton(
                        child: new Text('Show ongoing notification [Android]'),
                        onPressed: () async {
                          await _showOngoingNotification();
                        })),
                new Padding(
                    padding: new EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 8.0),
                    child: new RaisedButton(
                        child: new Text('cancel all notifications'),
                        onPressed: () async {
                          await _cancelAllNotifications();
                        })),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future _showNotification() async {
    NotificationDetailsAndroid androidPlatformChannelSpecifics =
        new NotificationDetailsAndroid(
            'your channel id', 'your channel name', 'your channel description',
            importance: Importance.Max, priority: Priority.High);
    NotificationDetailsIOS iOSPlatformChannelSpecifics =
        new NotificationDetailsIOS();
    NotificationDetails platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, 'plain title', 'plain body', platformChannelSpecifics,
        payload: 'item x');
  }

  Future _cancelNotification() async {
    await flutterLocalNotificationsPlugin.cancel(0);
  }

  /// Schedules a notification that specifies a different icon, sound and vibration pattern
  Future _scheduleNotification() async {
    var scheduledNotificationDateTime =
        new DateTime.now().add(new Duration(seconds: 5));
    var vibrationPattern = new Int64List(4);
    vibrationPattern[0] = 0;
    vibrationPattern[1] = 1000;
    vibrationPattern[2] = 5000;
    vibrationPattern[3] = 2000;
    NotificationDetailsAndroid androidPlatformChannelSpecifics =
        new NotificationDetailsAndroid('your other channel id',
            'your other channel name', 'your other channel description',
            icon: 'secondary_icon',
            sound: 'slow_spring_board',
            vibrationPattern: vibrationPattern);
    NotificationDetailsIOS iOSPlatformChannelSpecifics =
        new NotificationDetailsIOS(sound: "slow_spring_board.aiff");
    NotificationDetails platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.schedule(
        0,
        'scheduled title',
        'scheduled body',
        scheduledNotificationDateTime,
        platformChannelSpecifics);
  }

  Future _showNotificationWithNoSound() async {
    NotificationDetailsAndroid androidPlatformChannelSpecifics =
        new NotificationDetailsAndroid('silent channel id',
            'silent channel name', 'silent channel description',
            playSound: false,
            styleInformation: new DefaultStyleInformation(true, true));
    NotificationDetailsIOS iOSPlatformChannelSpecifics =
        new NotificationDetailsIOS(presentSound: false);
    NotificationDetails platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(0, '<b>silent</b> title',
        '<b>silent</b> body', platformChannelSpecifics);
  }

  Future _showBigTextNotification() async {
    BigTextStyleInformation bigTextStyleInformation = new BigTextStyleInformation(
        'Lorem <i>ipsum dolor sit</i> amet, consectetur <b>adipiscing elit</b>, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
        htmlFormatBigText: true,
        contentTitle: 'overridden <b>big</b> context title',
        htmlFormatContentTitle: true,
        summaryText: 'summary <i>text</i>',
        htmlFormatSummaryText: true);
    NotificationDetailsAndroid androidPlatformChannelSpecifics =
        new NotificationDetailsAndroid('big text channel id',
            'big text channel name', 'big text channel description',
            style: NotificationStyleAndroid.BigText,
            styleInformation: bigTextStyleInformation);
    NotificationDetails platformChannelSpecifics =
        new NotificationDetails(androidPlatformChannelSpecifics, null);
    await flutterLocalNotificationsPlugin.show(
        0, 'big text title', 'silent body', platformChannelSpecifics);
  }

  Future _showInboxNotification() async {
    List<String> lines = new List<String>();
    lines.add('line <b>1</b>');
    lines.add('line <i>2</i>');
    InboxStyleInformation inboxStyleInformation = new InboxStyleInformation(
        lines,
        htmlFormatLines: true,
        contentTitle: 'overridden <b>inbox</b> context title',
        htmlFormatContentTitle: true,
        summaryText: 'summary <i>text</i>',
        htmlFormatSummaryText: true);
    NotificationDetailsAndroid androidPlatformChannelSpecifics =
        new NotificationDetailsAndroid('inbox channel id', 'inboxchannel name',
            'inbox channel description',
            style: NotificationStyleAndroid.Inbox,
            styleInformation: inboxStyleInformation);
    NotificationDetails platformChannelSpecifics =
        new NotificationDetails(androidPlatformChannelSpecifics, null);
    await flutterLocalNotificationsPlugin.show(
        0, 'inbox title', 'inbox body', platformChannelSpecifics);
  }

  Future _showGroupedNotifications() async {
    String groupKey = 'com.android.example.WORK_EMAIL';
    String groupChannelId = 'grouped channel id';
    String groupChannelName = 'grouped channel name';
    String groupChannelDescription = 'grouped channel description';
    // example based on https://developer.android.com/training/notify-user/group.html
    NotificationDetailsAndroid firstNotificationAndroidSpecifics =
        new NotificationDetailsAndroid(
            groupChannelId, groupChannelName, groupChannelDescription,
            importance: Importance.Max,
            priority: Priority.High,
            groupKey: groupKey);
    NotificationDetails firstNotificationPlatformSpecifics =
        new NotificationDetails(firstNotificationAndroidSpecifics, null);
    await flutterLocalNotificationsPlugin.show(1, 'Alex Faarborg',
        'You will not believe...', firstNotificationPlatformSpecifics);
    NotificationDetailsAndroid secondNotificationAndroidSpecifics =
        new NotificationDetailsAndroid(
            groupChannelId, groupChannelName, groupChannelDescription,
            importance: Importance.Max,
            priority: Priority.High,
            groupKey: groupKey);
    NotificationDetails secondNotificationPlatformSpecifics =
        new NotificationDetails(secondNotificationAndroidSpecifics, null);
    await flutterLocalNotificationsPlugin.show(
        2,
        'Jeff Chang',
        'Please join us to celebrate the...',
        secondNotificationPlatformSpecifics);

    // create the summary notification required for older devices that pre-date Android 7.0 (API level 24)
    List<String> lines = new List<String>();
    lines.add('Alex Faarborg  Check this out');
    lines.add('Jeff Chang    Launch Party');
    InboxStyleInformation inboxStyleInformation = new InboxStyleInformation(
        lines,
        contentTitle: '2 new messages',
        summaryText: 'janedoe@example.com');
    NotificationDetailsAndroid androidPlatformChannelSpecifics =
        new NotificationDetailsAndroid(
            groupChannelId, groupChannelName, groupChannelDescription,
            style: NotificationStyleAndroid.Inbox,
            styleInformation: inboxStyleInformation,
            groupKey: groupKey,
            setAsGroupSummary: true);
    NotificationDetails platformChannelSpecifics =
        new NotificationDetails(androidPlatformChannelSpecifics, null);
    await flutterLocalNotificationsPlugin.show(
        3, 'Attention', 'Two new messages', platformChannelSpecifics);
  }

  Future _cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future onSelectNotification(String payload) async {
    if (payload != null) {
      debugPrint('notification payload: ' + payload);
    }

    /// IMPORTANT: On beta 2, the navigation doesn't seem to do a complete full page transition on Android when the app is already running.
    /// This has been fixed by the Flutter team on the master channel.
    await Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => new SecondScreen(payload)),
    );
  }

  Future _showOngoingNotification() async {
    NotificationDetailsAndroid androidPlatformChannelSpecifics =
        new NotificationDetailsAndroid(
            'your channel id', 'your channel name', 'your channel description',
            importance: Importance.Max, priority: Priority.High, ongoing: true);
    NotificationDetailsIOS iOSPlatformChannelSpecifics =
        new NotificationDetailsIOS();
    NotificationDetails platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(0, 'ongoing notification title',
        'ongoing notification body', platformChannelSpecifics);
  }

  Future _repeatNotification() async {
    NotificationDetailsAndroid androidPlatformChannelSpecifics =
        new NotificationDetailsAndroid('repeating channel id',
            'repeating channel name', 'repeating description');
    NotificationDetailsIOS iOSPlatformChannelSpecifics =
        new NotificationDetailsIOS();
    NotificationDetails platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.periodicallyShow(0, 'repeating title',
        'repeating body', RepeatInterval.EveryMinute, platformChannelSpecifics);
  }
}

class SecondScreen extends StatefulWidget {
  final String payload;
  SecondScreen(this.payload);
  @override
  State<StatefulWidget> createState() => new SecondScreenState();
}

class SecondScreenState extends State<SecondScreen> {
  String _payload;
  @override
  void initState() {
    super.initState();
    _payload = widget.payload;
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Second Screen with payload: " + _payload),
      ),
      body: new Center(
        child: new RaisedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: new Text('Go back!'),
        ),
      ),
    );
  }
}
