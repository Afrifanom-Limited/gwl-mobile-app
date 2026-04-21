import 'package:flutter/material.dart';
import 'package:flutter_countdown_timer/index.dart';
import 'package:gwcl/helpers/Buttons.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/models/Meter.dart';
import 'package:gwcl/system/LocalDatabase.dart';
import 'package:gwcl/system/RestDataSource.dart';
import 'package:gwcl/templates/AppHeaders.dart';
import 'package:gwcl/templates/Dialogs.dart';
import 'package:gwcl/views/home/Home.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:sms_autofill/sms_autofill.dart';

class VerifyMeterOwner extends StatefulWidget {
  final dynamic meterData;
  final dynamic resData;
  final Function returnFunction;

  const VerifyMeterOwner(
      {Key? key,
      required this.meterData,
      required this.resData,
      required this.returnFunction})
      : super(key: key);

  @override
  _VerifyMeterOwnerState createState() => _VerifyMeterOwnerState();
}

class _VerifyMeterOwnerState extends State<VerifyMeterOwner> {
  late CountdownTimerController _countdownTimerController;
  int endTime = DateTime.now().millisecondsSinceEpoch + 1000 * 1800;

  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _loading = false, _canVerify = true;
  late Meter _meter;

  late String _mobile_1, _mobile_2, _email_1;

  String _hideSomeCharactersPhone(String number) {
    var re = RegExp(r'\d{8}');
    return number.replaceFirst(re, '********');
  }

  String _hideSomeCharactersEmail(String email) {
    var re = RegExp(r'(?<=.{1}).(?=.*@)');
    return email.replaceAll(re, '*');
  }

  void _submitCode() async {
    FocusScope.of(context).requestFocus(FocusNode());
    if (_codeController.text.length == 4 && widget.resData != null) {
      setState(() => _loading = true);
      RestDataSource _request = new RestDataSource();
      _request.post(
        context,
        url: Endpoints.meters_add,
        data: {
          "meter_number": widget.meterData["meter_number"],
          "digital_address": widget.meterData["digital_address"],
          "meter_alias": widget.meterData["meter_alias"],
          "account_number": widget.meterData["account_number"],
          "lat": widget.meterData["lat"],
          "long": widget.meterData["long"],
          "otp_key": _codeController.text,
        },
      ).then((Map response) async {
        if (mounted) setState(() => _loading = false);
        if (response[Constants.success]) {
          _meter = Meter.map(response[Constants.response]);
          _onRequestSuccess(_meter);
        } else {
          _onRequestFailed(response[Constants.message]);
        }
      });
    }
  }

  _getResData() {
    setState(() {
      this._mobile_1 = widget.resData["mobile_1"];
      this._mobile_2 = widget.resData["mobile_2"];
      this._email_1 = widget.resData["email_1"];
    });
  }

  @override
  void initState() {
    _getResData();
    super.initState();
    _countdownTimerController = CountdownTimerController(
      endTime: endTime,
      onEnd: () => setState(() => _canVerify = false),
    );
    SmsAutoFill().listenForCode();
  }

  @override
  void dispose() {
    _countdownTimerController.dispose();
    SmsAutoFill().unregisterListener();
    super.dispose();
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
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(70.h),
          child: Container(
            color: Constants.kPrimaryColor,
            child: GeneralHeader(
                title: "Verify Ownership",
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
                  colorFilter: ColorFilter.linearToSrgbGamma(),
                ),
              ),
            ),
            SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Container(
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: Constants.indexHorizontalSpace),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Constants.kSizeHeight_10,
                          if (_canVerify)
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 4.w, vertical: 10.h),
                              child: GText(
                                textData:
                                    "We need to verify you are the owner of the "
                                    " customer account number.",
                                textFont: Constants.kFontLight,
                                textSize: 14.sp,
                                textColor: Constants.kWarningColor,
                                textMaxLines: 4,
                              ),
                            ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 4.w, vertical: 10.h),
                            child: GText(
                              textData:
                                  "A verification code has been sent to the following contacts."
                                  " Please enter the code below to "
                                  "verify and add account",
                              textFont: Constants.kFontLight,
                              textSize: 14.sp,
                              textMaxLines: 4,
                            ),
                          ),
                          Column(
                            children: <Widget>[
                              if (_mobile_1.toString() != "")
                                ListTile(
                                  leading: Icon(Icons.phone_android_sharp),
                                  title: GText(
                                    textData:
                                        "${_hideSomeCharactersPhone(_mobile_1)}",
                                    textSize: 14.sp,
                                  ),
                                ),
                              if (_mobile_2.toString() != "")
                                ListTile(
                                  leading: Icon(Icons.phone_iphone_rounded),
                                  title: GText(
                                    textData:
                                        "${_hideSomeCharactersPhone(_mobile_2)}",
                                    textSize: 14.sp,
                                  ),
                                ),
                              if (_email_1.toString() != "")
                                ListTile(
                                  leading: Icon(Icons.email_outlined),
                                  title: GText(
                                    textData:
                                        "${_hideSomeCharactersEmail(_email_1.toString())}",
                                    textSize: 14.sp,
                                  ),
                                ),
                            ],
                          ),
                          Constants.kSizeHeight_10,
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10.w, vertical: 10.h),
                                  child: GText(
                                    textData: "Enter 4-digits code *",
                                    textSize: 12.sp,
                                    textColor: Constants.kPrimaryColor,
                                  ),
                                ),
                                PinFieldAutoFill(
                                  decoration: BoxLooseDecoration(
                                    textStyle: TextStyle(
                                      fontSize: 16.sp,
                                      color: Constants.kAccentColor,
                                    ),
                                    strokeColorBuilder: FixedColorBuilder(
                                      Constants.kAccentColor.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  controller: _codeController,
                                  codeLength: 4,
                                  keyboardType: TextInputType.number,
                                  onCodeSubmitted: (code) {},
                                  currentCode: _codeController.text,
                                  onCodeChanged: (code) {
                                    if (code!.length == 4) {
                                      setState(
                                          () => _codeController.text = code);
                                      FocusScope.of(context)
                                          .requestFocus(FocusNode());
                                      if (_canVerify) _submitCode();
                                    }
                                  },
                                ),
                                Constants.kSizeHeight_10,
                                Center(
                                  child: CountdownTimer(
                                    controller: _countdownTimerController,
                                    endTime: endTime,
                                    endWidget: GText(
                                      textData: "Verification time has "
                                          "expired. Kindly try again",
                                      textColor: Constants.kRedColor,
                                    ),
                                    onEnd: () =>
                                        setState(() => _canVerify = false),
                                  ),
                                ),
                                _canVerify
                                    ? Constants.kSizeHeight_10
                                    : Container(),
                                Constants.kSizeHeight_5,
                                _canVerify
                                    ? buildElevatedButton(
                                        title: "Verify",
                                        bgColor: Constants.kPrimaryColor,
                                        onPressed: () => _submitCode(),
                                      )
                                    : Container(),
                                Constants.kSizeHeight_5,
                                _canVerify ? Container() : Container(),
                                !_canVerify
                                    ? buildTextButton(
                                        title: "Try again later",
                                        textSize: 12.sp,
                                        textColor: Constants.kPrimaryColor,
                                        onPressed: () => _proceedToHome(),
                                      )
                                    : Container(),
                              ],
                            ),
                          ),
                          // Constants.kSizeHeight_10,
                          // T//ODO: REMOVE IN PRODUCTION
                          // Center(
                          //   child: GText(
                          //     textData:
                          //         "Testing Mode: ${widget.resData["otp_key"]}",
                          //   ),
                          // ),
                          Constants.kSizeHeight_50
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _onRequestSuccess(Meter meter) async {
    var _localDb = new LocalDatabase();
    await _localDb.addMeter(meter);
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => Home(
            index: 0,
            message: "New meter account has been added successfully",
          ),
        ),
        (route) => false);
  }

  _proceedToHome() {
    Navigator.of(context)
        .pushNamedAndRemoveUntil(Home.id, (Route<dynamic> route) => false);
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
