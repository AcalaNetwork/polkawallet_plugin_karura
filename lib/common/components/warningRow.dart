import 'package:flutter/material.dart';
import 'package:polkawallet_ui/components/textTag.dart';

class WarningRow extends StatelessWidget {
  WarningRow(this.content);
  final String content;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextTag(
            content,
            padding: EdgeInsets.fromLTRB(8, 4, 8, 4),
            margin: EdgeInsets.only(bottom: 8),
            color: Colors.deepOrangeAccent,
          ),
        )
      ],
    );
  }
}
