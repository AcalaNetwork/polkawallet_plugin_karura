import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_karura/pages/earnNew/earnDexList.dart';
import 'package:polkawallet_plugin_karura/pages/earnNew/earnHistoryPage.dart';
import 'package:polkawallet_plugin_karura/pages/earnNew/earnLoanList.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginIconButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginPageTitleTaps.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';

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

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)!.settings.arguments as Map? ?? {};
      if (args['tab'] != null) {
        setState(() {
          _tab = int.parse(args['tab']);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;

    return PluginScaffold(
      appBar: PluginAppBar(
        title: Text(dic['earn.title']!),
        centerTitle: true,
        actions: [
          Container(
            padding: EdgeInsets.only(right: 16),
            child: PluginIconButton(
              icon: Icon(
                Icons.history,
                size: 22,
                color: Color(0xFF17161F),
              ),
              onPressed: () =>
                  Navigator.of(context).pushNamed(EarnHistoryPage.route),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.fromLTRB(16, 8, 0, 8),
              child: PluginPageTitleTaps(
                names: [dic['earn.dex']!, dic['earn.loan']!],
                activeTab: _tab,
                // fontSize: 20,
                // lineWidth: 6,
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
