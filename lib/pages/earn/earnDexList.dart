import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/pages/earn/earnDetailPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/currencyWithIcon.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/utils/format.dart';

class EarnDexList extends StatefulWidget {
  EarnDexList(this.plugin);
  final PluginKarura plugin;

  @override
  _EarnDexListState createState() => _EarnDexListState();
}

class _EarnDexListState extends State<EarnDexList> {
  Timer _timer;

  bool _loading = true;

  Future<void> _fetchData() async {
    await widget.plugin.service.earn.updateAllDexPoolInfo();

    widget.plugin.service.gov.updateBestNumber();
    if (mounted) {
      setState(() {
        _loading = false;
      });

      _timer = Timer(Duration(seconds: 30), () {
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

      final incentivesV2 = widget.plugin.store.earn.incentives;
      return dexPools.length == 0
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

                BigInt sharesTotal = BigInt.zero;
                double rewards = 0;
                double savingRewards = 0;

                sharesTotal = widget.plugin.store.earn.dexPoolInfoMapV2[poolId]
                        ?.sharesTotal ??
                    BigInt.zero;
                if (incentivesV2.dex != null) {
                  (incentivesV2.dex[poolId] ?? []).forEach((e) {
                    rewards += e.apr;
                  });
                  (incentivesV2.dexSaving[poolId] ?? []).forEach((e) {
                    savingRewards += e.apr;
                  });
                }

                final rewardsEmpty = incentivesV2.dex == null;
                return GestureDetector(
                  child: RoundedCard(
                    margin: EdgeInsets.only(bottom: 16),
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        CurrencyWithIcon(
                          PluginFmt.tokenView(poolId),
                          TokenIcon(poolId, widget.plugin.tokenIcons),
                          textStyle: Theme.of(context).textTheme.headline4,
                          mainAxisAlignment: MainAxisAlignment.center,
                        ),
                        Divider(height: 24),
                        Text(
                          Fmt.token(sharesTotal, dexPools[i].decimals),
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
            );
    });
  }
}
