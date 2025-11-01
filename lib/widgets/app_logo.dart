import 'package:flutter/material.dart';
import '../constants.dart';

class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({Key? key, this.size = 80.0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/roomiez_logo.png',
      height: size,
      width: size,
      fit: BoxFit.contain,
      color: primaryColor,
    );
  }
}
