import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mvc_pattern/mvc_pattern.dart';

import '../helpers/app_config.dart' as config;
import '../helpers/helper.dart';
import '../helpers/maps_util.dart';
import '../models/address.dart';
import '../models/order.dart';
import '../repository/order_repository.dart';
import '../repository/settings_repository.dart' as sett;

class MapController extends ControllerMVC {
  Order currentOrder;
  List<Order> orders = <Order>[];
  List<Marker> allMarkers = <Marker>[];
  Address currentAddress;
  Set<Polyline> polylines = new Set();
  CameraPosition cameraPosition;
  MapsUtil mapsUtil = new MapsUtil();
  double taxAmount = 0.0;
  double subTotal = 0.0;
  double deliveryFee = 0.0;
  double total = 0.0;
  Completer<GoogleMapController> mapController = Completer();

  List<Order> availableOrders = <Order>[];



  MapController() {
    // DirectionsService.init(sett.setting.value?.googleMapsKey);
  }

  void listenForNearOrders(Address myAddress, Address areaAddress) async {
    print('listenForOrders');
    final Stream<Order> stream = await getNearOrders(myAddress, areaAddress);
    stream.listen(
        (Order _order) {
          setState(() {
            orders.add(_order);
          });
          Helper.getOrderMarker(_order.deliveryAddress.toMap()).then((marker) {
            setState(() {
              allMarkers.add(marker);
            });
          });
        },
        onError: (a) {},
        onDone: () {
          calculateSubtotal();
        });
  }

  void listenForAvailbleOrders() async {
    print('listenForOrders AVAILABLE');
    final Stream<Order> stream = await getAvailableOrders();
    stream.listen(
            (Order _order) {
          setState(() {
            availableOrders.add(_order);
          });
          Helper.getOrderMarker(_order.deliveryAddress.toMap()).then((marker) {
            setState(() {
              allMarkers.add(marker);
            });
          });
        },
        onError: (a) {},
        onDone: () {
          calculateSubtotal();
        });
  }

  void getCurrentLocation() async {
    try {
      currentAddress = sett.myAddress.value;
      setState(() {
        if (currentAddress.isUnknown()) {
          cameraPosition = CameraPosition(
            target: LatLng(40, 3),
            zoom: 4,
          );
        } else {
          cameraPosition = CameraPosition(
            target: LatLng(currentAddress.latitude, currentAddress.longitude),
            zoom: 14.4746,
          );
        }
      });
      if (!currentAddress.isUnknown()) {
        Helper.getMyPositionMarker(currentAddress.latitude, currentAddress.longitude).then((marker) {
          setState(() {
            allMarkers.add(marker);
          });
        });
      }
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        print('Permission denied');
      }
    }
  }

  void getOrderLocation() async {
    try {
      currentAddress = sett.myAddress.value;
      setState(() {
        cameraPosition = CameraPosition(
          target: LatLng(currentOrder.deliveryAddress.latitude, currentOrder.deliveryAddress.longitude),
          zoom: 14.4746,
        );
      });
      if (!currentAddress.isUnknown()) {
        Helper.getMyPositionMarker(currentAddress.latitude, currentAddress.longitude).then((marker) {
          setState(() {
            allMarkers.add(marker);
          });
        });
      }
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        print('Permission denied');
      }
    }
  }

  Future<void> goCurrentLocation() async {
    final GoogleMapController controller = await mapController.future;

    sett.setCurrentLocation().then((_currentAddress) {
      setState(() {
        sett.myAddress.value = _currentAddress;
        currentAddress = _currentAddress;
      });
      controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: LatLng(_currentAddress.latitude, _currentAddress.longitude),
        zoom: 14.4746,
      )));
    });
  }

  void getOrdersOfArea() async {
    setState(() {
      orders = <Order>[];
      Address areaAddress = Address.fromJSON({"latitude": cameraPosition.target.latitude, "longitude": cameraPosition.target.longitude});
      if (cameraPosition != null) {
        listenForNearOrders(currentAddress, areaAddress);
      } else {
        listenForNearOrders(currentAddress, currentAddress);
      }
    });
  }

  void getDirectionSteps(Address currentRealAddress,String goTo) async {
    String destineAddress;
    destineAddress = goTo == 'customer' ?
        currentOrder.deliveryAddress.latitude.toString() + "," +
        currentOrder.deliveryAddress.longitude.toString()
        :  goTo == 'market' ?
        currentOrder.productOrders[0].product.market.latitude.toString() + "," +
        currentOrder.productOrders[0].product.market.longitude.toString()
          : null;
    if(destineAddress == null) return;

    currentAddress = sett.myAddress.value;
    Address originAddress = !currentRealAddress.isUnknown() ? currentRealAddress : currentAddress;

    if(originAddress.isUnknown()){
      await sett.getCurrentLocation().then((value) => getDirectionSteps(currentRealAddress, goTo));
    } else {
      String uriMaps = "origin=" +
          currentAddress.latitude.toString() +
          "," +
          currentAddress.longitude.toString() +
          "&destination=" + destineAddress +
          "&key=${sett.setting.value?.googleMapsKey}";


      mapsUtil
          .get(uriMaps)
          .then((dynamic res) {
        if (res != null) {

          // List<LatLng> _latLng = res as List<LatLng>;
          List pointsDecoded = decodePoly(res);
          List<LatLng> realPoints = convertToLatLng(pointsDecoded);
          realPoints?.insert(
              0, new LatLng(currentAddress.latitude, currentAddress.longitude));
          setState(() {
            polylines.add(new Polyline(
                visible: true,
                polylineId: new PolylineId(currentAddress.hashCode.toString()),
                points: realPoints,
                color: config.Colors().mainColor(0.8),
                width: 6));
          });
        }
      });
    }
  }



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

  void calculateSubtotal() async {
    subTotal = 0;
    currentOrder.productOrders?.forEach((product) {
      subTotal += product.quantity * product.price;
    });
    deliveryFee = currentOrder.productOrders?.elementAt(0)?.product?.market?.deliveryFee ?? 0;
    taxAmount = (subTotal + deliveryFee) * currentOrder.tax / 100;
    total = subTotal + taxAmount + deliveryFee;

    taxAmount = subTotal * currentOrder.tax / 100;
    total = subTotal + taxAmount;
    setState(() {});
  }

  Future refreshMap() async {
    setState(() {
      orders = <Order>[];
    });
    listenForNearOrders(currentAddress, currentAddress);
  }
}
