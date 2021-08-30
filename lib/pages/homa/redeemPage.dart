import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/api/types/txHomaData.dart';
import 'package:polkawallet_plugin_karura/common/constants/base.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/pages/homa/homaHistoryPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/currencyWithIcon.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class HomaRedeemPage extends StatefulWidget {
  HomaRedeemPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/acala/homa/redeem';

  @override
  _HomaRedeemPageState createState() => _HomaRedeemPageState();
}

class _HomaRedeemPageState extends State<HomaRedeemPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountPayCtrl = new TextEditingController();
  final TextEditingController _amountReceiveCtrl = new TextEditingController();

  int _radioSelect = 0;
  int _eraSelected = 0;
  double _fee = 0;

  Timer _timer;

  Future<void> _updateReceiveAmount(double input) async {
    if (input == null || input == 0) return;

    int era = 0;
    if (_radioSelect == 1) {
      era = widget.plugin.store.homa.stakingPoolInfo.freeList[_eraSelected].era;
    }
    final res = await widget.plugin.api.homa
        .queryHomaRedeemAmount(input, _radioSelect, era);
    double fee = 0;
    double amount = 0;
    if (res.fee > 0) {
      fee = res.fee;
      amount = res.received;
    } else {
      amount = res.amount;
    }

    if (mounted) {
      setState(() {
        _amountReceiveCtrl.text = amount.toStringAsFixed(6);
        _fee = fee;
      });
      _formKey.currentState.validate();
    }
  }

  void _onSupplyAmountChange(String v) {
    String supply = v.trim();
    if (supply.isEmpty) {
      return;
    }

    if (_timer != null) {
      _timer.cancel();
    }
    _timer = Timer(Duration(seconds: 1), () {
      _updateReceiveAmount(double.parse(supply));
    });
  }

  Future<void> _onRadioChange(int value) async {
    if (value == 1) {
      final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'acala');
      final pool = widget.plugin.store.homa.stakingPoolInfo;
      if (pool.freeList.length == 0) return;

      if (pool.freeList.length > 1) {
        await showCupertinoModalPopup(
          context: context,
          builder: (_) => Container(
            height: MediaQuery.of(context).copyWith().size.height / 3,
            child: CupertinoPicker(
              backgroundColor: Colors.white,
              itemExtent: 58,
              scrollController: FixedExtentScrollController(
                initialItem: _eraSelected,
              ),
              children: pool.freeList.map((i) {
                return Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Era ${i.era}, ${dic['homa.redeem.free']} ${Fmt.priceFloor(i.free)}',
                    style: TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onSelectedItemChanged: (v) {
                setState(() {
                  _eraSelected = v;
                });
              },
            ),
          ),
        );
      }
    }
    setState(() {
      _radioSelect = value;
    });
    if (_amountPayCtrl.text.isNotEmpty) {
      _updateReceiveAmount(double.parse(_amountPayCtrl.text.trim()));
    }
  }

  Future<void> _onSubmit(int liquidDecimal) async {
    if (_formKey.currentState.validate()) {
      final pay = _amountPayCtrl.text.trim();
      final receive = Fmt.priceFloor(
        double.parse(_amountReceiveCtrl.text),
        lengthMax: 4,
      );
      var strategy = TxHomaData.redeemTypeNow;
      if (_radioSelect == 2) {
        strategy = TxHomaData.redeemTypeWait;
      }
      int era = 0;
      final pool = widget.plugin.store.homa.stakingPoolInfo;
      if (pool.freeList.length > 0) {
        era = pool.freeList[_eraSelected].era;
      }
      final params = [
        Fmt.tokenInt(pay, liquidDecimal).toString(),
        _radioSelect == 1 ? {"Target": era} : strategy
      ];
      final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
          arguments: TxConfirmParams(
            module: 'homa',
            call: 'redeem',
            txTitle: I18n.of(context)
                .getDic(i18n_full_dic_acala, 'acala')['homa.redeem'],
            txDisplay: {
              "amountPay": pay,
              "amountReceive": receive,
              "strategy": _radioSelect == 1 ? 'Era $era' : strategy,
            },
            params: params,
          ))) as Map;
      if (res != null) {
        res['time'] = DateTime.now().millisecondsSinceEpoch;
        res['action'] = TxHomaData.actionRedeem;
        res['amountPay'] = pay;
        res['amountReceive'] = receive;
        res['params'] = params;
        widget.plugin.store.homa.addHomaTx(res, widget.keyring.current.pubKey);
        Navigator.of(context).pushNamed(HomaHistoryPage.route);
      }
    }
  }

  @override
  void dispose() {
    _amountPayCtrl.dispose();
    _amountReceiveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(_) {
    return Observer(
      builder: (BuildContext context) {
        final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'acala');
        final dicAssets =
            I18n.of(context).getDic(i18n_full_dic_acala, 'common');

        final symbols = widget.plugin.networkState.tokenSymbol;
        final decimals = widget.plugin.networkState.tokenDecimals;
        final stakeSymbol = relay_chain_token_symbol;
        final liquidSymbol = 'L$stakeSymbol';
        final liquidDecimal = decimals[symbols.indexOf(liquidSymbol)];

        final balance = Fmt.balanceInt(
            widget.plugin.store.assets.tokenBalanceMap[liquidSymbol].amount);

        final pool = widget.plugin.store.homa.stakingPoolInfo;

        double available = 0;
        String eraSelectText = dic['homa.era'];
        String eraSelectTextTail = '';
        if (pool.freeList.length > 0) {
          final item = pool.freeList[_eraSelected];
          available = item.free * pool.liquidExchangeRate;
          eraSelectText += ': ${item.era}';
          eraSelectTextTail =
              '(≈ ${(item.era - pool.currentEra).toInt()}${dic['homa.redeem.day']}, ${dicAssets['amount.available']}: ${Fmt.priceFloor(pool.freeList[_eraSelected].free)} $stakeSymbol)';
        }

        final primary = Theme.of(context).primaryColor;
        final grey = Theme.of(context).unselectedWidgetColor;

        final textStyleGray = TextStyle(fontSize: 13, color: grey);
        final textStyle = TextStyle(fontSize: 13);

        return Scaffold(
          appBar: AppBar(title: Text(dic['homa.redeem']), centerTitle: true),
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: <Widget>[
                RoundedCard(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Form(
                        key: _formKey,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  CurrencyWithIcon(
                                    liquidSymbol,
                                    TokenIcon(
                                        liquidSymbol, widget.plugin.tokenIcons),
                                    textStyle:
                                        Theme.of(context).textTheme.headline4,
                                  ),
                                  TextFormField(
                                    decoration: InputDecoration(
                                      hintText: dic['dex.pay'],
                                      labelText: dic['dex.pay'],
                                      suffix: GestureDetector(
                                        child: Icon(
                                          CupertinoIcons.clear_thick_circled,
                                          color:
                                              Theme.of(context).disabledColor,
                                          size: 18,
                                        ),
                                        onTap: () {
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) =>
                                                  _amountPayCtrl.clear());
                                        },
                                      ),
                                    ),
                                    inputFormatters: [
                                      UI.decimalInputFormatter(liquidDecimal)
                                    ],
                                    controller: _amountPayCtrl,
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                            decimal: true),
                                    validator: (v) {
                                      double amt;
                                      try {
                                        amt = double.parse(v.trim());
                                        if (v.trim().isEmpty || amt == 0) {
                                          return dicAssets['amount.error'];
                                        }
                                      } catch (err) {
                                        return dicAssets['amount.error'];
                                      }
                                      if (amt >
                                          Fmt.bigIntToDouble(
                                              balance, liquidDecimal)) {
                                        return dicAssets['amount.low'];
                                      }
                                      final input = double.parse(v.trim()) *
                                          pool.liquidExchangeRate;
                                      if (_radioSelect == 0 &&
                                          input > pool.freePool) {
                                        return dic['homa.pool.low'];
                                      }
                                      if (_radioSelect == 1 &&
                                          input > available) {
                                        return dic['homa.pool.low'];
                                      }
                                      return null;
                                    },
                                    onChanged: _onSupplyAmountChange,
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Text(
                                      '${dicAssets['balance']}: ${Fmt.token(balance, liquidDecimal)} $liquidSymbol',
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .unselectedWidgetColor),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(8, 2, 8, 0),
                              child: Icon(
                                Icons.repeat,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  CurrencyWithIcon(
                                    stakeSymbol,
                                    TokenIcon(
                                        stakeSymbol, widget.plugin.tokenIcons),
                                    textStyle:
                                        Theme.of(context).textTheme.headline4,
                                  ),
                                  TextFormField(
                                    decoration: InputDecoration(
                                      labelText: dic['dex.receive'],
                                      suffix: Container(
                                        height: 16,
                                        width: 8,
                                      ),
                                    ),
                                    controller: _amountReceiveCtrl,
                                    readOnly: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  dic['dex.rate'],
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .unselectedWidgetColor),
                                ),
                                Text(
                                    '1 $liquidSymbol = ${Fmt.priceFloor(pool.liquidExchangeRate, lengthMax: 4)} $stakeSymbol'),
                              ],
                            ),
                            GestureDetector(
                              child: Container(
                                child: Column(
                                  children: <Widget>[
                                    Icon(Icons.history, color: primary),
                                    Text(
                                      dic['loan.txs'],
                                      style: TextStyle(
                                          color: primary, fontSize: 14),
                                    )
                                  ],
                                ),
                              ),
                              onTap: () => Navigator.of(context)
                                  .pushNamed(HomaHistoryPage.route),
                            ),
                          ])
                    ],
                  ),
                ),
                RoundedCard(
                  margin: EdgeInsets.only(top: 16),
                  padding: EdgeInsets.fromLTRB(0, 8, 16, 8),
                  child: Column(
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.fromLTRB(16, 16, 0, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text('${dic['homa.redeem.fee']}:',
                                style: textStyle),
                            Text('(≈ ${Fmt.doubleFormat(_fee)} $stakeSymbol)',
                                style: textStyle),
                          ],
                        ),
                      ),
                      Divider(height: 4),
                      GestureDetector(
                        child: Row(
                          children: <Widget>[
                            Radio(
                              value: 0,
                              groupValue: _radioSelect,
                              onChanged: (v) => _onRadioChange(v),
                            ),
                            Expanded(
                              child: Text(dic['homa.now'], style: textStyle),
                            ),
                            Text(
                              '(${dic['homa.redeem.free']}: ${Fmt.priceFloor(pool.freePool)} $stakeSymbol)',
                              style: textStyle,
                            ),
                          ],
                        ),
                        onTap: () => _onRadioChange(0),
                      ),
                      GestureDetector(
                        child: Row(
                          children: <Widget>[
                            Radio(
                              value: 1,
                              groupValue: _radioSelect,
                              onChanged: (v) => _onRadioChange(v),
                            ),
                            Expanded(
                              child: Text(
                                eraSelectText,
                                style: pool.freeList.length == 0
                                    ? textStyleGray
                                    : textStyle,
                              ),
                            ),
                            Text(
                              eraSelectTextTail,
                              style: pool.freeList.length == 0
                                  ? textStyleGray
                                  : textStyle,
                            ),
                          ],
                        ),
                        onTap: () => _onRadioChange(1),
                      ),
                      GestureDetector(
                        child: Row(
                          children: <Widget>[
                            Radio(
                              value: 2,
                              groupValue: _radioSelect,
                              onChanged: (v) => _onRadioChange(v),
                            ),
                            Expanded(
                              child: Text(dic['homa.unbond'], style: textStyle),
                            ),
                            Text(
                              '(${pool.bondingDuration.toInt() + 1} Era ≈ ${(pool.unbondingDuration / 1000 ~/ SECONDS_OF_DAY) + 1} ${dic['homa.redeem.day']})',
                              style: textStyle,
                            ),
                          ],
                        ),
                        onTap: () => _onRadioChange(2),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: RoundedButton(
                    text: dic['homa.redeem'],
                    onPressed: () => _onSubmit(liquidDecimal),
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
