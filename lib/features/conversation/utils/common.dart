import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';


InputDecoration inputDecoration(
  BuildContext context, {
  Widget? prefixIcon,
  Widget? suffixIcon,
  String? label,
  String? labelText,
  double? borderRadius,
  Color? borderColor,
  EdgeInsetsGeometry? contentPadding,
}) {
  return InputDecoration(
    contentPadding: contentPadding ?? EdgeInsets.only(left: 16),
    hintText: label,
    labelText: labelText,
    labelStyle: secondaryTextStyle(),
    hintStyle: secondaryTextStyle(),
    alignLabelWithHint: true,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    border: InputBorder.none,
    filled: true,
    enabledBorder: OutlineInputBorder(
      borderRadius: radius(borderRadius ?? defaultRadius),
      borderSide: BorderSide(color: borderColor ?? Colors.transparent, width: 0.0),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: radius(borderRadius ?? defaultRadius),
      borderSide: BorderSide(width: 0.0, color: borderColor ?? Colors.transparent),
    ),
  );
}

Decoration decoration({Color? color}) {
  return BoxDecoration(
    borderRadius: radius(22),
    shape: BoxShape.rectangle,
  );
}
