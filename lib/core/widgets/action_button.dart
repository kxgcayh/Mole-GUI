import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;
  final List<Color>? gradient;
  final double height;
  final double borderRadius;

  const ActionButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.color,
    this.gradient,
    this.height = 44,
    this.borderRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = gradient ??
        [
          AppColors.primary,
          AppColors.primaryLight,
        ];

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: onPressed == null ? null : (color == null ? LinearGradient(colors: effectiveGradient) : null),
        color: onPressed == null ? AppColors.darkCardBorder : color,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: onPressed == null
            ? null
            : [
                BoxShadow(
                  color: (gradient?.first ?? color ?? AppColors.primary).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: isLoading ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else if (icon != null) ...[
                  Icon(icon, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                ],
                if (isLoading) const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
