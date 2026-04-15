import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/Endpoints.dart';

class Constants {
  static const appTitle = "Customer App";
  static const introPageKey = "introPageKey";
  static const appTitleFull = "Ghana Water Limited";
  static const appTitleShort = "GWL CUSTOMER APP";
  static const gwclWebsite = "https://www.gwcl.com.gh/";
  static const gwclBaseUrl = Endpoints.baseUrl;
  static const gwclFaq = Endpoints.baseUrl + "/info/faq";
  static const gwclPrivacyPolicy = Endpoints.baseUrl + "/info/privacypolicy";
  static const gwclTerms = Endpoints.baseUrl + "/info/termsofuse";
  static const gwclAutoPayment = Endpoints.baseUrl + "/info/autopayment";
  static const gwclAppDownload = Endpoints.baseUrl + "/download";
  static const gwclDbName = "gwcl_local_208231818.db";
  static const gwclTelephone = "tel:0302218240";
  static const afrifanomWebsite = "https://www.afrifanom.com/";

  static const appId = "gwcl_customer_app"; //gwcl_customer_app

  static const String success = "success";
  static const String message = "message";
  static const String response = "response";
  static const String token = "token";
  static const String localAuthPhone = "localAuthPhone";
  static const String localMomoPhone = "localMomoPhone";
  static const String localAuthKey = "localAuthKey";
  static const String allowBiometrics = "allowBiometrics";
  static const String allowSaveCardInfo = "allowSaveCardInfo";
  static const String biometricsAvailability = "biometricsAvailability";
  static const String canUpdateMeter = "canUpdateMeter";
  static const String canUpdateVendor = "canUpdateVendor";
  static const String showSessionExpired = "showSessionExpired";
  static const String showQuickAccess = "showQuickAccess";
  static const String accountNumbers = "accountNumbers";
  static const String debitCardInfo = "debitCardInfo";
  static const String paymentPercentageCharge = "paymentPercentageCharge";
  static const String feeds = "feeds";

  static const String complaintClosed = "closed";
  static const String complaintOpened = "opened";
  static const String complaintTransferred = "transferred";
  static const String complaintPrank = "prank";
  static const String complaintReviewing = "reviewing";
  static const String mySelf = "mySelf";
  static const String others = "others";
  static const String delete = "delete";
  static const String share = "share";
  static const String edit = "edit";

  static const String vodafone = "VODAFONE";
  static const String airteltigo = "AIRTELTIGO";

  static const String AUTOPAYMENT = "YES";

  static const String momo = "momo";
  static const String card = "card";

  static const String appDir = "gwcl";
  static const String tempDir = "temp";
  static const String uploadDir = "upload_temp";

  static const String errorFilter = r"[^:.\s\w]";

  static const String appErrorCode = "505";
  static const String errorEncountered = "We encountered an error while processing your request";
  static const String somethingWentWrong = "Sorry, something went wrong";
  static const String unableToSendRequest = "Cannot reach server. Please check your internet connection";
  static const String unableToRefresh = "Unable to refresh. You are viewing offline data";
  static const String notReady = "This section is still in development phase";
  static const String connectionTimedOut = "Connection timed out";
  static const String unableToReachServers = "Cannot reach server right now. Please try again in a few minutes";

  static double indexHorizontalSpace = 14.w;
  static double indexVerticalSpace = 8.h;

  static const Color kPrimaryColor = Color(0xff09328e);
  static const Color kPrimaryLightColor = Color(0xffe1ecfe);
  static const Color kWarningColor = Color(0xfff08731);
  static const Color kAccentColor = Color(0xff000000);
  static const Color kWhiteColor = Color(0xffffffff);
  static const Color kNearlyDarkBlueColor = Color(0xFF2389da);
  static const Color kRedColor = Colors.red;
  static const Color kGreyColor = Colors.grey;

  static Color kRedLightColor = Color(0xFFEF5350);
  static Color kGreenLightColor = Color(0xFF66BB6A);
  static Color kWarningLightColor = Color(0xFFFFA726);

  static const kFont = "Rubik";
  static const kFontLight = "Rubik-Light";
  static const kFontMedium = "Rubik-Medium";
  static const kFontBold = "Rubik-Bold";

  static const kGothamFont = "GothamBook";
  static const kGothamFontLight = "GothamLight";
  static const kGothamFontMedium = "GothamMedium";
  static const kGothamFontBold = "GothamBold";

  static SizedBox kSizeWidth_5 = SizedBox(width: 5.w);
  static SizedBox kSizeWidth_10 = SizedBox(width: 10.w);
  static SizedBox kSizeWidth_20 = SizedBox(width: 20.w);
  static SizedBox kSizeWidth_50 = SizedBox(width: 50.w);
  static SizedBox kSizeHeight_5 = SizedBox(height: 5.h);
  static SizedBox kSizeHeight_10 = SizedBox(height: 10.h);
  static SizedBox kSizeHeight_20 = SizedBox(height: 20.h);
  static SizedBox kSizeHeight_30 = SizedBox(height: 40.h);
  static SizedBox kSizeHeight_40 = SizedBox(height: 40.h);
  static SizedBox kSizeHeight_50 = SizedBox(height: 50.h);

  static const String regExp = "[a-zA-Z0-9\+\.\_\%\-\+]{1,256}" + "\\@" + "[a-zA-Z0-9][a-zA-Z0-9\\-]{0,64}" + "(" + "\\." + "[a-zA-Z0-9][a-zA-Z0-9\\-]{0,25}" + ")+";

  static const AssetImage kAppLogo = AssetImage("assets/images/logo.png");
  static const AssetImage kAppLogoWhite = AssetImage("assets/images/logo_white.png");
  static const AssetImage kSupportIcon = AssetImage("assets/images/support_icon.png");
  static const AssetImage kMeterIcon = AssetImage("assets/images/user.png");
  static const AssetImage kBillIcon = AssetImage("assets/images/payment_history.png");
  static const AssetImage kPaymentIcon = AssetImage("assets/images/purse.png");
  static const AssetImage kScheduleIcon = AssetImage("assets/images/schedule_icon.png");
  static const AssetImage kNotificationIcon = AssetImage("assets/images/alarm_icon.png");
  static const AssetImage kSettingsIcon = AssetImage("assets/images/settings_icon.png");
  static const AssetImage kActivityHistoryIcon = AssetImage("assets/images/bills.png");
  static const AssetImage kComplaintIconIcon = AssetImage("assets/images/feedback.png");
  static const AssetImage kAutoPaymentIconIcon = AssetImage("assets/images/auto_payment.png");

  static const AssetImage kBgOne = AssetImage("assets/images/bg_one.png");
  static const AssetImage kBgTwo = AssetImage("assets/images/bg_two.png");
  static const AssetImage kBgThree = AssetImage("assets/images/bg_three.png");
  static const AssetImage kBgFour = AssetImage("assets/images/bg_four.png");
  static const AssetImage kBgFive = AssetImage("assets/images/bg_five.png");
  static const AssetImage kCardBg = AssetImage("assets/images/card_bg.png");
  static const AssetImage kVectorOne = AssetImage("assets/images/vector_one.png");
  static const AssetImage kMeterBgOne = AssetImage("assets/images/meterbg_one.png");
  static const AssetImage kMeterBgTwo = AssetImage("assets/images/meterbg_two.png");
  static const AssetImage kProfileIcon = AssetImage("assets/images/profile_icon.png");

  static const AssetImage kVendorBgOne = AssetImage("assets/images/vendorbg_one.png");
  static const AssetImage kVendorBgTwo = AssetImage("assets/images/vendorbg_two.png");

  static const String kSuccessFlare = "assets/animate/success_check.flr";

  static const String kMomoIcon = "assets/images/mtn.png";
  static const String kAirteltigoIcon = "assets/images/airteltigo.png";
  static const String kVodafoneIcon = "assets/images/vodafone.png";
  static const String kVisaIcon = "assets/images/visa.png";
}
