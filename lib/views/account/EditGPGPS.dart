import 'dart:async';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gwcl/helpers/Buttons.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/helpers/Functions.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/TextFields.dart';
import 'package:gwcl/helpers/UpperCaseTextFormatter.dart';
import 'package:gwcl/models/Customer.dart';
import 'package:gwcl/system/LocalDatabase.dart';
import 'package:gwcl/system/RestDataSource.dart';
import 'package:gwcl/templates/AppHeaders.dart';
import 'package:gwcl/templates/Dialogs.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:permission_handler/permission_handler.dart';

class EditGPGPS extends StatefulWidget {
  static const String id = "/edit_gpgps";
  final String? gpgps;

  const EditGPGPS({Key? key, this.gpgps}) : super(key: key);
  @override
  _EditGPGPSState createState() => _EditGPGPSState();
}

class _EditGPGPSState extends State<EditGPGPS> {
  final _formKey = GlobalKey<FormState>();
  final _digitalAddressController = TextEditingController();
  bool _loading = false;
  late Customer _customerData;
  var _longitude, _latitude;
  String _loadingState = "";
  late Timer _timer;
  int _start = 15;

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
              content:
                  "Kindly check and ensure that your device location is turned on",
              confirmText: "Okay",
              confirmTextColor: Constants.kPrimaryColor,
              confirm: () {
                AppSettings.openAppSettings(type: AppSettingsType.location);
              },
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

  @override
  void initState() {
    if (widget.gpgps != null && widget.gpgps.toString().toLowerCase() != 'null')
      _digitalAddressController.text = widget.gpgps!;
    super.initState();
  }

  _getLocation() async {
    var res = new Map<String, dynamic>();
   // await _checkPermissions();
    setState(() {
      _loading = true;
      _loadingState = "Getting current location... ";
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
        setState(() => _digitalAddressController.text =
            response[Constants.response]["digital_address"]);
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

  _cancelTimer() {
    try {
      _timer.cancel();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  void _submitForm() async {
    FocusScope.of(context).requestFocus(FocusNode());
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      HapticFeedback.vibrate();
      return;
    } else if (_digitalAddressController.text == widget.gpgps) {
      setState(() => _loading = true);
      await Future.delayed(const Duration(seconds: 1), () {
        setState(() => _loading = false);
        Navigator.pop(context, true);
      });
    } else {
      setState(() => _loading = true);
      RestDataSource _request = new RestDataSource();
      _request.post(
        context,
        url: Endpoints.customers_editgpgps,
        data: {
          "digital_address": _digitalAddressController.text,
          "lat": _latitude,
          "long": _longitude,
        },
      ).then((Map response) async {
        if (mounted) setState(() => _loading = false);
        if (response[Constants.success]) {
          _customerData = Customer.map(response[Constants.response]);
          _onRequestSuccess(_customerData);
        } else {
          _onRequestFailed(response[Constants.message]);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: _loading,
      color: Constants.kWhiteColor.withValues(alpha: 0.8),
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
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(70.h),
          child: Container(
            color: Constants.kPrimaryColor,
            child: GeneralHeader(
              title: "Add/Change GPGPS",
            ),
          ),
        ),
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                    image: Constants.kBgTwo,
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.linearToSrgbGamma()),
              ),
            ),
            SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Constants.indexHorizontalSpace,
                  vertical: Constants.indexVerticalSpace,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Constants.kSizeHeight_10,
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5.w),
                            child: GText(
                              textData: "Ghana Post Digital Address *",
                              textSize: 12.sp,
                              textColor: Constants.kPrimaryColor,
                            ),
                          ),
                          Constants.kSizeHeight_5,
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5.w),
                            child: GText(
                              textData: 'Kindly provide your digital address',
                              textSize: 10.sp,
                              textColor: Constants.kGreyColor,
                              textMaxLines: 3,
                            ),
                          ),
                          Constants.kSizeHeight_10,
                          TextFormField(
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.next,
                            controller: _digitalAddressController,
                            validator: (value) =>
                                checkNull(value!, "Digital Address"),
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
                              title: "Digital Address",
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
                                            "location of your home, apartment or office?",
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
                          // Container(
                          //   decoration: BoxDecoration(
                          //       borderRadius:
                          //           BorderRadius.all(Radius.circular(20.w))),
                          //   child: Padding(
                          //     padding: EdgeInsets.symmetric(
                          //         horizontal: 45.w, vertical: 5.h),
                          //     child: Column(
                          //       crossAxisAlignment: CrossAxisAlignment.stretch,
                          //       children: [
                          //         buildTextButton(
                          //           title: "Tap here for Digital Address",
                          //           textColor: Constants.kPrimaryColor,
                          //           textSize: 13.sp,
                          //           onPressed: () {
                          //             showDialog(
                          //               context: context,
                          //               builder: (_) => ConfirmDialog(
                          //                 title: "Confirm Location",
                          //                 content: "Are you currently at the "
                          //                     "location of your home, apartment or office?",
                          //                 confirmText: "Yes",
                          //                 cancelText: "No",
                          //                 confirmTextColor:
                          //                     Constants.kPrimaryColor,
                          //                 confirm: () {
                          //                   _getLocation();
                          //                 },
                          //               ),
                          //             );
                          //           },
                          //         ),
                          //         Center(
                          //           child: GText(
                          //             textData: "Powered by GhanaPost GPS",
                          //             textSize: 8.sp,
                          //             textColor: Constants.kWarningColor,
                          //           ),
                          //         ),
                          //       ],
                          //     ),
                          //   ),
                          // ),
                          Constants.kSizeHeight_20,
                          buildElevatedButton(
                            title: "Submit",
                            onPressed: () {
                              _submitForm();
                            },
                          ),
                        ],
                      ),
                    ),
                    Constants.kSizeHeight_20,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _onRequestSuccess(Customer customer) async {
    var _localDb = new LocalDatabase();
    await _localDb.updateCustomer(customer);
    Navigator.pop(context, true);
  }

  _onRequestFailed(dynamic errorText) async {
    showDialog(
      context: context,
      builder: (_) => ErrorDialog(
        content:
            errorText.toString().replaceAll(RegExp(Constants.errorFilter), ""),
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
