import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/currencyWithIcon.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';

class CurrencySelectPage extends StatelessWidget {
  CurrencySelectPage(this.plugin);
  final PluginKarura plugin;
  static const String route = '/assets/currency';

  @override
  Widget build(BuildContext context) {
    final List currencyIds = ModalRoute.of(context).settings.arguments;
    return Scaffold(
      appBar: AppBar(
        title: Text(I18n.of(context)
            .getDic(i18n_full_dic_acala, 'common')['currency.select']),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          children: currencyIds.map((i) {
            return ListTile(
              title: CurrencyWithIcon(
                PluginFmt.tokenView(i ?? ''),
                TokenIcon(i ?? '', plugin.tokenIcons),
                textStyle: Theme.of(context).textTheme.headline4,
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 18,
              ),
              onTap: () {
                Navigator.of(context).pop(i);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
