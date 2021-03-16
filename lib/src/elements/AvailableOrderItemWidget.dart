import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:mvc_pattern/mvc_pattern.dart';
import 'package:roundsman/src/controllers/order_controller.dart';

import '../../generated/l10n.dart';
import '../helpers/helper.dart';
import '../models/order.dart';
import '../models/route_argument.dart';
import 'ProductOrderItemWidget.dart';

class AvailableOrderItemWidget extends StatefulWidget {
  final bool expanded;
  final Order order;
  final bool orderAssigned;
  final void Function(dynamic, dynamic) orderAccepted;

  AvailableOrderItemWidget(
      {Key key, this.expanded, this.order, this.orderAccepted, this.orderAssigned})
      : super(key: key);

  @override
  _AvailableOrderItemWidgetState createState() =>
      _AvailableOrderItemWidgetState();
}

class _AvailableOrderItemWidgetState
    extends StateMVC<AvailableOrderItemWidget> {
  OrderController _con;
  bool accepted;
  String statusRequest = "Aceptar";

  _AvailableOrderItemWidgetState() : super(OrderController()) {
    _con = controller;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).copyWith(dividerColor: Colors.transparent);
    return Stack(
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(top: 14),
              padding: EdgeInsets.only(top: 20, bottom: 5),
              decoration: BoxDecoration(
                color: Theme
                    .of(context)
                    .primaryColor
                    .withOpacity(0.9),
                boxShadow: [
                  BoxShadow(
                      color: Theme
                          .of(context)
                          .focusColor
                          .withOpacity(0.1),
                      blurRadius: 5,
                      offset: Offset(0, 2)),
                ],
              ),
              child: Theme(
                data: theme,
                child: ExpansionTile(
                  initiallyExpanded: widget.expanded,
                  title: Column(
                    children: <Widget>[
                      Text('${S
                          .of(context)
                          .order_id}: #${widget.order.id}'),
                      Text(
                        DateFormat('dd-MM-yyyy | HH:mm')
                            .format(widget.order.dateTime),
                        style: Theme
                            .of(context)
                            .textTheme
                            .caption,
                      ),
                    ],
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                  ),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Helper.getPrice(
                          Helper.getTotalOrdersPrice(widget.order), context,
                          style: Theme
                              .of(context)
                              .textTheme
                              .headline4),
                    ],
                  ),
                  children: <Widget>[
                    Column(
                        children: List.generate(
                          widget.order.productOrders.length,
                              (indexProduct) {
                            return ProductOrderItemWidget(
                                heroTag: 'mywidget.orders',
                                order: widget.order,
                                productOrder: widget.order.productOrders
                                    .elementAt(indexProduct));
                          },
                        )),
                    Padding(
                      padding:
                      EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  S
                                      .of(context)
                                      .delivery_fee,
                                  style: Theme
                                      .of(context)
                                      .textTheme
                                      .bodyText1,
                                ),
                              ),
                              Helper.getPrice(widget.order.deliveryFee, context,
                                  style: Theme
                                      .of(context)
                                      .textTheme
                                      .subtitle1)
                            ],
                          ),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  '${S
                                      .of(context)
                                      .tax} (${widget.order.tax}%)',
                                  style: Theme
                                      .of(context)
                                      .textTheme
                                      .bodyText1,
                                ),
                              ),
                              Helper.getPrice(
                                  Helper.getTaxOrder(widget.order), context,
                                  style: Theme
                                      .of(context)
                                      .textTheme
                                      .subtitle1)
                            ],
                          ),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  S
                                      .of(context)
                                      .total,
                                  style: Theme
                                      .of(context)
                                      .textTheme
                                      .bodyText1,
                                ),
                              ),
                              Helper.getPrice(
                                  Helper.getTotalOrdersPrice(widget.order),
                                  context,
                                  style: Theme
                                      .of(context)
                                      .textTheme
                                      .headline4)
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            Container(
              child: Wrap(
                alignment: WrapAlignment.end,
                children: <Widget>[
                  FlatButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/AvailableOrderDetails',
                          arguments: RouteArgument(id: widget.order.id));
                    },
                    textColor: Theme
                        .of(context)
                        .hintColor,
                    child: Wrap(
                      children: <Widget>[
                        Text(S
                            .of(context)
                            .viewDetails),
                        Icon(Icons.keyboard_arrow_right)
                      ],
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
        Container(
            margin: EdgeInsetsDirectional.only(start: 20),
            padding: EdgeInsets.symmetric(horizontal: 10),
            height: 28,
            width: 140,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(100)),
                color: Theme
                    .of(context)
                    .accentColor),
            alignment: AlignmentDirectional.center,
            child: GestureDetector(
              onTap: () async =>
              {
                  if (!widget.orderAssigned)
                    {
                      setState(() => {statusRequest = "Solicitando"}),
                       accepted = await _con.requestToAcceptOrder(widget.order.id),
                      accepted = true,
                       widget.orderAccepted(accepted, widget.order.id)
                    }
                  else
                    {
                      Fluttertoast.showToast(
                        msg: S
                            .of(context)
                            .you_already_have_an_assigned_order,
                        toastLength: Toast.LENGTH_LONG,
                        gravity: ToastGravity.TOP,
                        backgroundColor: Theme
                            .of(context)
                            .errorColor,
//      textColor: Theme.of(context).hintColor,
                        timeInSecForIosWeb: 10,
                      )
                    }

              },
              child: Text(
                statusRequest,
                maxLines: 1,
                style: Theme
                    .of(context)
                    .textTheme
                    .caption
                    .merge(TextStyle(
                    height: 1, color: Theme
                    .of(context)
                    .primaryColor)),
              ),
            )),
      ],
    );
  }
}
