import 'package:flutter/material.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

ElevatedButton buildElevatedButton(
    {required String title,
    Color? bgColor,
    Color? textColor,
    double? borderRadius,
    EdgeInsetsGeometry? padding,
    VoidCallback? onPressed}) {
  return ElevatedButton(
    child: Padding(
      padding: padding ?? EdgeInsets.symmetric(vertical: 12.h),
      child: GText(
        textData: title,
        textColor: textColor ?? Constants.kWhiteColor,
        textSize: 14.sp,
      ),
    ),
    style: ButtonStyle(
      backgroundColor:
          MaterialStateProperty.all<Color>(bgColor ?? Constants.kPrimaryColor),
      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 10.w),
        ),
      ),
    ),
    onPressed: onPressed,
  );
}

TextButton buildTextButton(
    {required String title,
    double? textSize,
    Color? textColor,
    VoidCallback? onPressed}) {
  return TextButton(
    child: GText(
      textData: title,
      textFont: Constants.kFontLight,
      textSize: textSize ?? 14.sp,
      textColor: textColor ?? Constants.kAccentColor,
    ),
    onPressed: onPressed,
  );
}

OutlinedButton buildOutlinedButton(
    {required String title,
    String? titleFont,
    Color? bgColor,
    double? textSize,
    Color? textColor,
    required VoidCallback onPressed,
    borderRadius,
    EdgeInsetsGeometry? padding}) {
  return OutlinedButton(
    child: Padding(
        padding: padding ?? EdgeInsets.all(5.w),
        child: GText(
          textData: title,
          textFont: titleFont ?? Constants.kFontLight,
          textSize: textSize ?? 14.sp,
          textColor: textColor ?? Constants.kWhiteColor,
        )),
    style: ButtonStyle(
      backgroundColor:
          MaterialStateProperty.all<Color>(bgColor ?? Constants.kPrimaryColor),
      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 10.w),
          side: BorderSide(
            color: Constants.kAccentColor,
          ),
        ),
      ),
    ),
    onPressed: onPressed,
  );
}

OutlinedButton localAuthOutlinedButton({required VoidCallback onPressed}) {
  return OutlinedButton(
    child: Padding(
      padding: EdgeInsets.all(5.w),
      child: Row(
        children: [
          Icon(
            Icons.fingerprint,
            size: 28.sp,
            color: Constants.kPrimaryColor,
          ),
          Icon(
            Icons.tag_faces_outlined,
            size: 28.sp,
            color: Constants.kPrimaryColor,
          ),
        ],
      ),
    ),
    style: ButtonStyle(
      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.w),
        ),
      ),
    ),
    onPressed: onPressed,
  );
}
