import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Functions.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/templates/AppHeaders.dart';
import 'package:gwcl/views/index/Login.dart';
import 'package:gwcl/views/index/RegisterCustomer.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class Welcome extends StatefulWidget {
  static const String id = "welcome";

  @override
  _WelcomeState createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation _animation;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: 500,
      ),
    );
    _animationController.forward();
    _animation = CurvedAnimation(curve: Curves.easeInExpo, parent: _animationController);
    _animationController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _animationController.dispose();
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
      child: Scaffold(
        backgroundColor: Constants.kPrimaryColor,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(10.h),
          child: DarkHeader(),
        ),
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(image: Constants.kBgOne, fit: BoxFit.cover),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Constants.kSizeHeight_20,
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Image(
                          image: Constants.kAppLogoWhite,
                          height: _animation.value * 120.h,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: GText(
                              textData: Constants.appTitle,
                              textFont: Constants.kFontLight,
                              textSize: 20.sp,
                              textColor: Constants.kWhiteColor,
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            Constants.appTitleFull,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Constants.kWhiteColor),
                          ),
                        ),
                        Constants.kSizeHeight_20,
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 60.w),
                          child: ElevatedButton(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              child: GText(
                                textData: "Register",
                                textColor: Constants.kPrimaryColor,
                                textSize: 14.sp,
                              ),
                            ),
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(Constants.kWhiteColor),
                              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.w),
                                ),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pushNamed(context, RegisterCustomer.id);
                            },
                          ),
                        ),
                        Constants.kSizeHeight_10,
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 60.w),
                          child: TextButton(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 6.h),
                              child: GText(
                                textData: "Sign In",
                                textSize: 14.sp,
                                textColor: Constants.kWhiteColor,
                              ),
                            ),
                            style: ButtonStyle(
                              shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.w),
                                  side: BorderSide(
                                    color: Constants.kWhiteColor,
                                  ),
                                ),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pushNamed(context, Login.id);
                            },
                          ),
                        ),
                        Constants.kSizeHeight_20
                      ],
                    ),
                  ),
                  buildPoweredByAfrifanom(),
                  Constants.kSizeHeight_20
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
