import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gwcl/helpers/Buttons.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Functions.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/models/Payment.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/templates/AppHeaders.dart';
import 'package:gwcl/templates/Modals.dart';
import 'package:gwcl/views/home/Home.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class CardCharged extends StatefulWidget {
  final Payment payment;
  const CardCharged({Key? key, required this.payment}) : super(key: key);
  @override
  _CardChargedState createState() => _CardChargedState();
}

class _CardChargedState extends State<CardCharged> {
  bool _loading = false;
  dynamic _format = DateFormat("dd MMMM, yyyy");

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
            child: DarkHeader(),
          ),
        ),
        body: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Container(
            child: Column(
              children: <Widget>[
                Stack(
                  children: [
                    Container(
                      height: 140.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          tileMode: TileMode.mirror,
                          begin: Alignment(-1.0, -0.7),
                          end: Alignment.bottomRight,
                          colors: [
                            Constants.kPrimaryColor,
                            Constants.kPrimaryColor,
                            Constants.kPrimaryColor,
                          ],
                          stops: [
                            0,
                            0.5,
                            1,
                          ],
                        ),
                        backgroundBlendMode: BlendMode.srcOver,
                      ),
                      child: Container(),
                    ),
                    Ink(
                      height: 80.h,
                      decoration: BoxDecoration(
                        color: Constants.kPrimaryLightColor,
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(top: 40.h),
                      child: Column(
                        children: <Widget>[
                          GText(
                            textData: "GHC ${widget.payment.amount}",
                            textSize: 26.sp,
                            textFont: Constants.kFontMedium,
                            textColor: Constants.kWhiteColor,
                          ),
                          Constants.kSizeHeight_5,
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            child: GText(
                              textData: "Transaction was Successful",
                              textFont: Constants.kFontLight,
                              textSize: 14.sp,
                              textMaxLines: 4,
                              textAlign: TextAlign.center,
                              textColor: Constants.kWhiteColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: Constants.indexHorizontalSpace),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Constants.kSizeHeight_10,
                      buildElevatedButton(
                        title: "View Payment Advice",
                        bgColor: Constants.kWhiteColor,
                        textColor: Constants.kWarningColor,
                        borderRadius: 1.w,
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (context) => Container(
                              child: ScreenModal(
                                title: "Payment Advice",
                                titleColor: Constants.kPrimaryColor,
                                isLoading: false,
                                body: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Constants.kSizeHeight_20,
                                    Table(
                                      border: TableBorder.symmetric(
                                          inside: BorderSide(
                                        width: 1,
                                      )),
                                      columnWidths: {
                                        0: FractionColumnWidth(.35),
                                      },
                                      children: [
                                        tableRow("Amount",
                                            "GHS ${widget.payment.actualAmount}"),
                                        tableRow("Trans. Fee",
                                            "GHS ${widget.payment.transactionCharge}"),
                                        tableRow("Card Type",
                                            "${widget.payment.network.toUpperCase()}"),
                                        tableRow("Beneficiary",
                                            "${widget.payment.meterAccountNumber == null ? widget.payment.gwclCustomerNumber : formatCustomerAccountNumber(widget.payment.meterAccountNumber)}"),
                                        tableRow("Ref. Key",
                                            "${widget.payment.transactionId}"),
                                        tableRow("Date",
                                            "${_format.format(DateTime.parse(widget.payment.dateCreated))}"),
                                      ],
                                    ),
                                    Constants.kSizeHeight_10,
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      Constants.kSizeHeight_5,
                      buildElevatedButton(
                        title: "Done",
                        borderRadius: 1.w,
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Home(
                                      index: 0,
                                    )),
                            (route) => false,
                          );
                        },
                      ),
                      Constants.kSizeHeight_10,
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
}
