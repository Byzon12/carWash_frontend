import 'package:flutter/material.dart';

class Background extends StatelessWidget {
  final String backgroundImage;
  final Widget child;
  final double overlayOpacity;

  const Background({
    Key? key,
    required this.backgroundImage,
    required this.child,
    this.overlayOpacity = 0.3,
  }) : super(key: key);

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
          Container(
            color: Colors.black.withOpacity(overlayOpacity),
          ),
          child,
        ],
      ),
    );
  }
}
