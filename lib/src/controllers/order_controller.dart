import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:mvc_pattern/mvc_pattern.dart';
import 'package:roundsman/src/helpers/distance_matrix.dart';
import 'package:roundsman/src/models/address.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../generated/l10n.dart';
import '../models/order.dart';
import '../repository/order_repository.dart';
import '../repository/user_repository.dart';
import '../repository/settings_repository.dart' as sett;
import '../repository/user_repository.dart' as userRepo;


class OrderController extends ControllerMVC {
  List<Order> orders = <Order>[];
  GlobalKey<ScaffoldState> scaffoldKey;

  List<Order> availableOrders = <Order>[];

  bool orderAssigned;

  final FirebaseFirestore fireStore = FirebaseFirestore.instance;
  SharedPreferences prefs;


  OrderController() {
    this.scaffoldKey = new GlobalKey<ScaffoldState>();
    orderAssigned = false;
  }

  void createUser() async {
    //final QuerySnapshot result =
    //await FirebaseFirestore.instance.collection('users').where('id', isEqualTo: firebaseUser.uid).get();

    // creamos el usuario en la base
    //userRepo.getCurrentUser();
    //FirebaseFirestore fireStore = FirebaseFirestore.instance;
    //fireStore.collection('locations').doc(currentUser.value.id).set({

    fireStore.collection('users').doc(userRepo.currentUser.value.id).set({
      'name': userRepo.currentUser.value.name,
      'id': userRepo.currentUser.value.id,
      'createdAt': DateTime.now().millisecondsSinceEpoch.toString(),
      'chattingWith': null
    }).catchError((onError) {
      print("ERROR ....");
      print(onError);
    });

    await prefs.setString('id', userRepo.currentUser.value.id);
    await prefs.setString('nickname', userRepo.currentUser.value.name);

  }


  Future<void> listenForOrders({String message}) async {
    if (!currentUser.value.active) {
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text("No estás Activo para recibir Ordenes"),
      ));
      return;
    }
    final Stream<Order> stream = await getOrders();
    stream.listen((Order _order) {
      setState(() {
        orders.add(_order);
      });
    }, onError: (a) {
      print(a);
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text(S.of(context).verify_your_internet_connection),
      ));
    }, onDone: () {
      if(orders.isNotEmpty) {
        sett.locationHelper.enableBackgroundListener();
        Order _order = orders.first;
        initBackgroundLocationListener(_order);
        setState(() => orderAssigned = true);
      } else {
        if(sett.locationHelper.locationSubscription != null) sett.locationHelper.locationSubscription.cancel();
      }
      if (message != null) {
        scaffoldKey?.currentState?.showSnackBar(SnackBar(
          content: Text(message),
        ));
      }
    });
  }

  initBackgroundLocationListener(Order order) async {
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
      initBackgroundLocationListener(order);
    }

    sett.locationHelper.locationSubscription = sett.locationHelper.listenLocationChanged().listen((LocationData currentLocation) {
      print(currentLocation.latitude.toString() + "," + currentLocation.longitude.toString());
      print("speed: " + currentLocation.speed.toString());
      String goTo = order.orderStatus.id == '1' || order.orderStatus.id == '2' ? 'market' : 'customer';
      print(currentLocation.time.toString() + "FROM INIT");
      getLocationsAndDistances(new Address.fromLatLng(currentLocation.latitude, currentLocation.longitude), goTo, order);
    });
  }


  getLocationsAndDistances(Address currentRealAddress, String goTo, Order order) async {
    Address destineAddress;
    destineAddress = goTo == 'customer' ?
    new Address.fromLatLng(order.deliveryAddress.latitude,
        order.deliveryAddress.longitude)
        : goTo == 'market' ?
    new Address.fromLatLng(double.parse(order.productOrders[0].product.market.latitude),
        double.parse(order.productOrders[0].product.market.longitude))
        : null;
    if (destineAddress == null) return;

    Address currentAddress = sett.myAddress.value;
    Address originAddress = !currentRealAddress.isUnknown()
        ? currentRealAddress
        : currentAddress;

    if (originAddress.isUnknown()) {
      await sett.getCurrentLocation().then((value) =>
          getLocationsAndDistances(currentRealAddress, goTo, order));
    } else {

      String urlDistanceMatrix = "https://maps.googleapis.com/maps/api/distancematrix/json" +
          "?units=metric" +
          "&origins="+ currentRealAddress.latitude.toString() + "," + currentRealAddress.longitude.toString() +
          "&destinations=" + destineAddress.latitude.toString() + "," + destineAddress.longitude.toString() +
          "&key=" + sett.setting.value?.googleMapsKey;

      Dio dio = new Dio();
      Response response=await dio.get(urlDistanceMatrix);
      DistanceMatrix distanceMatrix = DistanceMatrix.fromJson(response.data);
      String distance = distanceMatrix.elements.first.distance.text;
      String duration = distanceMatrix.elements.first.duration.text;
      int durationValue = distanceMatrix.elements.first.duration.value; // In seconds
      _addGeoPoint(
          currentRealAddress.latitude, currentRealAddress.longitude,
          distance, duration, durationValue, goTo);
    }
  }

  _addGeoPoint(latitude, longitude, distance, duration, durationValue, goTo) async {
    FirebaseFirestore fireStore;
    fireStore = FirebaseFirestore.instance;
    fireStore.collection('locations').doc(currentUser.value.id).set({
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      'duration': duration,
      'duration_value' : durationValue,
      'goTo': goTo == 'customer' ? 'Cliente' : 'Establecimiento'
    }).catchError((onError) {
      print(onError);
    });
    ;
  }


  Future<void> listenForAvailableOrders({bool active, String message}) async {
    if(active != null){
      if(!active) {
        scaffoldKey?.currentState?.showSnackBar(SnackBar(
          content: Text("No estás Activo para recibir Ordenes"),
        ));
        return;
      }
    }
    if (!currentUser.value.active) {
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text("No estás Activo para recibir Ordenes"),
      ));
      return;
    }
      final Stream<Order> stream = await getAvailableOrders();
      stream.listen((Order _order) {
        setState(() {
          availableOrders.add(_order);
        });
      }, onError: (a) {
        print(a);
        scaffoldKey?.currentState?.showSnackBar(SnackBar(
          content: Text(S.of(context).verify_your_internet_connection),
        ));
      }, onDone: () {
        if (message != null) {
          scaffoldKey?.currentState?.showSnackBar(SnackBar(
            content: Text(message),
          ));
        }
      });
  }

  void listenForOrdersHistory({String message}) async {
    final Stream<Order> stream = await getOrdersHistory();
    stream.listen((Order _order) {
      setState(() {
        orders.add(_order);
      });
    }, onError: (a) {
      print(a);
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text(S.of(context).verify_your_internet_connection),
      ));
    }, onDone: () {
      if (message != null) {
        scaffoldKey?.currentState?.showSnackBar(SnackBar(
          content: Text(message),
        ));
      }
    });
  }

  Future<void> refreshOrdersHistory() async {
    orders.clear();
    listenForOrdersHistory(message: S.of(context).order_refreshed_successfuly);
  }

  Future<void> refreshOrders() async {
    orders.clear();
    await listenForOrders(message: S.of(context).order_refreshed_successfuly);
    return true;
  }

  Future<void> refreshAvailableOrders() async {
    availableOrders.clear();
    await listenForAvailableOrders(message: S.of(context).order_refreshed_successfuly);
    return true;
  }

  setDriverState(bool active) {
    updateDriverState(active);
  }

  Future<bool> requestToAcceptOrder(id) async {
    return await acceptOrder(id);
  }
}
