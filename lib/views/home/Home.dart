import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/helpers/FlashHelper.dart';
import 'package:gwcl/helpers/Functions.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/models/AppInfo.dart';
import 'package:gwcl/system/LocalDatabase.dart';
import 'package:gwcl/system/RestDataSource.dart';
import 'package:gwcl/templates/CustomBadge.dart';
import 'package:gwcl/templates/Dialogs.dart';
import 'package:gwcl/templates/FloatingNavbar.dart';
import 'package:gwcl/views/home/HomeContent.dart';
import 'package:gwcl/views/home/HomeDrawer.dart';
import 'package:gwcl/views/info/Help.dart';
import 'package:gwcl/views/notifications/Notifications.dart';
import 'package:gwcl/views/settings/Settings.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mixpanel.dart';

class Home extends StatefulWidget {
  static const String id = "/home";
  final int index;
  final String? message;

  const Home({Key? key, this.index = 0, this.message}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  RestDataSource _request = new RestDataSource();
  final _advancedDrawerController = AdvancedDrawerController();
  int _index = 0, _notificationCount = 0;
  bool _loading = false;
  var _customer;
  late AppInfo _appInfo;

  _routeToPage() async {
    await _loadCustomerInfo();
    if (mounted && _customer != null) setState(() => _index = widget.index);
    _displayMessage();
  }

  Widget _loadContent() {
    Widget _widget;
    switch (_index) {
      case 0:
        _widget = HomeContent(customer: _customer);
        break;
      case 1:
        _widget = Help(customer: _customer);
        break;
      case 2:
        _widget = Settings(customer: _customer);
        break;
      default:
        _widget = HomeContent(customer: _customer);
        break;
    }
    return _widget;
  }

  _displayMessage() {
    if (mounted) {
      if (widget.message != null) {
        showBasicsFlash(context, widget.message, textColor: Constants.kAccentColor, bgColor: Constants.kWhiteColor);
      }
    }
  }

  _getAppInfo() {
    _request.get(context, url: Endpoints.app_info_view.replaceFirst("{id}", "${Constants.appId}")).then((Map response) async {
      try {
        if (response[Constants.success]) {
          SharedPreferences _localStorage = await SharedPreferences.getInstance();
          _localStorage.setString(Constants.paymentPercentageCharge, "0.00");
          _appInfo = AppInfo.map(response[Constants.response]);
          _checkForUpdate();
        }
      } catch (e) {}
    });
  }

  _checkForNotifications() {
    try {
      Timer.periodic(Duration(seconds: 15), (Timer t) {
        if (mounted) {
          _request.get(context, url: Endpoints.notifications_check_numbers).then((Map response) async {
            try {
              if (response[Constants.success]) {
                setState(() => _notificationCount = response[Constants.response]['notifications']);
              }
            } catch (e) {}
          });
        }
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  _checkForUpdate() async {
    Map packageInfo = await getDevicePackageInfo();
    double newVersion;
    double currentVersion = double.parse(packageInfo.values.toList()[2].trim().replaceAll(".", ""));
    if (Platform.isAndroid) {
      newVersion = double.parse(_appInfo.minAndroidVersion.trim().replaceAll(".", ""));
    } else {
      newVersion = double.parse(_appInfo.minIosVersion.trim().replaceAll(".", ""));
    }
    if (newVersion > currentVersion) {
      showVersionDialog(context, _appInfo.byForceUpdate.toString());
    }
  }

  @override
  void initState() {
    _loadCustomerInfo();
    _routeToPage();
    super.initState();
    _getAppInfo();
    _checkForNotifications();
  }

  @override
  void dispose() {
    super.dispose();
  }

  _loadCustomerInfo() async {
    var _localDb = new LocalDatabase();
    _customer = await _localDb.getCustomer();
    if (mounted) {
      _subscribeCustomerToNotificationService(_customer["phone_number"]);
      mixpanel?.track('View Landing Page');
    }
  }

  _subscribeCustomerToNotificationService(String phoneNumber) async {
    FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
    // On iOS, FCM topic subscription requires APNs token to be available first.
    if (Platform.isIOS) {
      final apnsToken = await firebaseMessaging.getAPNSToken();
      if (apnsToken == null || apnsToken.isEmpty) return;
    }
    await firebaseMessaging.subscribeToTopic(phoneNumber);
    await firebaseMessaging.subscribeToTopic(Constants.appId);
  }

  void _handleMenuButtonPressed() {
    // NOTICE: Manage Advanced Drawer state through the Controller.
    // _advancedDrawerController.value = AdvancedDrawerValue.visible();
    _advancedDrawerController.showDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: _loading,
      color: Constants.kWhiteColor.withValues(alpha: 0.8),
      opacity: 0.5,
      progressIndicator: CircularLoader(
        loaderColor: Constants.kPrimaryColor,
      ),
      child: AdvancedDrawer(
        backdropColor: Constants.kPrimaryColor.withValues(alpha: 0.7),
        controller: _advancedDrawerController,
        openRatio: 0.70,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        childDecoration: const BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
        ),
        drawer: HomeDrawer(),
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(70.h),
            child: Container(
              color: Constants.kPrimaryColor,
              child: AppBar(
                systemOverlayStyle: SystemUiOverlayStyle(
                  statusBarIconBrightness: Brightness.dark, // For Android (dark icons)
                  statusBarBrightness: Brightness.light, // For iOS (dark icons)
                ),
                elevation: 0,
                automaticallyImplyLeading: false,
                flexibleSpace: Container(
                  margin: EdgeInsets.only(top: 10.h),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        flex: 5,
                        child: Builder(builder: (BuildContext context) {
                          return Row(
                            children: [
                              Padding(
                                padding: EdgeInsets.only(left: 10.w),
                                child: IconButton(
                                  onPressed: _handleMenuButtonPressed,
                                  iconSize: 24.sp,
                                  icon: ValueListenableBuilder<AdvancedDrawerValue>(
                                    valueListenable: _advancedDrawerController,
                                    builder: (context, value, child) {
                                      return Icon(value.visible ? Icons.clear : Icons.menu);
                                    },
                                  ),
                                ),
                              ),
                              Image.asset(
                                "assets/images/logo.png",
                                fit: BoxFit.contain,
                                height: 50,
                              ),
                            ],
                          );
                        }),
                      ),
                      Expanded(
                        child: Builder(builder: (BuildContext context) {
                          return CustomBadge(
                            iconData: Icons.notifications_outlined,
                            alertCount: _notificationCount,
                            onTap: () {
                              Navigator.pushNamed(context, Notifications.id);
                            },
                          );
                        }),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: _loadContent(),
          bottomNavigationBar: FloatingNavbar(
            onTap: (int val) {
              HapticFeedback.lightImpact();
              setState(() => _index = val);
            },
            currentIndex: _index,
            backgroundColor: Colors.grey.shade100,
            unselectedItemColor: Constants.kGreyColor,
            selectedBackgroundColor: Constants.kPrimaryColor,
            selectedItemColor: Constants.kWhiteColor,
            elevation: 0,
            items: [
              FloatingNavbarItem(icon: Icons.home_filled, title: 'Home'),
              FloatingNavbarItem(icon: Icons.question_answer_outlined, title: 'Help'),
              FloatingNavbarItem(icon: Icons.settings_sharp, title: 'Settings'),
            ],
          ),
        ),
      ),
    );
  }
}

Future payBillOptionIos(BuildContext context) async {
  return await showCupertinoModalPopup(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return CupertinoActionSheet(
        title: GText(
          textData: "Choose an option",
          textSize: 14.sp,
        ),
        actions: <Widget>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context, Constants.mySelf);
            },
            isDefaultAction: true,
            child: GText(
              textData: "My Account",
              textSize: 14.sp,
              textColor: Constants.kPrimaryColor,
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context, Constants.others);
            },
            isDefaultAction: true,
            child: GText(
              textData: "Pay for Others",
              textSize: 14.sp,
              textColor: Constants.kPrimaryColor,
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.of(context).pop();
          },
          isDefaultAction: true,
          child: GText(
            textData: "Cancel",
            textSize: 14.sp,
            textColor: Constants.kRedColor,
          ),
        ),
      );
    },
  );
}

Future payBillOptionAndroid(BuildContext context) async {
  return await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: GText(
          textData: "Choose an option",
          textSize: 14.sp,
          textAlign: TextAlign.center,
        ),
        children: <Widget>[
          Divider(color: Constants.kPrimaryColor),
          SimpleDialogOption(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            onPressed: () {
              Navigator.pop(context, Constants.mySelf);
            },
            child: GText(
              textData: "My Account",
              textSize: 14.sp,
              textColor: Constants.kPrimaryColor,
              textAlign: TextAlign.center,
            ),
          ),
          Divider(color: Constants.kPrimaryColor),
          SimpleDialogOption(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            onPressed: () {
              Navigator.pop(context, Constants.others);
            },
            child: GText(
              textData: "Pay for Others",
              textSize: 14.sp,
              textColor: Constants.kPrimaryColor,
              textAlign: TextAlign.center,
            ),
          ),
          Divider(color: Constants.kPrimaryColor),
          SimpleDialogOption(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: GText(
              textData: "Cancel",
              textSize: 14.sp,
              textColor: Constants.kRedColor,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    },
  );
}
