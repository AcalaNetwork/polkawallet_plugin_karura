import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_karura/pages/earn/earnDexList.dart';
import 'package:polkawallet_plugin_karura/pages/earn/earnHistoryPage.dart';
import 'package:polkawallet_plugin_karura/pages/earn/earnLoanList.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/MainTabBar.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/iconButton.dart' as v3;

class EarnPage extends StatefulWidget {
  EarnPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/karura/earn';

  @override
  _EarnPageState createState() => _EarnPageState();
}

class _EarnPageState extends State<EarnPage> {
  int _tab = 0;

  @override
  void initState() {
    widget.plugin.store!.earn.getdexIncentiveLoyaltyEndBlock(widget.plugin);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;

    return Scaffold(
      appBar: AppBar(
        title: Text(dic['earn.title']!),
        centerTitle: true,
        leading: BackBtn(),
        actions: [
          Container(
            padding: EdgeInsets.only(right: 16),
            child: v3.IconButton(
              icon: Icon(
                Icons.history,
                color: Theme.of(context).cardColor,
                size: 18,
              ),
              onPressed: () =>
                  Navigator.of(context).pushNamed(EarnHistoryPage.route),
              isBlueBg: true,
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: MainTabBar(
                fontSize: 20,
                lineWidth: 6,
                tabs: [dic['earn.dex']!, dic['earn.loan']!],
                activeTab: _tab,
                onTap: (i) {
                  setState(() {
                    _tab = i;
                  });
                },
              ),
            ),
            Expanded(
              child: _tab == 0
                  ? EarnDexList(widget.plugin)
                  : EarnLoanList(widget.plugin, widget.keyring),
            )
          ],
        ),
      ),
    );
  }
}
