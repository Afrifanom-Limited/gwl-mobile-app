import 'package:awesome_card/awesome_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/Buttons.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/Text.dart';

class ScreenModal extends StatefulWidget {
  final Widget body;
  final bool isLoading;
  final String title;
  final Color? titleColor;
  final double? height;

  const ScreenModal({
    Key? key,
    required this.body,
    required this.title,
    this.titleColor,
    this.isLoading = false,
    this.height,
  }) : super(key: key);

  @override
  _ScreenModalState createState() => _ScreenModalState();
}

class _ScreenModalState extends State<ScreenModal> {
  @override
  Widget build(BuildContext context) {
    double _height = MediaQuery.of(context).size.height;
    return Container(
      height: _height * (widget.height ?? 0.80),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: 20.h, left: 10.w, right: 10.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(left: 10.w, right: 10.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(top: 14.h),
                    child: GText(
                      textData: widget.title,
                      textFont: Constants.kFontMedium,
                      textColor: widget.titleColor ?? Constants.kPrimaryColor,
                      textSize: 20.sp,
                    ),
                  ),
                  ClipOval(
                    child: Material(
                      color: Constants.kPrimaryColor.withOpacity(0.2), // button color
                      child: InkWell(
                        splashColor: Constants.kPrimaryColor.withOpacity(0.5),
                        child: SizedBox(width: 50, height: 50, child: Icon(Icons.close)),
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Constants.kSizeHeight_10,
            Flexible(
              flex: 10,
              fit: FlexFit.tight,
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Container(
                  child: widget.isLoading
                      ? Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.h),
                          child: SizedBox(
                            height: 2.h,
                            child: BarLoader(
                              barColor: Constants.kPrimaryColor,
                            ),
                          ),
                        )
                      : widget.body,
                ),
              ),
            ),
            Constants.kSizeHeight_20,
          ],
        ),
      ),
    );
  }
}

class CardModal extends StatefulWidget {
  final String cardNumber, expiryDate, cardHolderName, cvv;
  final String? bankName;

  const CardModal({Key? key, required this.cardNumber, required this.expiryDate, required this.cardHolderName, this.bankName, required this.cvv}) : super(key: key);

  @override
  _CardModalState createState() => _CardModalState();
}

class _CardModalState extends State<CardModal> {
  bool _showBack = false;

  _toggleShowBack() {
    setState(() {
      _showBack = !_showBack;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double _height = MediaQuery.of(context).size.height;
    return Container(
      height: _height * 0.5,
      decoration: BoxDecoration(
        color: Constants.kWhiteColor.withOpacity(0.01),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Constants.kSizeHeight_20,
            Constants.kSizeHeight_10,
            CreditCard(
              cardNumber: widget.cardNumber,
              cardExpiry: widget.expiryDate,
              cardHolderName: widget.cardHolderName,
              cvv: widget.cvv,
              bankName: "Debit Card",
              showBackSide: _showBack,
              backTextColor: Constants.kWhiteColor,
              showShadow: true,
              frontBackground: CardBackgrounds.black,
              backBackground: CardBackgrounds.white,
            ),
            Constants.kSizeHeight_20,
            buildOutlinedButton(
              title: "Rotate Card",
              onPressed: () {
                HapticFeedback.lightImpact();
                _toggleShowBack();
              },
              bgColor: Constants.kPrimaryLightColor,
              textColor: Constants.kPrimaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
