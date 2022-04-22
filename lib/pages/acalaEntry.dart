import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/pages/earnNew/earnPage.dart';
import 'package:polkawallet_plugin_karura/pages/homaNew/homaPage.dart';
import 'package:polkawallet_plugin_karura/pages/loanNew/loanPage.dart';
import 'package:polkawallet_plugin_karura/pages/swapNew/swapPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginItemCard.dart';

class DefiWidget extends StatelessWidget {
  DefiWidget(this.plugin);

  final PluginKarura plugin;

  final _liveModuleRoutes = {
    'loan': LoanPage.route,
    'swap': SwapPage.route,
    'earn': EarnPage.route,
    'homa': HomaPage.route,
  };

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'common');
    final modulesConfig =
        plugin.store!.setting.remoteConfig['modules'] ?? config_modules;
    List liveModules = [];
    if (modulesConfig.keys.length > 0) {
      liveModules = modulesConfig.keys.toList().sublist(1);
    }

    liveModules.retainWhere((e) => modulesConfig[e]['visible'] && e != 'nft');

    return SingleChildScrollView(
      child: Column(
        children: liveModules.map((e) {
          final enabled = modulesConfig[e]['enabled'];
          return GestureDetector(
            child: PluginItemCard(
              margin: EdgeInsets.only(bottom: 16),
              title: dic!['$e.title']!,
              describe: dic['$e.brief']!,
              icon: Image.asset(
                  "packages/polkawallet_plugin_karura/assets/images/icon_$e.png",
                  width: 18),
            ),
            onTap: () {
              if (enabled) {
                Navigator.of(context).pushNamed(_liveModuleRoutes[e]!);
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
