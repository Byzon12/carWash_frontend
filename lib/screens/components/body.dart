import 'package:flutter/material.dart';

class Background extends StatelessWidget {
  final String backgroundImage;
  final Widget child;
  final double overlayOpacity;

  const Background({
    super.key,
    required this.backgroundImage,
    required this.child,
    this.overlayOpacity = 0.3,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          Image.asset(
            backgroundImage,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Container(color: Colors.black.withValues(alpha: overlayOpacity)),
          child,
        ],
      ),
    );
  }
}
