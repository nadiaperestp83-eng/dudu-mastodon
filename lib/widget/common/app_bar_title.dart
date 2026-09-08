import 'package:flutter/material.dart';

class DropDownTitle extends StatelessWidget {
  final String title;
  final bool expand;
  final bool showIcon;
  final bool iconMaintainSize;
  final Color fontColor;
  final FontWeight fontWeight;
  final double fontSize;

  DropDownTitle(
      {this.title,
      this.expand = false,
      this.showIcon = false,
      this.iconMaintainSize = true,
      this.fontColor,
      this.fontWeight = FontWeight.normal,
      this.fontSize = 17});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 5, 5, 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            style: TextStyle(
                fontSize: fontSize, color: fontColor, fontWeight: fontWeight),
          ),
          Visibility(
              maintainSize: iconMaintainSize,
              maintainAnimation: iconMaintainSize,
              maintainState: iconMaintainSize,
              visible: showIcon,
              child: Icon(
            expand ? Icons.arrow_drop_up : Icons.arrow_drop_down,
            size: 20,
          )),
        ],
      ),
    );
  }
}
