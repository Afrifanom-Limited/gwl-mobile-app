import 'package:flutter/material.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/Constants.dart';

InputDecoration circularInputDecoration({
  required String title,
  IconButton? suffixIconButton,
  Color? fillColor,
  Widget? prefix,
  Widget? suffix,
  Color? errorTextColor,
  double? circularRadius,
  Color? counterColor,
  bool useDropDownPadding = false,
}) {
  return InputDecoration(
    suffixIcon: suffix ?? null,
    hintText: title,
    prefixIcon: prefix ?? null,
    filled: true,
    fillColor: fillColor ?? Constants.kPrimaryLightColor.withValues(alpha: 0.5),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(circularRadius ?? 17.w)),
      borderSide: BorderSide(color: Constants.kGreyColor.withValues(alpha: 0.02)),
    ),
    counterStyle: TextStyle(color: counterColor ?? Constants.kGreyColor),
    errorMaxLines: 5,
    errorStyle: TextStyle(color: errorTextColor ?? Constants.kRedColor, fontSize: 12.sp),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(circularRadius ?? 10.w)),
      borderSide: BorderSide(color: errorTextColor ?? Constants.kRedColor),
    ),
    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(circularRadius ?? 10.w))),
    contentPadding: EdgeInsets.symmetric(
      vertical: useDropDownPadding ? 5.h : 14.h,
      horizontal: useDropDownPadding ? 5.w : 18.w,
    ),
    isDense: true,
  );
}

TextStyle circularTextStyle({double? fontSize}) => TextStyle(fontSize: fontSize ?? 16.sp);

MaterialRoundedDatePickerStyle buildMaterialRoundedDatePickerStyle() {
  return MaterialRoundedDatePickerStyle(
    textStyleDayButton: TextStyle(fontSize: 24.sp, color: Colors.white),
    textStyleYearButton: TextStyle(fontSize: 34.sp, color: Colors.white),
    textStyleDayHeader: TextStyle(fontSize: 14.sp),
    textStyleMonthYearHeader: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
    paddingDateYearHeader: EdgeInsets.symmetric(vertical: 30.h, horizontal: 20.w),
    textStyleDayOnCalendarSelected: TextStyle(color: Colors.white),
    decorationDateSelected: BoxDecoration(color: Constants.kPrimaryColor, shape: BoxShape.circle),
    sizeArrow: 30.sp,
    textStyleButtonAction: TextStyle(
      fontSize: 14.sp,
    ),
    textStyleButtonPositive: TextStyle(fontSize: 14.sp, color: Constants.kPrimaryColor),
    textStyleButtonNegative: TextStyle(fontSize: 15.sp, color: Constants.kPrimaryColor),
    backgroundActionBar: Constants.kPrimaryLightColor,
  );
}
