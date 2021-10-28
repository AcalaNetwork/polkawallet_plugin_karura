import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_plugin_karura/common/constants/base.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/pages/earn/earnPage.dart';
import 'package:polkawallet_plugin_karura/pages/gov/democracyPage.dart';
import 'package:polkawallet_plugin_karura/pages/homa/homaPage.dart';
import 'package:polkawallet_plugin_karura/pages/loan/loanPage.dart';
import 'package:polkawallet_plugin_karura/pages/nft/nftPage.dart';
import 'package:polkawallet_plugin_karura/pages/swap/swapPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/entryPageCard.dart';

class AcalaEntry extends StatefulWidget {
  AcalaEntry(this.plugin, this.keyring);

  final PluginKarura plugin;
  final Keyring keyring;

  @override
  _AcalaEntryState createState() => _AcalaEntryState();
}

class _AcalaEntryState extends State<AcalaEntry> {
  final _liveModuleRoutes = {
    'loan': LoanPage.route,
    'swap': SwapPage.route,
    'earn': EarnPage.route,
    'homa': HomaPage.route,
    'nft': NFTPage.route,
    'gov': NFTPage.route,
  };

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'common');
    final dicGov = I18n.of(context).getDic(i18n_full_dic_karura, 'gov');
    final isKar = widget.plugin.basic.name == plugin_name_karura;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    dic[isKar ? 'karura' : 'acala'],
                    style: TextStyle(
                      fontSize: 20,
                      color: Theme.of(context).cardColor,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                ],
              ),
            ),
            Expanded(
              child: Observer(
                builder: (_) {
                  if (widget.plugin.sdk.api?.connectedNode == null) {
                    return Container(
                      padding: EdgeInsets.only(
                          top: MediaQuery.of(context).size.width / 2),
                      child: Column(
                        children: [
                          CupertinoActivityIndicator(),
                          Text(dic['node.connecting']),
                        ],
                      ),
                    );
                  }
                  final modulesConfig = widget.plugin.store.setting.liveModules;
                  final List liveModules =
                      modulesConfig.keys.toList().sublist(1);

                  liveModules?.retainWhere((e) => modulesConfig[e]['visible']);

                  return ListView(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: <Widget>[
                      Container(
                        height: 68,
                        margin: EdgeInsets.only(bottom: 16),
                        child: SvgPicture.asset(
                            'packages/polkawallet_plugin_karura/assets/images/${isKar ? 'logo_kar_empty' : 'logo1'}.svg',
                            color: Colors.white70),
                      ),
                      ...liveModules.map((e) {
                        final enabled = !isKar || modulesConfig[e]['enabled'];
                        return Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: GestureDetector(
                            child: EntryPageCard(
                              dic['$e.title'],
                              enabled ? dic['$e.brief'] : dic['coming'],
                              SvgPicture.asset(
                                module_icons_uri[e],
                                height: 88,
                              ),
                              color: Colors.transparent,
                            ),
                            onTap: () => Navigator.of(context).pushNamed(
                                _liveModuleRoutes[e],
                                arguments: enabled),
                          ),
                        );
                      }).toList(),
                      Visibility(
                          visible: isKar,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: GestureDetector(
                              child: EntryPageCard(
                                dicGov['democracy'],
                                dicGov['democracy.brief'],
                                SvgPicture.asset(
                                  'packages/polkawallet_plugin_karura/assets/images/democracy.svg',
                                  height: 88,
                                  color: Theme.of(context).primaryColor,
                                ),
                                color: Colors.transparent,
                              ),
                              onTap: () => Navigator.of(context)
                                  .pushNamed(DemocracyPage.route),
                            ),
                          )),
                    ],
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
