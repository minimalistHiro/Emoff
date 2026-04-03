import 'package:flutter/material.dart';

enum CustomButtonVariant { primary, secondary, danger }

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = CustomButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.height,
  });

  final String text;
  final VoidCallback? onPressed;
  final CustomButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? height;

  static const _cyan = Color(0xFF00D4FF);
  static const _danger = Color(0xFFFF4D4D);
  static const _disabled = Color(0xFF555555);

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;

    switch (variant) {
      case CustomButtonVariant.primary:
        return SizedBox(
          width: double.infinity,
          height: height ?? 48,
          child: ElevatedButton(
            onPressed: isDisabled ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDisabled ? _disabled : _cyan,
              foregroundColor: Colors.black,
              disabledBackgroundColor: _disabled,
              disabledForegroundColor: Colors.black54,
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: _buildChild(Colors.black),
          ),
        );
      case CustomButtonVariant.secondary:
        return SizedBox(
          width: double.infinity,
          height: height ?? 48,
          child: OutlinedButton(
            onPressed: isDisabled ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: isDisabled ? _disabled : _cyan,
              side: BorderSide(
                color: isDisabled ? _disabled : _cyan,
              ),
              backgroundColor: Colors.black,
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: _buildChild(_cyan),
          ),
        );
      case CustomButtonVariant.danger:
        return SizedBox(
          width: double.infinity,
          height: height ?? 48,
          child: ElevatedButton(
            onPressed: isDisabled ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDisabled ? _disabled : _danger,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _disabled,
              disabledForegroundColor: Colors.white54,
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: _buildChild(Colors.white),
          ),
        );
    }
  }

  Widget _buildChild(Color spinnerColor) {
    if (isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: spinnerColor,
        ),
      );
    }
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text),
          const SizedBox(width: 8),
          Icon(icon, size: 20),
        ],
      );
    }
    return Text(text);
  }
}
