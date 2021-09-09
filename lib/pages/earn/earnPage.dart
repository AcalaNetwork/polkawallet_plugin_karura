import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/pages/earn/earnDetailPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/currencyWithIcon.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/utils/format.dart';

class EarnPage extends StatefulWidget {
  EarnPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/karura/earn';

  @override
  _EarnPageState createState() => _EarnPageState();
}

class _EarnPageState extends State<EarnPage> {
  Timer _timer;

  bool _loading = true;

  Future<void> _fetchData() async {
    await widget.plugin.service.earn.updateAllDexPoolInfo();

    widget.plugin.service.gov.updateBestNumber();
    if (mounted) {
      setState(() {
        _loading = false;
      });

      _timer = Timer(Duration(seconds: 10), () {
        _fetchData();
      });
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');

    return Observer(builder: (_) {
      final dexPools = widget.plugin.store.earn.dexPools.toList();
      dexPools.retainWhere((e) => e.provisioning == null);
      return Scaffold(
          appBar: AppBar(title: Text(dic['earn.title']), centerTitle: true),
          body: SafeArea(
            child: dexPools.length == 0
                ? ListView(
                    padding: EdgeInsets.all(16),
                    children: [
                      Center(
                        child: Container(
                          height: MediaQuery.of(context).size.width,
                          child: ListTail(isEmpty: true, isLoading: _loading),
                        ),
                      )
                    ],
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: dexPools.length,
                    itemBuilder: (_, i) {
                      final poolId =
                          dexPools[i].tokens.map((e) => e['token']).join('-');
                      final poolInfo =
                          widget.plugin.store.earn.dexPoolInfoMap[poolId];
                      final rewards =
                          widget.plugin.store.earn.swapPoolRewards[poolId];
                      final savingRewards = widget
                          .plugin.store.earn.swapPoolSavingRewards[poolId];
                      final rewardsEmpty = rewards == null;
                      return GestureDetector(
                        child: RoundedCard(
                          margin: EdgeInsets.only(bottom: 16),
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              CurrencyWithIcon(
                                PluginFmt.tokenView(poolId),
                                TokenIcon(poolId, widget.plugin.tokenIcons),
                                textStyle:
                                    Theme.of(context).textTheme.headline4,
                                mainAxisAlignment: MainAxisAlignment.center,
                              ),
                              Divider(height: 24),
                              Text(
                                Fmt.token(poolInfo?.sharesTotal ?? BigInt.zero,
                                    dexPools[i].decimals),
                                style: Theme.of(context).textTheme.headline4,
                              ),
                              Container(
                                margin: EdgeInsets.only(top: 4),
                                child: Text('staked'),
                              ),
                              Container(
                                margin: EdgeInsets.only(top: 16),
                                child: Text(
                                  '${dic['earn.apy']}: ${rewardsEmpty ? '--.--%' : Fmt.ratio(rewards + savingRewards)}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor),
                                ),
                              )
                            ],
                          ),
                        ),
                        onTap: () => Navigator.of(context)
                            .pushNamed(EarnDetailPage.route, arguments: poolId),
                      );
                    },
                  ),
          ));
    });
  }
}
