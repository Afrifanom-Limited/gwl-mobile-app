import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/BlinkingWidget.dart';
import 'package:gwcl/helpers/Buttons.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/FetchFromWeb.dart';
import 'package:gwcl/helpers/Functions.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/system/LocalDatabase.dart';
import 'package:gwcl/views/complaint/ComplaintsList.dart';
import 'package:gwcl/views/complaint/LodgeComplaint.dart';
import 'package:gwcl/views/feedback/UserFeedback.dart';
import 'package:gwcl/views/home/Home.dart';
import 'package:gwcl/views/report/Report.dart';
import 'package:gwcl/views/report/RequestedReports.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:share_plus/share_plus.dart';

import '../../mixpanel.dart';

class Help extends StatefulWidget {
  static const String id = "/help";
  final dynamic customer;
  const Help({Key? key, required this.customer}) : super(key: key);
  @override
  _HelpState createState() => _HelpState();
}

class _HelpState extends State<Help> {
  bool _loading = false;
  var _meters = List.empty(growable: true);

  _loadMeters() async {
    setState(() => _loading = true);
    var _localDb = new LocalDatabase();
    var _res = await _localDb.getMeters();
    if (mounted) {
      setState(() {
        _loading = false;
        this._meters = _res;
      });
      return;
    }
  }

  @override
  void initState() {
    _loadMeters();
    super.initState();
    mixpanel?.track('View Help');
  }

  @override
  void dispose() {
    super.dispose();
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
      child: WillPopScope(
        onWillPop: () {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => Home(index: 0)), (route) => false);
          return new Future(() => false);
        },
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Constants.kSizeHeight_20,
              Image(
                image: Constants.kSupportIcon,
                height: 40.h,
                colorBlendMode: BlendMode.colorDodge,
              ),
              Constants.kSizeHeight_20,
              Center(
                child: GText(
                  textData: "Help Center",
                  textFont: Constants.kFontLight,
                  textSize: 20.sp,
                ),
              ),
              Constants.kSizeHeight_20,
              OutlinedButton(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BlinkingWidget(
                        widget: Icon(
                          Icons.call,
                          size: 24.sp,
                          color: Constants.kPrimaryColor,
                        ),
                      ),
                      Constants.kSizeHeight_10,
                      GText(
                        textData: "Call Us",
                        textColor: Constants.kPrimaryColor,
                        textSize: 15.sp,
                      ),
                    ],
                  ),
                ),
                onPressed: () => callLauncher(Constants.gwclTelephone),
              ),
              Constants.kSizeHeight_20,
              Divider(height: 0),
              TextButton(
                child: Padding(
                  padding: EdgeInsets.only(top: 12.h, bottom: 2.h),
                  child: ListTile(
                    title: GText(
                      textData: "Lodge Complaint",
                      textSize: 14.sp,
                      textColor: Constants.kPrimaryColor,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GText(
                          textData: "We take all complaints seriously and look to resolve "
                              "all complaints directly on a prompt and fair basis. ",
                          textMaxLines: 5,
                          textSize: 12.sp,
                          textColor: Constants.kPrimaryColor.withOpacity(0.6),
                        ),
                        Constants.kSizeHeight_5,
                        buildOutlinedButton(
                          bgColor: Constants.kPrimaryLightColor,
                          textColor: Constants.kAccentColor,
                          title: "View all complaints",
                          borderRadius: 10.w,
                          onPressed: () {
                            Navigator.pushNamed(context, ComplaintsList.id);
                          },
                        ),
                      ],
                    ),
                    leading: Icon(
                      Icons.comment_outlined,
                      size: 22.sp,
                      color: Constants.kPrimaryColor,
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 14.sp,
                      color: Constants.kPrimaryColor,
                    ),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, LodgeComplaint.id);
                },
              ),
              if (_meters.length > 0)
                Column(
                  children: [
                    Divider(height: 0, color: Constants.kGreyColor),
                    TextButton(
                      child: Padding(
                        padding: EdgeInsets.only(top: 12.h, bottom: 2.h),
                        child: ListTile(
                          title: GText(
                            textData: "Statement Request",
                            textSize: 14.sp,
                            textColor: Constants.kPrimaryColor,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              GText(
                                textData: "Tap to make a request for statement of billing "
                                    "or statement of payment",
                                textMaxLines: 5,
                                textSize: 12.sp,
                                textColor: Constants.kPrimaryColor.withOpacity(0.6),
                              ),
                              Constants.kSizeHeight_5,
                              buildOutlinedButton(
                                bgColor: Constants.kPrimaryLightColor,
                                textColor: Constants.kAccentColor,
                                title: "View all statements",
                                borderRadius: 10.w,
                                onPressed: () {
                                  Navigator.pushNamed(context, RequestedReports.id);
                                },
                              ),
                            ],
                          ),
                          leading: Icon(
                            Icons.library_books_sharp,
                            size: 22.sp,
                            color: Constants.kPrimaryColor,
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 14.sp,
                            color: Constants.kPrimaryColor,
                          ),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Report(
                              customer: widget.customer,
                              reportType: 'billing',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              Divider(height: 0, color: Constants.kGreyColor),
              TextButton(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 1.h),
                  child: ListTile(
                    title: GText(
                      textData: "User Experience Feedback",
                      textSize: 14.sp,
                      textColor: Constants.kPrimaryColor,
                    ),
                    leading: Icon(
                      Icons.star_half_outlined,
                      size: 26.sp,
                      color: Constants.kPrimaryColor,
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 14.w),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, UserFeedback.id);
                },
              ),
              Divider(height: 0, color: Constants.kGreyColor),
              TextButton(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 1.h),
                  child: ListTile(
                    title: GText(
                      textData: "Frequently Asked Questions",
                      textSize: 14.sp,
                      textColor: Constants.kPrimaryColor,
                    ),
                    leading: Icon(
                      Icons.help,
                      size: 24.sp,
                      color: Constants.kPrimaryColor,
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 14.w),
                  ),
                ),
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FetchFromWeb(url: Constants.gwclFaq),
                    ),
                  );
                },
              ),
              Divider(height: 0, color: Constants.kGreyColor),
              TextButton(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 1.h),
                  child: ListTile(
                    title: GText(
                      textData: "Invite A Friend",
                      textSize: 14.sp,
                      textColor: Constants.kPrimaryColor,
                    ),
                    leading: Icon(
                      Icons.share_outlined,
                      size: 22.sp,
                      color: Constants.kPrimaryColor,
                    ),
                    trailing: _loading
                        ? SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularLoader(
                              loaderColor: Constants.kPrimaryColor,
                              strokeWidth: 2.0,
                              isSmall: true,
                            ),
                          )
                        : Icon(Icons.arrow_forward_ios, size: 14.w),
                  ),
                ),
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  setState(() => _loading = true);
                  await Future.delayed(const Duration(seconds: 1), () {
                    Share.share(appShare("APP", null));
                  });
                  setState(() => _loading = false);
                },
              ),
              Divider(height: 0, color: Constants.kGreyColor),
              Constants.kSizeHeight_50,
            ],
          ),
        ),
      ),
    );
  }
}
