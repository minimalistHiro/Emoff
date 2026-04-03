import 'package:flutter/material.dart';

class CustomLoadingIndicator extends StatelessWidget {
  const CustomLoadingIndicator({
    super.key,
    this.size = 40,
  });

  final double size;

  static const _cyan = Color(0xFF00D4FF);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CircularProgressIndicator(
        color: _cyan,
        strokeWidth: 3,
      ),
    );
  }
}
