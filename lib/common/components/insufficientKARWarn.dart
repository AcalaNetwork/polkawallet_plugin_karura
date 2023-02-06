import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_karura/common/components/warningRow.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';

class InsufficientKARWarn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    return WarningRow(dic['warn.fee']!);
  }
}
