import 'package:flutter/material.dart';

class AdjustMultipleWidget extends StatefulWidget {
  AdjustMultipleWidget({Key? key}) : super(key: key);

  @override
  State<AdjustMultipleWidget> createState() => _AdjustMultipleWidgetState();
}

class _AdjustMultipleWidgetState extends State<AdjustMultipleWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
          color: Color(0x8AFFFFFF),
          borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              topRight: Radius.circular(24),
              bottomRight: Radius.circular(24))),
    );
  }
}
