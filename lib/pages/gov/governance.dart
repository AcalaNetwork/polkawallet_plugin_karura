import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_karura/pages/gov/democracy/democracy.dart';
import 'package:polkawallet_plugin_karura/pages/gov/democracy/proposals.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/topTaps.dart';

class Gov extends StatefulWidget {
  Gov(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/gov/democracy/index';

  @override
  _GovState createState() => _GovState();
}

class _GovState extends State<Gov> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'gov')!;
    final tabs = [dic['democracy.referendum']!, dic['democracy.proposal']!];

    return Column(
      children: <Widget>[
        Container(
          margin: EdgeInsets.only(top: 8),
          child: TopTabs(
            names: tabs,
            activeTab: _tab,
            onTab: (v) {
              setState(() {
                if (_tab != v) {
                  _tab = v;
                }
              });
            },
          ),
        ),
        Expanded(
          child: _tab == 0
              ? Democracy(widget.plugin, widget.keyring)
              : Proposals(widget.plugin),
        ),
      ],
    );
  }
}
