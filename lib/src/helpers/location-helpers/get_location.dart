import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';




class GetLocationWidget extends StatefulWidget {
  const GetLocationWidget({Key key}) : super(key: key);

  @override
  _GetLocationState createState() => _GetLocationState();
}

class _GetLocationState extends State<GetLocationWidget> {
  Location location = Location();

  LocationData _location;
  String _error;

  Future<void> _getLocation() async {
    setState(() {
      _error = null;
    });
    try {
      LocationData _locationResult = await location.getLocation();
      setState(() {
        _location = _locationResult;
      });
    } on Exception catch (err) {
      print(err);
      setState(() {

      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Location: ' + (_error ?? '${_location ?? "unknown"}'),
          style: Theme.of(context).textTheme.bodyText1,
        ),
        Row(
          children: <Widget>[
            ElevatedButton(
              child: const Text('Get'),
              onPressed: _getLocation,
            )
          ],
        ),
      ],
    );
  }
}
