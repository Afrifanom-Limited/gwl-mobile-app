import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gwcl/helpers/AES.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/helpers/Functions.dart';
import 'package:gwcl/models/Customer.dart';
import 'package:gwcl/system/Network.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RestDataSource {
  NetworkUtil _netUtil = new NetworkUtil();
  dynamic _success = false;
  dynamic _message, _response;
  var authToken = "", appVersion = "";
  Customer? _customerData;

  _getAuthToken() async {
    Map packageInfo = await getDevicePackageInfo();
    SharedPreferences _localStorage = await SharedPreferences.getInstance();
    var _token = _localStorage.getString(Constants.token);
    if (_token != null) {
      this.authToken = _token;
    }
    this.appVersion = packageInfo.values.toList()[2].toString().trim().replaceAll(".", "");
  }

  Future<Map<dynamic, dynamic>> login(
    BuildContext context, {
    required String phoneNumber,
    required String password,
  }) async {
    await _getAuthToken();
    return _netUtil
        .post(Endpoints.login, authToken, context,
            body: {
              "username": phoneNumber,
              "password": password,
            },
            appVersion: appVersion)
        .then((dynamic res) async {
      _success = res[Constants.success];
      _message = res[Constants.message];
      _response = res[Constants.response];
      if (res[Constants.success] == true) {
        SharedPreferences _localStorage = await SharedPreferences.getInstance();
        // Encrypt password
        var _encryptedPass = await Aes.encrypt(password);
        // Save credentials
        _localStorage.setString(Constants.token, res[Constants.response]['token']);
        _localStorage.setString(Constants.localAuthKey, _encryptedPass);
        _localStorage.setString(Constants.localAuthPhone, res[Constants.response]["user"]["phone_number"]);
      }
      _customerData = (res[Constants.success] == true) ? Customer.map(res[Constants.response]["user"]) : null;
      var map = new Map<String, dynamic>();
      map[Constants.success] = _success;
      map[Constants.message] = _message;
      map[Constants.response] = res[Constants.success] == true ? _customerData : _message;
      return map;
    });
  }

  Future<Map<dynamic, dynamic>> register(
    BuildContext context, {
    required String name,
    required String phoneNumber,
    required String deviceId,
    required String devicePlatform,
    required String password,
    required String appSignature,
  }) async {
    await _getAuthToken();
    return _netUtil
        .post(Endpoints.register, authToken, context,
            body: {"name": name, "phone_number": phoneNumber, "device_id": deviceId, "device_platform": devicePlatform, "password": password, "app_signature": appSignature}, appVersion: appVersion)
        .then((dynamic res) async {
      _success = res[Constants.success];
      _message = res[Constants.message];
      _response = res[Constants.response];
      if (res[Constants.success] == true) {
        SharedPreferences _localStorage = await SharedPreferences.getInstance();
        // Encrypt password
        var _encryptedPass = await Aes.encrypt(password);
        // Save credentials
        _localStorage.setString(Constants.token, res[Constants.response]['token']);
        _localStorage.setString(Constants.localAuthKey, _encryptedPass);
        _localStorage.setString(Constants.localAuthPhone, res[Constants.response]["user"]["phone_number"]);
      }
      _customerData = (res[Constants.success] == true) ? Customer.map(res[Constants.response]["user"]) : null;
      var map = new Map<String, dynamic>();
      map[Constants.success] = _success;
      map[Constants.message] = _message;
      map[Constants.response] = res[Constants.success] == true ? _customerData : _message;
      return map;
    });
  }

  Future<Map<dynamic, dynamic>> post(BuildContext context, {url, data}) async {
    await _getAuthToken();
    return _netUtil.post(url, authToken, context, body: data, appVersion: appVersion).then((dynamic res) async {
      _success = res[Constants.success];
      _message = res[Constants.message];
      _response = res[Constants.response];
      var map = new Map<String, dynamic>();
      map[Constants.success] = _success;
      map[Constants.message] = _message;
      map[Constants.response] = _response;
      return res;
    });
  }

  Future<Map<dynamic, dynamic>> get(BuildContext context, {url, queryParams}) async {
    await _getAuthToken();
    return _netUtil.get(url, authToken, context, queryParams: queryParams, appVersion: appVersion).then((dynamic res) async {
      _success = res[Constants.success];
      _message = res[Constants.message];
      _response = res[Constants.response];
      var map = new Map<String, dynamic>();
      map[Constants.success] = _success;
      map[Constants.message] = _message;
      map[Constants.response] = _response;
      return res;
    });
  }

  Future<Map<dynamic, dynamic>> getRaw(BuildContext context, {url, queryParams}) async {
    await _getAuthToken();
    return _netUtil.get(url, authToken, context, queryParams: queryParams, appVersion: appVersion).then((dynamic res) async {
      return res;
    });
  }

  Future<Map<dynamic, dynamic>> postFile(BuildContext context, {required String url, List<File> files = const [], data}) async {
    await _getAuthToken();
    return _netUtil.upload(url, authToken, context, files: files, body: data, appVersion: appVersion).then((dynamic res) async {
      _success = res[Constants.success];
      _message = res[Constants.message];
      _response = res[Constants.response];
      var map = new Map<String, dynamic>();
      map[Constants.success] = _success;
      map[Constants.message] = _message;
      map[Constants.response] = _response;
      return res;
    });
  }
}
