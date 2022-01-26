import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/api/types/dexPoolInfoData.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/infoItem.dart';
import 'package:polkawallet_ui/components/outlinedButtonSmall.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/tapTooltip.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class WithdrawLiquidityPage extends StatefulWidget {
  WithdrawLiquidityPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/karura/earn/withdraw';

  @override
  _WithdrawLiquidityPageState createState() => _WithdrawLiquidityPageState();
}

class _WithdrawLiquidityPageState extends State<WithdrawLiquidityPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountCtrl = new TextEditingController();

  Timer? _timer;

  bool _fromPool = false;

  DEXPoolInfo? _getPoolInfoData(String? poolId) {
    final poolInfo = widget.plugin.store!.earn.dexPoolInfoMap[poolId];
    return poolInfo != null
        ? DEXPoolInfo(poolInfo.shares, poolInfo.issuance, poolInfo.amountLeft,
            poolInfo.amountRight)
        : null;
  }

  Future<void> _refreshData() async {
    await widget.plugin.service!.earn.queryDexPoolInfo();
    if (mounted) {
      _timer = Timer(Duration(seconds: 30), () {
        if (mounted) {
          _refreshData();
        }
      });
    }
  }

  void _onAmountSelect(BigInt v, int? decimals, {bool isMax = false}) {
    setState(() {
      _amountCtrl.text =
          Fmt.bigIntToDouble(v, decimals!).toStringAsFixed(decimals);
    });
    _formKey.currentState!.validate();
  }

  String? _validateInput(String? value) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'common');

    final v = value!.trim();
    final error = Fmt.validatePrice(v, context);
    if (error != null) {
      return error;
    }

    final symbols = widget.plugin.networkState.tokenSymbol;
    final DexPoolData pool =
        ModalRoute.of(context)!.settings.arguments as DexPoolData;
    final balancePair = pool.tokens!
        .map((e) => AssetsUtils.tokenDataFromCurrencyId(widget.plugin, e))
        .toList();

    final poolInfo = _getPoolInfoData(pool.tokenNameId);

    final shareInputInt = Fmt.tokenInt(v, balancePair[0]!.decimals!);
    final shareFree = Fmt.balanceInt(
        widget.plugin.store!.assets.tokenBalanceMap[pool.tokenNameId]?.amount);
    final shareBalance = _fromPool ? shareFree + poolInfo!.shares! : shareFree;
    if (shareInputInt > shareBalance) {
      return dic!['amount.low'];
    }

    final shareInput = double.parse(v.trim());
    double min = 0;
    if (balancePair[0]!.symbol != symbols![0] &&
        Fmt.balanceInt(balancePair[0]!.amount) == BigInt.zero) {
      min = Fmt.balanceInt(balancePair[0]!.minBalance) /
          poolInfo!.amountLeft! *
          Fmt.bigIntToDouble(poolInfo.issuance, balancePair[0]!.decimals!);
    }
    if (balancePair[0]!.symbol != symbols[0] &&
        Fmt.balanceInt(balancePair[1]!.amount) == BigInt.zero) {
      final min2 = Fmt.balanceInt(balancePair[1]!.minBalance) /
          poolInfo!.amountRight! *
          Fmt.bigIntToDouble(poolInfo.issuance, balancePair[0]!.decimals!);
      min = min > min2 ? min : min2;
    }
    if (shareInput < min) {
      return '${dic!['amount.min']} ${Fmt.priceCeil(min, lengthMax: 6)}';
    }
    return null;
  }

  List _getTxParams(BigInt amount, bool fromPool) {
    final DexPoolData pool =
        ModalRoute.of(context)!.settings.arguments as DexPoolData;
    return [
      pool.tokens![0],
      pool.tokens![1],
      amount.toString(),
      '0',
      '0',
      fromPool,
    ];
  }

  Future<void> _onSubmit(int? shareDecimals) async {
    if (_formKey.currentState!.validate()) {
      final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
      final DexPoolData pool =
          ModalRoute.of(context)!.settings.arguments as DexPoolData;

      final tokenPair = pool.tokens!
          .map((e) => AssetsUtils.tokenDataFromCurrencyId(widget.plugin, e))
          .toList();
      final poolTokenSymbol = tokenPair
          .map((e) => PluginFmt.tokenView(e?.symbol))
          .toList()
          .join('-');

      final amount = _amountCtrl.text.trim();
      final amountInt = Fmt.tokenInt(amount, shareDecimals!);

      final poolToken = AssetsUtils.getBalanceFromTokenNameId(
          widget.plugin, pool.tokenNameId);
      final free = Fmt.balanceInt(poolToken?.amount);

      TxConfirmParams txParams = TxConfirmParams(
        module: 'dex',
        call: 'removeLiquidity',
        txTitle: I18n.of(context)!
            .getDic(i18n_full_dic_karura, 'acala')!['earn.remove'],
        txDisplay: {dic['earn.pool']: poolTokenSymbol},
        txDisplayBold: {
          dic['loan.amount']!: Text(
            '$amount LP',
            style: Theme.of(context).textTheme.headline1,
          ),
        },
        params: _getTxParams(amountInt, false),
      );
      if (_fromPool && amountInt > free) {
        if (free == BigInt.zero) {
          txParams = TxConfirmParams(
            module: 'dex',
            call: 'removeLiquidity',
            txTitle: I18n.of(context)!
                .getDic(i18n_full_dic_karura, 'acala')!['earn.remove'],
            txDisplay: {
              dic['earn.pool']: poolTokenSymbol,
              "": dic['earn.fromPool'],
            },
            txDisplayBold: {
              dic['loan.amount']!: Text(
                '$amount LP',
                style: Theme.of(context).textTheme.headline1,
              ),
            },
            params: _getTxParams(amountInt, true),
          );
        } else {
          final batchTxs = [
            'api.tx.dex.removeLiquidity(...${jsonEncode(_getTxParams(free, false))})',
            'api.tx.dex.removeLiquidity(...${jsonEncode(_getTxParams(amountInt - free, true))})',
          ];
          txParams = TxConfirmParams(
            module: 'utility',
            call: 'batch',
            txTitle: I18n.of(context)!
                .getDic(i18n_full_dic_karura, 'acala')!['earn.remove'],
            txDisplay: {
              dic['earn.pool']: poolTokenSymbol,
              "": dic['earn.fromPool'],
            },
            txDisplayBold: {
              dic['loan.amount']!: Text(
                '$amount LP',
                style: Theme.of(context).textTheme.headline1,
              ),
            },
            params: [],
            rawParams: '[[${batchTxs.join(',')}]]',
          );
        }
      }

      final res = (await Navigator.of(context)
          .pushNamed(TxConfirmPage.route, arguments: txParams)) as Map?;
      if (res != null) {
        Navigator.of(context).pop(res);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  @override
  void dispose() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }

    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(_) {
    return Observer(
      builder: (BuildContext context) {
        final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
        final dicAssets =
            I18n.of(context)!.getDic(i18n_full_dic_karura, 'common')!;

        final DexPoolData pool =
            ModalRoute.of(context)!.settings.arguments as DexPoolData;

        final poolToken = AssetsUtils.getBalanceFromTokenNameId(
            widget.plugin, pool.tokenNameId);
        final balancePair = pool.tokens!
            .map((e) => AssetsUtils.tokenDataFromCurrencyId(widget.plugin, e))
            .toList();
        final pairView =
            balancePair.map((e) => PluginFmt.tokenView(e!.symbol)).toList();

        double shareInput = 0;
        BigInt shareInputInt = BigInt.zero;
        try {
          shareInput = double.parse(_amountCtrl.text.trim());
          shareInputInt =
              Fmt.tokenInt(_amountCtrl.text.trim(), balancePair[0]!.decimals!);
        } catch (_) {}

        double shareIssuance = 0;
        BigInt shareFreeInt = BigInt.zero;
        BigInt? shareStakedInt = BigInt.zero;
        BigInt shareFromInt = BigInt.zero;
        BigInt shareInt10 = BigInt.zero;
        BigInt shareInt25 = BigInt.zero;
        BigInt shareInt50 = BigInt.zero;

        double poolLeft = 0;
        double poolRight = 0;
        double exchangeRate = 1;
        double amountLeft = 0;
        double amountRight = 0;

        final poolInfo = _getPoolInfoData(pool.tokenNameId);
        if (poolInfo != null) {
          shareFreeInt = Fmt.balanceInt(poolToken?.amount);
          shareStakedInt = poolInfo.shares;
          shareFromInt =
              _fromPool ? shareFreeInt + shareStakedInt! : shareFreeInt;
          shareIssuance =
              Fmt.bigIntToDouble(poolInfo.issuance, balancePair[0]!.decimals!);

          poolLeft = Fmt.bigIntToDouble(
              poolInfo.amountLeft, balancePair[0]!.decimals!);
          poolRight = Fmt.bigIntToDouble(
              poolInfo.amountRight, balancePair[1]!.decimals!);
          exchangeRate = poolLeft / poolRight;

          shareInt10 = BigInt.from(shareFromInt / BigInt.from(10));
          shareInt25 = BigInt.from(shareFromInt / BigInt.from(4));
          shareInt50 = BigInt.from(shareFromInt / BigInt.from(2));

          amountLeft = poolLeft * shareInput / shareIssuance;
          amountRight = poolRight * shareInput / shareIssuance;
        }

        final shareEmpty = shareFromInt == BigInt.zero;

        return Scaffold(
          appBar: AppBar(
            title: Text(dic['earn.remove']!),
            centerTitle: true,
            leading: BackBtn(),
          ),
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: <Widget>[
                Visibility(
                    visible: (poolInfo?.shares ?? BigInt.zero) > BigInt.zero,
                    child: RoundedCard(
                      padding: EdgeInsets.fromLTRB(8, 16, 8, 8),
                      child: Column(
                        children: [
                          Container(
                            margin: EdgeInsets.only(bottom: 8),
                            child: Text(
                                '${pairView.join('-')} ${dicAssets['balance']}'),
                          ),
                          Container(
                            margin: EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                InfoItem(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  title: dicAssets['amount.all'],
                                  content: Fmt.priceFloorBigInt(
                                      shareFreeInt + shareStakedInt!,
                                      balancePair[0]!.decimals!),
                                ),
                                InfoItem(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  title: dicAssets['amount.staked'],
                                  content: Fmt.priceFloorBigInt(shareStakedInt,
                                      balancePair[0]!.decimals!),
                                ),
                                InfoItem(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  title: dicAssets['amount.free'],
                                  content: Fmt.priceFloorBigInt(
                                      shareFreeInt, balancePair[0]!.decimals!),
                                )
                              ],
                            ),
                          ),
                          Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TapTooltip(
                                message: '${dic['earn.fromPool.txt']}\n',
                                child: Row(
                                  children: [
                                    Icon(Icons.info,
                                        color: Theme.of(context)
                                            .unselectedWidgetColor,
                                        size: 16),
                                    Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Text(dic['earn.fromPool']!),
                                    ),
                                  ],
                                ),
                              ),
                              CupertinoSwitch(
                                value: _fromPool,
                                onChanged: (res) {
                                  setState(() {
                                    _fromPool = res;
                                  });
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                    )),
                RoundedCard(
                  margin: EdgeInsets.only(top: 16),
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: TextFormField(
                          decoration: InputDecoration(
                            hintText: dicAssets['amount'],
                            labelText:
                                '${dicAssets['amount']} (${dic['earn.available']}: ${Fmt.priceFloorBigInt(shareFromInt, balancePair[0]!.decimals!, lengthMax: 4)} Shares)',
                            suffix: GestureDetector(
                              child: Icon(
                                CupertinoIcons.clear_thick_circled,
                                color: Theme.of(context).disabledColor,
                                size: 18,
                              ),
                              onTap: () {
                                WidgetsBinding.instance!.addPostFrameCallback(
                                    (_) => _amountCtrl.clear());
                              },
                            ),
                          ),
                          inputFormatters: [
                            UI.decimalInputFormatter(balancePair[0]!.decimals!)!
                          ],
                          controller: _amountCtrl,
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          validator: _validateInput,
                          onChanged: (v) {
                            setState(() {});
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            OutlinedButtonSmall(
                              content: '10%',
                              active:
                                  !shareEmpty && shareInputInt == shareInt10,
                              onPressed: shareEmpty
                                  ? null
                                  : () => _onAmountSelect(
                                      shareInt10, balancePair[0]!.decimals),
                            ),
                            OutlinedButtonSmall(
                              content: '25%',
                              active:
                                  !shareEmpty && shareInputInt == shareInt25,
                              onPressed: shareEmpty
                                  ? null
                                  : () => _onAmountSelect(
                                      shareInt25, balancePair[0]!.decimals),
                            ),
                            OutlinedButtonSmall(
                              content: '50%',
                              active:
                                  !shareEmpty && shareInputInt == shareInt50,
                              onPressed: shareEmpty
                                  ? null
                                  : () => _onAmountSelect(
                                      shareInt50, balancePair[0]!.decimals),
                            ),
                            OutlinedButtonSmall(
                              margin: EdgeInsets.only(right: 0),
                              content: '100%',
                              active:
                                  !shareEmpty && shareInputInt == shareFromInt,
                              onPressed: shareEmpty
                                  ? null
                                  : () => _onAmountSelect(
                                      shareFromInt, balancePair[0]!.decimals,
                                      isMax: true),
                            )
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '= ${Fmt.doubleFormat(amountLeft)} ${pairView[0]} + ${Fmt.doubleFormat(amountRight)} ${pairView[1]}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).unselectedWidgetColor,
                                wordSpacing: -4,
                              ),
                            )
                          ],
                        ),
                      ),
                      Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              dic['dex.rate']!,
                              style: TextStyle(
                                color: Theme.of(context).unselectedWidgetColor,
                              ),
                            ),
                          ),
                          Column(children: [
                            Text(
                                '1 ${pairView[0]} = ${Fmt.doubleFormat(1 / exchangeRate)} ${pairView[1]}'),
                            Text(
                                '1 ${pairView[1]} = ${Fmt.doubleFormat(exchangeRate)} ${pairView[0]}'),
                          ])
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: RoundedButton(
                    text: dic['earn.remove'],
                    onPressed: () => _onSubmit(balancePair[0]!.decimals),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

class DEXPoolInfo {
  DEXPoolInfo(this.shares, this.issuance, this.amountLeft, this.amountRight);

  final BigInt? shares;
  final BigInt? issuance;
  final BigInt? amountLeft;
  final BigInt? amountRight;
}
