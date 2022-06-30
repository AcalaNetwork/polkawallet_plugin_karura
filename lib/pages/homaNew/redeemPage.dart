import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/api/types/calcHomaRedeemAmount.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/pages/swapNew/bootstrapPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginInputBalance.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginLoadingWidget.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTextTag.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class RedeemPage extends StatefulWidget {
  RedeemPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/karura/homa/redeem';

  @override
  _RedeemPageState createState() => _RedeemPageState();
}

class _RedeemPageState extends State<RedeemPage> {
  final TextEditingController _amountPayCtrl = new TextEditingController();

  String? _error;
  BigInt? _maxInput;

  CalcHomaRedeemAmount? _data;
  num _receiveAmount = 0;
  num _fastReceiveAmount = 0;
  num _swapAmount = 0;

  List<String>? symbols;
  final stakeToken = relay_chain_token_symbol;
  List<int>? decimals;

  late double karBalance;

  late int stakeDecimal;

  late double minRedeem;

  Timer? _timer;

  bool isLoading = false;

  num _selectIndex = 0;

  @override
  void initState() {
    super.initState();

    symbols = widget.plugin.networkState.tokenSymbol;
    decimals = widget.plugin.networkState.tokenDecimals;

    karBalance = Fmt.balanceDouble(
        widget.plugin.balances.native?.availableBalance.toString() ?? "",
        decimals![symbols!.indexOf("L$stakeToken")]);

    stakeDecimal = decimals![symbols!.indexOf("L$stakeToken")];

    minRedeem = widget.plugin.store!.homa.env?.redeemThreshold ?? 0;
  }

  Future<void> _updateReceiveAmount(double? input) async {
    if (mounted && input != null) {
      setState(() {
        isLoading = true;
      });

      final data = await Future.wait([
        widget.plugin.api!.homa.calcHomaNewRedeemAmount(input, true),
        widget.plugin.api!.homa.calcHomaNewRedeemAmount(input, false),
      ]);

      setState(() {
        _fastReceiveAmount =
            data[0]!['canTryFastRedeem'] ? data[0]!['receive'] : 0;
        _receiveAmount = data[1]!['receive'];
        if (data[0]!['receive'] == 0) {
          _selectIndex = 1;
        }
      });

      final lToken =
          AssetsUtils.getBalanceFromTokenNameId(widget.plugin, 'L$stakeToken');
      final token =
          AssetsUtils.getBalanceFromTokenNameId(widget.plugin, stakeToken);
      final swapRes = await widget.plugin.api!.swap.queryTokenSwapAmount(
          input.toString(),
          null,
          [
            lToken.tokenNameId!,
            token.tokenNameId!,
          ],
          '0.1');
      setState(() {
        _swapAmount = swapRes.amount!;
        isLoading = false;
      });
    }
  }

  void _onSupplyAmountChange(String v, BigInt max) {
    final supply = v.trim();
    setState(() {
      _maxInput = null;
    });

    final error = _validateInput(supply, max);
    setState(() {
      _error = error;
      if (error != null) {
        _data = null;
      }
    });

    if (error != null) {
      return;
    }
    _updateReceiveAmount(double.tryParse(supply));
  }

  String? _validateInput(String supply, BigInt? max) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'common');
    final error = Fmt.validatePrice(supply, context);
    if (error != null) {
      return error;
    }

    final pay = double.parse(supply);
    if (_maxInput == null &&
        Fmt.tokenInt(supply,
                decimals![symbols!.indexOf('L$relay_chain_token_symbol')]) >
            max!) {
      return dic!['amount.low'];
    }

    if (pay < minRedeem) {
      final minLabel = I18n.of(context)!
          .getDic(i18n_full_dic_karura, 'acala')!['homa.pool.redeem'];
      return '$minLabel   ${minRedeem.toStringAsFixed(4)}';
    }

    return error;
  }

  void _onSetMax(BigInt? max) {
    final amount = Fmt.bigIntToDouble(max, stakeDecimal);
    setState(() {
      _amountPayCtrl.text = amount.toStringAsFixed(6);
      _maxInput = max;
      _error = _validateInput(amount.toString(), max);
    });

    if (_error == null) {
      _updateReceiveAmount(amount);
    }
  }

  BigInt _getMaxAmount() {
    final pendingRedeemReq = Fmt.balanceInt(
        (widget.plugin.store!.homa.userInfo?.redeemRequest ?? {})['amount'] ??
            '0');
    final lTokenBalance =
        widget.plugin.store!.assets.tokenBalanceMap["L$stakeToken"]!;
    return Fmt.balanceInt(lTokenBalance.amount) + pendingRedeemReq;
  }

  Future<void> _onSubmit() async {
    if (_fastReceiveAmount == 0 && _selectIndex == 0) {
      return;
    }
    final pay = _amountPayCtrl.text.trim();

    if (_error != null || pay.isEmpty || (_data == null && _receiveAmount == 0))
      return;

    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;

    final txDisplay = {
      dic['dex.pay']!: Text(
        '$pay L$stakeToken',
        style: Theme.of(context)
            .textTheme
            .headline1
            ?.copyWith(color: Colors.white),
      ),
      dic['dex.receive']!: Text(
        '≈ ${Fmt.priceFloor((_selectIndex == 0 ? _fastReceiveAmount : _selectIndex == 1 ? _swapAmount : _receiveAmount) as double?)} $stakeToken',
        style: Theme.of(context)
            .textTheme
            .headline1
            ?.copyWith(color: Colors.white),
      ),
    };

    String module = 'homa';
    String call = 'requestRedeem';
    List params = [
      (_maxInput ?? Fmt.tokenInt(pay, stakeDecimal)).toString(),
      false,
    ];
    String? paramsRaw;
    if (_selectIndex == 0 && _fastReceiveAmount > 0) {
      //fast redeem
      module = 'utility';
      call = 'batchAll';
      params = [
        (_maxInput ?? Fmt.tokenInt(pay, stakeDecimal)).toString(),
        true,
      ];
      paramsRaw = '[['
          'api.tx.homa.requestRedeem(...${jsonEncode(params)}),'
          'api.tx.homa.fastMatchRedeemsCompletely(["${widget.keyring.current.address}"])'
          ']]';
      params = [];
    } else if (_selectIndex == 1) {
      // swap
      final pendingRedeemReq = Fmt.balanceInt(
          (widget.plugin.store!.homa.userInfo?.redeemRequest ?? {})['amount'] ??
              '0');
      if (pendingRedeemReq > BigInt.zero) {
        module = 'utility';
        call = 'batch';
        params = [];
        paramsRaw = '[['
            'api.tx.homa.requestRedeem(...${jsonEncode([0, false])}),'
            'api.tx.dex.swapWithExactSupply(...${jsonEncode([
              [
                {'Token': 'L$stakeToken'},
                {'Token': stakeToken}
              ],
              (_maxInput ?? Fmt.tokenInt(pay, stakeDecimal)).toString(),
              "0",
            ])})'
            ']]';
      } else {
        module = 'dex';
        call = 'swapWithExactSupply';
        params = [
          [
            {'Token': 'L$stakeToken'},
            {'Token': stakeToken}
          ],
          (_maxInput ?? Fmt.tokenInt(pay, stakeDecimal)).toString(),
          "0",
        ];
      }
    }

    final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
        arguments: TxConfirmParams(
          module: module,
          call: call,
          txTitle: dic['homa.redeem'],
          txDisplay: _selectIndex != 2
              ? {
                  dic['homa.fast']: '',
                }
              : {},
          txDisplayBold: txDisplay,
          params: params,
          rawParams: paramsRaw,
          isPlugin: true,
        ))) as Map?;

    if (res != null) {
      Navigator.of(context).pop(
          '${(_selectIndex == 0 ? _fastReceiveAmount : _selectIndex == 1 ? _swapAmount : _receiveAmount)}');
    }
  }

  @override
  void dispose() {
    _amountPayCtrl.dispose();
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
    super.dispose();
  }

  @override
  Widget build(_) {
    return Observer(
      builder: (BuildContext context) {
        final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;

        final lTokenBalance =
            widget.plugin.store!.assets.tokenBalanceMap["L$stakeToken"]!;
        final max = _getMaxAmount();

        return PluginScaffold(
          appBar: PluginAppBar(
            title: Text('${dic['homa.redeem']} $stakeToken'),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: <Widget>[
                  PluginInputBalance(
                    tokenViewFunction: (value) {
                      return PluginFmt.tokenView(value);
                    },
                    margin: EdgeInsets.only(bottom: 2),
                    titleTag: dic['earn.unStake'],
                    inputCtrl: _amountPayCtrl,
                    balance: TokenBalanceData(
                        symbol: lTokenBalance.symbol,
                        amount: max.toString(),
                        decimals: lTokenBalance.decimals),
                    tokenIconsMap: widget.plugin.tokenIcons,
                    onInputChange: (v) => _onSupplyAmountChange(v, max),
                    onSetMax: karBalance > 0.1 ? (v) => _onSetMax(v) : null,
                    onClear: () {
                      setState(() {
                        _amountPayCtrl.text = '';
                      });
                      _onSupplyAmountChange('', max);
                    },
                  ),
                  Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dic['v3.homa.minUnstakingAmount']!,
                          style: Theme.of(context)
                              .textTheme
                              .headline5
                              ?.copyWith(
                                  color: Colors.white,
                                  fontSize: UI.getTextSize(12, context),
                                  fontWeight: FontWeight.w300),
                        ),
                        Text(
                          "${minRedeem.toStringAsFixed(4)} $stakeToken",
                          style: Theme.of(context)
                              .textTheme
                              .headline5
                              ?.copyWith(
                                  color: Colors.white,
                                  fontSize: UI.getTextSize(12, context),
                                  fontWeight: FontWeight.w300),
                        )
                      ],
                    ),
                  ),
                  ErrorMessage(_error,
                      margin: EdgeInsets.symmetric(vertical: 2)),
                  Visibility(visible: isLoading, child: PluginLoadingWidget()),
                  Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Column(
                        children: [
                          PluginTextTag(
                            title: dic['v3.selectRedeemMethod']!,
                          ),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                                horizontal: 11, vertical: 14),
                            margin: EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color: Color(0xCCFFFFFF), width: 1),
                                borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(8),
                                    topRight: Radius.circular(8),
                                    bottomRight: Radius.circular(8))),
                            child: Column(
                              children: [
                                UnStakeTypeItemWidget(
                                  title: dic['homa.fast']!,
                                  value:
                                      "${Fmt.priceFloor(_fastReceiveAmount.toDouble(), lengthMax: 4)} $relay_chain_token_symbol",
                                  describe: dic['homa.fast.describe']!,
                                  isSelect: _selectIndex == 0,
                                  ontap: () {
                                    setState(() {
                                      _selectIndex = 0;
                                    });
                                  },
                                ),
                                UnStakeTypeItemWidget(
                                  title: dic['dex.swap']!,
                                  value:
                                      "${Fmt.priceFloor(_swapAmount.toDouble(), lengthMax: 4)} $relay_chain_token_symbol",
                                  margin: EdgeInsets.symmetric(vertical: 14),
                                  describe: dic['dex.swap.describe']!,
                                  isSelect: _selectIndex == 1,
                                  ontap: () {
                                    setState(() {
                                      _selectIndex = 1;
                                    });
                                  },
                                ),
                                UnStakeTypeItemWidget(
                                  title: dic['v3.homa.unbond']!,
                                  value:
                                      "${Fmt.priceFloor(_receiveAmount.toDouble(), lengthMax: 4)} $relay_chain_token_symbol",
                                  describe: dic['v3.homa.unbond.describe']!,
                                  isSelect: _selectIndex == 2,
                                  ontap: () {
                                    setState(() {
                                      _selectIndex = 2;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          Visibility(
                              visible: _fastReceiveAmount == 0 &&
                                  _selectIndex == 0 &&
                                  _amountPayCtrl.text.length > 0,
                              child: Text(
                                dic['v3.fastRedeemError']!,
                                style: Theme.of(context)
                                    .textTheme
                                    .headline5
                                    ?.copyWith(
                                        color: Colors.white,
                                        fontSize: UI.getTextSize(12, context),
                                        fontWeight: FontWeight.w300),
                              )),
                        ],
                      )),
                  Padding(
                      padding: EdgeInsets.only(bottom: 24, top: 8),
                      child: PluginButton(
                        title: dic['homa.redeem']!,
                        onPressed: _onSubmit,
                      ))
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class UnStakeTypeItemWidget extends StatelessWidget {
  const UnStakeTypeItemWidget(
      {required this.title,
      required this.value,
      required this.describe,
      this.valueColor,
      this.subtitle,
      this.isSelect = false,
      this.margin,
      this.ontap,
      Key? key})
      : super(key: key);
  final String title;
  final String value;
  final String describe;
  final Color? valueColor;
  final Widget? subtitle;
  final bool isSelect;
  final EdgeInsetsGeometry? margin;
  final Function()? ontap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: ontap,
        child: Container(
          height: 125,
          padding: EdgeInsets.all(10),
          margin: margin,
          decoration: BoxDecoration(
              color: Color(0x24FFFFFF),
              border: isSelect
                  ? Border.all(color: Color(0xFFFC8156), width: 2)
                  : null,
              borderRadius: const BorderRadius.all(Radius.circular(8))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headline4?.copyWith(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headline4?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: valueColor ?? Colors.white),
                  )
                ],
              ),
              Visibility(child: subtitle ?? Container()),
              Container(
                  padding: EdgeInsets.only(top: 8),
                  margin: EdgeInsets.only(right: 60),
                  child: Text(
                    describe,
                    style: Theme.of(context).textTheme.headline5?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w300,
                        height: 1.3,
                        fontSize: UI.getTextSize(12, context)),
                  ))
            ],
          ),
        ));
  }
}
