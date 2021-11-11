import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:roundsman/src/repository/user_repository.dart';
import 'package:mvc_pattern/mvc_pattern.dart';

import '../../generated/l10n.dart';
import '../controllers/order_controller.dart';
import '../elements/EmptyOrdersWidget.dart';
import '../elements/OrderItemWidget.dart';
import '../elements/ShoppingCartButtonWidget.dart';

class OrdersWidget extends StatefulWidget {
  final GlobalKey<ScaffoldState> parentScaffoldKey;

  OrdersWidget({Key key, this.parentScaffoldKey}) : super(key: key);

  @override
  _OrdersWidgetState createState() => _OrdersWidgetState();
}

class _OrdersWidgetState extends StateMVC<OrdersWidget> {
  OrderController _con;
  bool isActive;

  _OrdersWidgetState() : super(OrderController()) {
    _con = controller;
  }

  @override
  void initState() {
    isActive = currentUser.value.active;
    _con.orders.clear();
    _con.listenForOrders();
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
              .accepted_orders,
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
                  _con.listenForAvailableOrders(active: val);
                }
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
        child: ListView(
          padding: EdgeInsets.symmetric(vertical: 10),
          children: <Widget>[
            _con.orders.isEmpty
                ? EmptyOrdersWidget()
                : ListView.separated(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              primary: false,
              itemCount: _con.orders.length,
              itemBuilder: (context, index) {
                var _order = _con.orders.elementAt(index);
                return OrderItemWidget(
                    expanded: index == 0 ? true : false, order: _order);
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


}
