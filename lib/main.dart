import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/firebase_options.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/LocalNotifications.dart';
import 'package:gwcl/mixpanel.dart';
import 'package:gwcl/views/ScreenRouter.dart';
import 'package:gwcl/views/account/Account.dart';
import 'package:gwcl/views/account/EditEmailAddress.dart';
import 'package:gwcl/views/account/EditGPGPS.dart';
import 'package:gwcl/views/account/UpdatePassword.dart';
import 'package:gwcl/views/complaint/ComplaintsList.dart';
import 'package:gwcl/views/complaint/LodgeComplaint.dart';
import 'package:gwcl/views/feedback/UserFeedback.dart';
import 'package:gwcl/views/home/AddAccount.dart';
import 'package:gwcl/views/home/Home.dart';
import 'package:gwcl/views/index/CustomerOption.dart';
import 'package:gwcl/views/index/ForgotPassword.dart';
import 'package:gwcl/views/index/Login.dart';
import 'package:gwcl/views/index/OtpConfirmation.dart';
import 'package:gwcl/views/index/RegisterCustomer.dart';
import 'package:gwcl/views/index/RegisterNonCustomer.dart';
import 'package:gwcl/views/index/Welcome.dart';
import 'package:gwcl/views/info/About.dart';
import 'package:gwcl/views/meter/AddMeter.dart';
import 'package:gwcl/views/meter/ReadMeter.dart';
import 'package:gwcl/views/notifications/Notifications.dart';
import 'package:gwcl/views/report/RequestedReports.dart';
import 'package:gwcl/views/transactions/AutoPayments.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'views/index/intro.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage? message) async {
  await Firebase.initializeApp();
  if (message != null) {
    processBackgroundMessage(message);
  }
}

// Entry point of Main Application
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  LocalNotification.initialize();
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  messaging.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
  if (Platform.isIOS) {
    messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  // Set the background messaging handler early on, as a named top-level function
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  /// Update the iOS foreground notification
  ///  presentation options to allow heads up notifications.
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top]).then((_) {
    runApp(RestartWidget(child: App()));
  });
}

Future<void> processBackgroundMessage(RemoteMessage message) async {
  LocalNotification.showBadger();
  LocalNotification.showNotification(message);
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  static final GlobalKey<NavigatorState> _navigatorKey = GlobalKey(debugLabel: "Main Navigator");

  _initFirebaseMessaging() async {
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        processBackgroundMessage(message);
      }
    });

    FirebaseMessaging.onBackgroundMessage((RemoteMessage? message) async {
      if (message != null) {
        processBackgroundMessage(message);
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage? message) {
      if (message != null) {
        processBackgroundMessage(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      processBackgroundMessage(message);
      _handleNotificationMessageReceived(message);
    });
  }

  @override
  void initState() {
    super.initState();
    initMixpanel();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _initFirebaseMessaging();
  }

  Future<bool> checkIntroPageCompleted() async {
    SharedPreferences _localStorage = await SharedPreferences.getInstance();
    return _localStorage.getBool(Constants.introPageKey) ?? false;
  }

  Widget startScreen() {
    return FutureBuilder(
      future: checkIntroPageCompleted(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data == true) {
            return ScreenRouter();
          } else {
            return Introduction();
          }
        } else {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(360, 690),
      builder: (BuildContext context, child) => MaterialApp(
        navigatorKey: _navigatorKey,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          DefaultCupertinoLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        locale: Locale('en', 'US'),
        supportedLocales: [
          const Locale('en', 'US'), // English
        ],
        title: 'GWL CUSTOMER APP',
        theme: ThemeData(
          primaryColor: Constants.kPrimaryColor,
          scaffoldBackgroundColor: Constants.kWhiteColor,
          appBarTheme: AppBarTheme(color: Constants.kWhiteColor),
          fontFamily: Constants.kFont,
          textTheme: TextTheme(
            headlineMedium: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
            displaySmall: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            labelLarge: TextStyle(color: Colors.white),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(backgroundColor: Constants.kPrimaryColor),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Constants.kAccentColor,
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
              style: TextButton.styleFrom(
            foregroundColor: Constants.kAccentColor,
          )),
          inputDecorationTheme: InputDecorationTheme(
            contentPadding: EdgeInsets.all(8),
            filled: true,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(style: BorderStyle.none),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Constants.kAccentColor),
        ),
        routes: {
          Introduction.id: (context) => Introduction(),
          Welcome.id: (context) => Welcome(),
          RegisterCustomer.id: (context) => RegisterCustomer(),
          RegisterNonCustomer.id: (context) => RegisterNonCustomer(),
          Login.id: (context) => Login(),
          ForgotPassword.id: (context) => ForgotPassword(),
          Home.id: (context) => Home(),
          AddAccount.id: (context) => AddAccount(),
          CustomerOption.id: (context) => CustomerOption(),
          OtpConfirmation.id: (context) => OtpConfirmation(),
          LodgeComplaint.id: (context) => LodgeComplaint(),
          Account.id: (context) => Account(),
          Notifications.id: (context) => Notifications(),
          AddMeter.id: (context) => AddMeter(),
          ReadMeter.id: (context) => ReadMeter(),
          EditEmailAddress.id: (context) => EditEmailAddress(),
          EditGPGPS.id: (context) => EditGPGPS(),
          About.id: (context) => About(),
          UpdatePassword.id: (context) => UpdatePassword(),
          ComplaintsList.id: (context) => ComplaintsList(),
          RequestedReports.id: (context) => RequestedReports(),
          UserFeedback.id: (context) => UserFeedback(),
          AutoPayments.id: (context) => AutoPayments(),
        },
        home: startScreen(),
      ),
    );
  }

  static _openNotifications() {
    _navigatorKey.currentState?.push(MaterialPageRoute(builder: (context) => Notifications()));
  }

  static _openComplaints() {
    _navigatorKey.currentState?.push(MaterialPageRoute(builder: (context) => ComplaintsList()));
  }

  void _handleNotificationMessageReceived(RemoteMessage message) {
    if (message.data["type"] == 'chat') {
      _openComplaints();
    } else {
      _openNotifications();
    }
  }
}

final _RebuildApp _reBuilder = _RebuildApp();

void rebuildApp() => _reBuilder.execute();

class _RebuildApp extends ValueNotifier<int> {
  _RebuildApp() : super(1);

  void execute() => value = value + 1;
}

class RestartWidget extends StatefulWidget {
  RestartWidget({required this.child});

  final Widget child;

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_RestartWidgetState>()?.restartApp();
  }

  @override
  _RestartWidgetState createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key key = UniqueKey();

  void restartApp() {
    setState(() {
      key = UniqueKey();
    });
  }

  // RestartWidget.restartApp(context);

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: key,
      child: widget.child,
    );
  }
}

// TODO: COMMENT OUT IN PRODUCTION
// class MyHttpOverrides extends HttpOverrides {
//   @override
//   HttpClient createHttpClient(SecurityContext context) {
//     return super.createHttpClient(context)
//       ..badCertificateCallback =
//           (X509Certificate cert, String host, int port) => true;
//   }
// }

// Permissions Helper
//.isGranted == has access to application
//.isDenied == does not have access to application, you can request again for the permission.
//.isPermanentlyDenied == does not have access to application, you cannot request again for the permission.
//.isRestricted == because of security/parental control you cannot use this permission.
//.isUndetermined == permission has not asked before.

// pod cache list
// pod cache clean --all
// pod cache clean 'FortifySec' --all
// rm -rf ~/Library/Caches/CocoaPods
// rm -rf Podfile.lock
// rm -rf ~/.pub-cache/hosted/pub.dartlang.org/
// rm -rf Pods
// rm -rf ~/Library/Developer/Xcode/DerivedData/*
// pod deintegrate
// flutter clean
// flutter pub cache repair
// pod repo update
// pod setup
// pod install

// Latest update contains bug fixes and performance enhancements
// source="$(readlink -f "${source}")"
