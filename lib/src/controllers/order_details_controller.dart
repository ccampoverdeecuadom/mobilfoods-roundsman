import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

// import 'package:background_location/background_location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/distance.dart';
import 'package:location/location.dart';
import 'package:mvc_pattern/mvc_pattern.dart';
import 'package:roundsman/src/helpers/distance_matrix.dart';
import 'package:roundsman/src/helpers/helper.dart';
import 'package:roundsman/src/helpers/location-helpers/location-helper.dart';
import 'package:roundsman/src/helpers/maps_util.dart';
import 'package:roundsman/src/models/address.dart';
import 'package:roundsman/src/pages/map.dart';
import 'package:roundsman/src/repository/user_repository.dart';

import '../../generated/l10n.dart';
import '../models/order.dart';
import '../repository/order_repository.dart';
import '../repository/settings_repository.dart' as sett;

class OrderDetailsController extends ControllerMVC {
  Order order;
  double deliveryFee = 0.0;
  GlobalKey<ScaffoldState> scaffoldKey;

  DateTime lastTimeLocation;

  LocationStatus _status = LocationStatus.UNKNOWN;
  Uint8List markerIcon;
  FirebaseFirestore fireStore;

  Address currentAddress;

  String duration;
  String distance;
  int durationValue;

  Set<Polyline> polylines = new Set();


  OrderDetailsController(bool initLocationListener) {
    this.scaffoldKey = new GlobalKey<ScaffoldState>();
    durationValue = 0;
    if (initLocationListener) {
      fireStore = FirebaseFirestore.instance;
      initBackgroundLocationListener();
    }
  }

  initBackgroundLocationListener() async {
    bool hasPermissions = await sett.locationHelper.validatePermissions();
    if(!hasPermissions) {
      Fluttertoast.showToast(
        msg: 'Debes dar permiso de seguimiento',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Theme.of(context).backgroundColor,
//      textColor: Theme.of(context).hintColor,
        timeInSecForIosWeb: 5,
      );
      initBackgroundLocationListener();
    }

    sett.locationHelper.stopListener();

    sett.locationHelper.locationSubscription = sett.locationHelper.listenLocationChanged().listen((LocationData currentLocation) {
        print(currentLocation.latitude.toString() + "," + currentLocation.longitude.toString());
        print("speed: " + currentLocation.speed.toString());
        String goTo = order.orderStatus.id == '1' || order.orderStatus.id == '2' ? 'market' : 'customer';
        print(currentLocation.time.toString() + "FROM CONTROLLER");
        getLocationsAndDistances(new Address.fromLatLng(currentLocation.latitude, currentLocation.longitude), goTo);
    });
  }

  stopBackgroundLocationListener() {
    sett.locationHelper.stopListener();
  }

  getLocationsAndDistances(Address currentRealAddress, String goTo) async {
    Address destineAddress;
    destineAddress = goTo == 'customer' ?
    new Address.fromLatLng(order.deliveryAddress.latitude,
        order.deliveryAddress.longitude)
        : goTo == 'market' ?
    new Address.fromLatLng(double.parse(order.productOrders[0].product.market.latitude),
        double.parse(order.productOrders[0].product.market.longitude))
        : null;
    if (destineAddress == null) return;

    currentAddress = sett.myAddress.value;
    Address originAddress = !currentRealAddress.isUnknown()
        ? currentRealAddress
        : currentAddress;

    if (originAddress.isUnknown()) {
      await sett.getCurrentLocation().then((value) =>
          getLocationsAndDistances(currentRealAddress, goTo));
    } else {

      String urlDistanceMatrix = "https://maps.googleapis.com/maps/api/distancematrix/json" +
          "?units=metric" +
          "&origins="+ currentRealAddress.latitude.toString() + "," + currentRealAddress.longitude.toString() +
          "&destinations=" + destineAddress.latitude.toString() + "," + destineAddress.longitude.toString() +
          "&key=" + sett.setting.value?.googleMapsKey;

      Dio dio = new Dio();
      Response response=await dio.get(urlDistanceMatrix);
      DistanceMatrix distanceMatrix = DistanceMatrix.fromJson(response.data);
      distance = distanceMatrix.elements.first.distance.text;
      duration = distanceMatrix.elements.first.duration.text;
      setState(() => durationValue = distanceMatrix.elements.first.duration.value);
      _addGeoPoint(
          currentRealAddress.latitude, currentRealAddress.longitude,
          distance, duration, durationValue, goTo);
    }
  }


  /*
  CallbackAction<Intent> onData(dynamic dto) {
    print(dtoToString(dto));
    String goTo = (order.orderStatus.id == "1" || order.orderStatus.id == "2")
        ? 'market'
        : 'customer';
    getDirectionSteps(
        new Address.fromLatLng(dto.latitude, dto.longitude), goTo);
    setState(() {
      if (_status == LocationStatus.UNKNOWN) {
        _status = LocationStatus.RUNNING;
      }
      lastLocation = dto;
      lastTimeLocation = DateTime.now();
    });
  }

   */


  void listenForOrder({String id, String message}) async {
    final Stream<Order> stream = await getOrder(id);
    stream.listen((Order _order) {
      setState(() => order = _order);
    }, onError: (a) {
      print(a);
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text(S
            .of(context)
            .verify_your_internet_connection),
      ));
    }, onDone: () {
      if (message != null) {
        scaffoldKey?.currentState?.showSnackBar(SnackBar(
          content: Text(message),
        ));
      }
    });
  }

  Future<void> refreshOrder() async {
    listenForOrder(id: order.id, message: S
        .of(context)
        .order_refreshed_successfuly);
  }

  void doDeliveredOrder(Order _order) async {
    deliveredOrder(_order).then((value) {
      setState(() {
        this.order.orderStatus.id = '5';
      });
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text('Se entregó con exito al cliente'),
      ));
    });
  }

  _addGeoPoint(latitude, longitude, distance, duration, durationValue, goTo) async {
    fireStore.collection('locations').doc(currentUser.value.id).set({
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      'duration': duration,
      'duration_value': durationValue,
      'goTo': goTo == 'customer' ? 'Cliente' : 'Establecimiento'
    }).catchError((onError) {
      print(onError);
    });
    ;
  }

  /*
  void getDirectionSteps(Address currentRealAddress, String goTo) async {
    String destineAddress;
    destineAddress = goTo == 'customer' ?
    order.deliveryAddress.latitude.toString() + "," +
        order.deliveryAddress.longitude.toString()
        : goTo == 'market' ?
    order.productOrders[0].product.market.latitude.toString() + "," +
        order.productOrders[0].product.market.longitude.toString()
        : null;
    if (destineAddress == null) return;

    currentAddress = sett.myAddress.value;
    Address originAddress = !currentRealAddress.isUnknown()
        ? currentRealAddress
        : currentAddress;

    if (originAddress.isUnknown()) {
      await sett.getCurrentLocation().then((value) =>
          getDirectionSteps(currentRealAddress, goTo));
    } else {
      String uriMaps = "origin=" +
          currentAddress.latitude.toString() +
          "," +
          currentAddress.longitude.toString() +
          "&destination=" + destineAddress +
          "&key=${sett.setting.value?.googleMapsKey}";


      final request = DirectionsRequest(
        origin: currentAddress.latitude.toString() + "," +
            currentAddress.longitude.toString(),
        destination: destineAddress,
        travelMode: TravelMode.driving,
      );

      directionsService.route(request,
              (DirectionsResult response, DirectionsStatus status) {
            if (status == DirectionsStatus.ok) {
              List pointsDecoded = decodePoly(
                  response.routes[0].overviewPolyline.points.toString());
              List<LatLng> realPoints = convertToLatLng(pointsDecoded);
              realPoints?.insert(
                  0, new LatLng(
                  currentAddress.latitude, currentAddress.longitude));
              setState(() {
                duration = response.routes[0].legs[0].duration.text;
                distance = response.routes[0].legs[0].distance.text;
                _addGeoPoint(
                    currentRealAddress.latitude, currentRealAddress.longitude,
                    distance, duration);
                polylines.add(new Polyline(
                    visible: true,
                    polylineId: new PolylineId(
                        currentAddress.hashCode.toString()),
                    points: realPoints,
                    color: config.Colors().mainColor(0.8),
                    width: 6));
              });
            } else {
              print(status);
            }
          });
    }
  }

   */


  // !DECODE POLY
  static List decodePoly(String poly) {
    var list = poly.codeUnits;
    var lList = new List();
    int index = 0;
    int len = poly.length;
    int c = 0;
    // repeating until all attributes are decoded
    do {
      var shift = 0;
      int result = 0;

      // for decoding value of one attribute
      do {
        c = list[index] - 63;
        result |= (c & 0x1F) << (shift * 5);
        index++;
        shift++;
      } while (c >= 32);
      /* if value is negative then bitwise not the value */
      if (result & 1 == 1) {
        result = ~result;
      }
      var result1 = (result >> 1) * 0.00001;
      lList.add(result1);
    } while (index < len);

    /*adding to previous value as done in encoding */
    for (var i = 2; i < lList.length; i++) lList[i] += lList[i - 2];

    print(lList.toString());

    return lList;
  }

  static List<LatLng> convertToLatLng(List points) {
    List<LatLng> result = <LatLng>[];
    for (int i = 0; i < points.length; i++) {
      if (i % 2 != 0) {
        result.add(LatLng(points[i - 1], points[i]));
      }
    }
    return result;
  }


}



