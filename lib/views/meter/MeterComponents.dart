import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/helpers/FlashHelper.dart';
import 'package:gwcl/helpers/Functions.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/models/Meter.dart';
import 'package:gwcl/system/LocalDatabase.dart';
import 'package:gwcl/system/RestDataSource.dart';
import 'package:gwcl/templates/Modals.dart';
import 'package:gwcl/templates/download_file_button.dart';
import 'package:gwcl/views/meter/MeterDetails.dart';
import 'package:gwcl/views/transactions/PayBill.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MeterCard extends StatefulWidget {
  final dynamic meterCard;
  final Color textColor, buttonTextColor;
  final AssetImage bgImage;
  final bool isLarge;
  final bool isDark;
  const MeterCard({
    Key? key,
    required this.meterCard,
    this.textColor = Constants.kPrimaryColor,
    this.bgImage = Constants.kMeterBgOne,
    this.buttonTextColor = Constants.kPrimaryColor,
    required this.isLarge,
    required this.isDark,
  }) : super(key: key);

  @override
  _MeterCardState createState() => _MeterCardState();
}

class _MeterCardState extends State<MeterCard> {
  bool _loading = false, _isOwing = true, _billLoading = false;
  late Meter _resMeter;
  var _meter, _amount = "";

  _refreshMeter() async {
    SharedPreferences _localStorage = await SharedPreferences.getInstance();
    if (mounted) setState(() => _loading = true);
    RestDataSource _request = new RestDataSource();
    _request.get(context, url: Endpoints.meters_refresh.replaceFirst("{id}", "${_meter["meter_id"]}")).then((Map response) async {
      if (mounted) setState(() => _loading = false);
      if (response[Constants.success]) {
        _resMeter = Meter.map(response[Constants.response]);
        var _localDb = new LocalDatabase();
        await _localDb.updateMeter(_resMeter);
        if (mounted)
          setState(() {
            _meter = response[Constants.response];
            _amount = _meter["balance"].toString();
          });
        //
        if (_amount.toString()[0] == "-") {
          if (mounted)
            setState(() {
              _isOwing = false;
              _amount = _amount.toString().replaceFirst(RegExp('-'), '');
              _amount = "(${_amount})";
            });
        } else {
          if (mounted)
            setState(() {
              _isOwing = true;
              _amount = _amount.toString();
            });
        }
        await _localStorage.setBool(Constants.canUpdateMeter, true);
      } else {
        showBasicsFlash(context, Constants.unableToRefresh.toString(), textColor: Constants.kWhiteColor, bgColor: Constants.kWarningLightColor);
      }
    });
  }

  _checkAndReloadMeter() async {
    SharedPreferences _localStorage = await SharedPreferences.getInstance();
    // Check and load meter info
    var _canUpdateMeter = _localStorage.getBool(Constants.canUpdateMeter);
    if (_canUpdateMeter == null) {
      Timer(new Duration(seconds: 2), _refreshMeter);
    }
  }

  _loadMeterInfo() {
    if (mounted) setState(() => this._meter = widget.meterCard);
    if (this._meter["balance"].toString()[0] == "-") {
      setState(() {
        _isOwing = false;
        _amount = _meter["balance"].toString().replaceFirst(RegExp('-'), '');
        _amount = "(${_amount})";
      });
    } else {
      setState(() {
        _isOwing = true;
        _amount = _meter["balance"].toString();
      });
    }
    _checkAndReloadMeter();
  }

  _getCurrentBill() {
    setState(() => _billLoading = true);
    RestDataSource _request = new RestDataSource();
    _request.get(context, url: Endpoints.meters_current_bill.replaceFirst("{id}", "${_meter["meter_id"]}")).then((Map response) async {
      if (mounted) setState(() => _billLoading = false);
      HapticFeedback.lightImpact();
      if (response[Constants.success]) {
        dynamic _meter = response[Constants.response]["meter"];
        _showResults(response[Constants.response]["bill"], response[Constants.response]["month"], fileUrl: _meter["current_bill"]);
      } else {
        showBasicsFlash(context, 'Unable to fetch Current Bill', textColor: Constants.kWhiteColor, bgColor: Constants.kWarningLightColor);
      }
    });
  }

  _billRows(bill) {
    List<TableRow> list = List.empty(growable: true);
    for (var i = 0; i < bill.length; i++) {
      dynamic item = bill[i];
      list.add(tableRow("${item['key']}", "${item["value"]}"));
    }
    return list;
  }

  _showResults(List bill, dynamic month, {fileUrl}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        child: ScreenModal(
          title: "$month",
          titleColor: Constants.kPrimaryColor,
          isLoading: false,
          height: 0.9,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Constants.kSizeHeight_10,
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: GText(
                  textData: "PAYMENT MADE SUBSEQUENT TO DATE OF THIS BILL WILL REFLECT ON YOUR NEXT BILL",
                  textFont: Constants.kFontLight,
                  textSize: 12.sp,
                  textColor: Constants.kWarningColor,
                  textMaxLines: 4,
                ),
              ),
              Constants.kSizeHeight_10,
              Table(
                  border: TableBorder.symmetric(
                      inside: BorderSide(
                    width: 1,
                  )),
                  columnWidths: {
                    0: FractionColumnWidth(.35),
                  },
                  children: _billRows(bill)),
              Constants.kSizeHeight_5,
              DownloadFileButton(
                pdfPath: fileUrl,
                buttonTitle: "View Bill",
              ),
              Constants.kSizeHeight_10,
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadMeterInfo();
  }

  @override
  Widget build(BuildContext context) {
    return widget.isLarge
        ? Container(
            margin: EdgeInsets.symmetric(vertical: 5.h),
            decoration: BoxDecoration(
              image: DecorationImage(image: widget.bgImage, fit: BoxFit.cover),
              borderRadius: BorderRadius.all(
                Radius.circular(10.w),
              ),
              border: Border.all(color: Constants.kPrimaryColor.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Constants.kPrimaryColor.withOpacity(0.2),
                  spreadRadius: 0,
                  blurRadius: 0.0,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: ListTile(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MeterDetails(
                      meterInfo: _meter,
                    ),
                  ),
                );
              },
              contentPadding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
              title: GText(
                textData: "${_meter["meter_alias"] ?? _meter["service_category_name"]}",
                textSize: 14.sp,
                textColor: widget.textColor.withOpacity(0.9),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Constants.kSizeHeight_10,
                  GText(
                    textData: "${_meter["account_number"]}",
                    textSize: 14.sp,
                    textColor: widget.textColor.withOpacity(0.9),
                    textFont: Constants.kFontMedium,
                  ),
                  Constants.kSizeHeight_5,
                  Row(
                    children: [
                      GText(
                        textData: _isOwing ? "You owe this amount" : "Your balance is",
                        textColor: widget.textColor.withOpacity(0.9),
                        textSize: 10.sp,
                      ),
                      Constants.kSizeWidth_10,
                      ShadowText(
                        textData: "GHS $_amount",
                        textStyle: TextStyle(color: _isOwing ? Colors.yellowAccent : Colors.white, fontSize: 14.sp),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: InkWell(
                child: _loading
                    ? Container(
                        margin: EdgeInsets.only(right: 5),
                        width: 16.w,
                        height: 16.h,
                        child: CircularLoader(
                          loaderColor: widget.textColor,
                          strokeWidth: 2.0,
                          isSmall: true,
                          isDark: widget.isDark,
                        ),
                      )
                    : Icon(
                        Icons.refresh_outlined,
                        color: widget.textColor,
                        size: 20.sp,
                      ),
                onTap: () {
                  HapticFeedback.lightImpact();
                  _refreshMeter();
                },
              ),
            ),
          )
        : Container(
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          // showModalBottomSheet(
                          //   context: context,
                          //   backgroundColor: Colors.transparent,
                          //   isScrollControlled: true,
                          //   builder: (context) => Container(
                          //     child: ScreenModal(
                          //       title: "Account Preview",
                          //       titleColor: Constants.kPrimaryColor,
                          //       isLoading: false,
                          //       body: Column(
                          //         crossAxisAlignment: CrossAxisAlignment.stretch,
                          //         children: [
                          //           Constants.kSizeHeight_20,
                          //           Table(
                          //             border: TableBorder.symmetric(
                          //                 inside: BorderSide(
                          //               width: 1,
                          //             )),
                          //             columnWidths: {
                          //               0: FractionColumnWidth(.35),
                          //             },
                          //             children: [
                          //               tableRow("Name", "${_meter["account_name"]}"),
                          //               tableRow("Account #",
                          //                   "${formatCustomerAccountNumber(_meter["account_number"])}"),
                          //               tableRow("Meter #", "${_meter["meter_number"]}"),
                          //               tableRow("Balance", "GHS $_amount",
                          //                   secondColColor: _isOwing
                          //                       ? Colors.orange
                          //                       : Constants.kPrimaryColor),
                          //               tableRow("Meter Type", "${_meter["meter_type"]}"),
                          //             ],
                          //           ),
                          //           Constants.kSizeHeight_10,
                          //         ],
                          //       ),
                          //     ),
                          //   ),
                          // );
                        },
                        child: Container(
                          width: 300.w,
                          padding: EdgeInsets.symmetric(vertical: 11.w, horizontal: 12.h),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Constants.kPrimaryColor.withOpacity(0.5),
                              Constants.kPrimaryColor,
                            ]),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Constants.kPrimaryColor.withOpacity(0.2)),
                            boxShadow: [
                              BoxShadow(
                                color: Constants.kPrimaryColor.withOpacity(0.2),
                                spreadRadius: 0,
                                blurRadius: 0.0,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 120.w,
                                      child: GText(
                                        textData: "${_meter["meter_alias"] ?? _meter["service_category_name"]}",
                                        textSize: 10.sp,
                                        textColor: widget.textColor,
                                        textFont: Constants.kFontLight,
                                        textMaxLines: 1,
                                      ),
                                    ),
                                    Spacer(),
                                    InkWell(
                                      child: _loading
                                          ? Container(
                                              margin: EdgeInsets.only(right: 5),
                                              width: 16.w,
                                              height: 16.h,
                                              child: CircularLoader(
                                                loaderColor: widget.textColor,
                                                strokeWidth: 2.0,
                                                isSmall: true,
                                                isDark: widget.isDark,
                                              ),
                                            )
                                          : Icon(
                                              Icons.refresh_outlined,
                                              color: widget.textColor,
                                              size: 20.sp,
                                            ),
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        _refreshMeter();
                                      },
                                    ),
                                    Constants.kSizeWidth_5
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          GText(
                                            textData: "${formatCustomerAccountNumber(_meter["account_number"])}",
                                            textSize: 14.sp,
                                            textColor: widget.textColor.withOpacity(0.9),
                                            textFont: Constants.kFontMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          ShadowText(
                                            textData: "GHS $_amount",
                                            textStyle: TextStyle(
                                              color: _isOwing ? Colors.yellowAccent : Colors.white,
                                              fontSize: 16.sp,
                                            ),
                                          ),
                                          GText(
                                            textData: _isOwing ? "You owe this amount" : "Your balance is",
                                            textColor: widget.textColor.withOpacity(0.9),
                                            textSize: 10.sp,
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              Divider(
                                height: 1,
                              ),
                              Expanded(
                                flex: 4,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(50),
                                          side: BorderSide(color: Constants.kWhiteColor),
                                        ),
                                      ),
                                      child: GText(
                                        textData: "More Info",
                                        textSize: 10.sp,
                                        textColor: Colors.white,
                                        textFont: Constants.kFontLight,
                                      ),
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => MeterDetails(
                                              meterInfo: _meter,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(50),
                                          side: BorderSide(color: Constants.kWhiteColor),
                                        ),
                                      ),
                                      child: GText(
                                        textData: "Pay Bill",
                                        textSize: 10.sp,
                                        textColor: Constants.kWhiteColor,
                                        textFont: Constants.kFontLight,
                                      ),
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PayBill(
                                              meter: _meter,
                                              hasOldBalance: true,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Constants.kSizeHeight_40,
                  ],
                ),
                Positioned(
                  bottom: 25,
                  right: 20,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      elevation: 6,
                      backgroundColor: Colors.white,
                    ),
                    child: _billLoading
                        ? CircularLoader(
                            loaderColor: Constants.kPrimaryColor,
                            isSmall: true,
                          )
                        : GText(
                            textData: "View Current Bill",
                            textSize: 12.sp,
                            textColor: widget.buttonTextColor,
                            textFont: Constants.kFontMedium,
                          ),
                    onPressed: () {
                      if (!_billLoading) _getCurrentBill();
                    },
                  ),
                ),
              ],
            ),
          );
  }
}
