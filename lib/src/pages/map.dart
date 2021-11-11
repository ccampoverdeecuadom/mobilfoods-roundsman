import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:mvc_pattern/mvc_pattern.dart';
import 'package:roundsman/src/controllers/order_details_controller.dart';
import 'package:roundsman/src/models/address.dart';
import 'package:roundsman/src/models/market.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../generated/l10n.dart';
import '../controllers/map_controller.dart';
import '../elements/CircularLoadingWidget.dart';
import '../helpers/helper.dart';
import '../models/order.dart';
import '../models/route_argument.dart';

class MapWidget extends StatefulWidget {
  final RouteArgument routeArgument;
  final GlobalKey<ScaffoldState> parentScaffoldKey;

  MapWidget({Key key, this.routeArgument, this.parentScaffoldKey})
      : super(key: key);

  @override
  _MapWidgetState createState() => _MapWidgetState();
}

enum LocationStatus { UNKNOWN, RUNNING, STOPPED }

class _MapWidgetState extends StateMVC<MapWidget> {
  String goTo;
  OrderDetailsController _controllerOderDetails;
  Address destineAddress;

  MapController _con;

  // Location _locationTracker = Location();
  // StreamSubscription _locationSubscription;

  Marker marker;
  Circle circle;
  GoogleMapController _controller;

  Uint8List markerIcon;

  _MapWidgetState() : super(MapController()) {
    _con = controller;
  }

  Future<Uint8List> getMarker(String pathImage) async {
    ByteData byteData = await DefaultAssetBundle.of(context).load(pathImage);
    return byteData.buffer.asUint8List();
  }

  @override
  void initState() {
    goTo = widget.routeArgument?.goTo;
    _controllerOderDetails = widget.routeArgument?.controllerMVC;
    _con.currentOrder = widget.routeArgument?.param as Order;
    super.initState();
    try {
      destineAddress = goTo == 'customer'
          ? new Address.fromLatLng(
              _controllerOderDetails.order.deliveryAddress.latitude,
              _controllerOderDetails.order.deliveryAddress.longitude)
          : goTo == 'market'
              ? new Address.fromLatLng(
                  double.parse(_controllerOderDetails
                      .order.productOrders[0].product.market.latitude),
                  double.parse(_controllerOderDetails
                      .order.productOrders[0].product.market.longitude))
              : null;
    } catch (e) {
      destineAddress == null;
    }
    prepareLocations();
  }

  @override
  void dispose() {
    /*BackgroundLocation.getLocationUpdates((location) {
      String goTo = _controllerOderDetails.order.orderStatus.id == '1' ||
              _controllerOderDetails.order.orderStatus.id == '2'
          ? 'market'
          : 'customer';
      _con.getDirectionSteps(
          new Address.fromLatLng(location.latitude, location.longitude), goTo);
      print(location.speed.toString() + "FROM MAP DISPOSE");
    });*/
    super.dispose();
  }

  prepareLocations() async {
    Uint8List imageDataStore =
        await getMarker("assets/img/icon_store_short.png");

    markerIcon =
        await Helper.getBytesFromAsset('assets/img/mobilfoods_marker_icon.png', 70);

    if (_con.currentOrder?.deliveryAddress?.latitude != null) {
      // user select a market
      Market market = _con.currentOrder.productOrders[0].product.market;
      _con.allMarkers.add(Marker(
          infoWindow: InfoWindow(title: market.name, snippet: market.address),
          icon: BitmapDescriptor.fromBytes(imageDataStore),
          position: LatLng(double.parse(market.latitude ?? '0'),
              double.parse(market.longitude ?? '0')),
          markerId: MarkerId(market.name)));
      print(_con.currentOrder.deliveryAddress.toMap().toString());
      _con.getOrderLocation();
      // _con.getDirectionSteps(new Address(), goTo);
      // getCurrentLocation();
      // _controllerOderDetails.initListenerLocation(onData);
      /// BackgroundLocation.getLocationUpdates((location) {
      //   _controllerOderDetails.getLocationsAndDistances(
      //       new Address.fromLatLng(location.latitude, location.longitude),
      //       goTo);
      //   updateMarkerAndCircle(
      //       location.latitude, location.longitude, markerIcon);
      //   print(location.latitude.toString() +
      //       " " +
      //       location.longitude.toString() +
      //       "FROM MAP");
      // });
    } else {
      _con.getCurrentLocation();
    }
  }

  /*
  CallbackAction<Intent> onData(dynamic dto) {
    print(dtoToString(dto));
    updateMarkerAndCircle(dto.latitude, dto.longitude, markerIcon);
  }
   */

/*
  void getCurrentLocation() async {
    try {

      final Uint8List markerIcon = await Helper.getBytesFromAsset('assets/img/icon_moto.png', 70);

      var location = await _locationTracker.getLocation();

      updateMarkerAndCircle(location, markerIcon);

      if (_locationSubscription != null) {
        _locationSubscription.cancel();
      }

      _locationTracker.changeSettings(
        distanceFilter: 20
      );

      _locationSubscription = _locationTracker.onLocationChanged.listen((newLocalData) {
        if (_controller != null) {
          _controller.animateCamera(CameraUpdate.newCameraPosition(new CameraPosition(
            // bearing: 192.8334901395799,
              bearing: 90.0,
              target: LatLng(newLocalData.latitude, newLocalData.longitude),
              tilt: 0,
              zoom: 16.60)));
          updateMarkerAndCircle(newLocalData, markerIcon);
          _addGeoPoint(newLocalData.latitude, newLocalData.longitude);
        }
      });



    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        debugPrint("Permission Denied");
      }
    }
  }
 */

  void updateMarkerAndCircle(latitude, longitude, Uint8List imageData) {
    LatLng latlng = LatLng(latitude, longitude);
    this.setState(() {
      marker = Marker(
          markerId: MarkerId("home"),
          position: latlng,
          // rotation: newLocalData.heading,
          draggable: false,
          zIndex: 2,
          flat: true,
          // anchor: Offset(0.5, 0.5),
          icon: BitmapDescriptor.fromBytes(imageData));
      Marker _marker = _con.allMarkers.firstWhere(
          (marker) => marker.markerId.value == "home",
          orElse: () => null);
      if (_marker != null) _con.allMarkers.remove(_marker);
      _con.allMarkers.add(marker);
      circle = Circle(
          circleId: CircleId("car"),
          // radius: newLocalData.accuracy,
          zIndex: 1,
          strokeColor: Theme.of(context).accentColor,
          center: latlng,
          fillColor: Colors.blue.withAlpha(70));
    });

    if (_controller != null) {
      _controller
          .animateCamera(CameraUpdate.newCameraPosition(new CameraPosition(
              // bearing: 192.8334901395799,
              // bearing: 90.0,
              target: LatLng(latitude, longitude),
              tilt: 0,
              zoom: 16.60)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: _con.currentOrder?.deliveryAddress?.latitude == null
            ? new IconButton(
                icon: new Icon(Icons.sort, color: Theme.of(context).hintColor),
                onPressed: () =>
                    widget.parentScaffoldKey.currentState.openDrawer(),
              )
            : IconButton(
                icon: new Icon(Icons.arrow_back,
                    color: Theme.of(context).hintColor),
                onPressed: () => {Navigator.of(context).pop()}),
        title: Text(
          S.of(context).delivery_addresses,
          style: Theme.of(context)
              .textTheme
              .headline6
              .merge(TextStyle(letterSpacing: 1.3)),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.directions,
              color: Theme.of(context).hintColor,
            ),
            onPressed: () {
              openMap();
              // _con.goCurrentLocation();
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.loose,
        alignment: AlignmentDirectional.bottomStart,
        children: <Widget>[
          destineAddress == null
              ? SizedBox(
                  height: 0,
                )
              : FloatingActionButton(onPressed: openMap),
          _con.cameraPosition == null
              ? CircularLoadingWidget(height: 0)
              : GoogleMap(
                  mapToolbarEnabled: false,
                  mapType: MapType.normal,
                  initialCameraPosition: _con.cameraPosition,
                  markers: Set.from(_con.allMarkers),
                  onMapCreated: (GoogleMapController controller) {
                    _controller = controller;
                    _con.mapController.complete(controller);
                  },
                  onCameraMove: (CameraPosition cameraPosition) {
                    _con.cameraPosition = cameraPosition;
                  },
                  onCameraIdle: () {
                    _con.getOrdersOfArea();
                  },
                  polylines: _controllerOderDetails.polylines,
                  // markers: Set.of((marker != null) ? [marker] : []),
                  circles: Set.of((circle != null) ? [circle] : []),
                ),
          Container(
            height: 110,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            margin: EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.9),
              boxShadow: [
                BoxShadow(
                    color: Theme.of(context).focusColor.withOpacity(0.1),
                    blurRadius: 5,
                    offset: Offset(0, 2)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                _con.currentOrder?.orderStatus?.id == '5'
                    ? Container(
                        width: 60,
                        height: 70,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green.withOpacity(0.2)),
                        child: Icon(
                          Icons.check,
                          color: Colors.green,
                          size: 32,
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 70,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                Theme.of(context).hintColor.withOpacity(0.1)),
                        child: Icon(
                          Icons.update,
                          color: Theme.of(context).hintColor.withOpacity(0.8),
                          size: 30,
                        ),
                      ),
                SizedBox(width: 15),
                Flexible(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            _controllerOderDetails.distance == null
                                ? SizedBox(
                                    height: 0,
                                  )
                                : Text("Distancia: " +
                                    _controllerOderDetails.distance),
                            _controllerOderDetails.duration == null
                                ? SizedBox(
                                    height: 0,
                                  )
                                : Text("Tiempo: " +
                                    _controllerOderDetails.duration),
                            Text(
                              S.of(context).order_id +
                                  "#${_con.currentOrder.id}",
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: Theme.of(context).textTheme.subtitle1,
                            ),
                            Text(
                              _con.currentOrder.payment?.method ??
                                  S.of(context).cash_on_delivery,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: Theme.of(context).textTheme.caption,
                            ),
                            Text(
                              DateFormat('yyyy-MM-dd HH:mm')
                                  .format(_con.currentOrder.dateTime),
                              style: Theme.of(context).textTheme.caption,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Helper.getPrice(
                              Helper.getTotalOrdersPrice(_con.currentOrder),
                              context,
                              style: Theme.of(context).textTheme.headline4),
                          Text(
                            S.of(context).items +
                                    ':' +
                                    _con.currentOrder.productOrders?.length
                                        ?.toString() ??
                                0,
                            style: Theme.of(context).textTheme.caption,
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  openMap() async {
    double latitude = destineAddress.latitude;
    double longitude = destineAddress.longitude;
    String googleUrl =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunch(googleUrl)) {
      await launch(googleUrl);
    } else {
      throw 'Could not open the map.';
    }
  }
}
