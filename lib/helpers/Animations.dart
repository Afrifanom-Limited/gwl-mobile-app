import 'package:flutter/material.dart';
import 'package:gwcl/helpers/Constants.dart';

class HeartBeatAnimator extends StatefulWidget {
  final IconData iconData;
  final double startSize;
  final double endSize;
  final Color? iconColor;
  final int speed;

  const HeartBeatAnimator({
    Key? key,
    required this.iconData,
    required this.startSize,
    required this.endSize,
    required this.speed,
    this.iconColor,
  });
  @override
  _HeartBeatAnimatorState createState() => _HeartBeatAnimatorState();
}

class _HeartBeatAnimatorState extends State<HeartBeatAnimator>
    with TickerProviderStateMixin {
  Animation? _heartAnimation;
  late AnimationController _arrowAnimationController, _heartAnimationController;

  @override
  void initState() {
    super.initState();
    _arrowAnimationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));

    _heartAnimationController = AnimationController(
        vsync: this, duration: Duration(milliseconds: widget.speed));
    _heartAnimation = Tween(begin: widget.startSize, end: widget.endSize)
        .animate(CurvedAnimation(
            curve: Curves.bounceOut, parent: _heartAnimationController));

    _heartAnimationController.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _heartAnimationController.repeat();
      }
    });
    _heartAnimationController.forward();
  }

  @override
  void dispose() {
    _arrowAnimationController.dispose();
    _heartAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _heartAnimationController,
      builder: (context, child) {
        return Center(
          child: Container(
            child: Center(
              child: Icon(
                widget.iconData,
                color: widget.iconColor ?? Constants.kWhiteColor,
                size: _heartAnimation?.value,
              ),
            ),
          ),
        );
      },
    );
  }
}
