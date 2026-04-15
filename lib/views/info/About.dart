import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/FetchFromWeb.dart';
import 'package:gwcl/helpers/Functions.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/templates/AppHeaders.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

import '../../mixpanel.dart';

class About extends StatefulWidget {
  static const String id = "/about";
  @override
  _AboutState createState() => _AboutState();
}

class _AboutState extends State<About> {
  bool _loading = false;
  String _appVersion = "1.0.0";

  _getAppVersion() async {
    Map packageInfo = await getDevicePackageInfo();
    setState(() {
      _appVersion = packageInfo.values.toList()[2];
    });
  }

  @override
  void initState() {
    _getAppVersion();
    mixpanel?.track('View About');
    super.initState();
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
              title: "About",
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
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Constants.indexHorizontalSpace,
                vertical: Constants.indexVerticalSpace,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Constants.kSizeHeight_20,
                  Expanded(
                    flex: 10,
                    child: Column(
                      children: [
                        Image(
                          image: Constants.kAppLogo,
                          height: 100.h,
                        ),
                        Constants.kSizeHeight_20,
                        Center(
                          child: Text(
                            Constants.appTitleFull,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).primaryColor),
                          ),
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: GText(
                              textData: Constants.appTitle,
                              textFont: Constants.kFontLight,
                              textSize: 24.sp,
                              textColor: Constants.kPrimaryColor,
                            ),
                          ),
                        ),
                        GText(
                          textData: "Version $_appVersion",
                          textSize: 10.sp,
                          textColor: Constants.kGreyColor,
                        ),
                        Constants.kSizeHeight_20,
                        InkWell(
                          child: GText(
                            textData: "Terms of Use",
                            textColor: Constants.kPrimaryColor,
                            textSize: 14.sp,
                            textFont: Constants.kFontLight,
                            textDecoration: TextDecoration.underline,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FetchFromWeb(url: Constants.gwclTerms),
                              ),
                            );
                          },
                        ),
                        Constants.kSizeHeight_10,
                        InkWell(
                          child: GText(
                            textData: "Privacy Policy",
                            textColor: Constants.kPrimaryColor,
                            textSize: 14.sp,
                            textFont: Constants.kFontLight,
                            textDecoration: TextDecoration.underline,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FetchFromWeb(url: Constants.gwclPrivacyPolicy),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  buildPoweredByAfrifanom(),
                  Constants.kSizeHeight_20,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
