import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/api/types/calcHomaRedeemAmount.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/pages/swap/bootstrapPage.dart';
import 'package:polkawallet_plugin_karura/pages/swap/swapTokenInput.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';

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

  bool homaNow = false;

  final _payFocusNode = FocusNode();

  String _error;
  BigInt _maxInput;

  CalcHomaRedeemAmount _data;

  List<String> symbols;
  final stakeToken = relay_chain_token_symbol;
  List<int> decimals;

  double karBalance;
  TokenBalanceData balanceData;

  int stakeDecimal;
  double balanceDouble;

  double minStake;

  Timer _timer;

  @override
  void initState() {
    super.initState();

    symbols = widget.plugin.networkState.tokenSymbol;
    decimals = widget.plugin.networkState.tokenDecimals;

    karBalance = Fmt.balanceDouble(
        widget.plugin.balances.native.availableBalance.toString(),
        decimals[symbols.indexOf("L$stakeToken")]);
    balanceData = widget.plugin.store.assets.tokenBalanceMap["L$stakeToken"];

    stakeDecimal = decimals[symbols.indexOf("L$stakeToken")];
    balanceDouble = Fmt.balanceDouble(balanceData.amount, stakeDecimal);

    minStake = Fmt.balanceDouble(
        widget.plugin.networkConst['homaLite']['minimumRedeemThreshold']
            .toString(),
        stakeDecimal);
  }

  Future<void> _updateReceiveAmount(double input) async {
    if (mounted) {
      var data = await widget.plugin.api.homa
          .calcHomaRedeemAmount(widget.keyring.current.address, input, homaNow);
      setState(() {
        _data = data;
      });
    }
  }

  void _onSupplyAmountChange(String v) {
    final supply = v.trim();
    setState(() {
      _maxInput = null;
    });

    final error = _validateInput(supply);
    setState(() {
      _error = error;
      if (error != null) {
        _data = null;
      }
    });

    if (error != null) {
      return;
    }
    _updateReceiveAmount(double.parse(supply));
  }

  String _validateInput(String supply) {
    final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'common');
    final error = Fmt.validatePrice(supply, context);
    if (error != null) {
      return error;
    }

    final pay = double.parse(supply);
    if (_maxInput == null && pay > balanceDouble) {
      return dic['amount.low'];
    }

    if (pay <= minStake && !homaNow) {
      final minLabel = I18n.of(context)
          .getDic(i18n_full_dic_karura, 'acala')['homa.pool.redeem'];
      return '$minLabel > ${minStake.toStringAsFixed(4)}';
    }

    final symbols = widget.plugin.networkState.tokenSymbol;
    final decimals = widget.plugin.networkState.tokenDecimals;
    final stakeDecimal = decimals[symbols.indexOf(relay_chain_token_symbol)];
    final poolInfo = widget.plugin.store.homa.poolInfo;
    if (Fmt.tokenInt(supply, stakeDecimal) + poolInfo.staked > poolInfo.cap) {
      return I18n.of(context)
          .getDic(i18n_full_dic_karura, 'acala')['homa.pool.cap.error'];
    }
    return error;
  }

  void _onSetMax(BigInt max) {
    final poolInfo = widget.plugin.store.homa.poolInfo;
    if (poolInfo.staked + max > poolInfo.cap) {
      max = poolInfo.cap - poolInfo.staked;
    }

    final amount = Fmt.bigIntToDouble(max, stakeDecimal);
    setState(() {
      _amountPayCtrl.text = amount.toStringAsFixed(6);
      _maxInput = max;
      _error = _validateInput(amount.toString());
    });

    _updateReceiveAmount(amount);
  }

  Future<void> _onSubmit() async {
    final pay = _amountPayCtrl.text.trim();

    if (_error != null || pay.isEmpty || _data == null) return;

    var params = [_data.newRedeemBalance, 0];
    var module = 'homaLite';
    var call = 'requestRedeem';
    var txDisplay = {
      "amountPay": pay,
      "amountReceive": _data.expected,
    };
    if (homaNow) {
      module = 'dex';
      call = 'swapWithExactSupply';
      txDisplay = {
        "currencyPay": 'L$stakeToken',
        "amountPay": pay,
        "currencyReceive": stakeToken,
        "amountReceive": _data.expected,
      };
      params = [
        [
          {'Token': 'L$stakeToken'},
          {'Token': stakeToken}
        ],
        Fmt.tokenInt(pay, stakeDecimal).toString(),
        "0",
      ];
    }
    final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
        arguments: TxConfirmParams(
          module: module,
          call: call,
          txTitle: I18n.of(context)
              .getDic(i18n_full_dic_karura, 'acala')['homa.redeem'],
          txDisplay: txDisplay,
          params: params,
        ))) as Map;

    if (res != null) {
      Navigator.of(context).pop('1');
    }
  }

  void _switchActon(bool value) {
    setState(() {
      homaNow = value;
    });
    if (homaNow) {
      if (_timer == null) {
        _timer = Timer.periodic(Duration(seconds: 20), (timer) {
          _updateReceiveAmount(double.parse(_amountPayCtrl.text.trim()));
        });
      }
    } else {
      if (_timer != null) {
        _timer.cancel();
        _timer = null;
      }
    }
    if (_amountPayCtrl.text.length > 0) {
      final error = _validateInput(_amountPayCtrl.text.trim());
      setState(() {
        _error = error;
        if (error != null) {
          _data = null;
        }
      });

      if (error != null) {
        return;
      }
      _updateReceiveAmount(double.parse(_amountPayCtrl.text.trim()));
    }
  }

  @override
  void dispose() {
    _amountPayCtrl.dispose();
    _payFocusNode.dispose();
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }
    super.dispose();
  }

  @override
  Widget build(_) {
    final grey = Theme.of(context).unselectedWidgetColor;
    final labelStyle = TextStyle(color: grey, fontSize: 13);
    return Observer(
      builder: (BuildContext context) {
        final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');

        return Scaffold(
          appBar: AppBar(
            title: Text('${dic['homa.redeem']} $stakeToken'),
            centerTitle: true,
            leading: BackBtn(),
          ),
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: <Widget>[
                RoundedCard(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SwapTokenInput(
                        title: dic['dex.pay'],
                        inputCtrl: _amountPayCtrl,
                        focusNode: _payFocusNode,
                        balance: widget.plugin.store.assets
                            .tokenBalanceMap["L$stakeToken"],
                        tokenIconsMap: widget.plugin.tokenIcons,
                        onInputChange: (v) => _onSupplyAmountChange(v),
                        onSetMax: karBalance > 0.1 ? (v) => _onSetMax(v) : null,
                        onClear: () {
                          setState(() {
                            _amountPayCtrl.text = '';
                          });
                          _onSupplyAmountChange('');
                        },
                      ),
                      ErrorMessage(_error),
                      // Visibility(
                      //     visible: _amountReceive.isNotEmpty,
                      //     child: Container(
                      //       margin: EdgeInsets.only(top: 16),
                      //       child: InfoItemRow(dic['dex.receive'],
                      //           '$_amountReceive L$stakeToken'),
                      //     )),
                      Container(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(dic['homa.now'],
                                style: TextStyle(fontSize: 13)),
                            Container(
                              margin: EdgeInsets.only(left: 5),
                              child: CupertinoSwitch(
                                value: homaNow,
                                onChanged: (res) => _switchActon(res),
                              ),
                            )
                          ],
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 5),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                          border: Border.all(
                              color: Theme.of(context).disabledColor,
                              width: 0.5),
                        ),
                        child: Column(
                          children: [
                            Visibility(
                                visible: !homaNow,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(dic['homa.redeem.unbonding'],
                                        style: labelStyle),
                                    Text("10 ${dic['homa.redeem.day']}")
                                  ],
                                )),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(dic['homa.redeem.receive'],
                                    style: labelStyle),
                                Text(
                                    "${_data != null ? _data.expected : 0} $stakeToken")
                              ],
                            ),
                            Visibility(
                                visible: homaNow,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(dic['homa.redeem.fee'],
                                        style: labelStyle),
                                    Text(
                                        "${_data != null ? _data.fee : 0} $stakeToken")
                                  ],
                                )),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: RoundedButton(
                    text: dic['homa.redeem'],
                    onPressed: () => _onSubmit(),
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
