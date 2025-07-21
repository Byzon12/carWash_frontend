import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';


class WelcomeImage extends StatelessWidget {
  const WelcomeImage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          "",
          style: TextStyle( color: Colors.white),
        ),
        const SizedBox(height: 300,),
        Row(
          children: [
            
            Expanded(
              flex: 8,
              child: SvgPicture.asset(
                "assets/images/welc.jpg",
              ),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 16.0* 2),
      ],
    );
  }
}