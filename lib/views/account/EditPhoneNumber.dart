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
import 'package:gwcl/system/RestDataSource.dart';
import 'package:gwcl/templates/AppHeaders.dart';
import 'package:gwcl/templates/Dialogs.dart';
import 'package:gwcl/views/account/VerifyPhoneNumber.dart';
import 'package:gwcl/views/home/Home.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:sms_autofill/sms_autofill.dart';

class EditPhoneNumber extends StatefulWidget {
  static const String id = "/edit_phone_number";
  final String? phoneNumber;
  final bool navigateToHome;
  final bool verifyMomo;

  const EditPhoneNumber({Key? key, this.phoneNumber, required this.navigateToHome, required this.verifyMomo}) : super(key: key);
  @override
  _EditPhoneNumberState createState() => _EditPhoneNumberState();
}

class _EditPhoneNumberState extends State<EditPhoneNumber> {
  final _formKey = GlobalKey<FormState>();
  final _phoneNumberController = TextEditingController();
  bool _loading = false;

  void _submitForm() async {
    FocusScope.of(context).requestFocus(FocusNode());
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      HapticFeedback.vibrate();
      return;
    } else if (_phoneNumberController.text == widget.phoneNumber) {
      setState(() => _loading = true);
      await Future.delayed(const Duration(seconds: 1), () {
        setState(() => _loading = false);
        Navigator.pop(context, true);
      });
    } else {
      setState(() => _loading = true);
      String appSignature = await SmsAutoFill().getAppSignature;
      RestDataSource _request = new RestDataSource();
      _request.post(
        context,
        url: Endpoints.send_otp_code,
        data: {"app_signature": appSignature, "phone_number": getMsisdn(_phoneNumberController.text)},
      ).then((Map response) async {
        if (mounted) setState(() => _loading = false);
        if (response[Constants.success]) {
          _onRequestSuccess(getMsisdn(_phoneNumberController.text));
        } else {
          _onRequestFailed(response[Constants.message]);
        }
      });
    }
  }

  @override
  void initState() {
    if (widget.phoneNumber != null) _phoneNumberController.text = widget.phoneNumber!;
    super.initState();
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
              title: "Change Phone Number",
            ),
          ),
        ),
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(image: Constants.kBgTwo, fit: BoxFit.cover, colorFilter: ColorFilter.linearToSrgbGamma()),
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
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 10.h),
                            child: GText(
                              textData: "Phone Number *",
                              textSize: 12.sp,
                              textColor: Constants.kPrimaryColor,
                            ),
                          ),
                          TextFormField(
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            controller: _phoneNumberController,
                            validator: (value) => validatePhone(value!),
                            onFieldSubmitted: (v) {
                              FocusScope.of(context).nextFocus();
                            },
                            style: circularTextStyle(),
                            decoration: circularInputDecoration(
                              title: "Phone Number",
                            ),
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                          ),
                          Constants.kSizeHeight_20,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("No OTP Yet?"),
                              buildTextButton(
                                  onPressed: () {
                                    launchURL("tel:" + Uri.encodeComponent('*1010*1010#'));
                                  },
                                  title: "Dial USSD *1010*1010#",
                                  textColor: Constants.kPrimaryColor),
                            ],
                          ),
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

  _onRequestSuccess(String phoneNumber) async {
    dynamic _result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VerifyPhoneNumber(phoneNumber: phoneNumber, verifyMomo: widget.verifyMomo),
      ),
    );
    if (_result == true) {
      if (widget.navigateToHome == true) {
        Navigator.of(context).pushNamedAndRemoveUntil(Home.id, (Route<dynamic> route) => false);
      } else {
        Navigator.pop(context, true);
      }
    }
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
