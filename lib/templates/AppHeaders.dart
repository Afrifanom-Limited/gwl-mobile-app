import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/FlashHelper.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/templates/CustomBadge.dart';

class InfoHeader extends StatelessWidget {
  const InfoHeader({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      systemOverlayStyle: SystemUiOverlayStyle.light,
      backgroundColor: Constants.kPrimaryColor,
      elevation: 1.0,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        margin: EdgeInsets.only(top: 30.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Builder(builder: (BuildContext context) {
              return CustomBadge(
                iconData: Icons.keyboard_backspace_sharp,
                alertCount: 0,
                onTap: () {
                  FocusScope.of(context).requestFocus(FocusNode());
                  Navigator.pop(context, false);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

class GeneralHeader extends StatefulWidget {
  final String title;
  final bool canGoBack;
  final Widget? actionButton;
  const GeneralHeader({
    Key? key,
    required this.title,
    this.canGoBack = true,
    this.actionButton,
  }) : super(key: key);

  @override
  _GeneralHeaderState createState() => _GeneralHeaderState();
}

class _GeneralHeaderState extends State<GeneralHeader> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      actions: [widget.actionButton ?? SizedBox()],
      automaticallyImplyLeading: false,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      flexibleSpace: Container(
        margin: EdgeInsets.only(top: 30.h),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Builder(builder: (BuildContext context) {
                return CustomBadge(
                  iconData: Icons.keyboard_backspace_sharp,
                  alertCount: 0,
                  onTap: () {
                    if (widget.canGoBack) {
                      FocusScope.of(context).requestFocus(FocusNode());
                      Navigator.pop(context, false);
                    } else {
                      showBasicsFlash(
                        context,
                        "Back button is disable because this screen action is required",
                        textColor: Constants.kWhiteColor,
                        bgColor: Constants.kWarningColor,
                        duration: Duration(seconds: 5),
                      );
                    }
                  },
                );
              }),
            ),
            Expanded(
              flex: 5,
              child: Builder(builder: (BuildContext context) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GText(
                    textData: widget.title,
                    textSize: 14.sp,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class LightHeader extends StatelessWidget {
  final bool canGoBack;
  const LightHeader({
    Key? key,
    this.canGoBack = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Constants.kWhiteColor,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        margin: EdgeInsets.only(top: 30.h),
        child: Row(
          children: <Widget>[],
        ),
      ),
    );
  }
}

class DarkHeader extends StatelessWidget {
  final Widget? widget;
  const DarkHeader({
    Key? key,
    this.widget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Constants.kPrimaryColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        margin: EdgeInsets.only(top: 30.h),
        child: Row(
          children: <Widget>[
            if (widget != null)
              Expanded(
                child: Builder(builder: (BuildContext context) {
                  return CustomBadge(
                    iconData: Icons.keyboard_backspace_sharp,
                    alertCount: 0,
                    onTap: () {
                      FocusScope.of(context).requestFocus(FocusNode());
                      Navigator.pop(context, false);
                    },
                  );
                }),
              ),
            widget ?? SizedBox()
          ],
        ),
      ),
      systemOverlayStyle: SystemUiOverlayStyle.light,
    );
  }
}
