import 'package:flutter/material.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/templates/AppHeaders.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/templates/Dialogs.dart';
import 'package:gwcl/views/account/EditEmailAddress.dart';
import 'package:gwcl/views/account/EditGPGPS.dart';
import 'package:gwcl/views/account/EditPhoneNumber.dart';
import 'package:gwcl/views/index/Welcome.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class Account extends StatefulWidget {
  static const String id = "/account";
  @override
  _AccountState createState() => _AccountState();
}

class _AccountState extends State<Account> {
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
              title: "Account",
            ),
          ),
        ),
        body: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                child: Table(
                  border: TableBorder.all(color: Constants.kPrimaryColor),
                  columnWidths: {
                    0: FractionColumnWidth(.35),
                  },
                  children: [
                    _tableRow("Username", "Kwabena"),
                    _tableRow("Email", "Not Set"),
                    _tableRow("Phone Number", "0549112267"),
                    _tableRow("Region", "Greater Accra"),
                    _tableRow("District", "Ayawaso East Municipal District"),
                    _tableRow("GPGPS", "GW9384229"),
                    _tableRow("No. of Meters", "2"),
                  ],
                ),
              ),
              Constants.kSizeHeight_10,
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: Column(
                  children: [
                    OutlinedButton(
                      child: ListTile(
                        title: GText(
                          textData: "Change Phone Number",
                          textSize: 12.sp,
                          textColor: Constants.kPrimaryColor,
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 14.w,
                          color: Constants.kPrimaryColor,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, EditPhoneNumber.id);
                      },
                    ),
                    OutlinedButton(
                      child: ListTile(
                        title: GText(
                          textData: "Add/Change GPGPS",
                          textSize: 12.sp,
                          textColor: Constants.kPrimaryColor,
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 14.w,
                          color: Constants.kPrimaryColor,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, EditGPGPS.id);
                      },
                    ),
                    OutlinedButton(
                      child: ListTile(
                        title: GText(
                          textData: "Add/Change Email Address",
                          textSize: 12.sp,
                          textColor: Constants.kPrimaryColor,
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 14.w,
                          color: Constants.kPrimaryColor,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, EditEmailAddress.id);
                      },
                    ),
                    OutlinedButton(
                      child: ListTile(
                        title: GText(
                          textData: "Sign Out",
                          textColor: Constants.kRedColor,
                          textSize: 13.sp,
                        ),
                        trailing: Icon(
                          Icons.power_settings_new,
                          size: 18.w,
                          color: Constants.kRedColor,
                        ),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => new ConfirmDialog(
                            title: "Sign out?",
                            content: "You will be logged out from your account"
                                " and redirected to the Welcome screen. "
                                "All cached data will be cleared.",
                            confirmText: "Sign Out",
                            confirmTextColor: Colors.red,
                            confirm: () {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                  Welcome.id, (Route<dynamic> route) => false);
                            },
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
    );
  }
}
