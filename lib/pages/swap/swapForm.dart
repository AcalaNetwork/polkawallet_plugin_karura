import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/api/types/swapOutputData.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/pages/swap/bootstrapPage.dart';
import 'package:polkawallet_plugin_karura/pages/swap/swapTokenInput.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/api/types/txInfoData.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/outlinedButtonSmall.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class SwapForm extends StatefulWidget {
  SwapForm(this.plugin, this.keyring, this.enabled);
  final PluginKarura plugin;
  final Keyring keyring;
  final bool enabled;

  @override
  _SwapFormState createState() => _SwapFormState();
}

class _SwapFormState extends State<SwapForm> {
  final TextEditingController _amountPayCtrl = new TextEditingController();
  final TextEditingController _amountReceiveCtrl = new TextEditingController();
  final TextEditingController _amountSlippageCtrl = new TextEditingController();

  final _payFocusNode = FocusNode();
  final _receiveFocusNode = FocusNode();
  final _slippageFocusNode = FocusNode();

  String _error;
  String _errorReceive;
  double _slippage = 0.005;
  bool _slippageSettingVisible = false;
  String _slippageError;
  List<String> _swapPair = [];
  int _swapMode = 0; // 0 for 'EXACT_INPUT' and 1 for 'EXACT_OUTPUT'
  double _swapRatio = 0;
  SwapOutputData _swapOutput = SwapOutputData();

  TxFeeEstimateResult _fee;
  BigInt _maxInput;

  // use a _timer to update page data consistently
  Timer _timer;
  // use another _timer to control swap amount query
  Timer _delayTimer;

  bool rateExchange = false;

  Future<void> _getTxFee({bool reload = false}) async {
    final sender = TxSenderData(
        widget.keyring.current.address, widget.keyring.current.pubKey);
    final txInfo = TxInfoData('balances', 'transfer', sender);
    final fee = await widget.plugin.sdk.api.tx
        .estimateFees(txInfo, [widget.keyring.current.address, '10000000000']);
    if (mounted) {
      setState(() {
        _fee = fee;
      });
    }
  }

  Future<void> _switchPair() async {
    final pay = _amountPayCtrl.text;
    setState(() {
      _swapPair = [_swapPair[1], _swapPair[0]];
      _amountPayCtrl.text = _amountReceiveCtrl.text;
      _amountReceiveCtrl.text = pay;
      _swapMode = _swapMode == 0 ? 1 : 0;
    });
    widget.plugin.store.swap
        .setSwapPair(_swapPair, widget.keyring.current.pubKey);
    if (_payFocusNode.hasFocus) {
      _payFocusNode.unfocus();
      _receiveFocusNode.requestFocus();
    } else if (_receiveFocusNode.hasFocus) {
      _receiveFocusNode.unfocus();
      _payFocusNode.requestFocus();
    }
    await _updateSwapAmount();
  }

  bool _onCheckBalance() {
    final symbols = widget.plugin.networkState.tokenSymbol;
    final decimals = widget.plugin.networkState.tokenDecimals;
    final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'common');
    final v = _amountPayCtrl.text.trim();
    final balancePair = PluginFmt.getBalancePair(widget.plugin, _swapPair);

    String error;
    String errorReceive;
    try {
      if (v.isEmpty || double.parse(v) == 0) {
        error = dic['amount.error'];
      }
    } catch (err) {
      error = dic['amount.error'];
    }
    if (error == null) {
      if (_maxInput == null &&
          double.parse(v) >
              Fmt.bigIntToDouble(Fmt.balanceInt(balancePair[0]?.amount ?? '0'),
                  balancePair[0]?.decimals)) {
        error = dic['amount.low'];
      }

      // check if user's receive token balance meet existential deposit.
      final decimalReceive = decimals[symbols.indexOf(_swapPair[1])];
      final receiveMin =
          Fmt.balanceDouble(existential_deposit[_swapPair[1]], decimalReceive);
      if ((balancePair[1] == null ||
              Fmt.balanceDouble(balancePair[1].amount, decimalReceive) ==
                  0.0) &&
          double.parse(_amountReceiveCtrl.text) < receiveMin) {
        errorReceive =
            '${dic['amount.min']} ${Fmt.priceCeil(receiveMin, lengthMax: 6)}';
      }
    }
    setState(() {
      _error = error;
      _errorReceive = errorReceive;
    });
    return error == null && _errorReceive == null;
  }

  void _onSupplyAmountChange(String v) {
    String supply = v.trim();
    setState(() {
      _swapMode = 0;
      _maxInput = null;
    });

    _onInputChange(supply);
  }

  void _onTargetAmountChange(String v) {
    String target = v.trim();
    setState(() {
      _swapMode = 1;
      _maxInput = null;
    });

    _onInputChange(target);
  }

  void _onInputChange(String input) {
    if (_delayTimer != null) {
      _delayTimer.cancel();
    }
    _delayTimer = Timer(Duration(milliseconds: 500), () {
      if (_swapMode == 0) {
        _calcSwapAmount(input, null);
      } else {
        _calcSwapAmount(null, input);
      }
    });
  }

  Future<void> _updateSwapAmount({bool init = false}) async {
    if (_swapMode == 0) {
      await _calcSwapAmount(_amountPayCtrl.text.trim(), null, init: init);
    } else {
      await _calcSwapAmount(null, _amountReceiveCtrl.text.trim(), init: init);
    }
  }

  void _setUpdateTimer({init = true}) {
    _updateSwapAmount(init: init);

    if (mounted) {
      _timer = Timer(Duration(seconds: 10), () {
        _setUpdateTimer(
            init: _amountPayCtrl.text.trim().isEmpty &&
                _amountReceiveCtrl.text.trim().isEmpty);
      });
    }
  }

  Future<void> _calcSwapAmount(
    String supply,
    String target, {
    bool init = false,
  }) async {
    if (_swapPair.length < 2) return;

    widget.plugin.service.assets.queryMarketPrices(_swapPair);

    if (supply == null) {
      final output = await widget.plugin.api.swap.queryTokenSwapAmount(
        supply,
        target.isEmpty ? '1' : target,
        _swapPair,
        _slippage.toString(),
      );
      if (mounted) {
        setState(() {
          if (!init) {
            if (target.isNotEmpty) {
              _amountPayCtrl.text = output.amount.toString();
            } else {
              _amountPayCtrl.text = '';
            }
          }
          _swapRatio = target.isEmpty
              ? output.amount
              : double.parse(target) / output.amount;
          _swapOutput = output;
        });
        if (!init) {
          _onCheckBalance();
        }
      }
    } else if (target == null) {
      final output = await widget.plugin.api.swap.queryTokenSwapAmount(
        supply.isEmpty ? '1' : supply,
        target,
        _swapPair,
        _slippage.toString(),
      );
      if (mounted) {
        setState(() {
          if (!init) {
            if (supply.isNotEmpty) {
              _amountReceiveCtrl.text = output.amount.toString();
            } else {
              _amountReceiveCtrl.text = '';
            }
          }
          _swapRatio = supply.isEmpty
              ? output.amount
              : output.amount / double.parse(supply);
          _swapOutput = output;
        });
        if (!init) {
          _onCheckBalance();
        }
      }
    }
  }

  void _onSetSlippage() {
    setState(() {
      _slippageSettingVisible = !_slippageSettingVisible;
    });
  }

  void _onSlippageChange(String v) {
    final Map dic = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');
    try {
      double value = double.parse(v.trim());
      if (value >= 50 || value < 0.1) {
        setState(() {
          _slippageError = dic['dex.slippage.error'];
        });
      } else {
        setState(() {
          _slippageError = null;
        });
        _updateSlippage(value / 100, custom: true);
      }
    } catch (err) {
      setState(() {
        _slippageError = dic['dex.slippage.error'];
      });
    }
  }

  Future<void> _updateSlippage(double input, {bool custom = false}) async {
    if (!custom) {
      _slippageFocusNode.unfocus();
      setState(() {
        _amountSlippageCtrl.text = '';
        _slippageError = null;
      });
    }
    setState(() {
      _slippage = input;
    });
    if (_swapMode == 0) {
      await _calcSwapAmount(_amountPayCtrl.text.trim(), null);
    } else {
      await _calcSwapAmount(null, _amountReceiveCtrl.text.trim());
    }
  }

  void _onSetMax(BigInt max, int decimals) {
    final amount = Fmt.bigIntToDouble(max, decimals).toStringAsFixed(6);
    setState(() {
      _swapMode = 0;
      _amountPayCtrl.text = amount;
      _maxInput = max;
      _error = null;
      _errorReceive = null;
    });
    _onInputChange(amount);
  }

  Future<void> _onSubmit(List<int> pairDecimals, double minMax) async {
    if (_onCheckBalance()) {
      final pay = _amountPayCtrl.text.trim();
      final receive = _amountReceiveCtrl.text.trim();

      BigInt input = Fmt.tokenInt(
          _swapMode == 0 ? pay : receive, pairDecimals[_swapMode == 0 ? 0 : 1]);
      if (_maxInput != null) {
        input = _maxInput;
        // keep tx fee for ACA swap
        if (_swapMode == 0 &&
            (_swapPair[0] == widget.plugin.networkState.tokenSymbol[0])) {
          input -= BigInt.two * Fmt.balanceInt(_fee.partialFee.toString());
        }
      }

      final params = [
        _swapOutput.path
            .map((e) => ({'Token': e['name'], 'decimal': e['decimal']}))
            .toList(),
        input.toString(),
        Fmt.tokenInt(minMax.toString(), pairDecimals[_swapMode == 0 ? 1 : 0])
            .toString(),
      ];
      Navigator.of(context).pushNamed(TxConfirmPage.route,
          arguments: TxConfirmParams(
            module: 'dex',
            call:
                _swapMode == 0 ? 'swapWithExactSupply' : 'swapWithExactTarget',
            txTitle: I18n.of(context)
                .getDic(i18n_full_dic_karura, 'acala')['dex.title'],
            txDisplay: {
              "currencyPay": _swapPair[0],
              "amountPay": pay,
              "currencyReceive": _swapPair[1],
              "amountReceive": receive,
            },
            params: params,
          ));
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _getTxFee();

      if (widget.plugin.store.swap.swapPair != null &&
          widget.plugin.store.swap
                  .swapPair(widget.keyring.current.pubKey)
                  .length >
              0) {
        setState(() {
          _swapPair =
              widget.plugin.store.swap.swapPair(widget.keyring.current.pubKey);
        });
      } else {
        final tokens = PluginFmt.getAllDexTokens(widget.plugin);
        if (tokens.length > 2) {
          setState(() {
            _swapPair = tokens.sublist(0, 2);
          });
        }
      }

      _setUpdateTimer(init: true);
    });
  }

  @override
  void dispose() {
    _amountPayCtrl.dispose();
    _amountReceiveCtrl.dispose();
    _payFocusNode.dispose();
    _receiveFocusNode.dispose();
    _slippageFocusNode.dispose();

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

        final currencyOptionsLeft = PluginFmt.getAllDexTokens(widget.plugin);
        final currencyOptionsRight = currencyOptionsLeft.toList();
        final List<String> swapPair = _swapPair.length > 1
            ? _swapPair
            : currencyOptionsLeft.length > 2
                ? currencyOptionsLeft.sublist(0, 2)
                : [];

        if (swapPair.length > 1) {
          currencyOptionsLeft.retainWhere((i) => i != swapPair[0]);
          currencyOptionsRight.retainWhere((i) => i != swapPair[1]);
        }

        final balancePair = PluginFmt.getBalancePair(widget.plugin, swapPair);

        double minMax = 0;
        if (_swapOutput.output != null) {
          minMax = _swapMode == 0
              ? _swapOutput.amount * (1 - _slippage)
              : _swapOutput.amount * (1 + _slippage);
        }

        final showExchangeRate = swapPair.length > 1 &&
            _amountPayCtrl.text.isNotEmpty &&
            _amountReceiveCtrl.text.isNotEmpty;

        final primary = Theme.of(context).primaryColor;
        final grey = Theme.of(context).unselectedWidgetColor;
        final labelStyle = TextStyle(color: grey, fontSize: 13);

        return ListView(
          padding: EdgeInsets.fromLTRB(8, 16, 8, 16),
          children: <Widget>[
            RoundedCard(
              padding: EdgeInsets.all(16),
              child: swapPair.length == 2
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        SwapTokenInput(
                          title: dic['dex.pay'],
                          inputCtrl: _amountPayCtrl,
                          focusNode: _payFocusNode,
                          balance: balancePair[0],
                          tokenOptions: currencyOptionsLeft,
                          tokenIconsMap: widget.plugin.tokenIcons,
                          marketPrice: widget
                              .plugin.store.assets.marketPrices[swapPair[0]],
                          onInputChange: _onSupplyAmountChange,
                          onTokenChange: (String token) {
                            if (token != null) {
                              setState(() {
                                _swapPair = token == swapPair[1]
                                    ? [token, swapPair[0]]
                                    : [token, swapPair[1]];
                                _maxInput = null;
                              });
                              widget.plugin.store.swap.setSwapPair(
                                  _swapPair, widget.keyring.current.pubKey);
                              _updateSwapAmount();
                            }
                          },
                          onSetMax: (v) =>
                              _onSetMax(v, balancePair[0].decimals),
                          onClear: () {
                            setState(() {
                              _maxInput = null;
                              _amountPayCtrl.text = '';
                            });
                          },
                        ),
                        ErrorMessage(_error),
                        GestureDetector(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(8, 10, 8, 0),
                            child: Icon(
                              Icons.arrow_downward,
                              color: Theme.of(context).primaryColor,
                              size: 18,
                            ),
                          ),
                          onTap:
                              _swapPair.length > 1 ? () => _switchPair() : null,
                        ),
                        Container(
                          margin: EdgeInsets.only(top: 12),
                          child: SwapTokenInput(
                            title: dic['dex.receive'],
                            inputCtrl: _amountReceiveCtrl,
                            focusNode: _receiveFocusNode,
                            balance: balancePair[1],
                            tokenOptions: currencyOptionsRight,
                            tokenIconsMap: widget.plugin.tokenIcons,
                            marketPrice: widget
                                .plugin.store.assets.marketPrices[swapPair[1]],
                            onInputChange: _onTargetAmountChange,
                            onTokenChange: (String token) {
                              if (token != null) {
                                setState(() {
                                  _swapPair = token == swapPair[0]
                                      ? [swapPair[1], token]
                                      : [swapPair[0], token];
                                  _maxInput = null;
                                });
                                widget.plugin.store.swap.setSwapPair(
                                    _swapPair, widget.keyring.current.pubKey);
                                _updateSwapAmount();
                              }
                            },
                            onClear: () {
                              setState(() {
                                _maxInput = null;
                                _amountReceiveCtrl.text = '';
                              });
                            },
                          ),
                        ),
                        ErrorMessage(_errorReceive),
                        Visibility(
                            visible: showExchangeRate,
                            child: Container(
                              margin:
                                  EdgeInsets.only(left: 16, top: 12, right: 16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text(dic['dex.rate'], style: labelStyle),
                                  Row(children: <Widget>[
                                    Text(
                                        '1 ${PluginFmt.tokenView(swapPair[rateExchange ? 1 : 0])} = ${(rateExchange ? 1 / _swapRatio : _swapRatio).toStringAsFixed(6)} ${PluginFmt.tokenView(swapPair[rateExchange ? 0 : 1])}'),
                                    GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            rateExchange = !rateExchange;
                                          });
                                        },
                                        child: Container(
                                          margin: EdgeInsets.only(left: 10),
                                          child: Icon(
                                            Icons.repeat,
                                            color: primary,
                                            size: 16.0,
                                            semanticLabel:
                                                'Text to announce in accessibility modes',
                                          ),
                                        )),
                                  ])
                                ],
                              ),
                            )),
                        Container(
                          margin: EdgeInsets.only(left: 16, top: 12, right: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                  child: Text(dic['dex.slippage'],
                                      style: labelStyle)),
                              GestureDetector(
                                  child: Row(
                                    children: [
                                      Text(
                                        Fmt.ratio(_slippage),
                                        style: TextStyle(color: primary),
                                      ),
                                      Icon(Icons.settings_outlined,
                                          color: primary, size: 16)
                                    ],
                                  ),
                                  onTap: _onSetSlippage),
                              // GestureDetector(
                              //     child: ,
                              //     onTap: _onSetSlippage)
                            ],
                          ),
                        ),
                        _slippageSettingVisible
                            ? Container(
                                margin:
                                    EdgeInsets.only(left: 8, right: 8, top: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    OutlinedButtonSmall(
                                      content: '0.1 %',
                                      active: _slippage == 0.001,
                                      onPressed: () => _updateSlippage(0.001),
                                    ),
                                    OutlinedButtonSmall(
                                      content: '0.5 %',
                                      active: _slippage == 0.005,
                                      onPressed: () => _updateSlippage(0.005),
                                    ),
                                    OutlinedButtonSmall(
                                      content: '1 %',
                                      active: _slippage == 0.01,
                                      onPressed: () => _updateSlippage(0.01),
                                    ),
                                    Expanded(
                                      child: Column(
                                        children: <Widget>[
                                          CupertinoTextField(
                                            padding: EdgeInsets.fromLTRB(
                                                12, 4, 12, 2),
                                            placeholder: I18n.of(context)
                                                .getDic(i18n_full_dic_karura,
                                                    'common')['custom'],
                                            placeholderStyle: TextStyle(
                                                fontSize: 12,
                                                height: 1.5,
                                                color: grey),
                                            inputFormatters: [
                                              UI.decimalInputFormatter(6)
                                            ],
                                            keyboardType:
                                                TextInputType.numberWithOptions(
                                                    decimal: true),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(24)),
                                              border: Border.all(
                                                  color: _slippageFocusNode
                                                          .hasFocus
                                                      ? primary
                                                      : grey),
                                            ),
                                            controller: _amountSlippageCtrl,
                                            focusNode: _slippageFocusNode,
                                            onChanged: _onSlippageChange,
                                            suffix: Container(
                                              padding:
                                                  EdgeInsets.only(right: 8),
                                              child: Text(
                                                '%',
                                                style: TextStyle(
                                                    color: _slippageFocusNode
                                                            .hasFocus
                                                        ? primary
                                                        : grey),
                                              ),
                                            ),
                                          ),
                                          _slippageError != null
                                              ? Text(
                                                  _slippageError,
                                                  style: TextStyle(
                                                      color: Colors.red,
                                                      fontSize: 10),
                                                )
                                              : Container()
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              )
                            : Container(),
                      ],
                    )
                  : Center(
                      child: Container(
                        height: MediaQuery.of(context).size.width / 2,
                        child: CupertinoActivityIndicator(),
                      ),
                    ),
            ),
            showExchangeRate && _swapOutput?.amount != null
                ? RoundedCard(
                    margin: EdgeInsets.only(top: 16),
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: <Widget>[
                        Container(
                          margin: EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                    dic[_swapMode == 0 ? 'dex.min' : 'dex.max'],
                                    style: labelStyle),
                              ),
                              Text(
                                  '${minMax.toStringAsFixed(6)} ${PluginFmt.tokenView(_swapMode == 0 ? _swapOutput.output : _swapOutput.input)}'),
                            ],
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                child:
                                    Text(dic['dex.impact'], style: labelStyle),
                              ),
                              Text('<${Fmt.ratio(_swapOutput.priceImpact)}'),
                            ],
                          ),
                        ),
                        _swapOutput?.fee != null
                            ? Container(
                                margin: EdgeInsets.only(bottom: 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(dic['dex.fee'],
                                          style: labelStyle),
                                    ),
                                    Text(
                                        '${_swapOutput.fee} ${PluginFmt.tokenView(swapPair[0])}'),
                                  ],
                                ),
                              )
                            : Container(),
                        (_swapOutput.path?.length ?? 0) > 2
                            ? Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(dic['dex.route'],
                                        style: labelStyle),
                                  ),
                                  Text(_swapOutput.path
                                      .map(
                                          (i) => PluginFmt.tokenView(i['name']))
                                      .toList()
                                      .join(' > ')),
                                ],
                              )
                            : Container()
                      ],
                    ),
                  )
                : Container(),
            Padding(
              padding: EdgeInsets.only(top: 24),
              child: RoundedButton(
                text: dic['dex.title'],
                onPressed: !widget.enabled || _swapRatio == 0
                    ? null
                    : () => _onSubmit(
                        balancePair.map((e) => e.decimals).toList(), minMax),
              ),
            )
          ],
        );
      },
    );
  }
}
