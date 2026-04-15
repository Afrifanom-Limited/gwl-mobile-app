import 'package:flutter/material.dart';
import 'package:flutter_countdown_timer/index.dart';
import 'package:gwcl/helpers/Buttons.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/models/Customer.dart';
import 'package:gwcl/system/LocalDatabase.dart';
import 'package:gwcl/system/RestDataSource.dart';
import 'package:gwcl/templates/AppHeaders.dart';
import 'package:gwcl/templates/Dialogs.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_autofill/sms_autofill.dart';

class VerifyPhoneNumber extends StatefulWidget {
  final String phoneNumber;
  final bool verifyMomo;
  const VerifyPhoneNumber({Key? key, required this.phoneNumber, required this.verifyMomo}) : super(key: key);
  @override
  _VerifyPhoneNumberState createState() => _VerifyPhoneNumberState();
}

class _VerifyPhoneNumberState extends State<VerifyPhoneNumber> {
  late CountdownTimerController _countdownTimerController;
  int endTime = DateTime.now().millisecondsSinceEpoch + 1000 * 300;

  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _loading = false, _canVerify = true;
  late Customer _customerData;

  void _submitCode() async {
    if (_codeController.text.length == 4) {
      FocusScope.of(context).requestFocus(FocusNode());
      setState(() => _loading = true);
      RestDataSource _request = new RestDataSource();

      var verifyType = "account";
      if (widget.verifyMomo) {
        verifyType = "mobilemoney";
      }

      _request.post(
        context,
        url: Endpoints.customers_editphonenumber,
        data: {
          "phone_number": widget.phoneNumber,
          "otp_key": _codeController.text,
          "verify_type": verifyType,
        },
      ).then((Map response) async {
        if (mounted) setState(() => _loading = false);
        if (response[Constants.success]) {
          _customerData = Customer.map(response[Constants.response]);
          _onRequestSuccess(_customerData, widget.phoneNumber);
        } else {
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
      color: Constants.kWhiteColor.withOpacity(0.8),
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
                      padding: EdgeInsets.symmetric(horizontal: Constants.indexHorizontalSpace),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Constants.kSizeHeight_10,
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 10.h),
                            child: GText(
                              textData: "A code has been sent to your phone number. "
                                  "Please enter the code below to "
                                  "verify your phone number",
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
                                      Constants.kAccentColor.withOpacity(0.3),
                                    ),
                                  ),
                                  controller: _codeController,
                                  codeLength: 4,
                                  keyboardType: TextInputType.number,
                                  onCodeSubmitted: (code) {},
                                  currentCode: _codeController.text,
                                  onCodeChanged: (code) {
                                    if (code!.length == 4) {
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
                                      textData: "Verification time has expired. Kindly "
                                          "try again",
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
                                Constants.kSizeHeight_5,
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

  _onRequestSuccess(Customer customer, String newNumber) async {
    var _localDb = new LocalDatabase();
    await _localDb.updateCustomer(customer);
    SharedPreferences _localStorage = await SharedPreferences.getInstance();
    _localStorage.setString(Constants.localMomoPhone, newNumber);
    Navigator.pop(context, true);
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
