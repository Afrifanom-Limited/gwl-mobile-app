import 'package:flutter/material.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class TermsAndConditions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double _width = MediaQuery.of(context).size.width;

    bool _loading = false;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      scrollable: true,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GText(textData: "Terms of Use"),
          Constants.kSizeHeight_10,
          ClipOval(
            child: Material(
              color: Constants.kPrimaryColor.withOpacity(0.2), // button color
              child: InkWell(
                splashColor: Constants.kPrimaryColor.withOpacity(0.5),
                child:
                    SizedBox(width: 35, height: 35, child: Icon(Icons.close)),
                onTap: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
      content: ModalProgressHUD(
        inAsyncCall: _loading,
        color: Constants.kWhiteColor.withOpacity(0.8),
        opacity: 0.5,
        progressIndicator: CircularLoader(
          loaderColor: Constants.kPrimaryColor,
        ),
        child: Container(
          width: _width * 1,
          //height: _height * 0.6,
          child: Column(
            children: [
              Divider(),
              Constants.kSizeHeight_10,
            ],
          ),
        ),
      ),
    );
  }
}
