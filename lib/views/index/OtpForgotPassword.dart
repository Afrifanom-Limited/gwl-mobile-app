import 'package:flutter/material.dart';
import 'package:flutter_countdown_timer/index.dart';
import 'package:gwcl/helpers/Buttons.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Functions.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/templates/AppHeaders.dart';
import 'package:gwcl/templates/Dialogs.dart';
import 'package:gwcl/views/index/ChangePassword.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:sms_autofill/sms_autofill.dart';

class OtpForgotPassword extends StatefulWidget {
  final String otpKey;
  final String msisdn;
  const OtpForgotPassword(
      {Key? key, required this.otpKey, required this.msisdn})
      : super(key: key);
  @override
  _OtpForgotPasswordState createState() => _OtpForgotPasswordState();
}

class _OtpForgotPasswordState extends State<OtpForgotPassword> {
  late CountdownTimerController _countdownTimerController;
  int endTime = DateTime.now().millisecondsSinceEpoch + 1000 * 300;

  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _loading = false, _canVerify = true;

  void _submitCode() async {
    FocusScope.of(context).requestFocus(FocusNode());
    String _otp = widget.otpKey.substring(4, 8);
    String _code = _otp.split('').reversed.join('');
    if (_codeController.text == _code) {
      _onRequestSuccess(widget.msisdn);
    } else {
      _onRequestFailed("Verification code is invalid");
    }
  }

  @override
  void initState() {
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
              title: "Verify Phone Number",
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
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 4.w, vertical: 10.h),
                            child: GText(
                              textData:
                                  "A code has been sent to ${widget.msisdn}. "
                                  "Please enter the code below to continue",
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
                                      textData:
                                          "Verification time has expired. Kindly "
                                          "restart password reset process",
                                      textColor: Constants.kRedColor,
                                    ),
                                    onEnd: () =>
                                        setState(() => _canVerify = false),
                                  ),
                                ),
                                Constants.kSizeHeight_10,
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

  _onRequestSuccess(String msisdn) async {
    dynamic _result = await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ChangePassword(msisdn: msisdn),
      ),
    );
    if (_result == true && mounted) {
      Navigator.pop(context, true);
    }
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
    //   errorText.toString(),
    //   textColor: Constants.kWhiteColor,
    //   bgColor: Constants.kRedLightColor,
    // );
  }
}
