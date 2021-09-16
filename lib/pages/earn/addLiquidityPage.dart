import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/pages/swap/swapTokenInput.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_plugin_karura/utils/uiUtils.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/tapTooltip.dart';
import 'package:polkawallet_ui/components/txButton.dart';
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

  final _leftFocusNode = FocusNode();
  final _rightFocusNode = FocusNode();

  Timer _timer;
  double _price = 0;
  bool _withStake = false;
  bool _withStakeAll = false;

  int _inputIndex = 0;
  BigInt _maxInputLeft;
  BigInt _maxInputRight;
  String _errorLeft;
  String _errorRight;

  Future<void> _refreshData() async {
    final String poolId = ModalRoute.of(context).settings.arguments;

    final runtimeVersion =
        widget.plugin.networkConst['system']['version']['specVersion'];
    if (runtimeVersion > 1009) {
      await widget.plugin.service.earn.updateAllDexPoolInfo();
    } else {
      await widget.plugin.service.earn.updateDexPoolInfo(poolId: poolId);
    }

    if (mounted) {
      final tokenPair = poolId.toUpperCase().split('-');
      final balancePair = PluginFmt.getBalancePair(widget.plugin, tokenPair);
      setState(() {
        if (runtimeVersion > 1009) {
          final poolInfo = widget.plugin.store.earn.dexPoolInfoMapV2[poolId];
          _price = Fmt.bigIntToDouble(
                  poolInfo.amountRight, balancePair[0].decimals) /
              Fmt.bigIntToDouble(poolInfo.amountLeft, balancePair[1].decimals);
        } else {
          final poolInfo = widget.plugin.store.earn.dexPoolInfoMap[poolId];
          _price = Fmt.bigIntToDouble(
                  poolInfo.amountRight, balancePair[0].decimals) /
              Fmt.bigIntToDouble(poolInfo.amountLeft, balancePair[1].decimals);
        }
      });
      _timer = Timer(Duration(seconds: 10), () {
        _refreshData();
      });
    }
  }

  Future<void> _onSupplyAmountChange(String supply) async {
    final value = supply.trim();
    double v = 0;
    try {
      v = value.isEmpty ? 0 : double.parse(value);
    } catch (e) {}
    setState(() {
      _inputIndex = 0;
      _amountRightCtrl.text = v == 0 ? '' : (v * _price).toStringAsFixed(8);
    });
    _onValidate();
  }

  Future<void> _onTargetAmountChange(String target) async {
    final value = target.trim();
    double v = 0;
    try {
      v = value.isEmpty ? 0 : double.parse(value);
    } catch (e) {}
    setState(() {
      _inputIndex = 1;
      _amountLeftCtrl.text = v == 0 ? '' : (v / _price).toStringAsFixed(8);
    });
    _onValidate();
  }

  String _onValidateInput(int index) {
    if (index == 0 && _maxInputLeft != null) return null;
    if (index == 1 && _maxInputRight != null) return null;

    final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'common');
    final String poolId = ModalRoute.of(context).settings.arguments;
    final tokenPair = poolId.toUpperCase().split('-');
    final balancePair = PluginFmt.getBalancePair(widget.plugin, tokenPair);

    final v =
        index == 0 ? _amountLeftCtrl.text.trim() : _amountRightCtrl.text.trim();
    final balance = balancePair[index];

    String error;
    try {
      if (v.isEmpty || double.parse(v) == 0) {
        error = dic['amount.error'];
      }
    } catch (err) {
      error = dic['amount.error'];
    }
    if (error == null) {
      if ((index == 0 && _maxInputLeft == null) ||
          (index == 1 && _maxInputRight == null)) {
        if (double.parse(v) >
            Fmt.bigIntToDouble(
                Fmt.balanceInt(balance?.amount ?? '0'), balance.decimals)) {
          error = dic['amount.low'];
        }
      }
    }

    // check if user's lp token balance meet existential deposit.
    final balanceLP = Fmt.balanceInt(widget
        .plugin.store.assets.tokenBalanceMap[poolId.toUpperCase()]?.amount);
    if (error == null && index == 0 && balanceLP == BigInt.zero) {
      double min = 0;
      final runtimeVersion =
          widget.plugin.networkConst['system']['version']['specVersion'];
      if (runtimeVersion > 1009) {
        final poolInfo = widget.plugin.store.earn.dexPoolInfoMapV2[poolId];
        min = Fmt.balanceInt(tokenPair[0] ==
                    widget.plugin.networkState.tokenSymbol[0]
                ? widget.plugin.networkConst['balances']['existentialDeposit']
                : existential_deposit[balance.id]) /
            poolInfo.issuance *
            Fmt.bigIntToDouble(poolInfo.amountLeft, balancePair[0].decimals);
      } else {
        final poolInfo = widget.plugin.store.earn.dexPoolInfoMap[poolId];
        min = Fmt.balanceInt(tokenPair[0] ==
                    widget.plugin.networkState.tokenSymbol[0]
                ? widget.plugin.networkConst['balances']['existentialDeposit']
                : existential_deposit[balance.id]) /
            poolInfo.issuance *
            Fmt.bigIntToDouble(poolInfo.amountLeft, balancePair[0].decimals);
      }

      final inputLeft = _inputIndex == 0
          ? double.parse(_amountLeftCtrl.text.trim())
          : (double.parse(_amountRightCtrl.text.trim()) / _price);
      if (inputLeft < min) {
        error = '${dic['amount.min']} ${Fmt.priceCeil(min, lengthMax: 6)}';
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
    _onSupplyAmountChange(amount);
  }

  void _onSetRightMax(BigInt max, int decimals) {
    final amount = Fmt.bigIntToDouble(max, decimals).toStringAsFixed(6);
    setState(() {
      _amountRightCtrl.text = amount;
      _maxInputLeft = null;
      _maxInputRight = max;
    });
    _onTargetAmountChange(amount);
  }

  Future<void> _onSubmit(int decimalsLeft, int decimalsRight) async {
    if (_onValidate()) {
      try {
        if (widget.plugin.store.setting.liveModules['loan']['actionsDisabled']
                [action_swap_add_lp] ??
            false) {
          UIUtils.showInvalidActionAlert(context, action_swap_add_lp);
          return;
        }
      } catch (err) {
        // ignore
      }

      final String poolId = ModalRoute.of(context).settings.arguments;
      final pair = poolId.toUpperCase().split('-');

      final amountLeft = _amountLeftCtrl.text.trim();
      final amountRight = _amountRightCtrl.text.trim();

      final params = [
        {'Token': pair[0]},
        {'Token': pair[1]},
        Fmt.tokenInt(amountLeft, decimalsLeft).toString(),
        Fmt.tokenInt(amountRight, decimalsRight).toString(),
        '0',
        _withStake,
      ];

      if (_withStakeAll) {
        final pool = poolId.split('-').map((e) => ({'Token': e})).toList();
        final balance = widget.plugin.store.assets.tokenBalanceMap[poolId];
        final balanceInt = Fmt.balanceInt(balance.amount);
        final batchTxs = [
          'api.tx.dex.addLiquidity(...${jsonEncode(params)})',
          'api.tx.incentives.depositDexShare({DEXShare: ${jsonEncode(pool)}}, "$balanceInt")',
        ];
        final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
            arguments: TxConfirmParams(
              module: 'utility',
              call: 'batch',
              txTitle: I18n.of(context)
                  .getDic(i18n_full_dic_karura, 'acala')['earn.add'],
              txDisplay: {
                "poolId": poolId,
                "amount": [amountLeft, amountRight],
                "withStake": _withStake,
                "stakeAll": '+ ' +
                    Fmt.priceFloorBigInt(balanceInt, balance.decimals,
                        lengthMax: 4) +
                    ' LP',
              },
              params: [],
              rawParams: '[[${batchTxs.join(',')}]]',
            ))) as Map;
        if (res != null) {
          Navigator.of(context).pop(res);
        }
      } else {
        final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
            arguments: TxConfirmParams(
              module: 'dex',
              call: 'addLiquidity',
              txTitle: I18n.of(context)
                  .getDic(i18n_full_dic_karura, 'acala')['earn.add'],
              txDisplay: {
                "poolId": poolId,
                "amount": [amountLeft, amountRight],
                "withStake": _withStake,
              },
              params: params,
            ))) as Map;
        if (res != null) {
          Navigator.of(context).pop(res);
        }
      }
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

    _amountLeftCtrl.dispose();
    _amountRightCtrl.dispose();
    _leftFocusNode.dispose();
    _rightFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(_) {
    return Observer(
      builder: (BuildContext context) {
        final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');

        final String poolId = ModalRoute.of(context).settings.arguments;
        final tokenPair = poolId.toUpperCase().split('-');
        final tokenPairView = [
          PluginFmt.tokenView(tokenPair[0]),
          PluginFmt.tokenView(tokenPair[1])
        ];

        final balancePair = PluginFmt.getBalancePair(widget.plugin, tokenPair);

        double userShare = 0;

        double amountLeft = 0;
        double amountRight = 0;

        final runtimeVersion =
            widget.plugin.networkConst['system']['version']['specVersion'];
        if (runtimeVersion > 1009) {
          final poolInfo = widget.plugin.store.earn.dexPoolInfoMapV2[poolId];
          if (poolInfo != null) {
            amountLeft = Fmt.bigIntToDouble(
                poolInfo.amountLeft, balancePair[0].decimals);
            amountRight = Fmt.bigIntToDouble(
                poolInfo.amountRight, balancePair[1].decimals);

            String input = _amountLeftCtrl.text.trim();
            try {
              final double amountInput =
                  double.parse(input.isEmpty ? '0' : input);
              userShare = amountInput / (amountInput + amountLeft);
            } catch (_) {
              // parse double failed
            }
          }
        } else {
          final poolInfo = widget.plugin.store.earn.dexPoolInfoMap[poolId];
          if (poolInfo != null) {
            amountLeft = Fmt.bigIntToDouble(
                poolInfo.amountLeft, balancePair[0].decimals);
            amountRight = Fmt.bigIntToDouble(
                poolInfo.amountRight, balancePair[1].decimals);

            String input = _amountLeftCtrl.text.trim();
            try {
              final double amountInput =
                  double.parse(input.isEmpty ? '0' : input);
              userShare = amountInput / (amountInput + amountLeft);
            } catch (_) {
              // parse double failed
            }
          }
        }

        final colorGray = Theme.of(context).unselectedWidgetColor;

        return Scaffold(
          appBar: AppBar(title: Text(dic['earn.add']), centerTitle: true),
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(8, 16, 8, 32),
              children: <Widget>[
                RoundedCard(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SwapTokenInput(
                        title: 'token 1',
                        inputCtrl: _amountLeftCtrl,
                        focusNode: _leftFocusNode,
                        balance: balancePair[0],
                        tokenIconsMap: widget.plugin.tokenIcons,
                        onInputChange: _onSupplyAmountChange,
                        onSetMax: (v) =>
                            _onSetLeftMax(v, balancePair[0].decimals),
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
                                  _errorLeft,
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
                        focusNode: _rightFocusNode,
                        balance: balancePair[1],
                        tokenIconsMap: widget.plugin.tokenIcons,
                        onInputChange: _onTargetAmountChange,
                        onSetMax: (v) =>
                            _onSetRightMax(v, balancePair[1].decimals),
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
                                  _errorRight,
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
                              dic['dex.rate'],
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
                              dic['earn.pool'],
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
                              dic['earn.share'],
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
                    poolId: poolId,
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
                    onPressed: () => _onSubmit(
                        balancePair[0].decimals, balancePair[1].decimals),
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
      {this.poolId,
      this.switchActive,
      this.switch1Active,
      this.onSwitch,
      this.onSwitch1});
  final PluginKarura plugin;
  final String poolId;
  final bool switchActive;
  final bool switch1Active;
  final Function(bool) onSwitch;
  final Function(bool) onSwitch1;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');
    final dicCommon = I18n.of(context).getDic(i18n_full_dic_karura, 'common');
    return Observer(builder: (_) {
      double rewardAPY = plugin.store.earn.swapPoolRewards[poolId] ?? 0;
      double savingRewardAPY =
          plugin.store.earn.swapPoolSavingRewards[poolId] ?? 0;

      final runtimeVersion =
          plugin.networkConst['system']['version']['specVersion'];
      if (runtimeVersion > 1009 && plugin.store.earn.incentives.dex != null) {
        (plugin.store.earn.incentives.dex[poolId] ?? []).forEach((e) {
          rewardAPY += e.apr;
        });
        (plugin.store.earn.incentives.dexSaving[poolId] ?? []).forEach((e) {
          savingRewardAPY += e.apr;
        });
      }
      final balanceInt =
          Fmt.balanceInt(plugin.store.assets.tokenBalanceMap[poolId].amount);
      final balance = Fmt.priceFloorBigInt(
          balanceInt, plugin.store.assets.tokenBalanceMap[poolId].decimals,
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
                    message: dic['earn.withStake.txt'],
                    child: Row(
                      children: [
                        Icon(Icons.info, color: colorGray, size: 16),
                        Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text(dic['earn.withStake']),
                        ),
                      ],
                    ),
                  ),
                  CupertinoSwitch(
                    value: switchActive,
                    onChanged: onSwitch,
                  ),
                ],
              ),
              balanceInt > BigInt.zero
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TapTooltip(
                          message:
                              '\n${dic['earn.withStake.all.txt']}\n(${dicCommon['balance']}: $balance ${PluginFmt.tokenView(poolId)})\n',
                          child: Row(
                            children: [
                              Icon(Icons.info, color: colorGray, size: 16),
                              Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Text(dic['earn.withStake.all']),
                              ),
                            ],
                          ),
                        ),
                        CupertinoSwitch(
                          value: switch1Active,
                          onChanged: onSwitch1,
                        ),
                      ],
                    )
                  : Container(),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: 16, bottom: 8),
            child: Text(dic['earn.withStake.info'],
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
