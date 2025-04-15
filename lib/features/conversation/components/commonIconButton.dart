import 'package:flutter/material.dart';

class CommonIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? toolTip;
  final double? iconSize;

  CommonIconButton({required this.onPressed, required this.icon, this.toolTip, this.iconSize});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      visualDensity: VisualDensity.compact,
      splashRadius: 22,
      tooltip: toolTip,
      iconSize: iconSize,
    );
  }
}
