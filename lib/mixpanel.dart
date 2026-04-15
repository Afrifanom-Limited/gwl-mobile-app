import 'package:mixpanel_flutter/mixpanel_flutter.dart';

Mixpanel? mixpanel;

Future<void> initMixpanel() async {
  // Once you've called this method once, you can access `mixpanel` throughout the rest of your application.
  mixpanel = await Mixpanel.init("b047a93904e59a200ab7977aff9fcc39", trackAutomaticEvents: false);
}
