import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_plugin_karura/api/types/swapOutputData.dart';
import 'package:polkawallet_plugin_karura/common/components/insufficientKARWarn.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/pages/swap/bootstrapPage.dart';
import 'package:polkawallet_plugin_karura/pages/swapNew/swapPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/api/types/txInfoData.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginInputBalance.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginOutlinedButtonSmall.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class SwapForm extends StatefulWidget {
  SwapForm(this.plugin, this.keyring, {this.initialSwapPair});
  final PluginKarura plugin;
  final Keyring keyring;
  final List<String>? initialSwapPair;

  @override
  _SwapFormState createState() => _SwapFormState();
}

class _SwapFormState extends State<SwapForm>
    with SingleTickerProviderStateMixin {
  final TextEditingController _amountPayCtrl = new TextEditingController();
  final TextEditingController _amountReceiveCtrl = new TextEditingController();
  final TextEditingController _amountSlippageCtrl = new TextEditingController();

  final _slippageFocusNode = FocusNode();

  String? _error;
  String? _errorReceive;
  double _slippage = 0.005;
  bool _slippageSettingVisible = false;
  String? _slippageError;
  List<String?> _swapPair = [];
  int _swapMode = 0; // 0 for 'EXACT_INPUT' and 1 for 'EXACT_OUTPUT'
  double? _swapRatio = 0;
  SwapOutputData _swapOutput = SwapOutputData();

  TxFeeEstimateResult? _fee;
  BigInt? _maxInput;

  // use a _timer to update page data consistently
  Timer? _timer;
  // use another _timer to control swap amount query
  Timer? _delayTimer;

  bool rateReversed = false;
  bool _detailShow = false;

  AnimationController? _animationController;
  Animation<double>? _animation;
  double angle = 0;

  Future<void> _getTxFee() async {
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
      _maxInput = null;
      _swapPair = [_swapPair[1], _swapPair[0]];
      _amountPayCtrl.text = _amountReceiveCtrl.text;
      _amountReceiveCtrl.text = pay;
      _swapMode = _swapMode == 0 ? 1 : 0;
    });
    widget.plugin.store!.swap
        .setSwapPair(_swapPair, widget.keyring.current.pubKey);

    await _updateSwapAmount();
  }

  bool _onCheckBalance() {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'common');
    final v = _amountPayCtrl.text.trim();
    final balancePair =
        AssetsUtils.getBalancePairFromTokenNameId(widget.plugin, _swapPair);

    String? error = Fmt.validatePrice(v, context);
    String? errorReceive;

    if (error == null) {
      if (_maxInput == null) {
        BigInt available = Fmt.balanceInt(balancePair[0]?.amount ?? '0');
        // limit user's input for tx fee if token is KAR
        if (balancePair[0]!.symbol == acala_token_ids[0]) {
          final accountED = PluginFmt.getAccountED(widget.plugin);
          available -= accountED +
              Fmt.balanceInt(_fee?.partialFee?.toString()) * BigInt.two;
        }
        if (double.parse(v) >
            Fmt.bigIntToDouble(available, balancePair[0]!.decimals!)) {
          error = dic!['amount.low'];
        }
      }

      // check if user's receive token balance meet existential deposit.
      final decimalReceive = balancePair[1]!.decimals!;
      final receiveMin = Fmt.balanceDouble(
          AssetsUtils.getBalanceFromTokenNameId(widget.plugin, _swapPair[1])!
              .minBalance!,
          decimalReceive);
      if ((balancePair[1] == null ||
              Fmt.balanceDouble(balancePair[1]!.amount!, decimalReceive) ==
                  0.0) &&
          double.parse(_amountReceiveCtrl.text) < receiveMin) {
        errorReceive =
            '${dic!['amount.min']} ${Fmt.priceCeil(receiveMin, lengthMax: 6)}';
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
      _delayTimer!.cancel();
    }
    _delayTimer = Timer(Duration(milliseconds: 500), () {
      if (_swapMode == 0) {
        _calcSwapAmount(input, null);
      } else {
        _calcSwapAmount(null, input);
      }
    });
  }

  Future<void> _updateSwapAmount() async {
    if (_swapMode == 0) {
      if (_amountPayCtrl.text.trim().isNotEmpty) {
        await _calcSwapAmount(_amountPayCtrl.text.trim(), null);
      }
    } else {
      if (_amountReceiveCtrl.text.trim().isNotEmpty) {
        await _calcSwapAmount(null, _amountReceiveCtrl.text.trim());
      }
    }
  }

  void _setUpdateTimer() {
    if (widget.plugin.sdk.api.connectedNode != null) {
      _updateSwapAmount();
    }

    if (mounted) {
      _timer = Timer(Duration(seconds: 10), () {
        _setUpdateTimer();
      });
    }
  }

  Future<void> _calcSwapAmount(String? supply, String? target) async {
    if (_swapPair.length < 2) return;

    widget.plugin.service!.assets.queryMarketPrices(_swapPair);

    try {
      if (supply == null) {
        final inputAmount = double.tryParse(target!);
        if (inputAmount == 0.0) return;

        final output = await widget.plugin.api!.swap.queryTokenSwapAmount(
          supply,
          target.isEmpty ? '1' : target,
          _swapPair.map((e) {
            final token =
                AssetsUtils.getBalanceFromTokenNameId(widget.plugin, e)!;
            return {...token.currencyId!, 'decimals': token.decimals};
          }).toList(),
          _slippage.toString(),
        );
        if (mounted) {
          setState(() {
            if (target.isNotEmpty) {
              _amountPayCtrl.text = output.amount.toString();
            } else {
              _amountPayCtrl.text = '';
            }
            _swapRatio = target.isEmpty
                ? output.amount
                : double.parse(target) / output.amount!;
            _swapOutput = output;
          });
          _onCheckBalance();
        }
      } else if (target == null) {
        final inputAmount = double.tryParse(supply);
        if (inputAmount == 0.0) return;

        final output = await widget.plugin.api!.swap.queryTokenSwapAmount(
          supply.isEmpty ? '1' : supply,
          target,
          _swapPair.map((e) {
            final token =
                AssetsUtils.getBalanceFromTokenNameId(widget.plugin, e)!;
            return {...token.currencyId!, 'decimals': token.decimals};
          }).toList(),
          _slippage.toString(),
        );
        if (mounted) {
          setState(() {
            if (supply.isNotEmpty) {
              _amountReceiveCtrl.text = output.amount.toString();
            } else {
              _amountReceiveCtrl.text = '';
            }
            _swapRatio = supply.isEmpty
                ? output.amount
                : output.amount! / double.parse(supply);
            _swapOutput = output;
          });
          _onCheckBalance();
        }
      }
    } on Exception catch (err) {
      setState(() {
        _error = err.toString().split(':')[0];
      });
    }
  }

  void _onSetSlippage() {
    setState(() {
      _slippageSettingVisible = !_slippageSettingVisible;
    });
  }

  void _onSlippageChange(String v) {
    final Map? dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala');
    try {
      double value = double.parse(v.trim());
      if (value >= 50 || value < 0.1) {
        setState(() {
          _slippageError = dic!['dex.slippage.error'];
        });
      } else {
        setState(() {
          _slippageError = null;
        });
        _updateSlippage(value / 100, custom: true);
      }
    } catch (err) {
      setState(() {
        _slippageError = dic!['dex.slippage.error'];
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

  void _onSetMax(BigInt max, int decimals, {BigInt? nativeKeepAlive}) {
    // keep some KAR for tx fee
    BigInt input = _swapPair[0] == acala_token_ids[0] &&
            (max - nativeKeepAlive! > BigInt.zero)
        ? max - nativeKeepAlive
        : max;

    final amount = Fmt.bigIntToDouble(input, decimals).toStringAsFixed(6);
    setState(() {
      _swapMode = 0;
      _amountPayCtrl.text = amount;
      _maxInput = input;
      _error = null;
      _errorReceive = null;
    });
    _onInputChange(amount);
  }

  Future<void> _onSubmit(List<int?> pairDecimals, double minMax) async {
    if (_onCheckBalance()) {
      final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;

      final pay = _amountPayCtrl.text.trim();
      final receive = _amountReceiveCtrl.text.trim();

      BigInt? input = Fmt.tokenInt(_swapMode == 0 ? pay : receive,
          pairDecimals[_swapMode == 0 ? 0 : 1]!);
      if (_maxInput != null) {
        input = _maxInput;
        // keep tx fee for ACA swap
        if (_swapMode == 0 &&
            (_swapPair[0] == widget.plugin.networkState.tokenSymbol![0])) {
          input =
              input! - BigInt.two * Fmt.balanceInt(_fee!.partialFee.toString());
        }
      }

      final params = [
        _swapOutput.path!
            .map((e) =>
                AssetsUtils.getBalanceFromTokenNameId(widget.plugin, e['name'])!
                    .currencyId)
            .toList(),
        input.toString(),
        Fmt.tokenInt(minMax.toString(), pairDecimals[_swapMode == 0 ? 1 : 0]!)
            .toString(),
      ];
      Navigator.of(context).pushNamed(TxConfirmPage.route,
          arguments: TxConfirmParams(
            module: 'dex',
            call:
                _swapMode == 0 ? 'swapWithExactSupply' : 'swapWithExactTarget',
            txTitle: dic['dex.title'],
            txDisplayBold: {
              dic['dex.pay']!: Text(
                '$pay ${AssetsUtils.getBalanceFromTokenNameId(widget.plugin, _swapPair[0])!.symbol}',
                style: Theme.of(context).textTheme.headline1,
              ),
              dic['dex.receive']!: Text(
                '$receive ${AssetsUtils.getBalanceFromTokenNameId(widget.plugin, _swapPair[1])!.symbol}',
                style: Theme.of(context).textTheme.headline1,
              ),
            },
            params: params,
          ));
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((_) async {
      _getTxFee();

      final cachedSwapPair =
          widget.plugin.store!.swap.swapPair(widget.keyring.current.pubKey);
      if (widget.initialSwapPair != null &&
          widget.initialSwapPair?.length == 2) {
        setState(() {
          _swapPair = widget.initialSwapPair!;
        });
      } else if (cachedSwapPair.length > 0 &&
          AssetsUtils.getBalanceFromTokenNameId(
                      widget.plugin, cachedSwapPair[0])!
                  .symbol !=
              null &&
          AssetsUtils.getBalanceFromTokenNameId(
                      widget.plugin, cachedSwapPair[1])!
                  .symbol !=
              null) {
        setState(() {
          _swapPair = cachedSwapPair;
        });
      } else {
        final tokens = PluginFmt.getAllDexTokens(widget.plugin);
        if (tokens.length > 1) {
          setState(() {
            _swapPair =
                tokens.sublist(0, 2).map((e) => e!.tokenNameId).toList();
          });
        } else {
          setState(() {
            _swapPair = [
              widget.plugin.networkState.tokenSymbol![0],
              relay_chain_token_symbol
            ];
          });
        }
      }

      _setUpdateTimer();
    });

    _animationController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    _animation = Tween(begin: 0.0, end: pi).animate(_animationController!)
      ..addListener(() {
        setState(() {
          angle = _animation!.value;
        });
      });
  }

  @override
  void dispose() {
    _amountPayCtrl.dispose();
    _amountReceiveCtrl.dispose();
    _slippageFocusNode.dispose();

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
        final dicGov = I18n.of(context)!.getDic(i18n_full_dic_karura, 'gov')!;

        final currencyOptionsLeft = PluginFmt.getAllDexTokens(widget.plugin);
        final currencyOptionsRight = currencyOptionsLeft.toList();
        final List<String?> swapPair = _swapPair.length > 1
            ? _swapPair
            : currencyOptionsLeft.length > 2
                ? currencyOptionsLeft
                    .sublist(0, 2)
                    .map((e) => e!.tokenNameId)
                    .toList()
                : [];

        if (widget.plugin.sdk.api.connectedNode == null ||
            swapPair.length < 2) {
          return ListView(
            children: [SwapSkeleton()],
          );
        }

        if (swapPair.length > 1) {
          currencyOptionsLeft.retainWhere((i) => i!.tokenNameId != swapPair[0]);
          currencyOptionsRight
              .retainWhere((i) => i!.tokenNameId != swapPair[1]);
        }

        final balancePair =
            AssetsUtils.getBalancePairFromTokenNameId(widget.plugin, swapPair);
        final nativeBalance = Fmt.balanceInt(
            widget.plugin.balances.native!.availableBalance.toString());
        final accountED = PluginFmt.getAccountED(widget.plugin);
        final nativeKeepAlive = accountED +
            Fmt.balanceInt((_fee?.partialFee ?? 0).toString()) * BigInt.two;
        final isNativeTokenLow = nativeBalance < nativeKeepAlive;

        double minMax = 0;
        if (_swapOutput.amount != null) {
          minMax = _swapMode == 0
              ? _swapOutput.amount! * (1 - _slippage)
              : _swapOutput.amount! * (1 + _slippage);
        }

        final showExchangeRate = swapPair.length > 1 &&
            _amountPayCtrl.text.isNotEmpty &&
            _amountReceiveCtrl.text.isNotEmpty;

        final grey = Theme.of(context).unselectedWidgetColor;
        final labelStyle = Theme.of(context)
            .textTheme
            .headline4
            ?.copyWith(color: Colors.white);

        return Column(children: [
          Expanded(
              child: ListView(
            padding: EdgeInsets.fromLTRB(8, 16, 8, 16),
            children: <Widget>[
              Visibility(
                visible: isNativeTokenLow,
                child: InsufficientKARWarn(),
              ),
              Visibility(
                  visible: Fmt.balanceInt(balancePair[0]!.amount) > BigInt.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                          padding: EdgeInsets.only(bottom: 6),
                          child: GestureDetector(
                            child: Text(dic['v3.swap.max']!,
                                style: Theme.of(context)
                                    .textTheme
                                    .headline5
                                    ?.copyWith(
                                        color: Color(0x88ffffff),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                            onTap: () {
                              _onSetMax(Fmt.balanceInt(balancePair[0]?.amount),
                                  balancePair[0]!.decimals!,
                                  nativeKeepAlive: nativeKeepAlive);
                            },
                          ))
                    ],
                  )),
              Stack(
                alignment: Alignment.topCenter,
                children: [
                  Column(
                    children: [
                      PluginInputBalance(
                        margin: EdgeInsets.only(bottom: 7),
                        inputCtrl: _amountPayCtrl,
                        tokenOptions: currencyOptionsLeft,
                        tokenSelectTitle: 'Select Collateral',
                        marketPrices: widget.plugin.store!.assets.marketPrices,
                        onInputChange: _onSupplyAmountChange,
                        onTokenChange: (token) {
                          setState(() {
                            _swapPair = token.tokenNameId == swapPair[1]
                                ? [token.tokenNameId, swapPair[0]]
                                : [token.tokenNameId, swapPair[1]];
                            _maxInput = null;
                          });
                          widget.plugin.store!.swap.setSwapPair(
                              _swapPair, widget.keyring.current.pubKey);
                          _updateSwapAmount();
                        },
                        // onSetMax: Fmt.balanceInt(balancePair[0]!.amount) > BigInt.zero
                        //     ? (v) => _onSetMax(v, balancePair[0]!.decimals!,
                        //         nativeKeepAlive: nativeKeepAlive)
                        //     : null,
                        onClear: () {
                          setState(() {
                            _maxInput = null;
                            _amountPayCtrl.text = '';
                          });
                        },
                        balance: balancePair[0],
                        tokenIconsMap: widget.plugin.tokenIcons,
                      ),
                      PluginInputBalance(
                        inputCtrl: _amountReceiveCtrl,
                        tokenOptions: currencyOptionsRight,
                        marketPrices: widget.plugin.store!.assets.marketPrices,
                        onInputChange: _onTargetAmountChange,
                        onTokenChange: (token) {
                          setState(() {
                            _swapPair = token.tokenNameId == swapPair[0]
                                ? [swapPair[1], token.tokenNameId]
                                : [swapPair[0], token.tokenNameId];
                            _maxInput = null;
                          });
                          widget.plugin.store!.swap.setSwapPair(
                              _swapPair, widget.keyring.current.pubKey);
                          _updateSwapAmount();
                        },
                        // onSetMax: Fmt.balanceInt(balancePair[0]!.amount) > BigInt.zero
                        //     ? (v) => _onSetMax(v, balancePair[0]!.decimals!,
                        //         nativeKeepAlive: nativeKeepAlive)
                        //     : null,
                        onClear: () {
                          setState(() {
                            _maxInput = null;
                            _amountReceiveCtrl.text = '';
                          });
                        },
                        balance: balancePair[1],
                        tokenIconsMap: widget.plugin.tokenIcons,
                      ),
                    ],
                  ),
                  GestureDetector(
                    child: Padding(
                      padding: EdgeInsets.only(
                          top: _amountPayCtrl.text.isNotEmpty ? 53.5 : 43.5),
                      child: Image.asset(
                          'packages/polkawallet_plugin_karura/assets/images/swap_switch.png',
                          width: 39),
                    ),
                    onTap: _swapPair.length > 1 ? () => _switchPair() : null,
                  ),
                ],
              ),
              ErrorMessage(
                _error ?? _errorReceive,
                margin: EdgeInsets.symmetric(vertical: 2),
              ),
              Visibility(
                  visible: showExchangeRate,
                  child: Container(
                    margin: EdgeInsets.only(top: 7, right: 1, bottom: 7),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          '1 ${PluginFmt.tokenView(balancePair[rateReversed ? 1 : 0]!.symbol)} = ${(rateReversed ? 1 / _swapRatio! : _swapRatio)!.toStringAsFixed(6)} ${PluginFmt.tokenView(balancePair[rateReversed ? 0 : 1]!.symbol)}',
                          style: Theme.of(context)
                              .textTheme
                              .headline5
                              ?.copyWith(color: Colors.white, fontSize: 10),
                        ),
                        GestureDetector(
                            onTap: () {
                              setState(() {
                                rateReversed = !rateReversed;
                              });
                            },
                            child: Container(
                              margin: EdgeInsets.only(left: 4),
                              child: Image.asset(
                                  'packages/polkawallet_plugin_karura/assets/images/swap_repeat.png',
                                  width: 16),
                            )),
                      ],
                    ),
                  )),
              Container(
                margin: EdgeInsets.only(right: 1, bottom: 7),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Text("${dic['dex.slippage']!}:",
                        style: Theme.of(context)
                            .textTheme
                            .headline5
                            ?.copyWith(color: Colors.white, fontSize: 10)),
                    GestureDetector(
                        child: Container(
                          margin: EdgeInsets.only(left: 3),
                          padding: EdgeInsets.symmetric(
                              horizontal: _slippage == 0.01 ? 8 : 5),
                          decoration: BoxDecoration(
                              color: Color(0xFFFF7849),
                              borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            Fmt.ratio(_slippage),
                            style: Theme.of(context)
                                .textTheme
                                .headline5
                                ?.copyWith(color: Colors.white, fontSize: 10),
                          ),
                        ),
                        onTap: _onSetSlippage),
                  ],
                ),
              ),
              Visibility(
                  visible: _slippageSettingVisible,
                  child: Container(
                    margin: EdgeInsets.only(left: 8, top: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        PluginOutlinedButtonSmall(
                          padding:
                              EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                          color: Color(0xFFFF7849),
                          unActiveTextcolor: Colors.white,
                          activeTextcolor: Colors.white,
                          fontSize: 8,
                          content: '0.1 %',
                          active: _slippage == 0.001,
                          onPressed: () => _updateSlippage(0.001),
                        ),
                        PluginOutlinedButtonSmall(
                          padding:
                              EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                          color: Color(0xFFFF7849),
                          unActiveTextcolor: Colors.white,
                          activeTextcolor: Colors.white,
                          fontSize: 8,
                          content: '0.5 %',
                          active: _slippage == 0.005,
                          onPressed: () => _updateSlippage(0.005),
                        ),
                        PluginOutlinedButtonSmall(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          color: Color(0xFFFF7849),
                          unActiveTextcolor: Colors.white,
                          activeTextcolor: Colors.white,
                          fontSize: 8,
                          content: '1 %',
                          active: _slippage == 0.01,
                          onPressed: () => _updateSlippage(0.01),
                        ),
                        Container(
                          width: 97,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              CupertinoTextField(
                                textAlign: TextAlign.right,
                                style: Theme.of(context)
                                    .textTheme
                                    .headline5
                                    ?.copyWith(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w300),
                                padding: EdgeInsets.fromLTRB(4, 0, 4, 0),
                                placeholder: I18n.of(context)!.getDic(
                                    i18n_full_dic_karura, 'common')!['custom'],
                                placeholderStyle: Theme.of(context)
                                    .textTheme
                                    .headline5
                                    ?.copyWith(
                                        color: grey,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w300),
                                inputFormatters: [UI.decimalInputFormatter(6)!],
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(4)),
                                  border: Border.all(color: Color(0xFF979797)),
                                ),
                                controller: _amountSlippageCtrl,
                                focusNode: _slippageFocusNode,
                                onChanged: _onSlippageChange,
                                // suffix: Container(
                                //   padding: EdgeInsets.only(right: 8),
                                //   child: Text(
                                //     '%',
                                //     style: TextStyle(
                                //         color: _slippageFocusNode.hasFocus
                                //             ? primary
                                //             : grey),
                                //   ),
                                // ),
                              ),
                              Visibility(
                                  visible: _slippageError != null,
                                  child: Text(
                                    _slippageError ?? "",
                                    style: TextStyle(
                                        color: Theme.of(context).errorColor,
                                        fontSize: 10),
                                  ))
                            ],
                          ),
                        )
                      ],
                    ),
                  )),
              Visibility(
                  visible: showExchangeRate && _swapOutput.amount != null,
                  child: Column(
                    children: [
                      GestureDetector(
                        child: Row(
                          children: [
                            Text(
                              dicGov['detail']!,
                              style: Theme.of(context)
                                  .textTheme
                                  .headline4
                                  ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Transform.rotate(
                                  angle: angle,
                                  child: SvgPicture.asset(
                                    "packages/polkawallet_ui/assets/images/triangle_bottom.svg",
                                    color: Color(0xFFFF7849),
                                  )),
                            )
                          ],
                        ),
                        onTap: () {
                          if (!_detailShow) {
                            _animationController!.forward();
                          } else {
                            _animationController!.reverse();
                          }
                          setState(() {
                            _detailShow = !_detailShow;
                          });
                        },
                      )
                    ],
                  )),
              Visibility(
                  visible: _detailShow,
                  child: Container(
                    decoration: BoxDecoration(
                        color: Color(0x24FFFFFF),
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(14),
                            topRight: Radius.circular(14),
                            bottomRight: Radius.circular(14))),
                    margin: EdgeInsets.only(top: 12),
                    padding: EdgeInsets.only(
                        left: 10, right: 10, bottom: 32, top: 12),
                    child: Column(
                      children: <Widget>[
                        Container(
                          margin: EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                    dic[_swapMode == 0
                                        ? 'dex.min'
                                        : 'dex.max']!,
                                    style: labelStyle),
                              ),
                              Text(
                                  '${minMax.toStringAsFixed(6)} ${showExchangeRate ? PluginFmt.tokenView(balancePair[_swapMode == 0 ? 1 : 0]!.symbol) : ''}',
                                  style: labelStyle),
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
                                    Text(dic['dex.impact']!, style: labelStyle),
                              ),
                              Text(
                                  '<${Fmt.ratio(_swapOutput.priceImpact ?? 0)}',
                                  style: labelStyle),
                            ],
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                child: Text(dic['dex.slippage']!,
                                    style: labelStyle),
                              ),
                              Text(Fmt.ratio(_slippage), style: labelStyle),
                            ],
                          ),
                        ),
                        Visibility(
                            visible: _swapOutput.fee != null,
                            child: Container(
                              margin: EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Expanded(
                                    child: Text(dic['dex.fee']!,
                                        style: labelStyle),
                                  ),
                                  Text(
                                      '${_swapOutput.fee} ${PluginFmt.tokenView(swapPair.length > 1 ? balancePair[0]!.symbol : '')}',
                                      style: labelStyle),
                                ],
                              ),
                            )),
                        Visibility(
                            visible: (_swapOutput.path?.length ?? 0) > 2,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(dic['dex.route']!,
                                      style: labelStyle),
                                ),
                                Text(
                                    _swapOutput.path != null
                                        ? _swapOutput.path!
                                            .map((i) => PluginFmt.tokenView(
                                                AssetsUtils
                                                        .getBalanceFromTokenNameId(
                                                            widget.plugin,
                                                            i['name'])
                                                    ?.symbol))
                                            .toList()
                                            .join(' > ')
                                        : "",
                                    style: labelStyle),
                              ],
                            ))
                      ],
                    ),
                  )),
            ],
          )),
          Padding(
              padding: EdgeInsets.only(left: 16, right: 16, bottom: 54),
              child: PluginButton(
                title: dic['dex.title']!,
                onPressed: _swapRatio == 0
                    ? null
                    : () => _onSubmit(
                        balancePair.map((e) => e!.decimals).toList(), minMax),
              ))
        ]);
      },
    );
  }
}
