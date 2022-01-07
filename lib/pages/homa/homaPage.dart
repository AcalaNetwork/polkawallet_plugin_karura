import 'dart:async';

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/api/types/homaNewEnvData.dart';
import 'package:polkawallet_plugin_karura/api/types/homaPendingRedeemData.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/pages/homa/homaHistoryPage.dart';
import 'package:polkawallet_plugin_karura/pages/homa/mintPage.dart';
import 'package:polkawallet_plugin_karura/pages/homa/redeemPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/infoItem.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/iconButton.dart' as v3;
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';

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
  String _unlockingKsm;
  bool _isHomaAlive = false;

  Future<void> _refreshRedeem() async {
    var data = await widget.plugin.api.homa
        .redeemRequested(widget.keyring.current.address);
    if (!mounted) return;

    if (data != null && data.length > 0) {
      setState(() {
        _unlockingKsm = data;
      });
    } else if (_unlockingKsm != null) {
      setState(() {
        _unlockingKsm = null;
      });
    }
  }

  Future<void> _refreshData() async {
    widget.plugin.service.assets.queryMarketPrices([relay_chain_token_symbol]);
    widget.plugin.service.gov.updateBestNumber();

    if (_isHomaAlive) {
      await widget.plugin.service.homa.queryHomaEnv();
      widget.plugin.service.homa.queryHomaPendingRedeem();
    } else {
      await widget.plugin.service.homa.queryHomaLiteStakingPool();
      _refreshRedeem();
    }

    if (_timer == null) {
      _timer = Timer.periodic(Duration(seconds: 20), (timer) {
        _refreshData();
      });
    }
  }

  void _onCancelRedeem() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');
        return CupertinoAlertDialog(
          title: Text(dic['homa.confirm']),
          content: Text(dic['homa.redeem.hint']),
          actions: <Widget>[
            CupertinoButton(
              child: Text(
                dic['homa.redeem.cancel'],
                style: TextStyle(
                  color: Theme.of(context).unselectedWidgetColor,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            CupertinoButton(
              child: Text(dic['homa.confirm']),
              onPressed: () {
                Navigator.of(context).pop();
                _onSubmit();
              },
            ),
          ],
        );
      },
    );
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final isHomaAlive = await widget.plugin.api.homa.isHomaAlive();
      setState(() {
        _isHomaAlive = isHomaAlive;
      });

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

  Size boundingTextSize(String text, TextStyle style) {
    if (text == null || text.isEmpty) {
      return Size.zero;
    }
    final TextPainter textPainter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(text: text, style: style))
      ..layout();
    return textPainter.size;
  }

  @override
  Widget build(_) {
    return Observer(
      builder: (BuildContext context) {
        final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');
        final dicAssets =
            I18n.of(context).getDic(i18n_full_dic_karura, 'common');
        final symbols = widget.plugin.networkState.tokenSymbol;
        final decimals = widget.plugin.networkState.tokenDecimals;

        final stakeSymbol = relay_chain_token_symbol;
        final isOldVersion = !_isHomaAlive;

        final poolInfo = widget.plugin.store.homa.poolInfo;
        final env = widget.plugin.store.homa.env;
        final staked = env != null
            ? BigInt.from(env.totalStaking)
            : poolInfo.staked ?? BigInt.zero;
        final cap = env != null
            ? BigInt.from(env.stakingSoftCap)
            : poolInfo.cap ?? BigInt.zero;
        final amountLeft = cap - staked;
        final liquidTokenIssuance = poolInfo.liquidTokenIssuance ?? BigInt.zero;

        final balances = AssetsUtils.getBalancePairFromTokenNameId(
            widget.plugin, [stakeSymbol, 'L$stakeSymbol']);
        final balanceStakeToken =
            Fmt.balanceDouble(balances[0].amount, balances[0].decimals);
        final balanceLiquidToken =
            Fmt.balanceDouble(balances[1].amount, balances[1].decimals);
        final exchangeRate = env != null
            ? 1 / env.exchangeRate
            : staked > BigInt.zero
                ? ((poolInfo.liquidTokenIssuance ?? BigInt.zero) / staked)
                : Fmt.balanceDouble(
                    widget.plugin.networkConst['homaLite']
                        ['defaultExchangeRate'],
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

        final minStake = env != null
            ? env.mintThreshold
            : (Fmt.balanceInt(widget
                    .plugin.networkConst['homaLite']['minimumMintThreshold']
                    .toString()) +
                Fmt.balanceInt(widget.plugin.networkConst['homaLite']['mintFee']
                    .toString()));

        final primary = Theme.of(context).primaryColor;
        final white = Theme.of(context).cardColor;

        return Scaffold(
          appBar: AppBar(
            title: Text('${dic['homa.title']} $stakeSymbol'),
            centerTitle: true,
            elevation: 0.0,
            leading: BackBtn(),
            actions: [
              Container(
                margin: EdgeInsets.only(right: 16),
                child: v3.IconButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(HomaHistoryPage.route),
                  icon: Icon(Icons.history, size: 18),
                  isBlueBg: true,
                ),
              )
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
                                            env != null
                                                ? Fmt.doubleFormat(
                                                    env.totalStaking)
                                                : Fmt.token(
                                                    staked, nativeDecimal),
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
                                            env != null
                                                ? Fmt.doubleFormat(
                                                    env.stakingSoftCap * 1.0)
                                                : Fmt.token(cap, nativeDecimal),
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
                                          '> ${env != null ? env.mintThreshold : Fmt.token(minStake, nativeDecimal)}',
                                    ),
                                    InfoItem(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      title: 'APR',
                                      content: env != null
                                          ? "≈ ${Fmt.priceFloor(env.apy * 100)}%"
                                          : '≈ 20%',
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                          isOldVersion
                              ? Container()
                              : _HomaUserInfoCard(
                                  env: widget.plugin.store.homa.env,
                                  userInfo: widget.plugin.store.homa.userInfo,
                                  address: widget.keyring.current.address,
                                  bestNumber:
                                      widget.plugin.store.gov.bestNumber,
                                  stakeTokenDecimals: balances[0].decimals,
                                  onClaimed: _refreshData,
                                ),
                          RoundedCard(
                            margin: EdgeInsets.fromLTRB(16, 0, 16, 32),
                            padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
                            child: Column(
                              children: [
                                Container(
                                  margin: EdgeInsets.only(bottom: 24),
                                  child: Text(isOldVersion
                                      ? dic['homa.user.stats']
                                      : 'KSM/LKSM ${dicAssets['balance']}'),
                                ),
                                isOldVersion
                                    ? Visibility(
                                        visible: _unlockingKsm != null &&
                                            double.tryParse(
                                                    _unlockingKsm ?? '0') !=
                                                0,
                                        child: Column(children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                  child: Container(
                                                padding:
                                                    EdgeInsets.only(left: 50),
                                                child: Text(
                                                  dic['homa.user.unlocking'],
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w400),
                                                ),
                                              )),
                                              Expanded(
                                                  child: Row(
                                                children: [
                                                  Container(
                                                    margin: EdgeInsets.only(
                                                        right: 8),
                                                    child: TokenIcon(
                                                        stakeSymbol,
                                                        widget
                                                            .plugin.tokenIcons),
                                                  ),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Text(
                                                            '${Fmt.priceFloor(double.tryParse(_unlockingKsm ?? '0'), lengthMax: 4)}',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Theme.of(
                                                                      context)
                                                                  .unselectedWidgetColor,
                                                            ),
                                                          ),
                                                          GestureDetector(
                                                            child: Container(
                                                                margin: EdgeInsets
                                                                    .only(
                                                                        left:
                                                                            4),
                                                                child: Text(
                                                                  dic['homa.redeem.cancel'],
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        12,
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
                                                            onTap:
                                                                _onCancelRedeem,
                                                          )
                                                        ],
                                                      ),
                                                      Text(
                                                          '≈ \$${Fmt.priceFloor((widget.plugin.store.assets.marketPrices[stakeSymbol] ?? 0) * double.tryParse(_unlockingKsm ?? '0'), lengthMax: 2)}',
                                                          style: TextStyle(
                                                              fontSize: 12)),
                                                    ],
                                                  )
                                                ],
                                              ))
                                            ],
                                          ),
                                          Container(
                                            child: Divider(height: 24),
                                          )
                                        ]))
                                    : Container(),
                                isOldVersion
                                    ? Column(
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                  child: Container(
                                                padding:
                                                    EdgeInsets.only(left: 50),
                                                child: Text(
                                                  dic['homa.user.ksm'],
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w400),
                                                ),
                                              )),
                                              Expanded(
                                                  child: Row(
                                                children: [
                                                  Container(
                                                    margin: EdgeInsets.only(
                                                        right: 8),
                                                    child: TokenIcon(
                                                        stakeSymbol,
                                                        widget
                                                            .plugin.tokenIcons),
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
                                                padding:
                                                    EdgeInsets.only(left: 50),
                                                child: Text(
                                                  dic['homa.user.lksm'],
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w400),
                                                ),
                                              )),
                                              Expanded(
                                                  child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    margin: EdgeInsets.only(
                                                        right: 8),
                                                    child: TokenIcon(
                                                        'L$stakeSymbol',
                                                        widget
                                                            .plugin.tokenIcons),
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
                                      )
                                    : Row(
                                        children: [
                                          Expanded(
                                              child: Row(
                                            children: [
                                              Container(
                                                margin:
                                                    EdgeInsets.only(right: 8),
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
                                          )),
                                          Expanded(
                                              child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                margin:
                                                    EdgeInsets.only(right: 8),
                                                child: TokenIcon(
                                                    'L$stakeSymbol',
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
                                      )
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
                                      .pushNamed(RedeemPage.route, arguments: {
                                    "isHomaAlive": _isHomaAlive
                                  }).then((value) {
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

                                          Navigator.of(context).pushNamed(
                                              MintPage.route,
                                              arguments: {
                                                "isHomaAlive": _isHomaAlive
                                              }).then((value) {
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

class _HomaUserInfoCard extends StatelessWidget {
  _HomaUserInfoCard({
    this.userInfo,
    this.address,
    this.env,
    this.bestNumber,
    this.stakeTokenDecimals,
    this.onClaimed,
  });

  String address;
  HomaPendingRedeemData userInfo;
  HomaNewEnvData env;
  BigInt bestNumber;
  int stakeTokenDecimals;
  Function() onClaimed;

  Future<void> _claimRedeem(BuildContext context, num claimable) async {
    final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');
    final res = await Navigator.of(context).pushNamed(
      TxConfirmPage.route,
      arguments: TxConfirmParams(
        module: 'homa',
        call: 'claimRedemption',
        txTitle: '${dic['homa.claim']} $relay_chain_token_symbol',
        txDisplay: {},
        txDisplayBold: {
          dic['loan.amount']: Text(
            '${Fmt.priceFloor(claimable, lengthMax: 4)} $relay_chain_token_symbol',
            style: Theme.of(context).textTheme.headline1,
          ),
        },
        params: [address],
      ),
    );
    if (res != null) {
      onClaimed();
    }
  }

  void _showUnbondings(BuildContext context, List unbundings) {
    final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');
    showCupertinoModalPopup(
      context: context,
      builder: (_) {
        return CupertinoActionSheet(
          title: Text(dic['homa.unbonding']),
          message: Column(
            children: unbundings.map((e) {
              return Container(
                margin: EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${Fmt.priceFloor(e['amount'], lengthMax: 4)} $relay_chain_token_symbol',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).unselectedWidgetColor),
                    ),
                    Container(
                      padding: EdgeInsets.only(left: 16),
                      child:
                          Text('${(e['era'] - userInfo.currentRelayEra)} Eras'),
                    )
                  ],
                ),
              );
            }).toList(),
          ),
          cancelButton: CupertinoButton(
            child: Text(
                I18n.of(context).getDic(i18n_full_dic_karura, 'common')['ok']),
            onPressed: () => Navigator.of(context).pop(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');
    final redeemRequest = Fmt.balanceDouble(
        (userInfo?.redeemRequest ?? {})['amount'] ?? '0', stakeTokenDecimals);
    double unbonding = 0;
    (userInfo?.unbondings ?? []).forEach((e) {
      unbonding += e['amount'];
    });
    final claimable = (userInfo?.claimable ?? 0).toDouble();
    final labelStyle = TextStyle(fontSize: 12);
    final contentStyle = TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).unselectedWidgetColor);
    final linkStyle = TextStyle(
      fontSize: 12,
      color: Theme.of(context).primaryColor,
      fontStyle: FontStyle.italic,
      decoration: TextDecoration.underline,
    );
    return RoundedCard(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 24),
            child: Text(dic['homa.user.stats']),
          ),
          Container(
            margin: EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                InfoItem(
                  title: dic['homa.RedeemRequest'] +
                      ' (L$relay_chain_token_symbol)',
                  content: Fmt.priceFloor(redeemRequest, lengthMax: 4),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                              dic['homa.unbonding'] +
                                  ' ($relay_chain_token_symbol)',
                              style: labelStyle),
                          Visibility(
                            visible: userInfo?.unbondings != null &&
                                ((userInfo?.unbondings?.length ?? 0) > 0),
                            child: GestureDetector(
                              child: Text(
                                I18n.of(context).getDic(
                                    i18n_full_dic_karura, 'common')['detail'],
                                style: linkStyle,
                              ),
                              onTap: () => _showUnbondings(
                                  context, userInfo?.unbondings),
                            ),
                          )
                        ],
                      ),
                      Text(
                        Fmt.priceFloor(unbonding, lengthMax: 4),
                        style: contentStyle,
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                              dic['homa.claimable'] +
                                  ' ($relay_chain_token_symbol)',
                              style: labelStyle),
                          Visibility(
                            visible: claimable > 0,
                            child: GestureDetector(
                              child: Text(
                                dic['homa.claim'],
                                style: linkStyle,
                              ),
                              onTap: () => _claimRedeem(context, claimable),
                            ),
                          )
                        ],
                      ),
                      Text(
                        Fmt.priceFloor(claimable, lengthMax: 4),
                        style: contentStyle,
                      )
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
