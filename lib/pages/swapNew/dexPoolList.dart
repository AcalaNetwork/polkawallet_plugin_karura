import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/api/types/dexPoolInfoData.dart';
import 'package:polkawallet_plugin_karura/pages/earn/addLiquidityPage.dart';
import 'package:polkawallet_plugin_karura/pages/earn/withdrawLiquidityPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginInfoItem.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginOutlinedButtonSmall.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/components/v3/plugin/roundedPluginCard.dart';
import 'package:polkawallet_ui/utils/format.dart';

class DexPoolList extends StatefulWidget {
  DexPoolList(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  @override
  _DexPoolListState createState() => _DexPoolListState();
}

class _DexPoolListState extends State<DexPoolList> {
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      new GlobalKey<RefreshIndicatorState>();

  Map _poolInfoMap = {};

  Future<void> _updateData() async {
    await widget.plugin.service!.earn.getDexPools();
    final pools = widget.plugin.store!.earn.dexPools.toList();
    final List? res = await widget.plugin.sdk.webView!.evalJavascript(
        'Promise.all([${pools.map((e) => 'api.query.dex.liquidityPool(${jsonEncode(e.tokens)})').join(',')}])');
    final poolInfoMap = {};
    pools.asMap().forEach((i, e) {
      poolInfoMap[e.tokenNameId] = res![i];
    });
    if (mounted) {
      setState(() {
        _poolInfoMap = poolInfoMap;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _refreshKey.currentState!.show();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      final dexPools = widget.plugin.store!.earn.dexPools.toList();
      dexPools.retainWhere((e) => e.provisioning == null);
      return RefreshIndicator(
        key: _refreshKey,
        onRefresh: _updateData,
        child: dexPools.length == 0
            ? ListView(
                padding: EdgeInsets.fromLTRB(8, 16, 8, 16),
                children: [
                  Center(
                    child: Container(
                      height: MediaQuery.of(context).size.width,
                      child: ListTail(
                        isEmpty: true,
                        isLoading: false,
                        color: Colors.white,
                      ),
                    ),
                  )
                ],
              )
            : ListView.builder(
                padding: EdgeInsets.fromLTRB(8, 16, 8, 16),
                itemCount: dexPools.length,
                itemBuilder: (_, i) {
                  final poolAmount =
                      _poolInfoMap[dexPools[i].tokenNameId] as List?;
                  return _DexPoolCard(
                    plugin: widget.plugin,
                    pool: dexPools[i],
                    poolAmount: poolAmount,
                    tokenIcons: widget.plugin.tokenIcons,
                  );
                },
              ),
      );
    });
  }
}

class _DexPoolCard extends StatelessWidget {
  _DexPoolCard({this.plugin, this.pool, this.poolAmount, this.tokenIcons});

  final PluginKarura? plugin;
  final DexPoolData? pool;
  final List? poolAmount;
  final Map<String, Widget>? tokenIcons;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    final colorGrey = Theme.of(context).unselectedWidgetColor;

    final balancePair = pool!.tokens!
        .map((e) => AssetsUtils.tokenDataFromCurrencyId(plugin, e))
        .toList();
    final tokenPairView =
        balancePair.map((e) => PluginFmt.tokenView(e!.symbol)).join('-');

    double? amountLeft;
    double? amountRight;
    double ratio = 0;
    if (poolAmount != null) {
      amountLeft = Fmt.balanceDouble(
          poolAmount![0].toString(), balancePair[0]!.decimals!);
      amountRight = Fmt.balanceDouble(
          poolAmount![1].toString(), balancePair[1]!.decimals!);
      ratio = amountLeft > 0 ? amountRight / amountLeft : 0;
    }

    return RoundedPluginCard(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.symmetric(vertical: 16),
      borderRadius: const BorderRadius.all(const Radius.circular(14)),
      color: Color(0x19FFFFFF),
      child: Column(
        children: [
          Padding(
              padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Row(
                children: [
                  Container(
                    child: TokenIcon(
                        balancePair.map((e) => e!.symbol).join('-'),
                        tokenIcons!,
                        size: 26),
                    margin: EdgeInsets.only(right: 12),
                  ),
                  Expanded(
                      child: Text(
                    tokenPairView,
                    style: Theme.of(context)
                        .textTheme
                        .headline3
                        ?.copyWith(color: Colors.white, fontSize: 18),
                  )),
                ],
              )),
          Container(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            color: Color(0x2bFFFFFF),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                PluginInfoItem(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  title: PluginFmt.tokenView(balancePair[0]!.symbol),
                  content:
                      amountLeft == null ? '--' : Fmt.priceFloor(amountLeft),
                ),
                PluginInfoItem(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  title: PluginFmt.tokenView(balancePair[1]!.symbol),
                  content:
                      amountRight == null ? '--' : Fmt.priceFloor(amountRight),
                ),
                PluginInfoItem(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  title: dic['boot.ratio'],
                  content: '1 : ${ratio.toStringAsFixed(4)}',
                ),
              ],
            ),
          ),
          Padding(
              padding: EdgeInsets.only(left: 16, right: 16, top: 16),
              child: Row(
                children: [
                  Expanded(
                    child: PluginOutlinedButtonSmall(
                      content: dic['dex.removeLiquidity'],
                      color: Colors.white,
                      active: true,
                      padding: EdgeInsets.only(top: 8, bottom: 8),
                      onPressed: () => Navigator.of(context).pushNamed(
                          WithdrawLiquidityPage.route,
                          arguments: pool),
                    ),
                  ),
                  Expanded(
                    child: PluginOutlinedButtonSmall(
                      content: dic['dex.addLiquidity'],
                      color: Color(0xFFFC8156),
                      active: true,
                      padding: EdgeInsets.only(top: 8, bottom: 8),
                      onPressed: () => Navigator.of(context).pushNamed(
                          AddLiquidityPage.route,
                          arguments: {'poolId': pool?.tokenNameId}),
                    ),
                  ),
                ],
              )),
        ],
      ),
    );
  }
}
