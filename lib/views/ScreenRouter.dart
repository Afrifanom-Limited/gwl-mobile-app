import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/helpers/Functions.dart';
import 'package:gwcl/helpers/PageTransitions.dart';
import 'package:gwcl/system/AuthState.dart';
import 'package:gwcl/system/RestDataSource.dart';
import 'package:permission_handler/permission_handler.dart';

import 'index/Login.dart';
import 'index/Welcome.dart';

class ScreenRouter extends StatefulWidget {
  @override
  _ScreenRouterState createState() => _ScreenRouterState();
}

class _ScreenRouterState extends State<ScreenRouter>
    implements AuthStateListener {
  _ScreenRouterState() {
    var authStateProvider = new AuthStateProvider();
    authStateProvider.subscribe(this);
  }

  @override
  onAuthStateChanged(AuthState state) async {
    print("auth sate changed to $state");
    if (state == AuthState.LOGGED_IN) {
      Navigator.pushReplacement(
        context,
        FadeRoute(
          //page: Introduction(),
          // page: Home(),
          page: Login(isLoggedIn: true),
        ),
      );
    } else {
      await _registerDevice();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Welcome();
  }

  Future buildScreen() {
    return new Future.delayed(const Duration(milliseconds: 600));
  }

  _checkPermissions() async {
    try {
      var locationStatus = await Permission.location.status;
      if (locationStatus.isPermanentlyDenied) {
      } else {
        locationStatus = await Permission.location.request();
      }
      if (!locationStatus.isGranted) {}
    } catch (e) {}
  }

  _getLocation() async {
    try {
      var res = new Map<String, dynamic>();
      await _checkPermissions();
      res = await getLongLat();
      return res;
    } catch (e) {}
  }

  _registerDevice() async {
    RestDataSource _request = new RestDataSource();
    var location = await _getLocation();
    Map deviceInfo = await getDeviceInfo();
    _request
        .post(
          context,
          url: Endpoints.app_downloads_add,
          data: {
            "device_id": deviceInfo.values.toList()[0],
            "platform": deviceInfo.values.toList()[1],
            "device_brand": deviceInfo.values.toList()[3],
            "device_model": deviceInfo.values.toList()[4],
            "longitude": location != null
                ? "${location.values.toList()[0]}"
                : "",
            "latitude": location != null
                ? "${location.values.toList()[1]}"
                : "",
          },
        )
        .then((Map response) async {});
  }
}
