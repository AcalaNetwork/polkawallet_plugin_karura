import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/api/types/calcHomaRedeemAmount.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/pages/swap/bootstrapPage.dart';
import 'package:polkawallet_plugin_karura/pages/swap/swapTokenInput.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/textTag.dart';
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

  bool _isFastRedeem = false;
  bool _canFastRedeem = false;

  String _error;
  BigInt _maxInput;

  CalcHomaRedeemAmount _data;
  num _receiveAmount = 0;
  num _fastFee = 0;

  List<String> symbols;
  final stakeToken = relay_chain_token_symbol;
  List<int> decimals;

  double karBalance;
  TokenBalanceData balanceData;

  int stakeDecimal;
  double balanceDouble;

  double minRedeem;

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

    minRedeem = widget.plugin.store.homa.env != null
        ? widget.plugin.store.homa.env.redeemThreshold
        : Fmt.balanceDouble(
            widget.plugin.networkConst['homaLite']['minimumRedeemThreshold']
                .toString(),
            stakeDecimal);
  }

  Future<void> _updateReceiveAmount(double input) async {
    if (mounted && input != null) {
      final isHomaAlive =
          (ModalRoute.of(context).settings.arguments as Map)['isHomaAlive'];
      if (isHomaAlive) {
        final data = await widget.plugin.api.homa
            .calcHomaNewRedeemAmount(input, _isFastRedeem);
        final canFast = data['canTryFastReddem'] ?? false;
        if (canFast) {
          setState(() {
            _receiveAmount = data['receive'];
            _fastFee = data['fee'] ?? 0;
            _canFastRedeem = true;
          });
        } else {
          if (_isFastRedeem) {
            // we can not do fast redeem, so we use swap here
            final lToken = AssetsUtils.getBalanceFromTokenNameId(
                widget.plugin, 'L$stakeToken');
            final token = AssetsUtils.getBalanceFromTokenNameId(
                widget.plugin, stakeToken);
            final swapRes = await widget.plugin.api.swap.queryTokenSwapAmount(
                input.toString(),
                null,
                [
                  {...lToken.currencyId, 'decimals': lToken.decimals},
                  {...token.currencyId, 'decimals': token.decimals},
                ],
                '0.1');
            setState(() {
              _canFastRedeem = false;
              _receiveAmount = swapRes.amount;
              _fastFee = swapRes.fee;
            });
          } else {
            // or we use normal redeem request
            setState(() {
              _canFastRedeem = false;
              _receiveAmount = data['receive'];
              _fastFee = 0;
            });
          }
        }
      } else {
        final data = await widget.plugin.api.homa.calcHomaRedeemAmount(
            widget.keyring.current.address, input, _isFastRedeem);
        setState(() {
          _data = data;
        });
      }
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
    _updateReceiveAmount(double.tryParse(supply));
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

    if (pay <= minRedeem && !_isFastRedeem) {
      final minLabel = I18n.of(context)
          .getDic(i18n_full_dic_karura, 'acala')['homa.pool.redeem'];
      return '$minLabel > ${minRedeem.toStringAsFixed(4)}';
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

  Future<void> _submitRedeemOld() async {
    final pay = _amountPayCtrl.text.trim();

    if (_error != null || pay.isEmpty || _data == null) return;

    final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');

    var params = [_data.newRedeemBalance, 0];
    var module = 'homaLite';
    var call = 'requestRedeem';
    final txDisplay = {
      dic['dex.pay']: Text(
        '${Fmt.priceFloor(double.parse(pay), lengthMax: 4)} L$stakeToken',
        style: Theme.of(context).textTheme.headline1,
      ),
      dic['dex.receive']: Text(
        '≈ ${Fmt.priceFloor(double.parse(_data.expected), lengthMax: 4)} $stakeToken',
        style: Theme.of(context).textTheme.headline1,
      ),
    };
    if (_isFastRedeem) {
      module = 'dex';
      call = 'swapWithExactSupply';
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
          txTitle: dic['homa.redeem'],
          txDisplayBold: txDisplay,
          params: params,
        ))) as Map;

    if (res != null) {
      Navigator.of(context).pop('1');
    }
  }

  Future<void> _onSubmit() async {
    final pay = _amountPayCtrl.text.trim();

    if (_error != null || pay.isEmpty || (_data == null && _receiveAmount == 0))
      return;

    final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');

    final txDisplay = {
      dic['dex.pay']: Text(
        '$pay L$stakeToken',
        style: Theme.of(context).textTheme.headline1,
      ),
      dic['dex.receive']: Text(
        '≈ ${Fmt.priceFloor(_receiveAmount)} $stakeToken',
        style: Theme.of(context).textTheme.headline1,
      ),
    };

    String module = 'homa';
    String call = 'requestRedeem';
    List params = [
      Fmt.tokenInt(pay, stakeDecimal).toString(),
      _isFastRedeem,
    ];
    String paramsRaw;
    if (_isFastRedeem) {
      if (_canFastRedeem) {
        module = 'utility';
        call = 'batch';
        paramsRaw = '[['
            'api.tx.homa.requestRedeem(...${jsonEncode(params)}),'
            'api.tx.homa.fastMatchRedeems(["${widget.keyring.current.address}"])'
            ']]';
        params = [];
      } else {
        module = 'dex';
        call = 'swapWithExactSupply';
        params = [
          [
            {'Token': 'L$stakeToken'},
            {'Token': stakeToken}
          ],
          Fmt.tokenInt(pay, stakeDecimal).toString(),
          "0",
        ];
      }
    }

    final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
        arguments: TxConfirmParams(
          module: module,
          call: call,
          txTitle: dic['homa.redeem'],
          txDisplay: _isFastRedeem
              ? {
                  dic['homa.fast']: '',
                }
              : {},
          txDisplayBold: txDisplay,
          params: params,
          rawParams: paramsRaw,
        ))) as Map;

    if (res != null) {
      Navigator.of(context).pop('1');
    }
  }

  void _switchFast(bool value) {
    setState(() {
      _isFastRedeem = value;
    });
    if (_amountPayCtrl.text.trim().isEmpty) return;

    if (_maxInput != null) {
      _onSetMax(_maxInput);
    } else {
      _updateReceiveAmount(double.tryParse(_amountPayCtrl.text.trim()));
    }
    // if (_isFastRedeem) {
    //   if (_timer == null) {
    //     _timer = Timer.periodic(Duration(seconds: 20), (timer) {
    //       _updateReceiveAmount(double.tryParse(_amountPayCtrl.text.trim()));
    //     });
    //   }
    // } else {
    //   if (_timer != null) {
    //     _timer.cancel();
    //     _timer = null;
    //   }
    // }
  }

  @override
  void dispose() {
    _amountPayCtrl.dispose();
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }
    super.dispose();
  }

  @override
  Widget build(_) {
    final isHomaAlive =
        (ModalRoute.of(context).settings.arguments as Map)['isHomaAlive'];

    final grey = Theme.of(context).unselectedWidgetColor;
    final labelStyle = TextStyle(color: grey, fontSize: 13);
    return Observer(
      builder: (BuildContext context) {
        final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');

        final pendingRedeemReq =
            (widget.plugin.store.homa.userInfo?.redeemRequest ?? {})['amount'];

        final lTokenBalance =
            widget.plugin.store.assets.tokenBalanceMap["L$stakeToken"];
        int unbondEras = 28;
        if (widget.plugin.networkConst['homa'] != null) {
          unbondEras =
              int.parse(widget.plugin.networkConst['homa']['bondingDuration']);
        }
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
                      Visibility(
                          visible: pendingRedeemReq != null &&
                              pendingRedeemReq > 0 &&
                              !_isFastRedeem,
                          child: Container(
                            margin: EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                    child: TextTag(
                                  dic['homa.redeem.pending'] +
                                      ' $pendingRedeemReq L$relay_chain_token_symbol' +
                                      '\n${dic['homa.redeem.replace']}',
                                  padding: EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 8),
                                ))
                              ],
                            ),
                          )),
                      SwapTokenInput(
                        title: dic['dex.pay'],
                        inputCtrl: _amountPayCtrl,
                        balance: _isFastRedeem
                            ? lTokenBalance
                            : TokenBalanceData(
                                symbol: lTokenBalance.symbol,
                                amount: (Fmt.balanceInt(lTokenBalance.amount) +
                                        Fmt.tokenInt(
                                            (pendingRedeemReq ?? 0).toString(),
                                            lTokenBalance.decimals))
                                    .toString(),
                                decimals: lTokenBalance.decimals),
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
                            Text(dic['homa.fast'],
                                style: TextStyle(fontSize: 13)),
                            Container(
                              margin: EdgeInsets.only(left: 5),
                              child: CupertinoSwitch(
                                value: _isFastRedeem,
                                onChanged: (res) => _switchFast(res),
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
                              visible: isHomaAlive
                                  ? (!_isFastRedeem ||
                                      (_isFastRedeem && _canFastRedeem))
                                  : !_isFastRedeem,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(dic['homa.redeem.unbonding'],
                                      style: labelStyle),
                                  Text("$unbondEras Kusama Eras")
                                ],
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(dic['homa.redeem.receive'],
                                    style: labelStyle),
                                Text(
                                    "${_data != null ? _data.expected : (_receiveAmount ?? 0)} $stakeToken")
                              ],
                            ),
                            Visibility(
                                visible: _isFastRedeem,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(dic['homa.redeem.fee'],
                                        style: labelStyle),
                                    Text(
                                        "${_data != null ? _data.fee : (_fastFee ?? 0)} L$stakeToken")
                                  ],
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: RoundedButton(
                    text: dic['homa.redeem'],
                    onPressed: isHomaAlive ? _onSubmit : _submitRedeemOld,
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
