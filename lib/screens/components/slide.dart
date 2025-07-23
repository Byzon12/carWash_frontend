import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/components/body.dart';

class SlideshowBackground extends StatefulWidget {
  final List<String> images;
  final Widget child;
  final Duration slideDuration;
  final Duration fadeDuration;

  const SlideshowBackground({
    super.key,
    required this.images,
    required this.child,
    this.slideDuration = const Duration(seconds: 4),
    this.fadeDuration = const Duration(milliseconds: 1200),
  });

  @override
  State<SlideshowBackground> createState() => _SlideshowBackgroundState();
}

class _SlideshowBackgroundState extends State<SlideshowBackground> {
  int _currentIndex = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(widget.slideDuration, (timer) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % widget.images.length;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: widget.fadeDuration,
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      child: Background(
        key: ValueKey(widget.images[_currentIndex]),
        backgroundImage: widget.images[_currentIndex],
        child: widget.child,
      ),
    );
  }
}
