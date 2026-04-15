import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ShadowText extends StatelessWidget {
  ShadowText({required this.textData, required this.textStyle});

  final String textData;
  final TextStyle textStyle;

  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        children: [
          Positioned(
            top: 1.0,
            left: 1.0,
            child: Text(
              textData,
              style: textStyle.copyWith(color: Colors.black.withOpacity(0.5)),
            ),
          ),
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
            child: Text(textData, style: textStyle),
          ),
        ],
      ),
    );
  }
}

class GText extends StatelessWidget {
  final String textData;
  final double? textHeight;
  final Color? textColor;
  final double textSize;
  final FontWeight? textWeight;
  final double? textLetterSpacing;
  final TextAlign? textAlign;
  final int? textMaxLines;
  final String textFont;
  final TextDecoration? textDecoration;
  final TextOverflow? textOverflow;

  const GText({
    required this.textData,
    this.textHeight,
    this.textColor,
    this.textSize = 12,
    this.textWeight,
    this.textLetterSpacing,
    this.textAlign,
    this.textMaxLines,
    this.textFont = Constants.kFont,
    this.textDecoration,
    this.textOverflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      textData,
      style: TextStyle(
        color: textColor,
        fontSize: textSize.sp,
        letterSpacing: textLetterSpacing,
        fontWeight: textWeight,
        height: textHeight,
        fontFamily: textFont,
        decoration: textDecoration ?? TextDecoration.none,
      ),
      textAlign: textAlign,
      maxLines: textMaxLines ?? 2,
      softWrap: true,
      overflow: textOverflow ?? TextOverflow.ellipsis,
    );
  }
}
