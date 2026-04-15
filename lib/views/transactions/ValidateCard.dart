import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gwcl/helpers/Buttons.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/helpers/Functions.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/PageTransitions.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/helpers/TextFields.dart';
import 'package:gwcl/models/Payment.dart';
import 'package:gwcl/system/LocalDatabase.dart';
import 'package:gwcl/system/RestDataSource.dart';
import 'package:gwcl/templates/AppHeaders.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/templates/Dialogs.dart';
import 'package:gwcl/views/transactions/CardCharged.dart';
import 'package:gwcl/views/complaint/LodgeComplaint.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ValidateCard extends StatefulWidget {
  final Payment payment;
  final String cardDetails;

  const ValidateCard({
    Key? key,
    required this.payment,
    required this.cardDetails,
  }) : super(key: key);

  @override
  _ValidateCardState createState() => _ValidateCardState();
}

class _ValidateCardState extends State<ValidateCard> {
  final _formKey = GlobalKey<FormState>();
  final _amountChargedController = TextEditingController();
  bool _loading = false, _canValidate = true;
  String _loadingState = "";
  late Payment _payment;

  void _submitAmount() {
    HapticFeedback.lightImpact();
    FocusScope.of(context).requestFocus(FocusNode());
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      HapticFeedback.vibrate();
      return;
    } else {
      setState(() => _loading = true);
      RestDataSource _request = new RestDataSource();
      _request.post(
        context,
        url: Endpoints.payment_history_verify_debit_card,
        data: {
          "payment_history_id": widget.payment.paymentHistoryId,
          "otp_code": _amountChargedController.text,
          "card_details": widget.cardDetails
        },
      ).then((Map response) async {
        if (mounted) setState(() => _loading = false);
        if (response[Constants.success]) {
          _payment = Payment.map(response[Constants.response]);
          _onRequestSuccess(_payment, widget.cardDetails);
        } else {
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

  // void _resetOtp() {
  //   HapticFeedback.lightImpact();
  //   setState(() => _loading = true);
  //   RestDataSource _request = new RestDataSource();
  //   _request.post(
  //     context,
  //     url: Endpoints.payment_history_reset_debit_card_otp,
  //     data: {
  //       "payment_history_id": widget.payment.paymentHistoryId,
  //     },
  //   ).then((Map response) async {
  //     if (mounted) setState(() => _loading = false);
  //     if (response[Constants.success]) {
  //       showBasicsFlash(
  //         context,
  //         response[Constants.message],
  //         textColor: Constants.kWhiteColor,
  //         bgColor: Constants.kGreenLightColor,
  //       );
  //     } else {
  //       _onRequestFailed(response[Constants.message]);
  //     }
  //   });
  // }

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
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(70.h),
          child: Container(
            color: Constants.kPrimaryColor,
            child: GeneralHeader(
                title: "Card Verification",
              ),
          ),
        ),
        body: SingleChildScrollView(
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
                      if (_canValidate)
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 4.w, vertical: 10.h),
                          child: GText(
                            textData: "Please verify first time use "
                                "of Card Details with Amount deducted "
                                "from Bank Account",
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
                              "An amount of money has been deducted from your "
                              "Bank Account. Kindly enter the exact "
                              "Amount in the space below:",
                          textFont: Constants.kFontLight,
                          textSize: 14.sp,
                          textMaxLines: 4,
                        ),
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
                                textData: "Enter amount charged *",
                                textSize: 12.sp,
                                textColor: Constants.kPrimaryColor,
                              ),
                            ),
                            TextFormField(
                              keyboardType: Platform.isAndroid
                                  ? TextInputType.phone
                                  : TextInputType.numberWithOptions(
                                      decimal: true, signed: false),
                              textInputAction: TextInputAction.next,
                              controller: _amountChargedController,
                              validator: (value) => checkNull(value!, "Amount"),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.]')),
                                LengthLimitingTextInputFormatter(7),
                              ],
                              onFieldSubmitted: (v) {
                                FocusScope.of(context).nextFocus();
                              },
                              toolbarOptions: ToolbarOptions(
                                paste: true,
                                cut: true,
                                copy: true,
                                selectAll: true,
                              ),
                              style: circularTextStyle(),
                              decoration: circularInputDecoration(
                                title: "",
                                circularRadius: 10.w,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 4.w, vertical: 10.h),
                              child: GText(
                                textData: "NOTE: Card will be blocked "
                                    "after 3 failed verification attempts.",
                                textFont: Constants.kFontLight,
                                textSize: 10.sp,
                                textColor: Constants.kPrimaryColor,
                                textMaxLines: 4,
                              ),
                            ),
                            _canValidate
                                ? Constants.kSizeHeight_10
                                : Container(),
                            Constants.kSizeHeight_5,
                            _canValidate
                                ? buildElevatedButton(
                                    title: "Submit",
                                    bgColor: Constants.kPrimaryColor,
                                    onPressed: () => _submitAmount(),
                                    borderRadius: 10.w,
                                  )
                                : Container(),
                            // Constants.kSizeHeight_5,
                            // buildTextButton(
                            //   title: "Resend Card OTP",
                            //   textSize: 14.sp,
                            //   textColor: Constants.kPrimaryColor,
                            //   onPressed: () => _resetOtp(),
                            // ),
                            Constants.kSizeHeight_20,
                          ],
                        ),
                      ),
                      Constants.kSizeHeight_50
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _onRequestSuccess(Payment payment, String cardDetails) async {
    var _localDb = new LocalDatabase();
    SharedPreferences _localStorage = await SharedPreferences.getInstance();
    await _localDb.addPaymentHistory(payment);
    await _localStorage.remove(Constants.canUpdateMeter);
    await _localStorage.remove(Constants.canUpdateVendor);
    if (payment.responseCode == '0') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CardCharged(
            payment: payment,
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ValidateCard(
            payment: payment,
            cardDetails: cardDetails,
          ),
        ),
      );
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
    //   errorText.toString().replaceAll(RegExp(Constants.errorFilter), ""),
    //   textColor: Constants.kWhiteColor,
    //   bgColor: Constants.kRedLightColor,
    //   duration: Duration(seconds: 4),
    // );
  }
}
