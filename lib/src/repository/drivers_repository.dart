import 'dart:convert';
import 'dart:io';

import 'package:global_configuration/global_configuration.dart';
import 'package:http/http.dart' as http;
import '../models/address.dart';
import 'settings_repository.dart';

import '../models/user.dart';
import '../repository/user_repository.dart' as userRepo;

void sendCurrentLocation() async {
  User _user = userRepo.currentUser.value;
  if (_user.apiToken == null) return;

  Address currentAddress = await setCurrentLocation();
  final String _apiToken = 'api_token=${_user.apiToken}';
  final String url = '${GlobalConfiguration().getString('api_base_url')}drivers/${_user.id}?$_apiToken';
  final client = new http.Client();
  var addressJson = json.encode(currentAddress.toMap());
  final response = await client.put(
    url,
    headers: {HttpHeaders.contentTypeHeader: 'application/json'},
    body: addressJson,
  );
}

