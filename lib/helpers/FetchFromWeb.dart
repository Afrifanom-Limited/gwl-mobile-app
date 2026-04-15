import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/templates/AppHeaders.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'Endpoints.dart';

class FetchFromWeb extends StatefulWidget {
  final String? url;
  final String? callBackScreen;
  final String? clientRequestId;

  const FetchFromWeb({Key? key, required this.url, this.callBackScreen, this.clientRequestId}) : super(key: key);

  @override
  _FetchFromWebState createState() => _FetchFromWebState();
}

class _FetchFromWebState extends State<FetchFromWeb> {
  bool _isLoading = true;
  late final WebViewController webViewController;

  @override
  void initState() {
    super.initState();
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onHttpError: (HttpResponseError error) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url ?? Endpoints.baseUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.h),
        child: Container(
          color: Constants.kPrimaryColor,
          child: InfoHeader(),
        ),
      ),
      body: Stack(
        children: <Widget>[
          WebViewWidget(
            controller: webViewController,
          ),
          _isLoading
              ? Container(
                  child: BarLoader(
                    barColor: Constants.kPrimaryColor,
                    thickness: 2.h,
                  ),
                )
              : Container(),
        ],
      ),
    );
  }
}
