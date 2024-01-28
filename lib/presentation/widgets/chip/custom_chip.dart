import 'package:flutter/material.dart';

class CustomChip extends StatelessWidget {
  const CustomChip({
    Key? key,
    required this.text,
    required this.backgroundColor,
    this.textColor = Colors.white,
    this.icon,
    this.textSize = 12,
    this.padding = const EdgeInsets.symmetric(
      horizontal: 5,
      vertical: 2,
    ),
  }) : super(key: key);

  final String text;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;
  final double textSize;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: textSize,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
