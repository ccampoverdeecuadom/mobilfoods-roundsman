import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:roundsman/src/elements/AvailableOrderItemWidget.dart';
import 'package:roundsman/src/models/route_argument.dart';
import 'package:roundsman/src/repository/user_repository.dart';
import 'package:mvc_pattern/mvc_pattern.dart';

import '../../generated/l10n.dart';
import '../controllers/order_controller.dart';
import '../elements/EmptyOrdersWidget.dart';

class AvailableOrdersWidget extends StatefulWidget {
  final GlobalKey<ScaffoldState> parentScaffoldKey;

  AvailableOrdersWidget({Key key, this.parentScaffoldKey}) : super(key: key);

  @override
  _AvailableOrdersWidgetState createState() => _AvailableOrdersWidgetState();
}

class _AvailableOrdersWidgetState extends StateMVC<AvailableOrdersWidget> {
  OrderController _con;
  bool isActive;

  _AvailableOrdersWidgetState() : super(OrderController()) {
    _con = controller;
  }

  @override
  void initState() {
    isActive = currentUser.value.active;
    _con.availableOrders.clear();
    _con.listenForOrders();
    _con.listenForAvailableOrders();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _con.scaffoldKey,
      appBar: AppBar(
        leading: new IconButton(
          icon: new Icon(Icons.sort, color: Theme
              .of(context)
              .hintColor),
          onPressed: () => widget.parentScaffoldKey.currentState.openDrawer(),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          S
              .of(context)
              .available_orders,
          style: Theme
              .of(context)
              .textTheme
              .headline6
              .merge(TextStyle(letterSpacing: 1.3)),
        ),
        actions: <Widget>[
          FlutterSwitch(
            activeColor: Theme.of(context).accentColor,
            activeText: 'Activo',
            inactiveText: 'Inactivo',
            width: 135.0,
            height: 40.0,
            toggleSize: 20.0,
            valueFontSize: 15.0,
            value: isActive,
            borderRadius: 30.0,
            padding: 8.0,
            showOnOff: true,
            onToggle: (val) {
              setState(() {
                isActive = val;
                currentUser.value.active = val;
                if(val) {
                  _con.availableOrders.clear();
                  _con.listenForAvailableOrders(active: val);}
                else _con.availableOrders.clear();
                _con.setDriverState(val);
              });
            },
          ),
        /*
          new ShoppingCartButtonWidget(iconColor: Theme
              .of(context)
              .hintColor, labelColor: Theme
              .of(context)
              .accentColor),

         */
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _con.refreshAvailableOrders,
        child:
        ListView(
          padding: EdgeInsets.symmetric(vertical: 10),
          children: <Widget>[
            _con.availableOrders.isEmpty ? EmptyOrdersWidget():
            _con.orderAssigned ?
            Text(
              S.of(context).you_already_have_an_assigned_order,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headline4,
            ) : SizedBox(height: 0,),
            SizedBox(height: 20,),
            ListView.separated(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              primary: false,
              itemCount: _con.availableOrders.length,
              itemBuilder: (context, index) {
                var _order = _con.availableOrders.elementAt(index);
                return AvailableOrderItemWidget(
                    expanded: true, order: _order, orderAccepted: orderAccepted, orderAssigned: _con.orderAssigned,);
              },
              separatorBuilder: (context, index) {
                return SizedBox(height: 20);
              },
            ),
          ],
        ),
      ),
    );
  }


  orderAccepted(dynamic accepted, orderId) {
    if(accepted) {
      _con.availableOrders.clear();
      _con.listenForAvailableOrders();
      Navigator.of(context).pushReplacementNamed('/Pages', arguments: 2);
      Navigator.of(context).pushNamed('/OrderDetails', arguments: RouteArgument(id: orderId));
    } else {
      setState(() {
        _con.availableOrders.clear();
      });
      Fluttertoast.showToast(
        msg: "Se asignó a otro Repartidor!",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        backgroundColor: Theme.of(context).errorColor,
//      textColor: Theme.of(context).hintColor,
        timeInSecForIosWeb: 5,
      );
      _con.listenForAvailableOrders(active: true);
    }
  }

}
