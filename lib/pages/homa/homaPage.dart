import 'dart:async';

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/pages/homa/homaHistoryPage.dart';
import 'package:polkawallet_plugin_karura/pages/homa/mintPage.dart';
import 'package:polkawallet_plugin_karura/pages/homa/redeemPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/infoItem.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';

class HomaPage extends StatefulWidget {
  HomaPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/karura/homa';

  @override
  _HomaPageState createState() => _HomaPageState();
}

class _HomaPageState extends State<HomaPage> {
  Timer _timer;
  String unlockingKsm;

  Future<void> _refreshRedeem() async {
    var data = await widget.plugin.api.homa
        .redeemRequested(widget.keyring.current.address);
    if (mounted) {
      if (data != null && data.length > 0) {
        setState(() {
          unlockingKsm = data;
        });
      } else if (unlockingKsm != null) {
        setState(() {
          unlockingKsm = null;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    widget.plugin.service.assets.queryMarketPrices([relay_chain_token_symbol]);
    await widget.plugin.service.homa.queryHomaLiteStakingPool();

    _refreshRedeem();

    if (_timer == null) {
      _timer = Timer.periodic(Duration(seconds: 20), (timer) {
        _refreshData();
      });
    }
  }

  Future<void> _onSubmit() async {
    var params = [0, 0];
    var module = 'homaLite';
    var call = 'requestRedeem';
    var txDisplay = {};
    final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
        arguments: TxConfirmParams(
          module: module,
          call: call,
          txTitle:
              "${I18n.of(context).getDic(i18n_full_dic_karura, 'acala')['homa.redeem.cancel']}${I18n.of(context).getDic(i18n_full_dic_karura, 'acala')['homa.redeem']}$relay_chain_token_symbol",
          txDisplay: txDisplay,
          params: params,
        ))) as Map;

    if (res != null) {
      _refreshRedeem();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
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
  Widget build(_) {
    return Observer(
      builder: (BuildContext context) {
        final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');
        final symbols = widget.plugin.networkState.tokenSymbol;
        final decimals = widget.plugin.networkState.tokenDecimals;

        final stakeSymbol = relay_chain_token_symbol;

        final poolInfo = widget.plugin.store.homa.poolInfo;
        final staked = poolInfo.staked ?? BigInt.zero;
        final cap = poolInfo.cap ?? BigInt.zero;
        final amountLeft = cap - staked;
        final liquidTokenIssuance = poolInfo.liquidTokenIssuance ?? BigInt.zero;

        final balances = PluginFmt.getBalancePair(
            widget.plugin, [stakeSymbol, 'L$stakeSymbol']);
        final balanceStakeToken =
            Fmt.balanceDouble(balances[0].amount, balances[0].decimals);
        final balanceLiquidToken =
            Fmt.balanceDouble(balances[1].amount, balances[1].decimals);
        final exchangeRate = staked > BigInt.zero
            ? (liquidTokenIssuance / staked)
            : Fmt.balanceDouble(
                widget.plugin.networkConst['homaLite']['defaultExchangeRate'],
                acala_price_decimals);

        final List<charts.Series> seriesList = [
          new charts.Series<num, int>(
            id: 'chartData',
            domainFn: (_, i) => i,
            colorFn: (_, i) => i == 0
                ? charts.MaterialPalette.red.shadeDefault
                : charts.MaterialPalette.gray.shade100,
            measureFn: (num i, _) => i,
            data: [
              staked.toDouble(),
              (amountLeft > BigInt.zero ? amountLeft : BigInt.zero).toDouble(),
            ],
          )
        ];

        final nativeDecimal = decimals[symbols.indexOf(stakeSymbol)];

        final minStake = Fmt.balanceInt(widget
                .plugin.networkConst['homaLite']['minimumMintThreshold']
                .toString()) +
            Fmt.balanceInt(
                widget.plugin.networkConst['homaLite']['mintFee'].toString());

        final primary = Theme.of(context).primaryColor;
        final white = Theme.of(context).cardColor;

        return Scaffold(
          appBar: AppBar(
            title: Text('${dic['homa.title']} $stakeSymbol'),
            centerTitle: true,
            elevation: 0.0,
            actions: [
              IconButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(HomaHistoryPage.route),
                  icon: Icon(Icons.history))
            ],
          ),
          body: Stack(
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                height: 180,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [primary, white],
                  stops: [0.4, 0.9],
                )),
              ),
              SafeArea(
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: ListView(
                        children: <Widget>[
                          RoundedCard(
                            margin: EdgeInsets.all(16),
                            padding: EdgeInsets.all(16),
                            child: Column(
                              children: <Widget>[
                                Text('$stakeSymbol ${dic['homa.pool']}'),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        alignment: AlignmentDirectional.center,
                                        children: [
                                          Container(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                3,
                                            child: charts.PieChart(seriesList,
                                                animate: false,
                                                defaultRenderer: new charts
                                                        .ArcRendererConfig(
                                                    arcWidth: 10)),
                                          ),
                                          TokenIcon(stakeSymbol,
                                              widget.plugin.tokenIcons),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            dic['homa.pool.bonded'],
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          Text(
                                            Fmt.token(staked, nativeDecimal),
                                            style: Theme.of(context)
                                                .textTheme
                                                .headline4,
                                          ),
                                          Container(
                                            margin: EdgeInsets.only(top: 8),
                                            child: Text(
                                              dic['homa.pool.cap'],
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                          Text(
                                            Fmt.token(cap, nativeDecimal),
                                            style: Theme.of(context)
                                                .textTheme
                                                .headline4,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '1 KSM ≈ ${Fmt.priceFloor(exchangeRate, lengthMax: 4)} LKSM',
                                  style: TextStyle(fontSize: 12),
                                ),
                                Divider(height: 24),
                                Row(
                                  children: <Widget>[
                                    InfoItem(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      title: dic['homa.pool.min'],
                                      content:
                                          '> ${Fmt.token(minStake, nativeDecimal)}',
                                    ),
                                    InfoItem(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      title: 'APR',
                                      content: '≈ 16%',
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                          RoundedCard(
                            margin: EdgeInsets.fromLTRB(16, 0, 16, 32),
                            padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
                            child: Column(
                              children: [
                                Container(
                                  margin: EdgeInsets.only(bottom: 24),
                                  child: Text(dic['homa.user.stats']),
                                ),
                                Visibility(
                                    visible: unlockingKsm != null &&
                                        double.tryParse(unlockingKsm ?? '0') !=
                                            0,
                                    child: Column(children: [
                                      Row(
                                        children: [
                                          Expanded(
                                              child: Container(
                                            padding: EdgeInsets.only(left: 50),
                                            child: Text(
                                              dic['homa.user.unlocking'],
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w400),
                                            ),
                                          )),
                                          Expanded(
                                              child: Row(
                                            children: [
                                              Container(
                                                margin:
                                                    EdgeInsets.only(right: 8),
                                                child: TokenIcon(stakeSymbol,
                                                    widget.plugin.tokenIcons),
                                              ),
                                              // InfoItem(
                                              //   title:
                                              //       '≈ \$${Fmt.priceFloor((widget.plugin.store.assets.marketPrices[stakeSymbol] ?? 0) * double.tryParse(unlockingKsm ?? '0'), lengthMax: 2)}',
                                              //   content:
                                              //       '${Fmt.priceFloor(double.tryParse(unlockingKsm ?? '0'), lengthMax: 4)}',
                                              //   lowTitle: true,
                                              // ),
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Column(
                                                    children: [
                                                      Text(
                                                        '${Fmt.priceFloor(double.tryParse(unlockingKsm ?? '0'), lengthMax: 4)}',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Theme.of(
                                                                  context)
                                                              .unselectedWidgetColor,
                                                        ),
                                                      ),
                                                      Text(
                                                          '≈ \$${Fmt.priceFloor((widget.plugin.store.assets.marketPrices[stakeSymbol] ?? 0) * double.tryParse(unlockingKsm ?? '0'), lengthMax: 2)}',
                                                          style: TextStyle(
                                                              fontSize: 12,
                                                              color: Theme.of(
                                                                      context)
                                                                  .unselectedWidgetColor)),
                                                    ],
                                                  ),
                                                  GestureDetector(
                                                      child: Container(
                                                          margin:
                                                              EdgeInsets.only(
                                                                  left: 5),
                                                          child: Text(
                                                            dic['homa.redeem.cancel'],
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontStyle:
                                                                  FontStyle
                                                                      .italic,
                                                              decoration:
                                                                  TextDecoration
                                                                      .underline,
                                                              color: Theme.of(
                                                                      context)
                                                                  .primaryColor,
                                                            ),
                                                          )),
                                                      onTap: () {
                                                        showCupertinoDialog(
                                                          context: context,
                                                          builder: (BuildContext
                                                              context) {
                                                            return CupertinoAlertDialog(
                                                              title: Text(dic[
                                                                  'homa.confirm']),
                                                              content: Text(dic[
                                                                  'homa.redeem.hint']),
                                                              actions: <Widget>[
                                                                CupertinoButton(
                                                                  child: Text(
                                                                    dic['homa.redeem.cancel'],
                                                                    style:
                                                                        TextStyle(
                                                                      color: Theme.of(
                                                                              context)
                                                                          .unselectedWidgetColor,
                                                                    ),
                                                                  ),
                                                                  onPressed:
                                                                      () {
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop();
                                                                  },
                                                                ),
                                                                CupertinoButton(
                                                                  child: Text(
                                                                    dic['homa.confirm'],
                                                                    style:
                                                                        TextStyle(
                                                                      color: Theme.of(
                                                                              context)
                                                                          .unselectedWidgetColor,
                                                                    ),
                                                                  ),
                                                                  onPressed:
                                                                      () {
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop();
                                                                    _onSubmit();
                                                                  },
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        );
                                                      })
                                                ],
                                              )
                                            ],
                                          ))
                                        ],
                                      ),
                                      Container(
                                        child: Divider(height: 24),
                                      )
                                    ])),
                                Row(
                                  children: [
                                    Expanded(
                                        child: Container(
                                      padding: EdgeInsets.only(left: 50),
                                      child: Text(
                                        dic['homa.user.ksm'],
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400),
                                      ),
                                    )),
                                    Expanded(
                                        child: Row(
                                      children: [
                                        Container(
                                          margin: EdgeInsets.only(right: 8),
                                          child: TokenIcon(stakeSymbol,
                                              widget.plugin.tokenIcons),
                                        ),
                                        InfoItem(
                                          title:
                                              '≈ \$${Fmt.priceFloor((widget.plugin.store.assets.marketPrices[stakeSymbol] ?? 0) * balanceStakeToken)}',
                                          content: Fmt.priceFloor(
                                              balanceStakeToken,
                                              lengthMax: 4),
                                          lowTitle: true,
                                        ),
                                      ],
                                    ))
                                  ],
                                ),
                                Container(
                                  child: Divider(height: 24),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                        child: Container(
                                      padding: EdgeInsets.only(left: 50),
                                      child: Text(
                                        dic['homa.user.lksm'],
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400),
                                      ),
                                    )),
                                    Expanded(
                                        child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          margin: EdgeInsets.only(right: 8),
                                          child: TokenIcon('L$stakeSymbol',
                                              widget.plugin.tokenIcons),
                                        ),
                                        InfoItem(
                                          title:
                                              '≈ ${Fmt.priceFloor(balanceLiquidToken / exchangeRate, lengthMax: 4)} $stakeSymbol',
                                          content: Fmt.priceFloor(
                                              balanceLiquidToken,
                                              lengthMax: 4),
                                          lowTitle: true,
                                        ),
                                      ],
                                    ))
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Visibility(
                        visible: liquidTokenIssuance >= BigInt.zero,
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Container(
                                color: primary,
                                child: TextButton(
                                  child: Text(
                                    '${dic['homa.redeem']} $stakeSymbol',
                                    style: TextStyle(color: white),
                                  ),
                                  onPressed: () => Navigator.of(context)
                                      .pushNamed(RedeemPage.route)
                                      .then((value) {
                                    if (value != null) {
                                      _refreshData();
                                    }
                                  }),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                color: staked < cap
                                    ? Theme.of(context).accentColor
                                    : Theme.of(context).disabledColor,
                                child: TextButton(
                                  child: Text(
                                    '${dic['homa.mint']} L$stakeSymbol',
                                    style: TextStyle(color: white),
                                  ),
                                  onPressed: staked < cap
                                      ? () async {
                                          // if (!(await _confirmMint())) return;

                                          Navigator.of(context)
                                              .pushNamed(MintPage.route)
                                              .then((value) {
                                            if (value != null) {
                                              _refreshData();
                                            }
                                          });
                                        }
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        )),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
