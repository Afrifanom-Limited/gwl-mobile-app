import 'dart:async';

import 'package:cool_alert/cool_alert.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_countdown_timer/index.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/Animations.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/helpers/Functions.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/models/Payment.dart';
import 'package:gwcl/system/LocalDatabase.dart';
import 'package:gwcl/system/RestDataSource.dart';
import 'package:gwcl/templates/AppHeaders.dart';
import 'package:gwcl/templates/Dialogs.dart';
import 'package:gwcl/views/home/Home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AwaitingPayment extends StatefulWidget {
  final Payment payment;

  const AwaitingPayment({Key? key, required this.payment}) : super(key: key);

  @override
  _AwaitingPaymentState createState() => _AwaitingPaymentState();
}

class _AwaitingPaymentState extends State<AwaitingPayment> {
  late CountdownTimerController _countdownTimerController;
  int endTime = DateTime.now().millisecondsSinceEpoch + 1000 * 300;

  late Timer _timer;
  bool _checkingPayment = true;
  late Payment _payment;

  _startPaymentCheck() {
    _timer = Timer.periodic(Duration(seconds: 5), (Timer t) {
      try {
        _checkPaymentCompletion();
      } catch (e) {}
    });
  }

  _cancelPaymentCheck() {
    _timer.cancel();
  }

  void _checkPaymentCompletion() {
    RestDataSource _request = new RestDataSource();
    _request.get(context, url: Endpoints.payment_history_view.replaceFirst("{id}", "${widget.payment.paymentHistoryId}")).then((Map response) {
      if (response[Constants.success]) {
        _payment = Payment.map(response[Constants.response]);
        _onRequestSuccess(_payment);
      } else {
        _onRequestFailed(Constants.unableToRefresh);
      }
    });
  }

  _backToPreviousScreen() {
    FocusScope.of(context).requestFocus(FocusNode());
    Navigator.pop(context, false);
  }

  @override
  void initState() {
    _countdownTimerController = CountdownTimerController(
      endTime: endTime,
      //onEnd: () => _backToPreviousScreen(),
    );
    super.initState();
    _startPaymentCheck();
  }

  @override
  void dispose() {
    _countdownTimerController.dispose();
    super.dispose();
    _cancelPaymentCheck();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.h),
        child: Container(
          color: Constants.kPrimaryColor,
          child: GeneralHeader(
            title: "Confirm Payment",
          ),
        ),
      ),
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_checkingPayment)
              Container(
                child: SizedBox(
                  height: 3.h,
                  child: BarLoader(
                    barColor: Constants.kPrimaryColor,
                  ),
                ),
              ),
            Constants.kSizeHeight_20,
            if (widget.payment.paymentMethod.toString().toLowerCase() == "card") ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: GText(textData: "Waiting for Card Payment"),
              ),
            ] else ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: GText(
                  textData: "To complete payment, Kindly enter your"
                      " wallet PIN to confirm "
                      "transaction - ${widget.payment.msisdn}",
                  textSize: 14.sp,
                  textColor: Constants.kPrimaryColor,
                  textMaxLines: 6,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 3,
                child: Builder(builder: (BuildContext context) {
                  return HeartBeatAnimator(
                    iconData: Icons.smartphone_outlined,
                    startSize: 60.h,
                    endSize: 55.h,
                    iconColor: Constants.kPrimaryColor,
                    speed: 1000,
                  );
                }),
              ),
              Center(
                child: CountdownTimer(
                  controller: _countdownTimerController,
                  endTime: endTime,
                  endWidget: GText(
                    textData: "Confirmation time has expired. Kindly try again",
                    textColor: Constants.kRedColor,
                  ),
                  onEnd: () => _backToPreviousScreen(),
                ),
              ),
              if (widget.payment.network.toString().toLowerCase() == "mtn")
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  child: GText(
                    textData: "Not receiving any confirmation prompt?",
                    textSize: 12.sp,
                    textColor: Constants.kPrimaryColor,
                    textMaxLines: 6,
                    textDecoration: TextDecoration.underline,
                    textAlign: TextAlign.center,
                  ),
                ),
              Constants.kSizeHeight_5,
              Expanded(
                flex: 12,
                child: ListView(
                  physics: BouncingScrollPhysics(),
                  children: <Widget>[
                    if (widget.payment.network.toString().toLowerCase() == "mtn")
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          ListStep(
                            stepText: "Step 1 - Dial *170#",
                          ),
                          ListStep(
                            stepText: "Step 2 - Choose option: 6) Wallet",
                          ),
                          ListStep(
                            stepText: "Step 3 -Choose option: 3) My Approvals",
                          ),
                          ListStep(
                            stepText: "Step 4 - Enter your MOMO pin to retrieve"
                                " your pending approval list",
                          ),
                          ListStep(
                            stepText: "Step 5 - Choose a pending transaction",
                          ),
                          ListStep(
                            stepText: "Step 6 - Choose option 1 to approve",
                          ),
                        ],
                      ),
                    if (widget.payment.network.toString().toLowerCase() == "airteltigo")
                      Column(
                        children: <Widget>[
                          Constants.kSizeHeight_10,
                          GText(
                            textData: "AIRTELTIGO MONEY",
                            textSize: 14.sp,
                            textFont: Constants.kFontBold,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    if (widget.payment.network.toString().toLowerCase() == "vodafone")
                      Column(
                        children: <Widget>[
                          Constants.kSizeHeight_10,
                          GText(
                            textData: "VODAFONE CASH",
                            textSize: 14.sp,
                            textFont: Constants.kFontBold,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    Constants.kSizeHeight_50
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  bool _checkPaymentStatus(Payment payment) {
    if (payment.paymentStatus == 'success') {
      return true;
    }
    return false;
  }

  Future<void> closeBrowserWindow() async {
    try {
      await closeInAppWebView();
    } catch (ex) {
      debugPrint(ex.toString());
    }
  }

  _onRequestSuccess(Payment payment) async {
    SharedPreferences _localStorage = await SharedPreferences.getInstance();
    var _localDb = new LocalDatabase();
    await _localDb.updatePaymentHistory(payment);
    if (payment.paymentStatus != 'pending') {
      await closeBrowserWindow();
      HapticFeedback.vibrate();
      if (mounted) setState(() => _checkingPayment = false);
      _cancelPaymentCheck();
      _countdownTimerController.disposeTimer();
      await _localStorage.remove(Constants.canUpdateMeter);
      await _localStorage.remove(Constants.canUpdateVendor);
      coolAlert(
        context,
        _checkPaymentStatus(payment) ? CoolAlertType.success : CoolAlertType.error,
        title: _checkPaymentStatus(payment) ? "Success" : "Failed",
        subtitle: _checkPaymentStatus(payment) ? "Payment was successful. Your Transaction ID is ${payment?.transactionId ?? 'N/A'}" : "Payment was unsuccessful",
        confirmBtnText: "Done",
        showCancelBtn: false,
        barrierDismissible: false,
        onConfirmBtnTap: () {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => Home(index: 0),
              ),
              (route) => false,
            );
          });
        },
      );
    }
  }

  _onRequestFailed(dynamic errorText) async {
    await closeBrowserWindow();
    _cancelPaymentCheck();
    _countdownTimerController.disposeTimer();
    showDialog(
      context: context,
      builder: (_) => ErrorDialog(
        content: errorText.toString().replaceAll(RegExp(Constants.errorFilter), ""),
      ),
    );
  }
}

class ListStep extends StatelessWidget {
  final String stepText;

  const ListStep({Key? key, required this.stepText});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: ListTile(
        title: GText(
          textData: stepText,
          textMaxLines: 4,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
