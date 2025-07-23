import 'package:flutter/material.dart';

class WelcomeImage extends StatelessWidget {
  const WelcomeImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("", style: TextStyle(color: Colors.white)),
        const SizedBox(height: 300),
        Row(
          children: [
            Expanded(flex: 8, child: Image.asset("assets/images/welc.jpg")),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 16.0 * 2),
      ],
    );
  }
}
