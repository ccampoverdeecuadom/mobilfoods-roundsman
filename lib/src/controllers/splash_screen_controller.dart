import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mvc_pattern/mvc_pattern.dart';
import 'package:roundsman/src/models/route_argument.dart';

import '../../generated/l10n.dart';
import '../helpers/custom_trace.dart';
import '../repository/settings_repository.dart' as settingRepo;
import '../repository/user_repository.dart' as userRepo;

class SplashScreenController extends ControllerMVC with ChangeNotifier {
  ValueNotifier<Map<String, double>> progress = new ValueNotifier(new Map());
  GlobalKey<ScaffoldState> scaffoldKey;
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  SplashScreenController() {
    this.scaffoldKey = new GlobalKey<ScaffoldState>();
    // Should define these variables before the app loaded
    progress.value = {"Setting": 0, "User": 0};
  }

  @override
  void initState() {
    super.initState();
    firebaseMessaging.requestPermission(sound: true, badge: true, alert: true);

    FirebaseMessaging.onMessage.listen((event) => notificationOnMessage(event.notification.title));
    FirebaseMessaging.onMessageOpenedApp.listen((event) => notificationOnLaunch(event.data));
    // configureFirebase(firebaseMessaging);
    settingRepo.setting.addListener(() {
      if (settingRepo.setting.value.appName != null && settingRepo.setting.value.appName != '' && settingRepo.setting.value.mainColor != null) {
        progress.value["Setting"] = 41;
        progress?.notifyListeners();
      }
    });
    userRepo.currentUser.addListener(() {
      if (userRepo.currentUser.value.auth != null) {
        progress.value["User"] = 59;
        progress?.notifyListeners();
      }
    });
    Timer(Duration(seconds: 20), () {
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text(S.of(this.state.context).verify_your_internet_connection),
      ));
    });
  }
/*
  void configureFirebase(FirebaseMessaging _firebaseMessaging) {
    try {
      _firebaseMessaging.configure(
        onMessage: notificationOnMessage,
        onLaunch: notificationOnLaunch,
        onResume: notificationOnResume,
      );
    } catch (e) {
      print(CustomTrace(StackTrace.current, message: e));
      print(CustomTrace(StackTrace.current, message: 'Error Config Firebase'));
    }
  }

 */

  Future notificationOnResume(Map<String, dynamic> message) async {
    print(CustomTrace(StackTrace.current, message: message['data']['id']));
    try {
      if (message['data']['id'] == "orders") {
        settingRepo.navigatorKey.currentState.pushReplacementNamed('/Pages', arguments:0);
      } else if (message['data']['id'] == "update_order") {
        var orderId = message['data']['order_id'];
        settingRepo.navigatorKey.currentState.pushNamed(
            '/OrderDetails', arguments: RouteArgument(id: orderId));
      }
    } catch (e) {
      print(CustomTrace(StackTrace.current, message: e));
    }
  }

  Future notificationOnLaunch(Map<String, dynamic> message) async {
    String messageId = await settingRepo.getMessageId();
    try {
      if (messageId != message['google.message_id']) {
        if (message['id'] == "orders") {
          await settingRepo.saveMessageId(message['google.message_id']);
          settingRepo.navigatorKey.currentState.pushReplacementNamed('/Pages', arguments: 0);
        } else if(message['id'] == "update_order") {
          var orderId = message['order_id'];
          settingRepo.navigatorKey.currentState.pushNamed('/OrderDetails', arguments: RouteArgument(id: orderId));
        }
      }
    } catch (e) {
      print(CustomTrace(StackTrace.current, message: e));
    }
  }

  Future notificationOnMessage(String title) async {
    Fluttertoast.showToast(
      msg: title,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 6,
    );
    settingRepo.navigatorKey.currentState.pushReplacementNamed('/Pages', arguments: 2);
  }

}
