import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
// import 'package:flutter_mobx/flutter_mobx.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:polkawallet_plugin_karura/common/constants/index.dart';
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
// import 'package:polkawallet_ui/components/SkaletonList.dart';
// import 'package:polkawallet_ui/components/entryPageCard.dart';
import 'package:polkawallet_ui/components/v3/plugin/metaHubPage.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginItemCard.dart';

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
  };

  List<MetaHubItem> getMetaItems() {
    final List<MetaHubItem> items = [];
    items.add(MetaHubItem("Staking", Container()));
    items.add(MetaHubItem("Defi", buildDefi()));
    items.add(MetaHubItem("Parachain", Container()));
    items.add(MetaHubItem("Governance", Container()));
    return items;
  }

  Widget buildDefi() {
    final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'common');
    final dicGov = I18n.of(context).getDic(i18n_full_dic_karura, 'gov');
    final modulesConfig = widget.plugin.store.setting.liveModules;
    final List liveModules = modulesConfig.keys.toList().sublist(1);

    liveModules?.retainWhere((e) => modulesConfig[e]['visible']);
    return Container(
      child: Column(
        children: [
          ...liveModules.map((e) {
            final enabled = modulesConfig[e]['enabled'];
            return GestureDetector(
              child: PluginItemCard(
                margin: EdgeInsets.only(bottom: 16),
                title: dic['$e.title'],
                describe: dic['$e.brief'],
              ),
              onTap: () {
                if (enabled) {
                  Navigator.of(context)
                      .pushNamed(_liveModuleRoutes[e], arguments: enabled);
                } else {
                  showCupertinoDialog(
                    context: context,
                    builder: (context) {
                      return CupertinoAlertDialog(
                        title: Text(dic['upgrading']),
                        content: Text(dic['upgrading.context']),
                        actions: <Widget>[
                          CupertinoDialogAction(
                            child: Text(dic['upgrading.btn']),
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
          GestureDetector(
            child: PluginItemCard(
              margin: EdgeInsets.only(bottom: 16),
              title: dicGov['democracy'],
              describe: dicGov['democracy.brief'],
            ),
            onTap: () => Navigator.of(context).pushNamed(DemocracyPage.route),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'common');
    // final dicGov = I18n.of(context).getDic(i18n_full_dic_karura, 'gov');

    return MetaHubPage(
      pluginName: widget.plugin.basic.name,
      metaItems: getMetaItems(),
    );

    // return Scaffold(
    //   backgroundColor: Colors.transparent,
    //   body: SafeArea(
    //     child: Column(
    //       children: <Widget>[
    //         Padding(
    //           padding: EdgeInsets.all(16),
    //           child: Row(
    //             mainAxisAlignment: MainAxisAlignment.center,
    //             children: <Widget>[
    //               Text(
    //                 dic['karura'],
    //                 style: TextStyle(
    //                   fontSize: 20,
    //                   color: Theme.of(context).cardColor,
    //                   fontWeight: FontWeight.w500,
    //                 ),
    //               )
    //             ],
    //           ),
    //         ),
    //         Expanded(
    //           child: Observer(
    //             builder: (_) {
    //               if (widget.plugin.sdk.api?.connectedNode == null) {
    //                 return Column(children: [
    //                   Container(
    //                     height: 68,
    //                     margin: EdgeInsets.only(bottom: 16),
    //                     child: SvgPicture.asset(
    //                         'packages/polkawallet_plugin_karura/assets/images/logo_kar_empty.svg',
    //                         color: Colors.white70),
    //                   ),
    //                   Expanded(
    //                       child: SkaletonList(
    //                     items: _liveModuleRoutes.length,
    //                   ))
    //                 ]);
    //                 // return Container(
    //                 //   padding: EdgeInsets.only(
    //                 //       top: MediaQuery.of(context).size.width / 2),
    //                 //   child: Column(
    //                 //     children: [
    //                 //       CupertinoActivityIndicator(),
    //                 //       Text(dic['node.connecting']),
    //                 //     ],
    //                 //   ),
    //                 // );
    //               }
    //               final modulesConfig = widget.plugin.store.setting.liveModules;
    //               final List liveModules =
    //                   modulesConfig.keys.toList().sublist(1);

    //               liveModules?.retainWhere((e) => modulesConfig[e]['visible']);

    //               return ListView(
    //                 padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
    //                 children: <Widget>[
    //                   Container(
    //                     height: 68,
    //                     margin: EdgeInsets.only(bottom: 16),
    //                     child: SvgPicture.asset(
    //                         'packages/polkawallet_plugin_karura/assets/images/logo_kar_empty.svg',
    //                         color: Colors.white70),
    //                   ),
    //                   ...liveModules.map((e) {
    //                     final enabled = modulesConfig[e]['enabled'];
    //                     return Padding(
    //                       padding: EdgeInsets.only(bottom: 16),
    //                       child: GestureDetector(
    //                         child: EntryPageCard(
    //                           dic['$e.title'],
    //                           dic['$e.brief'],
    //                           SvgPicture.asset(
    //                             module_icons_uri[e],
    //                             height: 88,
    //                           ),
    //                           color: Colors.transparent,
    //                         ),
    //                         onTap: () {
    //                           if (enabled) {
    //                             Navigator.of(context).pushNamed(
    //                                 _liveModuleRoutes[e],
    //                                 arguments: enabled);
    //                           } else {
    //                             showCupertinoDialog(
    //                               context: context,
    //                               builder: (context) {
    //                                 return CupertinoAlertDialog(
    //                                   title: Text(dic['upgrading']),
    //                                   content: Text(dic['upgrading.context']),
    //                                   actions: <Widget>[
    //                                     CupertinoDialogAction(
    //                                       child: Text(dic['upgrading.btn']),
    //                                       onPressed: () {
    //                                         Navigator.of(context).pop();
    //                                       },
    //                                     ),
    //                                   ],
    //                                 );
    //                               },
    //                             );
    //                           }
    //                         },
    //                       ),
    //                     );
    //                   }).toList(),
    //                   Padding(
    //                     padding: EdgeInsets.only(bottom: 16),
    //                     child: GestureDetector(
    //                       child: EntryPageCard(
    //                         dicGov['democracy'],
    //                         dicGov['democracy.brief'],
    //                         SvgPicture.asset(
    //                           'packages/polkawallet_plugin_karura/assets/images/democracy.svg',
    //                           height: 88,
    //                           color: Theme.of(context).primaryColor,
    //                         ),
    //                         color: Colors.transparent,
    //                       ),
    //                       onTap: () => Navigator.of(context)
    //                           .pushNamed(DemocracyPage.route),
    //                     ),
    //                   ),
    //                 ],
    //               );
    //             },
    //           ),
    //         )
    //       ],
    //     ),
    //   ),
    // );
  }
}
