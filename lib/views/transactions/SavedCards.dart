import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gwcl/helpers/Buttons.dart';
import 'package:gwcl/helpers/ColumnBuilder.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/FlashHelper.dart';
import 'package:gwcl/helpers/Functions.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/models/SavedCard.dart';
import 'package:gwcl/system/LocalDatabase.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/templates/AppHeaders.dart';
import 'package:gwcl/templates/Dialogs.dart';
import 'package:gwcl/views/transactions/CardPaymentForm.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class SavedCards extends StatefulWidget {
  final dynamic paymentDetails;
  final dynamic accountName;
  final dynamic accountNumber;

  const SavedCards(
      {Key? key, this.paymentDetails, this.accountName, this.accountNumber})
      : super(key: key);

  @override
  _SavedCardsState createState() => _SavedCardsState();
}

class _SavedCardsState extends State<SavedCards> {
  bool _loading = false, _refreshing = false;
  var _savedCards = List.empty(growable: true);

  _loadReportRequests() async {
    var _localDb = new LocalDatabase();
    var _res = await _localDb.getCards();
    if (mounted) {
      setState(() => this._savedCards = _res);
      return;
    }
  }

  @override
  void initState() {
    _loadReportRequests();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: _loading,
      color: Constants.kWhiteColor.withValues(alpha: 0.8),
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
                title: "Saved Cards",
                actionButton: Container(
                  margin: EdgeInsets.only(top: 22.h, right: 10.w),
                  child: IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color: Constants.kWhiteColor,
                    ),
                    onPressed: () {
                      _loadReportRequests();
                      showBasicsFlash(
                        context,
                        "Saved cards list has been refreshed",
                        textColor: Constants.kAccentColor,
                        bgColor: Constants.kWhiteColor,
                      );
                    },
                  ),
                ),
            ),
          ),
        ),
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                    image: Constants.kBgTwo,
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.linearToSrgbGamma()),
              ),
            ),
            _refreshing
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        child: SizedBox(
                          height: 3.h,
                          child: BarLoader(
                            barColor: Constants.kPrimaryColor,
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Constants.indexHorizontalSpace,
                vertical: Constants.indexVerticalSpace,
              ),
              child: !hasData(_savedCards)
                  ? Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: GText(
                            textData: "You have not saved any cards yet. "
                                "Kindly tap the '+' icon to add a debit card",
                            textAlign: TextAlign.center,
                            textSize: 13.sp,
                            textColor: Constants.kGreyColor,
                            textMaxLines: 5,
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          buildElevatedButton(
                            title: "Add New Card",
                            bgColor: Colors.green[500],
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CardPaymentForm(
                                    transData: widget.paymentDetails,
                                    accountName: widget.accountName,
                                    accountNumber: widget.accountNumber,
                                  ),
                                ),
                              );
                            },
                          ),
                          Constants.kSizeHeight_5,
                          Divider(height: 5, color: Constants.kPrimaryColor),
                          Constants.kSizeHeight_5,
                          // ListView.separated(
                          //   physics: BouncingScrollPhysics(),
                          //   padding: EdgeInsets.only(bottom: 60.h),
                          //   separatorBuilder: (BuildContext context, int index) {
                          //     return Align(
                          //       alignment: Alignment.centerRight,
                          //       child: Container(
                          //         height: 0.5,
                          //         width: MediaQuery.of(context).size.width / 1.3,
                          //         child: Divider(),
                          //       ),
                          //     );
                          //   },
                          //   itemCount: _savedCards.length,
                          //   itemBuilder: (BuildContext context, int index) {
                          //     SavedCard card = SavedCard.map(_savedCards[index]);
                          //     return CardItem(
                          //       card: card,
                          //       paymentDetails: widget.paymentDetails,
                          //       accountName: widget.accountName,
                          //       accountNumber: widget.accountNumber,
                          //     );
                          //   },
                          // ),
                          ColumnBuilder(
                            itemCount: _savedCards.length,
                            itemBuilder: (BuildContext context, int index) {
                              SavedCard card =
                                  SavedCard.map(_savedCards[index]);
                              return CardItem(
                                card: card,
                                paymentDetails: widget.paymentDetails,
                                accountName: widget.accountName,
                                accountNumber: widget.accountNumber,
                              );
                            },
                          ),
                          Constants.kSizeHeight_50
                        ],
                      ),
                    ),
            ),
          ],
        ),
        // floatingActionButton: FloatingActionButton.extended(
        //   elevation: 10,
        //   shape:
        //       RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.w)),
        //   hoverColor: Constants.kPrimaryColor,
        //   backgroundColor: Constants.kPrimaryColor,
        //   onPressed: () {
        //
        //   },
        //   icon: Icon(Icons.add),
        //   label: GText(
        //     textData: "Add New Card",
        //     textAlign: TextAlign.center,
        //     textSize: 14.sp,
        //   ),
        //   tooltip: 'Add New Card',
        // ),
        // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }
}

class CardItem extends StatefulWidget {
  const CardItem({
    Key? key,
    required this.card,
    required this.paymentDetails,
    required this.accountName,
    required this.accountNumber,
  }) : super(key: key);

  final SavedCard card;
  final dynamic paymentDetails, accountName, accountNumber;

  @override
  State<CardItem> createState() => _CardItemState();
}

class _CardItemState extends State<CardItem> {
  bool _isDeleted = false;
  _deleteCard() async {
    var _localDb = new LocalDatabase();
    await _localDb.deleteCard(widget.card.savedCardId.toString());
    if (mounted) setState(() => _isDeleted = true);
  }

  @override
  Widget build(BuildContext context) {
    return _isDeleted
        ? Container()
        : Card(
            child: ListTile(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CardPaymentForm(
                      transData: widget.paymentDetails,
                      accountName: widget.accountName,
                      accountNumber: widget.accountNumber,
                      savedCard: widget.card,
                    ),
                  ),
                );
              },
              onLongPress: () async {
                HapticFeedback.lightImpact();
                var optionSelection;
                if (Platform.isAndroid) {
                  optionSelection = await optionAndroidDialog(context);
                } else if (Platform.isIOS) {
                  optionSelection = await optionIosDialog(context);
                }
                if (optionSelection == Constants.delete) {
                  _deleteCard();
                }
              },
              contentPadding:
                  EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
              leading: Icon(
                Icons.credit_card,
              ),
              title: GText(
                textData: "${widget.card.cardNumberFirst}****"
                    "****${widget.card.cardNumberLast}",
                textSize: 16.sp,
                textFont: Constants.kFontMedium,
              ),
              subtitle: Padding(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                child: GText(
                  textData: widget.card.cardName,
                  textSize: 12.sp,
                  textWeight: FontWeight.normal,
                ),
              ),
              trailing: GText(
                textData: widget.card.expiryDate,
                textSize: 12.sp,
                textWeight: FontWeight.normal,
              ),
            ),
          );
  }
}
