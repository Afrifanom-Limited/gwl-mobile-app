import 'package:flutter/material.dart';
import 'package:gwcl/helpers/Constants.dart';

class ThumbsUpIconAnimator extends StatefulWidget {
  final bool isLiked;
  final double size;
  final VoidCallback onTap;

  ThumbsUpIconAnimator({
    required this.isLiked,
    this.size = 22.0,
    required this.onTap,
  });

  @override
  _ThumbsUpIconAnimatorState createState() => _ThumbsUpIconAnimatorState();
}

class _ThumbsUpIconAnimatorState extends State<ThumbsUpIconAnimator>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeController;
  late Animation<double> _likeAnimation;

  @override
  void initState() {
    super.initState();
    final quick = const Duration(milliseconds: 500);
    final scaleTween = Tween(begin: 0.0, end: 1.0);
    _likeController = AnimationController(duration: quick, vsync: this);
    _likeAnimation = scaleTween.animate(
      CurvedAnimation(
        parent: _likeController,
        curve: Curves.elasticOut,
      ),
    );

    // Ensure a full scale like button on init.
    _likeController.animateTo(1.0, duration: Duration.zero);
  }

  @override
  void dispose() {
    _likeController.dispose();
    super.dispose();
  }

  void _animate() {
    _likeController
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return _TapAbleHeart(
      isLiked: widget.isLiked,
      size: widget.size,
      onTap: () {
        _animate();
        widget.onTap();
      },
      animation: _likeAnimation,
    );
  }
}

class _TapAbleHeart extends AnimatedWidget {
  final bool isLiked;
  final double size;
  final VoidCallback onTap;

  _TapAbleHeart({
    Key? key,
    required this.isLiked,
    required this.size,
    required this.onTap,
    required Animation<double> animation,
  }) : super(key: key, listenable: animation);

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: listenable as Animation<double>,
      child: GestureDetector(
        child: isLiked
            ? Icon(Icons.thumb_up, size: size, color: Constants.kPrimaryColor)
            : Icon(
                Icons.thumb_up_alt_outlined,
                size: size,
                color: Constants.kGreyColor,
              ),
        onTap: onTap,
      ),
    );
  }
}
