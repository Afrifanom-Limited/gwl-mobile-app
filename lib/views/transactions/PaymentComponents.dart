import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Functions.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/models/Meter.dart';
import 'package:gwcl/templates/Modals.dart';
import 'package:gwcl/templates/download_file_button.dart';
import 'package:intl/intl.dart';

final _fullDateFormat = DateFormat("dd MMMM, yyyy hh:mm aaa");
String _formatDate(DateTime date, DateFormat format) {
  try {
    return _fullDateFormat.format(date);
    // return DateFormat.jm().format(date);
  } catch (e) {}
  return '';
}

class Transaction extends StatelessWidget {
  final payment;
  const Transaction({Key? key, required this.payment}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    late String transactionName;
    late IconData transactionIconData;
    Color _color = Colors.orange;

    switch (payment["payment_status"]) {
      case 'success':
        transactionName = "Success";
        transactionIconData = Icons.check_circle_outline_outlined;
        _color = Color(0xFF42AE49);
        break;
      case 'failed':
        transactionName = "Failed";
        transactionIconData = Icons.error_outline;
        _color = Constants.kRedColor;
        break;
      case 'pending':
        transactionName = "Pending";
        transactionIconData = Icons.history_toggle_off_outlined;
        _color = Colors.orange;
        break;
    }

    String accountNumber = "";
    if (payment["meter_account_number"] != null) {
      accountNumber = formatCustomerAccountNumber(payment["meter_account_number"]);
    } else if (payment["meter_account_number"] != null) {
      accountNumber = formatCustomerAccountNumber(payment["gwcl_customer_number"]);
    }

    return GestureDetector(
      onTap: () {
        var transDate = "N/A";

        var transId = payment['payment_history_id'];
        var fileUrl = "/generate-payment-receipt?payment_id=$transId";

        if (payment["date_created"] != null) {
          var tDate = DateTime.parse(payment["date_created"]);
          transDate = _formatDate(tDate, _fullDateFormat);
        }
        HapticFeedback.lightImpact();
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => Container(
            child: ScreenModal(
              title: "$transactionName",
              titleColor: _color,
              isLoading: false,
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      tableRow("Account #", "${payment["meter_account_number"] == null ? payment["gwcl_customer_number"] : payment["meter_account_number"]}"),
                      tableRow("Amount", "${payment["actual_amount"] == null ? 'N/A' : payment["actual_amount"]}"),
                      tableRow("Prev. Bal", "${payment["old_balance"] == null ? 'N/A' : payment["old_balance"]}"),
                      tableRow("New Bal", "${payment["new_balance"] == null ? 'N/A' : payment["new_balance"]}"),
                      tableRow("Used", "${payment["meter_last_reading"] == null ? 'N/A' : payment["meter_last_reading"]}"),
                      tableRow("Ref. Key", "${payment["transaction_id"]}"),
                      tableRow("Network", "${payment["network"].toString().toUpperCase()}"),
                      tableRow("Channel", "${payment["payment_method"].toString().toUpperCase()}"),
                      tableRow("Trans. Date", transDate),
                      tableRow("Status", "${payment["payment_status"].toString().toUpperCase()}", secondColColor: _color),
                    ],
                  ),
                  Constants.kSizeHeight_10,
                  DownloadFileButton(
                    pdfPath: fileUrl,
                    buttonTitle: "Download Receipt",
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 7.w),
        padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 15.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: Constants.kGreyColor.withValues(alpha: 0.1),
              spreadRadius: 2,
              blurRadius: 2.0,
              offset: Offset(2, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      GText(
                        textData: "${payment["payer_name"] == null ? payment["msisdn"] : payment["payer_name"]}",
                        textSize: 12.sp,
                        textFont: Constants.kFontMedium,
                        textColor: Constants.kPrimaryColor,
                        textMaxLines: 1,
                      ),
                      GText(
                        textData: accountNumber,
                        textSize: 13.5.sp,
                        textFont: Constants.kFontBold,
                        textColor: Colors.grey.shade700,
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      GText(
                        textData: "GHS ${payment["amount"]}",
                        textFont: Constants.kFontMedium,
                        textSize: 15.sp,
                        textColor: _color,
                      ),
                      GText(
                        textData: "$transactionName",
                        textFont: Constants.kFontBold,
                        textColor: _color,
                      ),
                      GText(
                        textData: "${payment["payment_method"].toString().toUpperCase() == ""
                            "CARD" ? payment["network"].toString().toUpperCase() : payment["payment_method"].toString().toUpperCase()}",
                        textFont: Constants.kFontMedium,
                        textColor: Colors.grey.shade700,
                      ),
                      GText(
                        textData: "${_formatDate(DateTime.parse(payment['date_created']), _fullDateFormat)}",
                        textFont: Constants.kFontLight,
                        textSize: 8.sp,
                        textColor: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Constants.kSizeHeight_5,
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: <Widget>[
            //     Icon(
            //       transactionIconData,
            //       size: 15.w,
            //       color: _color,
            //     ),
            //
            //   ],
            // ),
            // Constants.kSizeHeight_5,
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: <Widget>[
            //
            //   ],
            // ),
          ],
        ),
      ),
    );
  }
}

class GWCLTransaction extends StatelessWidget {
  final payment;
  final Meter meter;
  const GWCLTransaction({
    Key? key,
    required this.payment,
    required this.meter,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    dynamic _format = DateFormat("dd MMMM, yyyy");

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => Container(
            child: ScreenModal(
              title: "Statement",
              isLoading: false,
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Constants.kSizeHeight_20,
                  Table(
                    border: TableBorder.symmetric(
                        inside: BorderSide(
                      width: 1,
                    )),
                    columnWidths: {
                      0: FractionColumnWidth(.45),
                    },
                    children: [
                      tableRow("Account # ", "${formatCustomerAccountNumber(meter.accountNumber)}"),
                      tableRow("Trans. Type", "${payment["trans_type"]}"),
                      tableRow(
                        "Debit",
                        "${payment["debit"]}",
                        secondColColor: Constants.kRedLightColor,
                      ),
                      tableRow("Credit", "${payment["credit"]}"),
                      tableRow("Trans. Sequence", "${payment["no_series"]}"),
                      tableRow("Balance", "GHS ${payment["balance"]}"),
                      tableRow("Trans. Ref.", "${payment["trans_ref"] != "" ? payment["trans_ref"] : "None"}"),
                      tableRow("Date", "${_format.format(DateTime.parse(payment["trans_date"]))}"),
                    ],
                  ),
                  Constants.kSizeHeight_10,
                ],
              ),
            ),
          ),
        );
      },
      child: Card(
        elevation: 2,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 15.w),
          padding: EdgeInsets.symmetric(vertical: 10.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  GText(
                    textData: "Account # ${formatCustomerAccountNumber(meter.accountNumber)}",
                    textSize: 13.sp,
                    textFont: Constants.kFontMedium,
                  ),
                  GText(
                    textData: "${payment["trans_type"]}",
                    textFont: Constants.kFontMedium,
                    textSize: 12.sp,
                    textColor: Constants.kPrimaryColor,
                  ),
                ],
              ),
              Constants.kSizeHeight_5,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  GText(
                    textData: "Transaction Ref: "
                        "${payment["trans_ref"] != "" ? payment["trans_ref"] : "None"}",
                    textFont: Constants.kFontLight,
                    textSize: 12.sp,
                    textColor: Constants.kPrimaryColor,
                  ),
                  if (payment["trans_type"] == "BILL CHARGE")
                    GText(
                      textData: "Debit: ${payment["debit"]}",
                      textFont: Constants.kFontLight,
                      textColor: Constants.kRedLightColor,
                      textSize: 12.sp,
                    )
                  else
                    GText(
                      textData: "Credit: ${payment["credit"]}",
                      textFont: Constants.kFontLight,
                      textSize: 12.sp,
                    ),
                ],
              ),
              Constants.kSizeHeight_5,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  GText(
                    textData: "${_format.format(DateTime.parse(payment["trans_date"]))}",
                    textFont: Constants.kFontLight,
                    textSize: 8.sp,
                  ),
                  GText(
                    textData: "Balance: GHS ${payment["balance"]}",
                    textFont: Constants.kFontBold,
                    textColor: payment["trans_type"] == "BILL CHARGE" ? Constants.kGreyColor : Constants.kGreenLightColor,
                    textSize: 11.sp,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
