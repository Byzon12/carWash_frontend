import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/components/slide.dart';
import 'package:flutter_application_1/screens/main/reponsive%20.dart';
import 'package:flutter_application_1/screens/main/welcome/loginsignupbtn.dart';
import 'package:flutter_application_1/screens/main/welcome/wel.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const List<String> bgImages = [
    'assets/images/welc.jpg',
    'assets/images/welc1.jpg',
    'assets/images/welc2.png',
    'assets/images/welc3.png',
    'assets/images/welc4.png',
  ];

  @override
  Widget build(BuildContext context) {
    return SlideshowBackground(
      images: bgImages,
      child: SingleChildScrollView(
        child: SafeArea(
          child: Responsive(
            desktop: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                Expanded(child: WelcomeImage()),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 450, child: LoginAndSignupBtn()),
                    ],
                  ),
                ),
              ],
            ),
            mobile: MobileWelcomeScreen(),
          ),
        ),
      ),
    );
  }
}

class MobileWelcomeScreen extends StatelessWidget {
  const MobileWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,

      children: <Widget>[
        const WelcomeImage(),

        Center(child: SizedBox(width: 300, child: const LoginAndSignupBtn())),
      ],
    );
  }
}
