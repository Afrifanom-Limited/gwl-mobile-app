import 'package:flutter/material.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/templates/AppHeaders.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ViewMeterBill extends StatefulWidget {
  static const String id = "/view_meter_bill";
  @override
  _ViewMeterBillState createState() => _ViewMeterBillState();
}

class _ViewMeterBillState extends State<ViewMeterBill> {
  bool _loading = false;

  TableRow _tableRow(firstCol, secondCol) {
    return TableRow(
      children: [
        Container(
          padding: EdgeInsets.all(10.w),
          child: GText(
              textData: firstCol ?? "None",
              textSize: 12.sp,
              textColor: Constants.kGreyColor),
        ),
        Container(
          color: Constants.kPrimaryLightColor,
          padding: EdgeInsets.all(10.w),
          child: GText(
            textData: secondCol ?? "None",
            textSize: 12.sp,
            textColor: Constants.kPrimaryColor,
          ),
        ),
      ],
    );
  }

  _quickLoad() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1), () {
      setState(() => _loading = false);
    });
  }

  @override
  void initState() {
    _quickLoad();
    super.initState();
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
                title: "Meter Bill",
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
                    colorFilter: ColorFilter.linearToSrgbGamma()),
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
                    Table(
                      border: TableBorder.all(color: Constants.kPrimaryColor),
                      columnWidths: {
                        0: FractionColumnWidth(.5),
                      },
                      children: [
                        _tableRow("ACC #", "0302-7365-2111"),
                        _tableRow("ACC HOLDER", "KWABENA DOUGAN"),
                        _tableRow("PREV", "3961"),
                        _tableRow("NEW", "4017"),
                        _tableRow("USED", "56 AT 5.602083"),
                        _tableRow("WATER", "397.75"),
                        _tableRow("1% FIRE", "3.14"),
                        _tableRow("2% RURAL", "6.27"),
                        _tableRow("SERVICE CHARGE", "6.00"),
                        _tableRow("MONTH TOT", "329.13"),
                        _tableRow("PREV BAL", "791.00"),
                        _tableRow("BAL DUE", "1120.13"),
                        _tableRow("DUE BY", "PAY BAL DUE"),
                      ],
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
}
