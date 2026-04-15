import 'package:flutter/material.dart';

class CustomBadge extends StatelessWidget {
  final IconData iconData;
  final String? text;
  final VoidCallback? onTap;
  final int alertCount;

  const CustomBadge({
    Key? key,
    this.onTap,
    this.text,
    required this.iconData,
    required this.alertCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double _height = MediaQuery.of(context).size.height;
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
                  size: alertCount > 0 ? MediaQuery.of(context).size.width * 0.08 : MediaQuery.of(context).size.width * 0.07,
                ),
              ],
            ),
            if (alertCount > 0)
              Positioned(
                bottom: _height * 0.046,
                right: _height * 0.01,
                child: Icon(
                  Icons.circle,
                  color: Colors.red,
                  size: _height * 0.016,
                ),
              )
          ],
        ),
      ),
    );
  }
}
