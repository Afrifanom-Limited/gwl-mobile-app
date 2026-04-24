import 'package:flutter/material.dart';
import 'package:gwcl/helpers/BlinkingWidget.dart';

class CustomBadge extends StatelessWidget {
  final IconData iconData;
  final String? text;
  final VoidCallback? onTap;
  final int alertCount;
  final bool showLiveUpdate;

  const CustomBadge({
    Key? key,
    this.onTap,
    this.text,
    required this.iconData,
    required this.alertCount,
    this.showLiveUpdate = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  iconData,
                  size: MediaQuery.of(context).size.width * 0.07,
                ),
              ],
            ),
            // Live update blinking green dot
            if (showLiveUpdate)
              Positioned(
                top: MediaQuery.of(context).size.width * 0.10,
                right: MediaQuery.of(context).size.width * 0.02,
                child: BlinkingWidget(
                  widget: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
