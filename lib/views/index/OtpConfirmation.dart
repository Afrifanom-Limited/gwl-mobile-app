import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_countdown_timer/index.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/Buttons.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/helpers/Functions.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/models/Customer.dart';
import 'package:gwcl/system/LocalDatabase.dart';
import 'package:gwcl/system/RestDataSource.dart';
import 'package:gwcl/templates/Dialogs.dart';
import 'package:gwcl/views/home/Home.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../../mixpanel.dart';

class OtpConfirmation extends StatefulWidget {
  static const String id = "otp_confirmation";
  final String? appSignature;
  const OtpConfirmation({Key? key, this.appSignature}) : super(key: key);
  @override
  _OtpConfirmationState createState() => _OtpConfirmationState();
}

class _OtpConfirmationState extends State<OtpConfirmation> {
  late CountdownTimerController _countdownTimerController;
  int endTime = DateTime.now().millisecondsSinceEpoch + 1000 * 300;

  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _loading = false, _canVerify = true;
  late Customer _customerData;

  void _submitCode() async {
    FocusScope.of(context).requestFocus(FocusNode());
    if (_codeController.text.length == 4) {
      setState(() => _loading = true);
      RestDataSource _request = new RestDataSource();
      _request.post(
        context,
        url: Endpoints.verify_phone_number,
        data: {"otp_key": _codeController.text},
      ).then((Map response) async {
        if (response[Constants.success]) {
          mixpanel?.track('Sign Up Completion');
          _customerData = Customer.map(response[Constants.response]);
          _onRequestSuccess(_customerData);
        } else {
          if (mounted) setState(() => _loading = false);
          _onRequestFailed(response[Constants.message]);
        }
      });
    } else {
      return;
    }
  }

  @override
  void initState() {
    super.initState();
    _countdownTimerController = CountdownTimerController(endTime: endTime, onEnd: () => setState(() => _canVerify = false));
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
          preferredSize: Size.fromHeight(20.h),
          child: AppBar(
            elevation: 0,
            automaticallyImplyLeading: false,
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
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: Constants.indexHorizontalSpace),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5.w),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "OTP Sent",
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Theme.of(context).primaryColor),
                                ),
                                Spacer(),
                                InkWell(
                                  child: SizedBox(
                                    height: 50.h,
                                    child: Icon(Icons.close),
                                  ),
                                  onTap: () => exit(0),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 10.h),
                            child: GText(
                              textData: "A verification code has "
                                  "been sent to the phone number you provided. Please"
                                  " enter the code below to activate your account.",
                              textFont: Constants.kFontLight,
                              textSize: 14.sp,
                              textMaxLines: 4,
                            ),
                          ),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
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
                                    if (code!.toString().length == 4) {
                                      setState(() => _codeController.text = code);
                                      FocusScope.of(context).requestFocus(FocusNode());
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
                                      textData: "Verification time has expired. You can try again later",
                                      textColor: Constants.kRedColor,
                                    ),
                                    onEnd: () => setState(() => _canVerify = false),
                                  ),
                                ),
                                _canVerify ? Constants.kSizeHeight_10 : Container(),
                                Constants.kSizeHeight_5,
                                _canVerify
                                    ? buildElevatedButton(
                                        title: "Verify",
                                        bgColor: Constants.kPrimaryColor,
                                        onPressed: () => _submitCode(),
                                      )
                                    : Container(),
                                Constants.kSizeHeight_20,
                                _canVerify ? dialUssdForCode() : SizedBox(),
                                // buildTextButton(
                                //   title: "I will verify later",
                                //   textSize: 14.sp,
                                //   textColor: Constants.kPrimaryColor,
                                //   onPressed: () {
                                //     showDialog(
                                //       context: context,
                                //       builder: (_) => ConfirmDialog(
                                //         title: "Kindly take note",
                                //         content:
                                //             "You will have to verify your phone"
                                //             " number before you can perform any form "
                                //             "of transactions while using the GWCL Customer app.",
                                //         confirmText: "I understand",
                                //         confirmTextColor:
                                //             Constants.kPrimaryColor,
                                //         confirm: () => _proceedToHome(),
                                //       ),
                                //     );
                                //   },
                                // ),
                              ],
                            ),
                          ),
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

  _onRequestSuccess(Customer customer) async {
    var _localDb = new LocalDatabase();
    await _localDb.updateCustomer(customer);
    if (mounted) setState(() => _loading = false);
    _proceedToHome();
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

  _proceedToHome() {
    Navigator.of(context).pushNamedAndRemoveUntil(Home.id, (Route<dynamic> route) => false);
  }
}
