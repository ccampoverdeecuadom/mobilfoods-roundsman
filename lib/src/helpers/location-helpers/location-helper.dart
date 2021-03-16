import 'dart:async';

import 'package:location/location.dart';
import 'package:roundsman/src/models/address.dart';

import '../distance_matrix.dart';

class LocationHelper {

  bool backgroundEnable;
  Location location = Location();
  StreamSubscription<LocationData> locationSubscription;

  LocationHelper() {
    settingLocation();
    validatePermissions();
  }

  settingLocation() async {
   await location.changeSettings(distanceFilter: 10, interval: 10000);
  }

  Future<bool> validatePermissions() async {
    bool isEnableBackgroundLocationListener = await enableBackgroundListener();
    if(!isEnableBackgroundLocationListener){
      return Future.value(false);
    }

    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return Future.value(false);
      }
    }
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return Future.value(false);
      }
    }

    return Future.value(_serviceEnabled && _permissionGranted == PermissionStatus.granted);
  }

  Future<bool> enableBackgroundListener() async {
    settingLocation();
    try {
      backgroundEnable =
          await location.enableBackgroundMode(enable: true);
      return backgroundEnable;
    }catch (e) {
      return Future.value(false);
    }
  }

  resetInstanceLocation() {
    disableBackgroundListener();
    location = Location();
    settingLocation();
   }

  Future<bool> disableBackgroundListener() async {
    try {
      backgroundEnable =
      await location.enableBackgroundMode(enable: false);
          return backgroundEnable;
      }catch (e) {
        return Future.value(false);
      }
    }

  Location getCurrentLocationInstance() {
    return location;
  }

  Stream<LocationData> listenLocationChanged()  {
    if(locationSubscription != null) locationSubscription.cancel();
    return location.onLocationChanged;
  }

  stopListener() async {
    disableBackgroundListener();
    await locationSubscription.cancel();
  }


}