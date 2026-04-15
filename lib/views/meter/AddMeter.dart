import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/Buttons.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/helpers/Functions.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/MaskTextInputFormatter.dart';
import 'package:gwcl/helpers/PageTransitions.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/helpers/TextFields.dart';
import 'package:gwcl/helpers/UpperCaseTextFormatter.dart';
import 'package:gwcl/system/RestDataSource.dart';
import 'package:gwcl/templates/Dialogs.dart';
import 'package:gwcl/views/complaint/LodgeComplaint.dart';
import 'package:gwcl/views/home/Home.dart';
import 'package:gwcl/views/meter/VerifyMeterOwner.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../../mixpanel.dart';

class AddMeter extends StatefulWidget {
  static const String id = "/add_meter";
  @override
  _AddMeterState createState() => _AddMeterState();
}

class _AddMeterState extends State<AddMeter> {
  final _formKey = GlobalKey<FormState>();
  final _meterNumberController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _digitalAddressController = TextEditingController();
  final _aliasController = TextEditingController();
  bool _loading = false;
  var _longitude, _latitude;
  String _loadingState = "";
  late Timer _timer;
  int _start = 15;

  void _submitForm() async {
    FocusScope.of(context).requestFocus(FocusNode());
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      HapticFeedback.vibrate();
      return;
    } else {
      setState(() => _loading = true);
      RestDataSource _request = new RestDataSource();
      String appSignature = await SmsAutoFill().getAppSignature;
      var _meterData = {
        "meter_number": _meterNumberController.text,
        "digital_address": _digitalAddressController.text,
        "meter_alias": _aliasController.text,
        "account_number": stripSymbols(_accountNumberController.text),
        "lat": _latitude,
        "long": _longitude,
      };

      _request.post(
        context,
        url: Endpoints.meters_verify_customer,
        data: {"app_signature": appSignature, "account_number": stripSymbols(_accountNumberController.text)},
      ).then((Map response) async {
        if (mounted) setState(() => _loading = false);
        if (response[Constants.success]) {
          mixpanel?.track('Add Account Customer Success');
          _onRequestSuccess(_meterData, response[Constants.response]);
        } else {
          mixpanel?.track('Add Account Customer Failed');
          if (response[Constants.response] == "410") {
            showDialog(
              context: context,
              builder: (_) => new ConfirmDialog(
                title: "Oops!",
                content: response[Constants.message],
                confirmText: "Report",
                confirmTextColor: Constants.kPrimaryColor,
                cancelText: "Okay",
                confirm: () {
                  Navigator.pushReplacement(
                    context,
                    FadeRoute(
                      page: LodgeComplaint(
                        message: "Hello, \n${response[Constants.message]}",
                      ),
                    ),
                  );
                },
              ),
            );
          } else {
            _onRequestFailed(response[Constants.message]);
          }
        }
      });
    }
  }

  void _startTimer() {
    const oneSec = const Duration(seconds: 1);
    _timer = new Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_start == 0) {
          setState(() {
            _loading = false;
            _loadingState = "";
            _start = 10;
            _cancelTimer();
          });
          HapticFeedback.vibrate();
          showDialog(
            context: context,
            builder: (_) => ConfirmDialog(
              title: "Unable to get location",
              content: "Kindly check and ensure that your device location is turned on",
              confirmText: "Okay",
              confirmTextColor: Constants.kPrimaryColor,
              confirm: AppSettings.openLocationSettings,
            ),
          );
        } else {
          setState(() {
            _start--;
          });
        }
      },
    );
  }

  _cancelTimer() {
    try {
      _timer.cancel();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  _getLocation() async {
    var res = new Map<String, dynamic>();
    //await _checkPermissions();
    setState(() {
      _loading = true;
      _loadingState = "Getting current location...";
    });
    _startTimer();
    res = await getLongLat();
    if (mounted)
      setState(() {
        _loading = false;
        _loadingState = "";
        _longitude = "${res.values.toList()[0]}";
        _latitude = "${res.values.toList()[1]}";
      });
    _cancelTimer();
    _requestDigitalAddress(_latitude, _longitude);
  }

  void _requestDigitalAddress(dynamic lat, dynamic long) async {
    setState(() {
      _loading = true;
      _loadingState = "Requesting digital address from GhanaPostGPS...";
    });
    RestDataSource _request = new RestDataSource();
    _request.post(
      context,
      url: Endpoints.gps_get_digital_address,
      data: {
        "lat": lat,
        "long": long,
      },
    ).then((Map response) async {
      if (mounted)
        setState(() {
          _loading = false;
          _loadingState = "";
        });
      if (response[Constants.success]) {
        setState(() => _digitalAddressController.text = response[Constants.response]["digital_address"]);
      } else {
        _onRequestFailed(response[Constants.message]);
      }
    });
  }

  _checkPermissions() async {
    var locationStatus = await Permission.location.status;
    if (locationStatus.isPermanentlyDenied) {
      HapticFeedback.vibrate();
      showDialog(
        context: context,
        builder: (_) => ConfirmDialog(
          title: "Location Access Required",
          content: "Kindly go your App's settings and allow location access",
          confirmText: "Okay",
          confirmTextColor: Constants.kPrimaryColor,
          confirm: () async {
            await openAppSettings();
          },
        ),
      );
    } else {
      locationStatus = await Permission.location.request();
    }
    if (!locationStatus.isGranted) {
      HapticFeedback.vibrate();
      showDialog(
        context: context,
        builder: (_) => ConfirmDialog(
          title: "Location Access Required",
          content: "This app needs access to your device's location",
          confirmText: "Okay",
          confirmTextColor: Constants.kPrimaryColor,
          confirm: () async {
            locationStatus = await Permission.location.request();
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: _loading,
      color: Constants.kWhiteColor.withOpacity(0.8),
      opacity: 0.5,
      progressIndicator: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularLoader(
            loaderColor: Constants.kPrimaryColor,
          ),
          if (_loadingState.length > 0)
            Container(
              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
              margin: EdgeInsets.only(top: 10.h),
              color: Constants.kGreyColor,
              child: GText(
                textData: _loadingState,
                textSize: 10.sp,
                textColor: Constants.kPrimaryColor,
              ),
            )
        ],
      ),
      child: Scaffold(
        body: Stack(
          children: [
            Container(),
            SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Constants.indexHorizontalSpace,
                ),
                child: Column(children: <Widget>[
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Constants.kSizeHeight_20,
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5.w),
                          child: GText(
                            textData: "Customer Account Number *",
                            textSize: 12.sp,
                            textColor: Constants.kPrimaryColor,
                          ),
                        ),
                        Constants.kSizeHeight_5,
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5.w),
                          child: GText(
                            textData: "Enter your 12-characters Ghana Water customer"
                                " account number. An OTP code will "
                                "be sent to customer's phone number to verify ownership",
                            textSize: 10.sp,
                            textColor: Constants.kGreyColor,
                            textMaxLines: 5,
                          ),
                        ),
                        Constants.kSizeHeight_10,
                        TextFormField(
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          controller: _accountNumberController,
                          toolbarOptions: ToolbarOptions(
                            paste: true,
                            cut: true,
                            copy: true,
                            selectAll: true,
                          ),
                          textCapitalization: TextCapitalization.characters,
                          validator: (value) {
                            if (value!.length < 14) return "Invalid customer number provided";
                            return null;
                          },
                          inputFormatters: [MaskTextInputFormatter(mask: "GGGG-GGGG-GGGG")],
                          onFieldSubmitted: (v) {
                            FocusScope.of(context).nextFocus();
                          },
                          style: circularTextStyle(),
                          decoration: circularInputDecoration(
                            title: "",
                          ),
                        ),
                        Constants.kSizeHeight_20,
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5.w),
                          child: GText(
                            textData: "Alias (optional)",
                            textSize: 12.sp,
                            textColor: Constants.kPrimaryColor,
                          ),
                        ),
                        Constants.kSizeHeight_5,
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5.w),
                          child: GText(
                            textData: "For example: Kwabena Dougan's Home",
                            textSize: 10.sp,
                            textColor: Constants.kGreyColor,
                          ),
                        ),
                        Constants.kSizeHeight_10,
                        TextFormField(
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          controller: _aliasController,
                          onFieldSubmitted: (v) {
                            FocusScope.of(context).nextFocus();
                          },
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(30),
                          ],
                          style: circularTextStyle(),
                          decoration: circularInputDecoration(
                            title: "",
                          ),
                        ),
                        Constants.kSizeHeight_20,
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 5.w,
                          ),
                          child: GText(
                            textData: "Digital Address (optional)",
                            textSize: 12.sp,
                            textColor: Constants.kPrimaryColor,
                          ),
                        ),
                        Constants.kSizeHeight_5,
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              GText(
                                textData: 'Provide the digital address of your meter location ',
                                textSize: 10.sp,
                                textMaxLines: 3,
                                textColor: Constants.kGreyColor,
                              ),
                              SizedBox(height: 2.h),
                              GText(
                                textData: "Powered by GhanaPost GPS",
                                textSize: 10.sp,
                                textColor: Constants.kWarningColor,
                              ),
                            ],
                          ),
                        ),
                        Constants.kSizeHeight_10,
                        TextFormField(
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          controller: _digitalAddressController,
                          onFieldSubmitted: (v) {
                            FocusScope.of(context).nextFocus();
                          },
                          inputFormatters: <TextInputFormatter>[
                            UpperCaseTextFormatter(),
                            FilteringTextInputFormatter.allow(
                              RegExp("[a-zA-Z0-9-]"),
                            ),
                            LengthLimitingTextInputFormatter(12),
                          ],
                          style: circularTextStyle(),
                          decoration: circularInputDecoration(
                            title: "",
                            suffix: Container(
                              margin: EdgeInsets.only(right: 3.w),
                              child: buildOutlinedButton(
                                title: "Get Address",
                                bgColor: Constants.kPrimaryLightColor,
                                textColor: Constants.kPrimaryColor,
                                padding: EdgeInsets.all(1.w),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => ConfirmDialog(
                                      title: "Confirm Location",
                                      content: "Are you currently at the "
                                          "location of the water meter?",
                                      confirmText: "Yes",
                                      cancelText: "No",
                                      confirmTextColor: Constants.kPrimaryColor,
                                      confirm: () {
                                        _getLocation();
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        Constants.kSizeHeight_20,
                        buildElevatedButton(
                          title: "Add Customer Account",
                          onPressed: () {
                            _submitForm();
                          },
                        ),
                        Constants.kSizeHeight_5,
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _onRequestSuccess(dynamic meterData, dynamic resData) async {
    Navigator.pushReplacement(
      context,
      FadeRoute(
        page: VerifyMeterOwner(
          meterData: meterData,
          resData: resData,
          returnFunction: () {
            _proceedToHome();
          },
        ),
      ),
    );
  }

  _proceedToHome() {
    Navigator.of(context).pushNamedAndRemoveUntil(Home.id, (Route<dynamic> route) => false);
  }

  _onRequestFailed(dynamic errorText) async {
    showDialog(
      context: context,
      builder: (_) => ErrorDialog(
        content: errorText.toString().replaceAll(RegExp(Constants.errorFilter), ""),
      ),
    );
    // showBasicsFlash(
    //   context,
    //   errorText.toString().replaceAll(RegExp(Constants.errorFilter), ""),
    //   textColor: Constants.kWhiteColor,
    //   bgColor: Constants.kRedLightColor,
    // );
  }
}
