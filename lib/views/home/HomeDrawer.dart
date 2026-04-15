import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/PageTransitions.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/views/complaint/ComplaintsList.dart';
import 'package:gwcl/views/home/Home.dart';
import 'package:gwcl/views/info/About.dart';
import 'package:gwcl/views/notifications/Notifications.dart';
import 'package:gwcl/views/report/RequestedReports.dart';
import 'package:gwcl/views/transactions/PayBill.dart';
import 'package:gwcl/views/transactions/PayBillForOthers.dart';

class HomeDrawer extends StatefulWidget {
  @override
  _HomeDrawerState createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListTileTheme(
        textColor: Constants.kWhiteColor,
        iconColor: Constants.kWhiteColor,
        child: ListView(
          children: [
            Constants.kSizeHeight_50,
            ListTile(
              onTap: () {
                Navigator.pushAndRemoveUntil(
                    context,
                    FadeRoute(
                      page: Home(
                        index: 0,
                      ),
                    ),
                    (route) => false);
              },
              leading: Icon(Icons.home_filled),
              title: GText(textData: "Home", textSize: 14.sp),
            ),
            ListTile(
              onTap: () {
                Navigator.pushAndRemoveUntil(
                    context,
                    FadeRoute(
                      page: Home(
                        index: 1,
                      ),
                    ),
                    (route) => false);
              },
              leading: Icon(Icons.question_answer_outlined),
              title: GText(textData: "Help", textSize: 14.sp),
            ),
            ListTile(
              onTap: () {
                Navigator.pushAndRemoveUntil(
                    context,
                    FadeRoute(
                      page: Home(
                        index: 2,
                      ),
                    ),
                    (route) => false);
              },
              leading: Icon(Icons.settings_sharp),
              title: GText(textData: "Settings", textSize: 14.sp),
            ),
            Divider(color: Constants.kPrimaryLightColor),
            // ListTile(
            //   onTap: () {
            //     Navigator.pushNamed(context, AutoPayments.id);
            //   },
            //   leading: Icon(Icons.sync),
            //   title: GText(textData: "My Auto-Payments", textSize: 14.sp),
            // ),
            ListTile(
              onTap: () async {
                var payBillSelection;
                if (Platform.isAndroid) {
                  payBillSelection = await payBillOptionAndroid(context);
                } else if (Platform.isIOS) {
                  payBillSelection = await payBillOptionIos(context);
                }
                if (payBillSelection == Constants.mySelf) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PayBill(
                        hasOldBalance: false,
                      ),
                    ),
                  );
                }
                if (payBillSelection == Constants.others) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PayBillForOthers(),
                    ),
                  );
                }
              },
              leading: Icon(Icons.payment),
              title: GText(textData: "Pay Bill", textSize: 14.sp),
            ),
            ListTile(
              onTap: () {
                Navigator.pushNamed(context, RequestedReports.id);
              },
              leading: Icon(Icons.file_copy_rounded),
              title: GText(textData: "Statements", textSize: 14.sp),
            ),
            ListTile(
              onTap: () {
                Navigator.pushNamed(context, ComplaintsList.id);
              },
              leading: Icon(Icons.comment_outlined),
              title: GText(textData: "My Complaints", textSize: 14.sp),
            ),
            ListTile(
              onTap: () {
                Navigator.pushNamed(context, Notifications.id);
              },
              leading: Icon(Icons.notifications_active),
              title: GText(textData: "Notifications", textSize: 14.sp),
            ),
            Divider(color: Constants.kPrimaryLightColor),
            ListTile(
              onTap: () {
                Navigator.pushNamed(context, About.id);
              },
              leading: Icon(Icons.help),
              title: GText(textData: "App Info", textSize: 14.sp),
            ),
            Divider(color: Constants.kPrimaryLightColor),
            ListTile(
              onTap: () => exit(0),
              leading: Icon(Icons.exit_to_app),
              title: GText(textData: "Exit", textSize: 14.sp),
            ),
            Constants.kSizeHeight_50
          ],
        ),
      ),
    );
  }
}
