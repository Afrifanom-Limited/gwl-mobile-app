import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/Constants.dart';
import '../../helpers/PageTransitions.dart';
import 'Welcome.dart';

class Introduction extends StatelessWidget {
  static const String id = "introduction";
  final introKey = GlobalKey<IntroductionScreenState>();

  Widget _buildFullscreenImage(String imgName) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/$imgName'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black45, BlendMode.colorBurn),
        ),
      ),
    );
  }

  Future<bool> setIntroPageCompleted() async {
    SharedPreferences _localStorage = await SharedPreferences.getInstance();
    return _localStorage.setBool(Constants.introPageKey, true);
  }

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(fontSize: 19.0);
    const pageDecoration = PageDecoration(
      fullScreen: true,
      titleTextStyle: TextStyle(
        fontSize: 28.0,
        fontWeight: FontWeight.w700,
      ),
      bodyFlex: 1,
      bodyTextStyle: bodyStyle,

      bodyPadding: EdgeInsets.all(20),
      bodyAlignment: Alignment.bottomCenter,

      imageFlex: 2,
      //  pageColor: Colors.white,

      imagePadding: EdgeInsets.zero,
    );
    return IntroductionScreen(
      key: introKey,
      globalBackgroundColor: Colors.white,
      allowImplicitScrolling: true,
      autoScrollDuration: 3000,
      infiniteAutoScroll: true,
      animationDuration: 3000,
      globalFooter: SizedBox(
        height: 120,
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            child: Stack(
              children: [
                Image.asset("assets/images/btn-shape.png"),
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Getting Started',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 30.0),
                      Icon(Icons.arrow_forward),
                    ],
                  ),
                )
              ],
            ),
            onPressed: () {
              setIntroPageCompleted();
              Navigator.pushReplacement(
                context,
                FadeRoute(page: Welcome()),
              );
            },
          ),
        ),
      ),
      pages: [
        PageViewModel(
          titleWidget: Text(
            "Welcome to Ghana Water Limited",
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white),
          ),
          bodyWidget: SizedBox.shrink(),
          image: _buildFullscreenImage('intro1.png'),
          decoration: pageDecoration,
        ),
        PageViewModel(
          titleWidget: Text(
            "Water is vital for life supporting",
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white),
          ),
          bodyWidget: SizedBox.shrink(),
          image: _buildFullscreenImage('intro2.jpg'),
          decoration: pageDecoration,
        ),
        PageViewModel(
          titleWidget: Text(
            "Water is essential for all living things",
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white),
          ),
          bodyWidget: SizedBox.shrink(),
          image: _buildFullscreenImage('intro3.jpg'),
          decoration: pageDecoration,
        ),
      ],
      showSkipButton: false,
      showDoneButton: false,
      showNextButton: false,
      skipOrBackFlex: 0,
      nextFlex: 0,
      showBackButton: false,
      curve: Curves.easeInToLinear,
      controlsMargin: const EdgeInsets.all(16),
      controlsPadding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
      dotsDecorator: const DotsDecorator(
        size: Size(10.0, 10.0),
        color: Color(0xFFBDBDBD),
        activeSize: Size(33.0, 10.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
      dotsContainerDecorator: const ShapeDecoration(
        //color: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
      ),
    );
  }
}
