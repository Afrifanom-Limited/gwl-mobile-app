import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/Buttons.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/helpers/FetchFromWeb.dart';
import 'package:gwcl/helpers/FlashHelper.dart';
import 'package:gwcl/helpers/Functions.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/PageTransitions.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/helpers/TextFields.dart';
import 'package:gwcl/models/AutoPayment.dart';
import 'package:gwcl/models/Payment.dart';
import 'package:gwcl/system/LocalDatabase.dart';
import 'package:gwcl/system/RestDataSource.dart';
import 'package:gwcl/templates/AppHeaders.dart';
import 'package:gwcl/templates/Dialogs.dart';
import 'package:gwcl/views/complaint/LodgeComplaint.dart';
import 'package:gwcl/views/transactions/AwaitingPayment.dart';
import 'package:gwcl/views/transactions/CardCharged.dart';
import 'package:gwcl/views/transactions/ValidateCard.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mixpanel.dart';

class PayBillSummary extends StatefulWidget {
  final dynamic paymentDetails;
  final dynamic apiUrl;
  final dynamic paymentType;

  const PayBillSummary({
    Key? key,
    required this.paymentDetails,
    required this.apiUrl,
    required this.paymentType,
  }) : super(key: key);
  @override
  _PayBillSummaryState createState() => _PayBillSummaryState();
}

class _PayBillSummaryState extends State<PayBillSummary> {
  RestDataSource _request = new RestDataSource();
  bool _loading = false, _autoPayLoading = false;
  late Payment _payment;
  bool _toggleRecurringBilling = false;
  late AutoPayment _autoPayment;

  @override
  void initState() {
    super.initState();
    //_getAutoPaymentInfo();
  }

  _submitRequest() {
    setState(() => _loading = true);
    _request.post(context, url: widget.apiUrl, data: widget.paymentDetails).then((Map response) async {
      if (mounted) setState(() => _loading = false);

      if (response[Constants.success]) {
        _payment = Payment.map(response[Constants.response]);
        if (widget.paymentType == Constants.momo) {
          mixpanel?.track('Submit Pay Bill Momo');
          _onRequestSuccess(_payment);
        } else {
          var data = response[Constants.response];
          String accessToken = data["accessToken"] ?? '';
          String deviceUrl = data["deviceUrl"] ?? '';
          String transactionId = data["transactionId"] ?? '';
          _payment = Payment.map(data['payment']);

          if (accessToken.isNotEmpty && deviceUrl.isNotEmpty) {
            Uri otpUrl = Uri.parse("${Endpoints.public}card_verify_otp").replace(
              queryParameters: {
                "deviceDataCollectionUrl": deviceUrl,
                "jwt": accessToken,
                "transactionId": transactionId,
              },
            );
            mixpanel?.track('Submit Pay Bill Card');
            launchURL(otpUrl.toString());
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AwaitingPayment(payment: _payment),
              ),
            );
          } else {
            _onCardRequestSuccess(_payment, widget.paymentDetails["card_details"]);
          }
        }
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

  // void _getAutoPaymentInfo() async {
  //   setState(() => _autoPayLoading = true);
  //   if (stripSymbols(widget.paymentDetails['account_number'])
  //               .toString()
  //               .length >
  //           11 &&
  //       autoPaymentEligible(widget.paymentDetails['network'].toString())) {
  //     _request
  //         .get(
  //       context,
  //       url: Endpoints.auto_payments_view.replaceFirst(
  //           "{id}", "${stripSymbols(widget.paymentDetails['account_number'])}"),
  //     )
  //         .then((Map response) async {
  //       setState(() => _autoPayLoading = false);
  //       if (response[Constants.success]) {
  //         if (hasData(response[Constants.response])) {
  //           setState(() => this._toggleRecurringBilling = true);
  //           _autoPayment = AutoPayment.map(response[Constants.response]);
  //         } else {
  //           setState(() => this._toggleRecurringBilling = false);
  //         }
  //       } else {
  //         showDialog(
  //           context: context,
  //           builder: (_) => ErrorDialog(content: Constants.unableToRefresh),
  //         );
  //       }
  //     });
  //   }
  // }

  _addAutoPayment() async {
    _request.post(
      context,
      url: Endpoints.auto_payments_add,
      data: {
        "account_number": stripSymbols(widget.paymentDetails['account_number']),
        "msisdn": widget.paymentDetails['msisdn'],
        "customer_name": widget.paymentDetails['account_name'],
        "network": widget.paymentDetails['network'],
        "last_bill_amount": widget.paymentDetails['amount'],
      },
    ).then((Map response) async {
      if (response[Constants.success]) {
        _autoPayment = AutoPayment.map(response[Constants.response]);
      } else {}
    });
  }

  _deleteAutoPayment() async {
    _request
        .get(context, url: Endpoints.auto_payments_delete.replaceFirst("{valOne}", "${_autoPayment.autoPaymentId}").replaceFirst("{valTwo}", "${_autoPayment.transactionId}"))
        .then((Map response) async {
      if (response[Constants.success]) {
      } else {}
    });
  }

  _toggleAllowRecurringBilling(selectedValue) async {
    try {
      final _formKey = GlobalKey<FormState>();
      final _confirmInputController = TextEditingController();
      bool _requestSent = false;
      if (selectedValue) {
        await showDialog(
            context: context,
            barrierDismissible: false,
            useRootNavigator: true,
            builder: (BuildContext context) {
              return StatefulBuilder(builder: (context, setState) {
                return AlertDialog(
                  content: Stack(
                    children: <Widget>[
                      _requestSent
                          ? SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 10.h,
                                    ),
                                    child: GText(
                                      textData: "Request Sent!",
                                      textSize: 15.sp,
                                      textFont: Constants.kFontMedium,
                                      textColor: Constants.kPrimaryColor,
                                      textMaxLines: 7,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 10.h,
                                    ),
                                    child: GText(
                                      textData: "Kindly wait for 1-5 minutes. You will receive"
                                          " a confirmation prompt on your mobile device."
                                          " Kindly enter your wallet PIN to"
                                          " activate Auto-Payment. ",
                                      textSize: 12.sp,
                                      textColor: Constants.kPrimaryColor,
                                      textMaxLines: 12,
                                    ),
                                  ),
                                  Constants.kSizeHeight_5,
                                  buildElevatedButton(
                                    title: "I have confirmed",
                                    borderRadius: 10.w,
                                    onPressed: () {
                                      Navigator.pop(context, true);
                                      showBasicsFlash(
                                        context,
                                        "Auto Payment enabled successfully",
                                        textColor: Constants.kWhiteColor,
                                        bgColor: Constants.kGreenLightColor,
                                      );
                                    },
                                  ),
                                  Constants.kSizeHeight_5,
                                  buildTextButton(
                                    title: "I didn't receive any prompt",
                                    textColor: Constants.kRedColor,
                                    onPressed: () {
                                      Navigator.pop(context, false);
                                      showBasicsFlash(
                                        context,
                                        "Sorry, kindly wait for 3-5 minutes and try again",
                                        textColor: Constants.kAccentColor,
                                        bgColor: Constants.kWhiteColor,
                                        duration: Duration(seconds: 7),
                                      );
                                    },
                                  )
                                ],
                              ),
                            )
                          : SingleChildScrollView(
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10.w,
                                        vertical: 10.h,
                                      ),
                                      child: GText(
                                        textData: "This will add account number: "
                                            "${widget.paymentDetails['account_number']} to "
                                            "the Auto-Payment service. Your monthly bills"
                                            " will automatically be paid using your current"
                                            " payment method or channel.",
                                        textSize: 12.sp,
                                        textColor: Constants.kPrimaryColor,
                                        textMaxLines: 15,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                                      child: RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: "Please type",
                                              style: TextStyle(
                                                color: Constants.kPrimaryColor,
                                                fontSize: 12.sp,
                                              ),
                                            ),
                                            TextSpan(
                                              text: ' ',
                                            ),
                                            TextSpan(
                                              text: Constants.AUTOPAYMENT,
                                              style: TextStyle(color: Constants.kPrimaryColor, fontSize: 12.sp, fontWeight: FontWeight.w800),
                                            ),
                                            TextSpan(
                                              text: ' ',
                                            ),
                                            TextSpan(
                                              text: 'to confirm',
                                              style: TextStyle(
                                                color: Constants.kPrimaryColor,
                                                fontSize: 12.sp,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    TextFormField(
                                      keyboardType: TextInputType.text,
                                      textInputAction: TextInputAction.next,
                                      controller: _confirmInputController,
                                      toolbarOptions: ToolbarOptions(
                                        paste: true,
                                        cut: true,
                                        copy: true,
                                        selectAll: true,
                                      ),
                                      validator: (value) {
                                        if (value != Constants.AUTOPAYMENT)
                                          return 'Confirmation text is invalid';
                                        else
                                          return null;
                                      },
                                      onFieldSubmitted: (v) {
                                        FocusScope.of(context).nextFocus();
                                      },
                                      style: circularTextStyle(),
                                      decoration: circularInputDecoration(title: "", circularRadius: 10.w),
                                    ),
                                    Constants.kSizeHeight_10,
                                    buildElevatedButton(
                                      title: "Continue",
                                      borderRadius: 10.w,
                                      onPressed: () async {
                                        final isValid = _formKey.currentState!.validate();
                                        if (!isValid) {
                                          HapticFeedback.mediumImpact();
                                          return;
                                        } else {
                                          _addAutoPayment();
                                          setState(() => _requestSent = true);
                                        }
                                      },
                                    ),
                                    Constants.kSizeHeight_5,
                                    buildTextButton(
                                        title: "Cancel",
                                        textColor: Constants.kRedColor,
                                        onPressed: () {
                                          Navigator.pop(context, false);
                                        })
                                  ],
                                ),
                              ),
                            ),
                    ],
                  ),
                );
              });
            }).then((valueFromDialog) {
          print(valueFromDialog);
          if (valueFromDialog == true) {
            setState(() => this._toggleRecurringBilling = true);
          }
        });
      } else {
        showDialog(
          context: context,
          builder: (_) => ConfirmDialog(
            title: "Confirm Action",
            content: "This will remove account number: "
                "${widget.paymentDetails['account_number']} from "
                "the Auto-Payment service. Do you want to continue?",
            confirmText: "Yes",
            confirmTextColor: Constants.kPrimaryColor,
            confirm: () async {
              setState(() => this._toggleRecurringBilling = false);
              _deleteAutoPayment();
            },
          ),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    }
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
              title: "Confirm and Send",
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Container(
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        color: Constants.kPrimaryColor.withValues(alpha: 0.9),
                        elevation: 0.0,
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 20.w),
                          title: GText(
                            textData: "${widget.paymentDetails['account_name'].toString().length < 1 ? "NO NAME" : widget.paymentDetails['account_name']}",
                            textSize: 16.sp,
                            textColor: Constants.kWhiteColor,
                          ),
                          subtitle: Container(
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            child: GText(
                              textData: "${widget.paymentDetails['account_number']}",
                              textSize: 14.sp,
                              textColor: Constants.kWarningColor,
                            ),
                          ),
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              GText(
                                textData: "Total",
                                textSize: 10.sp,
                                textColor: Constants.kWhiteColor,
                              ),
                              Constants.kSizeHeight_5,
                              GText(
                                textData: "GHS ${widget.paymentDetails['amount'].toStringAsFixed(2)}",
                                textSize: 13.sp,
                                textColor: Colors.greenAccent,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Constants.kSizeHeight_20,
                    buildInfoTile(
                      title: "Amount",
                      trailing: "GHS ${widget.paymentDetails['actual_amount']}",
                    ),
                    // Divider(height: 5, color: Constants.kPrimaryColor),
                    // buildInfoTile(
                    //     title: "Transaction Fee",
                    //     trailing:
                    //         "GHS ${widget.paymentDetails['transaction_charge']}"),
                    Divider(height: 5, color: Constants.kPrimaryColor),
                    buildInfoTile(title: "Phone Number", trailing: "${widget.paymentDetails['msisdn']}"),
                    Divider(height: 5, color: Constants.kPrimaryColor),
                    buildInfoTile(
                      title: "Service Provider",
                      trailing: "${widget.paymentDetails['network'].toString().toUpperCase()}",
                    ),
                    // AUTO-PAYMENT SERVICE
                    if (autoPaymentEligible(widget.paymentDetails['network'].toString()) && _autoPayLoading)
                      Container(
                        child: BarLoader(
                          barColor: Constants.kPrimaryColor,
                          thickness: 0.5.h,
                        ),
                      ),
                    if (!_autoPayLoading)
                      if (autoPaymentEligible(widget.paymentDetails['network'].toString()))
                        if (!_autoPayLoading)
                          Container(
                            color: _toggleRecurringBilling ? Constants.kGreenLightColor.withValues(alpha: 0.3) : Constants.kPrimaryColor.withValues(alpha: 0.1),
                            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 10.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SwitchListTile(
                                  activeColor: Constants.kPrimaryColor,
                                  value: _toggleRecurringBilling,
                                  title: GText(
                                    textData: _toggleRecurringBilling ? "Auto-Payment is Enabled" : "Enable Auto-Payment",
                                    textSize: 14.sp,
                                    textFont: Constants.kFontMedium,
                                    textColor: Constants.kPrimaryColor,
                                  ),
                                  subtitle: Container(
                                    margin: EdgeInsets.only(top: 5.h),
                                    child: GText(
                                      textData: "Water bills for "
                                          "${widget.paymentDetails['account_number']} "
                                          "will automatically be "
                                          "paid "
                                          "on a scheduled date.",
                                      textSize: 12.sp,
                                      textMaxLines: 5,
                                    ),
                                  ),
                                  isThreeLine: true,
                                  onChanged: (val) => setState(() {
                                    _toggleAllowRecurringBilling(val);
                                  }),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 15.w),
                                  child: InkWell(
                                    child: GText(
                                      textData: "Learn more about Auto-Payment",
                                      textColor: Constants.kPrimaryColor,
                                      textSize: 12.sp,
                                      textFont: Constants.kFontLight,
                                      textDecoration: TextDecoration.underline,
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => FetchFromWeb(url: Constants.gwclAutoPayment),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Divider(height: 5, color: Constants.kPrimaryColor),
                    Constants.kSizeHeight_20,
                    buildElevatedButton(
                      borderRadius: 10.w,
                      title: "Pay Now",
                      onPressed: () {
                        _submitRequest();
                      },
                    ),
                    Constants.kSizeHeight_50,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ListTile buildInfoTile({
    required String title,
    required String trailing,
  }) {
    return ListTile(
      title: GText(
        textData: title,
        textSize: 14.sp,
        textColor: Constants.kGreyColor,
      ),
      trailing: GText(
        textData: trailing,
        textSize: 14.sp,
        textFont: Constants.kFontMedium,
      ),
    );
  }

  _onCardRequestSuccess(Payment payment, String cardDetails) async {
    var _localDb = new LocalDatabase();
    SharedPreferences _localStorage = await SharedPreferences.getInstance();
    await _localDb.addPaymentHistory(payment);
    await _localStorage.remove(Constants.canUpdateMeter);
    if (payment.responseCode == '0') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CardCharged(payment: payment),
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

  _onRequestSuccess(Payment payment) async {
    var _localDb = new LocalDatabase();
    await _localDb.addPaymentHistory(payment);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AwaitingPayment(
          payment: payment,
        ),
      ),
    );
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

class WaitingCardVerification extends StatefulWidget {
  const WaitingCardVerification({Key? key}) : super(key: key);

  @override
  State<WaitingCardVerification> createState() => _WaitingCardVerificationState();
}

class _WaitingCardVerificationState extends State<WaitingCardVerification> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.h),
        child: Container(
          color: Constants.kPrimaryColor,
          child: GeneralHeader(
            title: "Card Verification",
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Constants.kSizeHeight_20,
            Container(
              height: 30.h,
              width: 100.w,
              child: Center(
                child: CircularProgressIndicator(
                  color: Constants.kPrimaryColor,
                ),
              ),
            ),
            Constants.kSizeHeight_20,
            GText(
              textData: "Waiting for Card Payment Verification ",
              textSize: 14.sp,
              textFont: Constants.kFontMedium,
              textColor: Constants.kPrimaryColor,
              textAlign: TextAlign.center,
            ),
            Constants.kSizeHeight_20,
            FilledButton.icon(
              style: FilledButton.styleFrom(padding: EdgeInsets.all(12)),
              onPressed: () {
                FocusScope.of(context).requestFocus(FocusNode());
                Navigator.pop(context, false);
              },
              label: GText(
                textData: "Done",
                textSize: 14.sp,
              ),
              icon: Icon(
                Icons.check_circle,
                size: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
