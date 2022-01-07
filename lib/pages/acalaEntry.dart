import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:polkawallet_plugin_karura/pages/earn/earnPage.dart';
import 'package:polkawallet_plugin_karura/pages/gov/democracyPage.dart';
import 'package:polkawallet_plugin_karura/pages/homa/homaPage.dart';
import 'package:polkawallet_plugin_karura/pages/loan/loanPage.dart';
import 'package:polkawallet_plugin_karura/pages/nft/nftPage.dart';
import 'package:polkawallet_plugin_karura/pages/swap/swapPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginItemCard.dart';

class DefiWidget extends StatefulWidget {
  DefiWidget(this.plugin);

  final PluginKarura plugin;

  @override
  _DefiWidgetState createState() => _DefiWidgetState();
}

class _DefiWidgetState extends State<DefiWidget> {
  final _liveModuleRoutes = {
    'loan': LoanPage.route,
    'swap': SwapPage.route,
    'earn': EarnPage.route,
    'homa': HomaPage.route,
  };

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'common');
    final dicGov = I18n.of(context)!.getDic(i18n_full_dic_karura, 'gov')!;
    final modulesConfig = widget.plugin.store!.setting.liveModules;
    final List liveModules = modulesConfig.keys.toList().sublist(1);

    liveModules.retainWhere((e) => modulesConfig[e]['visible'] && e != 'nft');
    return Container(
      child: Column(
        children: liveModules.map((e) {
          final enabled = modulesConfig[e]['enabled'];
          return GestureDetector(
            child: PluginItemCard(
              margin: EdgeInsets.only(bottom: 16),
              title: dic!['$e.title']!,
              describe: dic['$e.brief']!,
            ),
            onTap: () {
              if (enabled) {
                Navigator.of(context)
                    .pushNamed(_liveModuleRoutes[e]!, arguments: enabled);
              } else {
                showCupertinoDialog(
                  context: context,
                  builder: (context) {
                    return CupertinoAlertDialog(
                      title: Text(dic['upgrading']!),
                      content: Text(dic['upgrading.context']!),
                      actions: <Widget>[
                        CupertinoDialogAction(
                          child: Text(dic['upgrading.btn']!),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              }
            },
          );
        }).toList(),
      ),
    );
  }
}

class NFTWidget extends StatefulWidget {
  NFTWidget(this.plugin);

  final PluginKarura plugin;

  @override
  _NFTWidgetState createState() => _NFTWidgetState();
}

class _NFTWidgetState extends State<NFTWidget> {
  final _liveModuleRoutes = {
    'nft': NFTPage.route,
  };

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'common');
    final dicGov = I18n.of(context)!.getDic(i18n_full_dic_karura, 'gov')!;
    final modulesConfig = widget.plugin.store!.setting.liveModules;
    final List liveModules = modulesConfig.keys.toList().sublist(1);

    liveModules.retainWhere((e) => modulesConfig[e]['visible'] && e == 'nft');
    return Container(
      child: Column(
        children: liveModules.map((e) {
          final enabled = modulesConfig[e]['enabled'];
          return GestureDetector(
            child: PluginItemCard(
              margin: EdgeInsets.only(bottom: 16),
              title: dic!['$e.title']!,
              describe: dic['$e.brief']!,
            ),
            onTap: () {
              if (enabled) {
                Navigator.of(context)
                    .pushNamed(_liveModuleRoutes[e]!, arguments: enabled);
              } else {
                showCupertinoDialog(
                  context: context,
                  builder: (context) {
                    return CupertinoAlertDialog(
                      title: Text(dic['upgrading']!),
                      content: Text(dic['upgrading.context']!),
                      actions: <Widget>[
                        CupertinoDialogAction(
                          child: Text(dic['upgrading.btn']!),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              }
            },
          );
        }).toList(),
      ),
    );
  }
}

class GovernanceWidget extends StatefulWidget {
  GovernanceWidget();

  @override
  _GovernanceWidgetState createState() => _GovernanceWidgetState();
}

class _GovernanceWidgetState extends State<GovernanceWidget> {
  @override
  Widget build(BuildContext context) {
    final dicGov = I18n.of(context)!.getDic(i18n_full_dic_karura, 'gov')!;

    return Container(
      child: Column(
        children: [
          GestureDetector(
            child: PluginItemCard(
              margin: EdgeInsets.only(bottom: 16),
              title: dicGov['democracy']!,
              describe: dicGov['democracy.brief']!,
            ),
            onTap: () => Navigator.of(context).pushNamed(DemocracyPage.route),
          ),
        ],
      ),
    );
  }
}
