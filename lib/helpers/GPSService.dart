// ignore_for_file: prefer_const_constructors, avoid_print, constant_identifier_names

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class GPSLocation {
  StreamSubscription<Position>? locationSubscription;
  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;

  Position? currentLocation;
  Future<GPSLocationError> requestLocationServicePermission() async {
    bool serviceEnabled;
    LocationPermission permission;
    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return GPSLocationError.ServiceNotEnabled;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.

        return GPSLocationError.PermissionNotGranted;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return GPSLocationError.PermissionNotGranted;
    }

    return GPSLocationError.None;
  }

  Future<void> initGPSLocationService() async {
    GPSLocationError status = await requestLocationServicePermission();
    if (status == GPSLocationError.PermissionNotGranted) {
      return openAppSettings();
    }

    if (status == GPSLocationError.ServiceNotEnabled) {
      return openLocationSettings();
    }
  }

  void initStreams() {
    try {
      if (locationSubscription == null) {
        final LocationSettings locationSettings;
        if (defaultTargetPlatform == TargetPlatform.android) {
          locationSettings = AndroidSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 1,
            //forceLocationManager: false,
            intervalDuration: const Duration(seconds: 5),
            //foregroundNotificationConfig: notificationConfig,
          );
        } else if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
          locationSettings = AppleSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            activityType: ActivityType.automotiveNavigation,
            distanceFilter: 2,
            pauseLocationUpdatesAutomatically: true,
            showBackgroundLocationIndicator: true,
          );
        } else {
          locationSettings = const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 2,
          );
        }
        locationSubscription = _geolocatorPlatform.getPositionStream(locationSettings: locationSettings).listen((Position? position) {
          if (position != null) {
            currentLocation = position;
          }
        });
      } else {
        locationSubscription?.resume();
      }
    } catch (ex) {
      print(ex);
    }
  }

  void cancelStream() {
    try {
      if (locationSubscription != null) {
        locationSubscription?.cancel();
        locationSubscription = null;
      }
    } catch (ex) {
      print(ex);
    }
  }

  Future<Position?> getCurrentLocation() async {
    try {
      requestLocationServicePermission();
      var location = await _geolocatorPlatform.getCurrentPosition();
      return location;
    } catch (ex) {
      debugPrint("Location Service Permission ${ex.toString()}");
    }

    try {
      var location = await _geolocatorPlatform.getLastKnownPosition();
      return location;
    } catch (ex) {
      debugPrint("Location Service Permission ${ex.toString()}");
    }
    return currentLocation;
  }

  void openAppSettings() async {
    await _geolocatorPlatform.openAppSettings();
  }

  void openLocationSettings() async {
    await _geolocatorPlatform.openLocationSettings();
  }
}

enum GPSLocationError { ServiceNotEnabled, PermissionNotGranted, None }
