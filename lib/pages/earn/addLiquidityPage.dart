import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/api/types/dexPoolInfoData.dart';
import 'package:polkawallet_plugin_karura/common/components/insufficientKARWarn.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/pages/swap/swapTokenInput.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/api/types/txInfoData.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/tapTooltip.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';

class AddLiquidityPage extends StatefulWidget {
  AddLiquidityPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/karura/earn/deposit';
  static const String actionDeposit = 'deposit';

  @override
  _AddLiquidityPageState createState() => _AddLiquidityPageState();
}

class _AddLiquidityPageState extends State<AddLiquidityPage> {
  final TextEditingController _amountLeftCtrl = new TextEditingController();
  final TextEditingController _amountRightCtrl = new TextEditingController();

  Timer? _timer;
  double _price = 0;
  bool _withStake = true;
  bool _withStakeAll = false;

  int _inputIndex = 0;
  BigInt? _maxInputLeft;
  BigInt? _maxInputRight;
  String? _errorLeft;
  String? _errorRight;

  TxFeeEstimateResult? _fee;

  Future<void> _refreshData() async {
    final DexPoolData? pool = ModalRoute.of(context)!.settings.arguments as DexPoolData?;

    await widget.plugin.service!.earn.updateAllDexPoolInfo();

    if (mounted) {
      final balancePair = pool!.tokens!
          .map((e) => AssetsUtils.tokenDataFromCurrencyId(widget.plugin, e))
          .toList();
      setState(() {
        final poolInfo =
            widget.plugin.store!.earn.dexPoolInfoMap[pool.tokenNameId]!;
        _price = Fmt.bigIntToDouble(
                poolInfo.amountRight, balancePair[0]!.decimals!) /
            Fmt.bigIntToDouble(poolInfo.amountLeft, balancePair[1]!.decimals!);
      });
      _timer = Timer(Duration(seconds: 30), () {
        _refreshData();
      });
    }
  }

  Future<void> _onSupplyAmountChange(String supply,
      {bool isSetMax = false}) async {
    final value = supply.trim();
    double v = 0;
    try {
      v = value.isEmpty ? 0 : double.parse(value);
    } catch (e) {}
    setState(() {
      _inputIndex = 0;
      _amountRightCtrl.text = v == 0 ? '' : (v * _price).toStringAsFixed(8);
      // clear max input on amount changes
      if (!isSetMax) {
        _maxInputLeft = null;
      }
    });
    _onValidate();
  }

  Future<void> _onTargetAmountChange(String target,
      {bool isSetMax = false}) async {
    final value = target.trim();
    double v = 0;
    try {
      v = value.isEmpty ? 0 : double.parse(value);
    } catch (e) {}
    setState(() {
      _inputIndex = 1;
      _amountLeftCtrl.text = v == 0 ? '' : (v / _price).toStringAsFixed(8);
      // clear max input on amount changes
      if (!isSetMax) {
        _maxInputRight = null;
      }
    });
    _onValidate();
  }

  String? _onValidateInput(int index) {
    if (index == 0 && _maxInputLeft != null) return null;
    if (index == 1 && _maxInputRight != null) return null;

    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'common');
    final DexPoolData pool = ModalRoute.of(context)!.settings.arguments as DexPoolData;
    final balancePair = pool.tokens!
        .map((e) => AssetsUtils.tokenDataFromCurrencyId(widget.plugin, e))
        .toList();

    final v =
        index == 0 ? _amountLeftCtrl.text.trim() : _amountRightCtrl.text.trim();
    final balance = balancePair[index];

    String? error = Fmt.validatePrice(v, context);
    if (error == null) {
      if ((index == 0 && _maxInputLeft == null) ||
          (index == 1 && _maxInputRight == null)) {
        BigInt available = Fmt.balanceInt(balance?.amount ?? '0');
        // limit user's input for tx fee if token is KAR
        if (balance!.symbol == acala_token_ids[0]) {
          final accountED = PluginFmt.getAccountED(widget.plugin);
          available -= accountED +
              Fmt.balanceInt(_fee?.partialFee?.toString()) * BigInt.two;
        }
        if (double.parse(v) > Fmt.bigIntToDouble(available, balance.decimals!)) {
          error = dic!['amount.low'];
        }
      }
    }

    // check if user's lp token balance meet existential deposit.
    final balanceLP =
        widget.plugin.store!.assets.tokenBalanceMap[pool.tokenNameId];
    final balanceInt = Fmt.balanceInt(balanceLP?.amount ?? '0');
    if (error == null && index == 0 && balanceInt == BigInt.zero) {
      double min = 0;
      final poolInfo =
          widget.plugin.store!.earn.dexPoolInfoMap[pool.tokenNameId]!;
      min = Fmt.balanceInt(balanceLP?.minBalance ?? '0') /
          poolInfo.issuance! *
          Fmt.bigIntToDouble(poolInfo.amountLeft, balancePair[0]!.decimals!);

      final inputLeft = _inputIndex == 0
          ? double.parse(_amountLeftCtrl.text.trim())
          : (double.parse(_amountRightCtrl.text.trim()) / _price);
      if (inputLeft < min) {
        error = '${dic!['amount.min']} ${Fmt.priceCeil(min, lengthMax: 6)}';
      }
    }

    return error;
  }

  bool _onValidate() {
    final errorLeft = _onValidateInput(0);
    if (errorLeft != null) {
      setState(() {
        _errorLeft = errorLeft;
        _errorRight = null;
      });
      return false;
    }
    final errorRight = _onValidateInput(1);
    if (errorRight != null) {
      setState(() {
        _errorLeft = null;
        _errorRight = errorRight;
      });
      return false;
    }
    setState(() {
      _errorLeft = null;
      _errorRight = null;
    });
    return true;
  }

  void _onSetLeftMax(BigInt max, int decimals) {
    final amount = Fmt.bigIntToDouble(max, decimals).toStringAsFixed(6);
    setState(() {
      _amountLeftCtrl.text = amount;
      _maxInputLeft = max;
      _maxInputRight = null;
    });
    _onSupplyAmountChange(amount, isSetMax: true);
  }

  void _onSetRightMax(BigInt max, int decimals) {
    final amount = Fmt.bigIntToDouble(max, decimals).toStringAsFixed(6);
    setState(() {
      _amountRightCtrl.text = amount;
      _maxInputLeft = null;
      _maxInputRight = max;
    });
    _onTargetAmountChange(amount, isSetMax: true);
  }

  Future<void> _onSubmit(int? decimalsLeft, int? decimalsRight) async {
    if (_onValidate()) {
      final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala');
      final DexPoolData pool = ModalRoute.of(context)!.settings.arguments as DexPoolData;

      final amountLeft = _amountLeftCtrl.text.trim();
      final amountRight = _amountRightCtrl.text.trim();

      final params = [
        pool.tokens![0],
        pool.tokens![1],
        _maxInputLeft != null
            ? _maxInputLeft.toString()
            : Fmt.tokenInt(amountLeft, decimalsLeft!).toString(),
        _maxInputRight != null
            ? _maxInputRight.toString()
            : Fmt.tokenInt(amountRight, decimalsRight!).toString(),
        '0',
        _withStake,
      ];

      final poolSymbol =
          AssetsUtils.getBalanceFromTokenNameId(widget.plugin, pool.tokenNameId)!
              .symbol;
      final tokenPair = pool.tokens!
          .map((e) => AssetsUtils.tokenDataFromCurrencyId(widget.plugin, e))
          .toList();
      if (_withStakeAll) {
        final balance =
            widget.plugin.store!.assets.tokenBalanceMap[pool.tokenNameId]!;
        final balanceInt = Fmt.balanceInt(balance.amount);
        final batchTxs = [
          'api.tx.dex.addLiquidity(...${jsonEncode(params)})',
          'api.tx.incentives.depositDexShare({DEXShare: ${jsonEncode(pool.tokens)}}, "$balanceInt")',
        ];
        final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
            arguments: TxConfirmParams(
              module: 'utility',
              call: 'batch',
              txTitle: I18n.of(context)!
                  .getDic(i18n_full_dic_karura, 'acala')!['earn.add'],
              txDisplay: {
                dic!['earn.pool']:
                    '${tokenPair[0]!.symbol}-${tokenPair[1]!.symbol}',
                "": dic['earn.withStake.info'],
                dic['earn.withStake.all']: '+ ' +
                    Fmt.priceFloorBigInt(balanceInt, balance.decimals!,
                        lengthMax: 4) +
                    ' LP',
              },
              txDisplayBold: {
                "Token 1": Text(
                  '$amountLeft ${tokenPair[0]!.symbol}',
                  style: Theme.of(context).textTheme.headline1,
                ),
                "Token 2": Text(
                  '$amountRight ${tokenPair[1]!.symbol}',
                  style: Theme.of(context).textTheme.headline1,
                ),
              },
              params: [],
              rawParams: '[[${batchTxs.join(',')}]]',
            ))) as Map?;
        if (res != null) {
          Navigator.of(context).pop(res);
        }
      } else {
        final txDisplay = {dic!['earn.pool']: poolSymbol};
        if (_withStake) {
          txDisplay[''] = dic['earn.withStake.info'];
        }
        final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
            arguments: TxConfirmParams(
              module: 'dex',
              call: 'addLiquidity',
              txTitle: I18n.of(context)!
                  .getDic(i18n_full_dic_karura, 'acala')!['earn.add'],
              txDisplay: txDisplay,
              txDisplayBold: {
                "Token 1": Text(
                  '$amountLeft ${tokenPair[0]!.symbol}',
                  style: Theme.of(context).textTheme.headline1,
                ),
                "Token 2": Text(
                  '$amountRight ${tokenPair[1]!.symbol}',
                  style: Theme.of(context).textTheme.headline1,
                ),
              },
              params: params,
            ))) as Map?;
        if (res != null) {
          Navigator.of(context).pop(res);
        }
      }
    }
  }

  Future<String> _getTxFee() async {
    if (_fee?.partialFee != null) {
      return _fee!.partialFee.toString();
    }

    final sender = TxSenderData(
        widget.keyring.current.address, widget.keyring.current.pubKey);
    final fee = await widget.plugin.sdk.api.tx
        .estimateFees(TxInfoData('dex', 'addLiquidity', sender), [
      {'Token': 'KAR'},
      {'Token': 'KSM'},
      '1000000000000',
      '100000000000',
      '0',
      true,
    ]);
    if (mounted) {
      setState(() {
        _fee = fee;
      });
    }
    return fee.partialFee.toString();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _refreshData();
      _getTxFee();
    });
  }

  @override
  void dispose() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }

    _amountLeftCtrl.dispose();
    _amountRightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(_) {
    return Observer(
      builder: (BuildContext context) {
        final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;

        final DexPoolData pool = ModalRoute.of(context)!.settings.arguments as DexPoolData;
        final tokenPair = pool.tokens!
            .map((e) => AssetsUtils.tokenDataFromCurrencyId(widget.plugin, e))
            .toList();
        final tokenPairView = [
          PluginFmt.tokenView(tokenPair[0]!.symbol),
          PluginFmt.tokenView(tokenPair[1]!.symbol)
        ];

        final nativeBalance = Fmt.balanceInt(
            widget.plugin.balances.native!.availableBalance.toString());
        final accountED = PluginFmt.getAccountED(widget.plugin);

        double userShare = 0;

        double amountLeft = 0;
        double amountRight = 0;

        final poolInfo =
            widget.plugin.store!.earn.dexPoolInfoMap[pool.tokenNameId];
        if (poolInfo != null) {
          amountLeft =
              Fmt.bigIntToDouble(poolInfo.amountLeft, tokenPair[0]!.decimals!);
          amountRight =
              Fmt.bigIntToDouble(poolInfo.amountRight, tokenPair[1]!.decimals!);

          String input = _amountLeftCtrl.text.trim();
          try {
            final double amountInput =
                double.parse(input.isEmpty ? '0' : input);
            userShare = amountInput / (amountInput + amountLeft);
          } catch (_) {
            // parse double failed
          }
        }

        final colorGray = Theme.of(context).unselectedWidgetColor;

        return Scaffold(
          appBar: AppBar(
            title: Text(dic['earn.add']!),
            centerTitle: true,
            leading: BackBtn(),
          ),
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(8, 16, 8, 32),
              children: <Widget>[
                RoundedCard(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Visibility(
                        visible: nativeBalance - accountED <
                            Fmt.balanceInt((_fee?.partialFee ?? 0).toString()) *
                                BigInt.two,
                        child: InsufficientKARWarn(),
                      ),
                      SwapTokenInput(
                        title: 'token 1',
                        inputCtrl: _amountLeftCtrl,
                        balance: tokenPair[0],
                        tokenIconsMap: widget.plugin.tokenIcons,
                        onInputChange: (v) => _onSupplyAmountChange(v),
                        onSetMax: tokenPair[0]!.symbol == acala_token_ids[0]
                            ? null
                            : (v) => _onSetLeftMax(v, tokenPair[0]!.decimals!),
                        onClear: () {
                          setState(() {
                            _maxInputLeft = null;
                            _amountLeftCtrl.text = '';
                          });
                        },
                      ),
                      Container(
                        margin: EdgeInsets.only(left: 16, top: 2),
                        child: _errorLeft == null
                            ? null
                            : Row(children: [
                                Text(
                                  _errorLeft!,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.red),
                                )
                              ]),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add,
                            color: Theme.of(context).primaryColor,
                          )
                        ],
                      ),
                      SwapTokenInput(
                        title: 'token 2',
                        inputCtrl: _amountRightCtrl,
                        balance: tokenPair[1],
                        tokenIconsMap: widget.plugin.tokenIcons,
                        onInputChange: (v) => _onTargetAmountChange(v),
                        onSetMax: tokenPair[1]!.symbol == acala_token_ids[0]
                            ? null
                            : (v) => _onSetRightMax(v, tokenPair[1]!.decimals!),
                        onClear: () {
                          setState(() {
                            _maxInputRight = null;
                            _amountRightCtrl.text = '';
                          });
                        },
                      ),
                      Container(
                        margin: EdgeInsets.only(left: 16, top: 2),
                        child: _errorRight == null
                            ? null
                            : Row(children: [
                                Text(
                                  _errorRight!,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.red),
                                )
                              ]),
                      ),
                      Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              dic['dex.rate']!,
                              style: TextStyle(
                                color: colorGray,
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                  '1 ${tokenPairView[0]} = ${Fmt.doubleFormat(_price, length: 6)} ${tokenPairView[1]}'),
                              Text(
                                  '1 ${tokenPairView[1]} = ${Fmt.doubleFormat(1 / _price, length: 6)} ${tokenPairView[0]}')
                            ],
                          ),
                        ],
                      ),
                      Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              dic['earn.pool']!,
                              style: TextStyle(color: colorGray),
                            ),
                          ),
                          Text(
                            '${Fmt.doubleFormat(amountLeft)} ${tokenPairView[0]}\n+ ${Fmt.doubleFormat(amountRight)} ${tokenPairView[1]}',
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              dic['earn.share']!,
                              style: TextStyle(color: colorGray),
                            ),
                          ),
                          Text(Fmt.ratio(userShare)),
                        ],
                      )
                    ],
                  ),
                ),
                RoundedCard(
                  margin: EdgeInsets.only(top: 16, bottom: 16),
                  padding: EdgeInsets.fromLTRB(8, 8, 8, 16),
                  child: StakeLPTips(
                    widget.plugin,
                    pool: pool,
                    poolSymbol: tokenPair.join('-'),
                    switchActive: _withStake,
                    switch1Active: _withStakeAll,
                    onSwitch: (v) {
                      setState(() {
                        _withStake = v;
                      });
                    },
                    onSwitch1: (v) {
                      setState(() {
                        _withStakeAll = v;
                        if (v && !_withStake) {
                          _withStake = v;
                        }
                      });
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: RoundedButton(
                    text: dic['earn.add'],
                    onPressed: () =>
                        _onSubmit(tokenPair[0]!.decimals, tokenPair[1]!.decimals),
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

class StakeLPTips extends StatelessWidget {
  StakeLPTips(this.plugin,
      {this.poolSymbol,
      this.pool,
      this.switchActive,
      this.switch1Active,
      this.onSwitch,
      this.onSwitch1});
  final PluginKarura plugin;
  final String? poolSymbol;
  final DexPoolData? pool;
  final bool? switchActive;
  final bool? switch1Active;
  final Function(bool)? onSwitch;
  final Function(bool)? onSwitch1;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala');
    final dicCommon = I18n.of(context)!.getDic(i18n_full_dic_karura, 'common');
    return Observer(builder: (_) {
      double rewardAPY = 0;
      double savingRewardAPY = 0;

      if (plugin.store!.earn.incentives.dex != null) {
        (plugin.store!.earn.incentives.dex![pool!.tokenNameId!] ?? []).forEach((e) {
          rewardAPY += e.apr;
        });
        (plugin.store!.earn.incentives.dexSaving[pool!.tokenNameId!] ?? [])
            .forEach((e) {
          savingRewardAPY += e.apr;
        });
      }
      final balanceInt = Fmt.balanceInt(
          plugin.store!.assets.tokenBalanceMap[pool!.tokenNameId]?.amount);
      final balance = Fmt.priceFloorBigInt(balanceInt,
          plugin.store!.assets.tokenBalanceMap[pool!.tokenNameId]?.decimals ?? 12,
          lengthMax: 4);
      final colorGray = Theme.of(context).unselectedWidgetColor;
      return Column(
        children: [
          Row(
            mainAxisAlignment: balanceInt > BigInt.zero
                ? MainAxisAlignment.spaceAround
                : MainAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TapTooltip(
                    message: dic!['earn.withStake.txt']!,
                    child: Row(
                      children: [
                        Icon(Icons.info, color: colorGray, size: 16),
                        Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text(dic['earn.withStake']!),
                        ),
                      ],
                    ),
                  ),
                  CupertinoSwitch(
                    value: switchActive!,
                    onChanged: onSwitch,
                  ),
                ],
              ),
              Visibility(
                  visible: balanceInt > BigInt.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TapTooltip(
                        message:
                            '\n${dic['earn.withStake.all.txt']}\n(${dicCommon!['balance']}: $balance ${PluginFmt.tokenView(poolSymbol)})\n',
                        child: Row(
                          children: [
                            Icon(Icons.info, color: colorGray, size: 16),
                            Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Text(dic['earn.withStake.all']!),
                            ),
                          ],
                        ),
                      ),
                      CupertinoSwitch(
                        value: switch1Active ?? false,
                        onChanged: onSwitch1,
                      ),
                    ],
                  )),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: 16, bottom: 8),
            child: Text(dic['earn.withStake.info']!,
                style: TextStyle(fontSize: 12)),
          ),
          Text(
            '${dic['earn.apy']}: ${Fmt.ratio(rewardAPY + savingRewardAPY)}',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
        ],
      );
    });
  }
}
