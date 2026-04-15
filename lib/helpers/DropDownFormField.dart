import 'package:flutter/material.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DropDownFormField extends FormField<dynamic> {
  final String titleText;
  final String hintText;
  final bool required;
  final String errorText;
  final dynamic value;
  final List dataSource;
  final String textField;
  final String valueField;
  final String labelImage;
  final Function onChanged;
  final bool filled;
  final Color fillColor;
  final InputDecoration? inputDecoration;
  final EdgeInsets contentPadding;

  DropDownFormField(
      {Key? key,
        FormFieldSetter<dynamic>? onSaved,
        FormFieldValidator<dynamic>? validator,
        bool autoValidate = false,
        this.titleText = '',
        this.hintText = 'Select ...',
        this.required = false,
        this.errorText = 'Please select one option',
        this.value,
        required this.dataSource,
        required this.textField,
        required this.valueField,
        this.labelImage = "",
        required this.onChanged,
        this.inputDecoration,
        this.filled = true,
        this.fillColor = Constants.kWhiteColor,
        this.contentPadding =
        const EdgeInsets.symmetric(horizontal: 10, vertical: 10)})
      : super(
    key: key,
    onSaved: onSaved,
    validator: validator,
    initialValue: value == '' ? null : value,
    builder: (FormFieldState<dynamic> state) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InputDecorator(
            decoration: inputDecoration ??
                InputDecoration(
                    contentPadding: contentPadding,
                    filled: filled,
                    fillColor: fillColor),
            child: Container(
              margin: EdgeInsets.only(right: 7.w),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<dynamic>(
                  icon: const SizedBox.shrink(),
                  isExpanded: true,
                  dropdownColor: Constants.kWhiteColor,
                  hint: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: GText(
                      textData: hintText,
                      textColor: Colors.grey.shade500,
                      textSize: 14.sp,
                    ),
                  ),
                  value: value == '' ? null : value,
                  onChanged: (dynamic newValue) {
                    state.didChange(newValue);
                    onChanged(newValue);
                  },
                  items: dataSource.map((item) {
                    return DropdownMenuItem<dynamic>(
                      value: item[valueField],
                      child: ListTile(
                        leading: item[labelImage] == null
                            ? null
                            : Container(
                          margin: EdgeInsets.only(bottom: 5.h),
                          child: Image(
                            image: AssetImage(item[labelImage]),
                            height: item[valueField] == "CARD"
                                ? 15.h
                                : 22.h,
                          ),
                        ),
                        title: Container(
                          width: 80.w,
                          margin: EdgeInsets.only(bottom: 5.h),
                          child: GText(
                            textData: item[textField],
                            textSize: 14.sp,
                            textMaxLines: 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          SizedBox(height: state.hasError ? 5.0 : 0.0),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w),
            child: GText(
              textData: state.errorText ?? '',
              textColor: Colors.red,
              textSize: state.hasError ? 11.sp : 0.0,
            ),
          ),
        ],
      );
    },
  );
}