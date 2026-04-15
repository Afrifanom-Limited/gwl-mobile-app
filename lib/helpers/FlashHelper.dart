import 'package:flash/flash_helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flash/flash.dart';
import 'package:flutter/material.dart';
import 'package:gwcl/helpers/Text.dart';

showBasicsFlash(BuildContext context, message, {Color textColor = Colors.white, required Color bgColor, Duration? duration}) {
  context.showFlash<bool>(
    builder: (context, controller) => FlashBar(
      backgroundColor: bgColor,
      controller: controller,
      content: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
        child: Center(
          child: GText(
            textData: '$message',
            textSize: 12.sp,
            // textFont: Constants.kFontMedium,
            textColor: textColor,
            textMaxLines: 3,
          ),
        ),
      ),
    ),
  );
}
