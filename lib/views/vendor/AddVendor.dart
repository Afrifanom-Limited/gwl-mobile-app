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
import 'package:gwcl/system/RestDataSource.dart';
import 'package:gwcl/templates/Dialogs.dart';
import 'package:gwcl/views/complaint/LodgeComplaint.dart';
import 'package:gwcl/views/home/Home.dart';
import 'package:gwcl/views/vendor/VerifyVendor.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../../mixpanel.dart';

class AddVendor extends StatefulWidget {
  static const String id = "/add_vendor";
  @override
  _AddVendorState createState() => _AddVendorState();
}

class _AddVendorState extends State<AddVendor> {
  final _formKey = GlobalKey<FormState>();
  final _accountNumberController = TextEditingController();
  bool _loading = false;
  String _loadingState = "";

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
      var _vendorData = {"account_number": stripSymbols(_accountNumberController.text)};

      _request.post(
        context,
        url: Endpoints.vendors_verify,
        data: {"app_signature": appSignature, "account_number": stripSymbols(_accountNumberController.text)},
      ).then((Map response) async {
        if (mounted) setState(() => _loading = false);
        if (response[Constants.success]) {
          mixpanel?.track('Add Account Vendor Success');
          _onRequestSuccess(_vendorData, response[Constants.response]);
        } else {
          mixpanel?.track('Add Account Vendor Failed');
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

  @override
  void dispose() {
    super.dispose();
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
                            textData: "Vendor Account Number *",
                            textSize: 12.sp,
                            textColor: Constants.kPrimaryColor,
                          ),
                        ),
                        Constants.kSizeHeight_5,
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5.w),
                          child: GText(
                            textData: "Enter your Ghana Water vendor"
                                " account number. An OTP code will "
                                "be sent to vendor's phone number to verify ownership of account",
                            textSize: 10.sp,
                            textColor: Constants.kGreyColor,
                            textMaxLines: 5,
                          ),
                        ),
                        Constants.kSizeHeight_10,
                        TextFormField(
                          keyboardType: TextInputType.phone,
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
                            if (value!.length < 8) return "Invalid vendor number provided";
                            return null;
                          },
                          inputFormatters: [MaskTextInputFormatter(mask: "GGGGGGGG")],
                          onFieldSubmitted: (v) {
                            FocusScope.of(context).nextFocus();
                          },
                          style: circularTextStyle(),
                          decoration: circularInputDecoration(
                            title: "",
                          ),
                        ),
                        Constants.kSizeHeight_20,
                        buildElevatedButton(
                          title: "Add Vendor Account",
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

  _onRequestSuccess(dynamic vendorData, dynamic resData) async {
    Navigator.pushReplacement(
      context,
      FadeRoute(
        page: VerifyVendor(
          vendorData: vendorData,
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
  }
}
