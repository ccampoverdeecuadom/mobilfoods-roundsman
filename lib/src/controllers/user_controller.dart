import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mvc_pattern/mvc_pattern.dart';
import 'package:roundsman/src/helpers/custom_trace.dart';
import 'package:roundsman/src/models/route_argument.dart';

import '../../generated/l10n.dart';
import '../helpers/helper.dart';
import '../models/user.dart';
import '../repository/user_repository.dart' as repository;
import '../repository/settings_repository.dart' as settingRepo;


class UserController extends ControllerMVC {
  User user = new User();
  bool hidePassword = true;
  bool loading = false;
  GlobalKey<FormState> loginFormKey;
  GlobalKey<ScaffoldState> scaffoldKey;
  FirebaseMessaging _firebaseMessaging;
  OverlayEntry loader;

  UserController() {
    loader = Helper.overlayLoader(this);
    loginFormKey = new GlobalKey<FormState>();
    this.scaffoldKey = new GlobalKey<ScaffoldState>();
    _firebaseMessaging = FirebaseMessaging.instance;

    /****************Start FIREBASE******************/
    FirebaseMessaging.onMessage.listen((RemoteMessage remoteMessage) {
      if (remoteMessage.data['id'] == "orders") {
        Fluttertoast.showToast(
          msg: remoteMessage.notification.title,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          backgroundColor: Theme.of(settingRepo.navigatorKey.currentState.context).backgroundColor,
//      textColor: Theme.of(context).hintColor,
          timeInSecForIosWeb: 5,
        );
        settingRepo.navigatorKey.currentState.pushReplacementNamed('/Pages', arguments: 0);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage remoteMessage) {
        try {
          if (remoteMessage.data['id'] == "orders") {
            settingRepo.navigatorKey.currentState.pushReplacementNamed('/Pages', arguments: 0);
          }
      } catch (e) {
        print(CustomTrace(StackTrace.current, message: e));
      }
    });

    _firebaseMessaging.getToken().then((String _deviceToken) {
      print(_deviceToken);
      user.deviceToken = _deviceToken;
    }).catchError((e) {
      print('Notification not configured');
    });
  }

  void login() async {
    FocusScope.of(this.state.context).unfocus();
    if (loginFormKey.currentState.validate()) {
      loginFormKey.currentState.save();
      Overlay.of(this.state.context).insert(loader);
      repository.login(user).then((value) {
        if (value != null && value.apiToken != null) {
          Navigator.of(scaffoldKey.currentContext).pushReplacementNamed('/Pages', arguments: 0);
        } else {
          scaffoldKey?.currentState?.showSnackBar(SnackBar(
            content: Text(S.of(this.state.context).wrong_email_or_password),
          ));
        }
      }).catchError((e) {
        loader.remove();
        scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text(S.of(this.state.context).thisAccountNotExist),
        ));
      }).whenComplete(() {
        Helper.hideLoader(loader);
      });
    }
  }

  void register() async {
    FocusScope.of(this.state.context).unfocus();
    if (loginFormKey.currentState.validate()) {
      loginFormKey.currentState.save();
      Overlay.of(this.state.context).insert(loader);
      repository.register(user).then((value) {
        if (value != null && value.apiToken != null) {
          Navigator.of(scaffoldKey.currentContext).pushReplacementNamed('/Pages', arguments: 0);
        } else {
          scaffoldKey?.currentState?.showSnackBar(SnackBar(
            content: Text(S.of(this.state.context).wrong_email_or_password),
          ));
        }
      }).catchError((e) {
        loader.remove();
        scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text(S.of(this.state.context).thisAccountNotExist),
        ));
      }).whenComplete(() {
        Helper.hideLoader(loader);
      });
    }
  }

  void resetPassword() {
    FocusScope.of(this.state.context).unfocus();
    if (loginFormKey.currentState.validate()) {
      loginFormKey.currentState.save();
      Overlay.of(this.state.context).insert(loader);
      repository.resetPassword(user).then((value) {
        if (value != null && value == true) {
          scaffoldKey?.currentState?.showSnackBar(SnackBar(
            content: Text(S.of(this.state.context).your_reset_link_has_been_sent_to_your_email),
            action: SnackBarAction(
              label: S.of(this.state.context).login,
              onPressed: () {
                Navigator.of(scaffoldKey.currentContext).pushReplacementNamed('/Login');
              },
            ),
            duration: Duration(seconds: 10),
          ));
        } else {
          loader.remove();
          scaffoldKey.currentState.showSnackBar(SnackBar(
            content: Text(S.of(this.state.context).error_verify_email_settings),
          ));
        }
      }).whenComplete(() {
        Helper.hideLoader(loader);
      });
    }
  }
}
