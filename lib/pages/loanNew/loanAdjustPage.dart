import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_karura/api/types/loanType.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/pages/swapNew/bootstrapPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/infoItemRow.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginInputBalance.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginPageTitleTaps.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginRadioButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/components/v3/txButton.dart';
import 'package:polkawallet_ui/pages/v3/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/utils/format.dart';

class LoanAdjustPage extends StatefulWidget {
  LoanAdjustPage(this.plugin, this.keyring, {Key? key}) : super(key: key);
  final PluginKarura plugin;
  final Keyring keyring;
  static const String route = '/loan/adjust';

  @override
  State<LoanAdjustPage> createState() => _LoanAdjustPageState();
}

class _LoanAdjustPageState extends State<LoanAdjustPage> {
  int _tab = 0;
  List<String> _tabTitle = [];
  LoanData? _loan;
  LoanData? _editorLoan;
  String _type = "";
  bool _selectRadio = true;

  TextEditingController _firstController = TextEditingController();
  TextEditingController _lastController = TextEditingController();
  String? _error1;
  String? _error2;

  List<String> getTabTitle() {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    if (_type == "collateral") {
      return [dic['loan.deposit']!, dic['loan.withdraw']!];
    }
    return [dic['loan.mint']!, dic['loan.payback']!];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      final data = ModalRoute.of(context)!.settings.arguments as Map;
      setState(() {
        _loan = data["loan"];
        _editorLoan = _loan!.deepCopy();
        _type = data['type'];
        _tabTitle = getTabTitle();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    final textStyle = Theme.of(context).textTheme.headline5?.copyWith(
        color: PluginColorsDark.headline1, fontSize: 12, height: 2.0);

    final debitRatio =
        (_editorLoan?.collateralInUSD ?? BigInt.zero) == BigInt.zero
            ? 0.0
            : _editorLoan!.debits /
                _editorLoan!.collateralInUSD *
                Fmt.bigIntToDouble(_editorLoan!.type.liquidationRatio, 18);

    final balancePair = _editorLoan == null
        ? []
        : AssetsUtils.getBalancePairFromTokenNameId(widget.plugin,
            [_editorLoan!.token!.tokenNameId, karura_stable_coin]);
    return PluginScaffold(
        appBar: PluginAppBar(
          title: Text(_type == "collateral"
              ? dic['v3.loan.adjustCollateral']!
              : "${dic['v3.loan.adjustMinted']} ${PluginFmt.tokenView(karura_stable_coin)}"),
        ),
        body: SafeArea(
            child: _editorLoan == null
                ? Container()
                : Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Container(
                          margin: EdgeInsets.fromLTRB(16, 16, 0, 16),
                          child: PluginPageTitleTaps(
                            names: _tabTitle,
                            activeTab: _tab,
                            onTap: (i) {
                              if (i != _tab) {
                                setState(() {
                                  _error1 = null;
                                  _error2 = null;
                                  _firstController.text = "";
                                  _lastController.text = "";
                                  _editorLoan = _loan!.deepCopy();
                                  if (i == 0) {
                                    _selectRadio = true;
                                  } else {
                                    _selectRadio = false;
                                  }
                                  _tab = i;
                                });
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Padding(
                                padding: EdgeInsets.only(top: 20),
                                child: Column(
                                  children: [
                                    buildFirstInputView(),
                                    InfoItemRow(
                                      "${dic['v3.loan.requiredSafety']}",
                                      "${Fmt.priceFloorBigIntFormatter(_editorLoan!.requiredCollateral, _editorLoan!.token!.decimals!)} ${PluginFmt.tokenView(_editorLoan!.token!.symbol)}",
                                      labelStyle: textStyle,
                                      contentStyle: textStyle,
                                    ),
                                    buildLastInputView(),
                                    InfoItemRow(
                                      "${dic['v3.loan.currentCollateral']}:",
                                      "${Fmt.priceFloorBigIntFormatter(_editorLoan!.collaterals, _editorLoan!.token!.decimals!)} ${PluginFmt.tokenView(_editorLoan!.token!.symbol)}",
                                      labelStyle: textStyle,
                                      contentStyle: textStyle,
                                    ),
                                    InfoItemRow(
                                      "${dic['v3.loan.currentMinted']}:",
                                      "${Fmt.priceFloorBigIntFormatter(_editorLoan!.debits, balancePair[1]!.decimals!, lengthMax: 4)} ${PluginFmt.tokenView(karura_stable_coin)}",
                                      labelStyle: textStyle,
                                      contentStyle: textStyle,
                                    ),
                                    InfoItemRow(
                                      "${dic['v3.loan.newloanRatio']}:",
                                      "${Fmt.ratio(debitRatio)}",
                                      labelStyle: textStyle,
                                      contentStyle: textStyle,
                                    ),
                                    InfoItemRow(
                                      "${dic['v3.loan.newLiquidationPrice']}:",
                                      "\$ ${Fmt.priceFloorBigInt(_editorLoan!.liquidationPrice, acala_price_decimals)}",
                                      labelStyle: textStyle,
                                      contentStyle: textStyle,
                                    ),
                                  ],
                                )),
                          ),
                        ),
                        Padding(
                            padding: EdgeInsets.only(top: 37, bottom: 38),
                            child: PluginButton(
                              title: '${dic['v3.loan.submit']}',
                              onPressed: () {
                                if (_error1 == null && _error2 == null) {
                                  _onSubmit();
                                }
                              },
                            )),
                      ],
                    ))));
  }

  Widget buildLastInputView() {
    if (_editorLoan == null) {
      return Container();
    }
    var titleTag = '';
    String seleteRadioTest = '';
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    if (_tab == 0) {
      if (_type != 'collateral') {
        titleTag = dic['loan.deposit']!;
        seleteRadioTest = dic['v3.loan.depositMeanwhile']!;
      } else {
        titleTag = dic['loan.mint']!;
        seleteRadioTest = dic['v3.loan.mintMeanwhile']!;
      }
    } else {
      if (_type != 'collateral') {
        titleTag = dic['loan.withdraw']!;
        seleteRadioTest = dic['v3.loan.withdrawMeanwhile']!;
      } else {
        titleTag = dic['loan.payback']!;
        seleteRadioTest = dic['v3.loan.paybackMeanwhile']!;
      }
    }
    final banlance = getBalance(titleTag);

    final textStyle = Theme.of(context)
        .textTheme
        .headline5
        ?.copyWith(color: PluginColorsDark.headline1, fontSize: 14);
    return Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Column(
          children: [
            GestureDetector(
                onTap: () {
                  if (_selectRadio) {
                    _inputChage(titleTag, "0");
                  } else {
                    _inputChage(titleTag, _lastController.text);
                  }
                  setState(() {
                    _selectRadio = !_selectRadio;
                  });
                },
                child: Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Row(
                      children: [
                        PluginRadioButton(
                          value: _selectRadio,
                        ),
                        Padding(
                            padding: EdgeInsets.only(left: 5),
                            child: Text(
                              "$seleteRadioTest (${PluginFmt.tokenView(banlance.symbol)})",
                              style: textStyle,
                            )),
                      ],
                    ))),
            Visibility(
                visible: _selectRadio,
                child: Column(
                  children: [
                    Padding(
                        padding: EdgeInsets.only(top: 30),
                        child: PluginInputBalance(
                          key: Key("2"),
                          tokenViewFunction: (value) {
                            return PluginFmt.tokenView(value);
                          },
                          titleTag: titleTag,
                          inputCtrl: _lastController,
                          onSetMax: BigInt.parse(banlance.amount!) >
                                      BigInt.zero &&
                                  titleTag != dic['loan.mint']
                              ? (max) {
                                  var value = Fmt.bigIntToDouble(
                                          max, banlance.decimals!)
                                      .toString();
                                  var error = _validateAmount(
                                      value,
                                      banlance.amount!,
                                      banlance.decimals!,
                                      titleTag);
                                  setState(() {
                                    _lastController.text = value;
                                    _error2 = null;
                                  });
                                  if (error == null) {
                                    _inputChage(titleTag, _lastController.text);
                                  }
                                  if (titleTag == dic['loan.payback']!) {
                                    final withdrawBalance =
                                        getBalance(dic['loan.withdraw']!);
                                    var error = _validateAmount(
                                        _firstController.text,
                                        withdrawBalance.amount!,
                                        withdrawBalance.decimals!,
                                        dic['loan.withdraw']!);
                                    setState(() {
                                      _error1 = error;
                                    });
                                  } else if (titleTag == dic['loan.deposit']!) {
                                    final withdrawBalance =
                                        getBalance(dic['loan.mint']!);
                                    var error = _validateAmount(
                                        _firstController.text,
                                        withdrawBalance.amount!,
                                        withdrawBalance.decimals!,
                                        dic['loan.mint']!);
                                    setState(() {
                                      _error1 = error;
                                    });
                                  }
                                }
                              : null,
                          onClear: () {
                            setState(() {
                              _lastController.text = "";
                              _error2 = null;
                            });
                            _inputChage(titleTag, _lastController.text);
                            if (titleTag == dic['loan.payback']!) {
                              final withdrawBalance =
                                  getBalance(dic['loan.withdraw']!);
                              var error = _validateAmount(
                                  _firstController.text,
                                  withdrawBalance.amount!,
                                  withdrawBalance.decimals!,
                                  dic['loan.withdraw']!);
                              setState(() {
                                _error1 = error;
                              });
                            } else if (titleTag == dic['loan.deposit']!) {
                              final withdrawBalance =
                                  getBalance(dic['loan.mint']!);
                              var error = _validateAmount(
                                  _firstController.text,
                                  withdrawBalance.amount!,
                                  withdrawBalance.decimals!,
                                  dic['loan.mint']!);
                              setState(() {
                                _error1 = error;
                              });
                            }
                          },
                          onInputChange: (v) {
                            var error = _validateAmount(v, banlance.amount!,
                                banlance.decimals!, titleTag);
                            setState(() {
                              _error2 = error;
                            });
                            if (error == null) {
                              _inputChage(titleTag, _lastController.text);
                              if (titleTag == dic['loan.payback']!) {
                                final withdrawBalance =
                                    getBalance(dic['loan.withdraw']!);
                                var error = _validateAmount(
                                    _firstController.text,
                                    withdrawBalance.amount!,
                                    withdrawBalance.decimals!,
                                    dic['loan.withdraw']!);
                                setState(() {
                                  _error1 = error;
                                });
                              } else if (titleTag == dic['loan.deposit']!) {
                                final withdrawBalance =
                                    getBalance(dic['loan.mint']!);
                                var error = _validateAmount(
                                    _firstController.text,
                                    withdrawBalance.amount!,
                                    withdrawBalance.decimals!,
                                    dic['loan.mint']!);
                                setState(() {
                                  _error1 = error;
                                });
                              }
                            }
                          },
                          balance: banlance,
                          tokenIconsMap: widget.plugin.tokenIcons,
                        )),
                    ErrorMessage(_error2,
                        margin: EdgeInsets.symmetric(vertical: 2)),
                  ],
                ))
          ],
        ));
  }

  Widget buildFirstInputView() {
    if (_editorLoan == null) {
      return Container();
    }
    var titleTag = '';
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    if (_tab == 0) {
      if (_type == 'collateral') {
        titleTag = dic['loan.deposit']!;
      } else {
        titleTag = dic['loan.mint']!;
      }
    } else {
      if (_type == 'collateral') {
        titleTag = dic['loan.withdraw']!;
      } else {
        titleTag = dic['loan.payback']!;
      }
    }
    final banlance = getBalance(titleTag);
    return Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Column(
          children: [
            PluginInputBalance(
              key: Key("1"),
              tokenViewFunction: (value) {
                return PluginFmt.tokenView(value);
              },
              titleTag: titleTag,
              inputCtrl: _firstController,
              onSetMax: BigInt.parse(banlance.amount!) > BigInt.zero &&
                      titleTag != dic['loan.mint']
                  ? (max) {
                      var value = Fmt.bigIntToDouble(max, banlance.decimals!)
                          .toString();
                      var error = _validateAmount(value, banlance.amount!,
                          banlance.decimals!, titleTag);
                      setState(() {
                        _firstController.text = value;
                        _error1 = error;
                      });
                      if (error == null) {
                        _inputChage(titleTag, _firstController.text);
                      }
                      if (titleTag == dic['loan.payback']!) {
                        final withdrawBalance =
                            getBalance(dic['loan.withdraw']!);
                        var error = _validateAmount(
                            _lastController.text,
                            withdrawBalance.amount!,
                            withdrawBalance.decimals!,
                            dic['loan.withdraw']!);
                        setState(() {
                          _error2 = error;
                        });
                      } else if (titleTag == dic['loan.deposit']!) {
                        final withdrawBalance = getBalance(dic['loan.mint']!);
                        var error = _validateAmount(
                            _lastController.text,
                            withdrawBalance.amount!,
                            withdrawBalance.decimals!,
                            dic['loan.mint']!);
                        setState(() {
                          _error2 = error;
                        });
                      }
                    }
                  : null,
              onClear: () {
                setState(() {
                  _firstController.text = "";
                  _error1 = null;
                });
                _inputChage(titleTag, _firstController.text);
                if (titleTag == dic['loan.payback']!) {
                  final withdrawBalance = getBalance(dic['loan.withdraw']!);
                  var error = _validateAmount(
                      _lastController.text,
                      withdrawBalance.amount!,
                      withdrawBalance.decimals!,
                      dic['loan.withdraw']!);
                  setState(() {
                    _error2 = error;
                  });
                } else if (titleTag == dic['loan.deposit']!) {
                  final withdrawBalance = getBalance(dic['loan.mint']!);
                  var error = _validateAmount(
                      _lastController.text,
                      withdrawBalance.amount!,
                      withdrawBalance.decimals!,
                      dic['loan.mint']!);
                  setState(() {
                    _error2 = error;
                  });
                }
              },
              onInputChange: (v) {
                var error = _validateAmount(
                    v, banlance.amount!, banlance.decimals!, titleTag);
                setState(() {
                  _error1 = error;
                });
                if (error == null) {
                  _inputChage(titleTag, _firstController.text);
                  if (titleTag == dic['loan.payback']!) {
                    final withdrawBalance = getBalance(dic['loan.withdraw']!);
                    var error = _validateAmount(
                        _lastController.text,
                        withdrawBalance.amount!,
                        withdrawBalance.decimals!,
                        dic['loan.withdraw']!);
                    setState(() {
                      _error2 = error;
                    });
                  } else if (titleTag == dic['loan.deposit']!) {
                    final withdrawBalance = getBalance(dic['loan.mint']!);
                    var error = _validateAmount(
                        _lastController.text,
                        withdrawBalance.amount!,
                        withdrawBalance.decimals!,
                        dic['loan.mint']!);
                    setState(() {
                      _error2 = error;
                    });
                  }
                }
              },
              balance: banlance,
              tokenIconsMap: widget.plugin.tokenIcons,
            ),
            ErrorMessage(_error1, margin: EdgeInsets.symmetric(vertical: 2)),
          ],
        ));
  }

  TokenBalanceData getBalance(String titleTag) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    String symbol = '';
    int decimals = 12;
    String amount = '';
    final balancePair = AssetsUtils.getBalancePairFromTokenNameId(
        widget.plugin, [_editorLoan!.token!.tokenNameId, karura_stable_coin]);
    if (titleTag == dic['loan.payback']!) {
      symbol = karura_stable_coin;
      decimals = balancePair[1]?.decimals ?? 12;
      amount = (Fmt.balanceInt(balancePair[1]!.amount) -
                      Fmt.balanceInt(balancePair[1]!.minBalance) >
                  _loan!.debits
              ? _loan!.debits
              : Fmt.balanceInt(balancePair[1]!.amount) -
                          Fmt.balanceInt(balancePair[1]!.minBalance) >
                      BigInt.zero
                  ? Fmt.balanceInt(balancePair[1]!.amount) -
                      Fmt.balanceInt(balancePair[1]!.minBalance)
                  : BigInt.zero)
          .toString();
    } else if (titleTag == dic['loan.mint']!) {
      symbol = karura_stable_coin;
      decimals = balancePair[1]?.decimals ?? 12;
      amount = (_editorLoan!.maxToBorrow - _loan!.debits > BigInt.zero
              ? _editorLoan!.maxToBorrow - _loan!.debits
              : BigInt.zero)
          .toString();
    } else if (titleTag == dic['loan.deposit']!) {
      symbol = _editorLoan!.token!.symbol!;
      decimals = _editorLoan!.token?.decimals ?? 12;
      amount = balancePair[0]!.amount!;
    } else if (titleTag == dic['loan.withdraw']!) {
      symbol = _editorLoan!.token!.symbol!;
      decimals = _editorLoan!.token?.decimals ?? 12;
      amount =
          (_loan!.collaterals - _editorLoan!.requiredCollateral > BigInt.zero
                  ? _loan!.collaterals - _editorLoan!.requiredCollateral
                  : BigInt.zero)
              .toString();
    }
    return TokenBalanceData(symbol: symbol, decimals: decimals, amount: amount);
  }

  String? _validateAmount(
      String value, String max, int decimals, String titleTag) {
    // final assetDic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'common');
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala');

    String v = value.trim();
    if (v.length == 0) {
      return null;
    }
    final error = Fmt.validatePrice(v, context);
    if (error != null) {
      return error;
    }

    BigInt debits = Fmt.tokenInt(v, decimals);
    if (debits > BigInt.parse(max)) {
      return '${dic!['loan.max']} ${Fmt.priceFloorBigIntFormatter(BigInt.parse(max), decimals)}';
    }

    if (titleTag == dic!['loan.payback']! || titleTag == dic['loan.deposit']!) {
      final minimumDebitValue =
          Fmt.bigIntToDouble(_loan!.type.minimumDebitValue, decimals);
      final debits = titleTag == dic['loan.payback']!
          ? _loan!.debits - Fmt.tokenInt(v, decimals)
          : _loan!.debits + Fmt.tokenInt(v, decimals);
      if (debits > BigInt.zero && debits < _loan!.type.minimumDebitValue) {
        return '${dic['loan.warn1']}$minimumDebitValue ${PluginFmt.tokenView(karura_stable_coin)}';
      }
    }
    return null;
  }

  void _inputChage(String titleTag, String v) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    final balancePair = AssetsUtils.getBalancePairFromTokenNameId(
        widget.plugin, [_editorLoan!.token!.tokenNameId, karura_stable_coin]);
    if (titleTag == dic['loan.payback']!) {
      if (v == "0") {
        _valueChange(debits: _loan!.debits);
        return;
      }
      final debits = Fmt.tokenInt(v, balancePair[1]!.decimals!);
      _valueChange(debits: _loan!.debits - debits);
    } else if (titleTag == dic['loan.mint']!) {
      if (v == "0") {
        _valueChange(debits: _loan!.debits);
        return;
      }
      final debits = Fmt.tokenInt(v, balancePair[1]!.decimals!);
      _valueChange(debits: _loan!.debits + debits);
    } else if (titleTag == dic['loan.deposit']!) {
      if (v == "0") {
        _valueChange(collaterals: _loan!.collaterals);
        return;
      }
      final collaterals = Fmt.tokenInt(v, balancePair[0]!.decimals!);
      _valueChange(collaterals: _loan!.collaterals + collaterals);
    } else if (titleTag == dic['loan.withdraw']!) {
      if (v == "0") {
        _valueChange(collaterals: _loan!.collaterals);
        return;
      }
      final collaterals = Fmt.tokenInt(v, balancePair[0]!.decimals!);
      _valueChange(collaterals: _loan!.collaterals - collaterals);
    }
  }

  void _valueChange({BigInt? debits, BigInt? collaterals}) {
    final tokenPrice =
        widget.plugin.store!.assets.prices[_editorLoan!.token!.tokenNameId]!;
    final stableCoinDecimals = widget
        .plugin.store!.assets.tokenBalanceMap[karura_stable_coin]!.decimals!;
    final collateralDecimals = _editorLoan!.token!.decimals!;
    if (debits != null && debits != _editorLoan!.debits) {
      if (debits == _loan!.debits) {
        setState(() {
          _editorLoan!.debits = debits;
          _editorLoan!.debitShares = _loan!.debitShares;
          _editorLoan!.debitInUSD = _loan!.debitInUSD;
          _editorLoan!.collateralInUSD = _loan!.collateralInUSD;
          _editorLoan!.collateralRatio = _loan!.collateralRatio;
          _editorLoan!.requiredCollateral = _loan!.requiredCollateral;
          _editorLoan!.liquidationPrice = _loan!.liquidationPrice;
        });
        return;
      }
      setState(() {
        _editorLoan!.debits = debits;
        _editorLoan!.debitShares = _editorLoan!.type.debitToDebitShare(debits);
        _editorLoan!.debitInUSD = _editorLoan!.debits;
        _editorLoan!.collateralInUSD = _editorLoan!.type.tokenToUSD(
            _editorLoan!.collaterals, tokenPrice,
            stableCoinDecimals: stableCoinDecimals,
            collateralDecimals: collateralDecimals);
        _editorLoan!.collateralRatio = _editorLoan!.type.calcCollateralRatio(
            _editorLoan!.debitInUSD, _editorLoan!.collateralInUSD);
        _editorLoan!.requiredCollateral = _editorLoan!.type
            .calcRequiredCollateral(_editorLoan!.debitInUSD, tokenPrice,
                stableCoinDecimals: stableCoinDecimals,
                collateralDecimals: collateralDecimals);
        _editorLoan!.liquidationPrice = _editorLoan!.type.calcLiquidationPrice(
            _editorLoan!.debitInUSD, _editorLoan!.collaterals,
            stableCoinDecimals: stableCoinDecimals,
            collateralDecimals: collateralDecimals);
      });
    }

    if (collaterals != null && collaterals != _editorLoan!.collaterals) {
      if (debits == _loan!.collaterals) {
        setState(() {
          _editorLoan!.collaterals = collaterals;
          _editorLoan!.collateralInUSD = _loan!.collateralInUSD;
          _editorLoan!.maxToBorrow = _loan!.maxToBorrow;
          _editorLoan!.collateralRatio = _loan!.collateralRatio;
          _editorLoan!.liquidationPrice = _loan!.liquidationPrice;
        });
        return;
      }
      setState(() {
        _editorLoan!.collaterals = collaterals;
        _editorLoan!.collateralInUSD = _editorLoan!.type.tokenToUSD(
            _editorLoan!.collaterals, tokenPrice,
            stableCoinDecimals: stableCoinDecimals,
            collateralDecimals: collateralDecimals);
        _editorLoan!.maxToBorrow = _editorLoan!.type.calcMaxToBorrow(
            _editorLoan!.collaterals, tokenPrice,
            stableCoinDecimals: stableCoinDecimals,
            collateralDecimals: collateralDecimals);
        _editorLoan!.collateralRatio = _editorLoan!.type.calcCollateralRatio(
            _editorLoan!.debitInUSD, _editorLoan!.collateralInUSD);
        _editorLoan!.liquidationPrice = _editorLoan!.type.calcLiquidationPrice(
            _editorLoan!.debitInUSD, _editorLoan!.collaterals,
            stableCoinDecimals: stableCoinDecimals,
            collateralDecimals: collateralDecimals);
      });
    }
  }

  Future<void> _onSubmit() async {
    final params = await _getTxParams(_editorLoan!, _loan!);
    if (params == null) return null;

    final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
        arguments: TxConfirmParams(
          module: 'honzon',
          call: 'adjustLoan',
          txTitle: "adjust Vault",
          txDisplayBold: params['detail'],
          params: params['params'],
          isPlugin: true,
        ))) as Map?;
    if (res != null) {
      Navigator.of(context).pop(res);
    }
  }

  Future<Map?> _getTxParams(LoanData loan, LoanData originalLoan) async {
    final collaterals = loan.collaterals - originalLoan.collaterals;
    final debitShares = loan.debitShares - originalLoan.debitShares;
    final debits = loan.type.debitShareToDebit(debitShares);

    if (collaterals == BigInt.zero && debits == BigInt.zero) {
      return null;
    }

    if (loan.type.debitShareToDebit(loan.debitShares) == BigInt.zero &&
        loan.collaterals > BigInt.zero) {
      final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala');
      await showCupertinoDialog(
          context: context,
          builder: (_) {
            return CupertinoAlertDialog(
              content: Text(dic!['v3.loan.paybackMessage']!),
              actions: <Widget>[
                CupertinoDialogAction(
                  child: Text(dic['v3.loan.iUnderstand']!),
                  onPressed: () => Navigator.of(context).pop(false),
                )
              ],
            );
          });
    }

    final balancePair = AssetsUtils.getBalancePairFromTokenNameId(
        widget.plugin, [loan.token!.tokenNameId, karura_stable_coin]);
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala');
    final Map<String, Widget> detail = Map<String, Widget>();
    if (collaterals != BigInt.zero) {
      var dicValue = 'loan.deposit';
      if (collaterals < BigInt.zero) {
        dicValue = 'loan.withdraw';
      }
      detail[dic![dicValue]!] = Text(
        '${Fmt.priceFloorBigInt(collaterals.abs(), balancePair[0]!.decimals!, lengthMax: 4)} ${PluginFmt.tokenView(loan.token!.symbol)}',
        style: Theme.of(context)
            .textTheme
            .headline1
            ?.copyWith(color: Colors.white),
      );
    }

    BigInt debitSubtract = debitShares;
    if (debitShares != BigInt.zero) {
      var dicValue = 'loan.mint';
      if (originalLoan.debits == BigInt.zero &&
          debits <= loan.type.minimumDebitValue) {
        final minimumDebitValue = Fmt.bigIntToDouble(
            loan.type.minimumDebitValue, balancePair[1]!.decimals!);
        if (loan.maxToBorrow < loan.type.minimumDebitValue) {
          final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala');
          showCupertinoDialog(
              context: context,
              builder: (_) {
                return CupertinoAlertDialog(
                  content: Text(
                      "${dic!['v3.loan.errorMessage5']}$minimumDebitValue${dic['v3.loan.errorMessage6']}"),
                  actions: <Widget>[
                    CupertinoDialogAction(
                      child: Text(I18n.of(context)!.getDic(
                          i18n_full_dic_karura, 'common')!['upgrading.btn']!),
                      onPressed: () => Navigator.of(context).pop(false),
                    )
                  ],
                );
              });
          return null;
        }
        final bool canContinue = await (_confirmPaybackParams(
                '${dic!['loan.warn4']}$minimumDebitValue${dic['loan.warn5']}')
            as Future<bool>);
        if (!canContinue) return null;
        debitSubtract = loan.type.debitToDebitShare(
            (loan.type.minimumDebitValue + BigInt.from(10000)));
      }
      if (debitShares < BigInt.zero) {
        dicValue = 'loan.payback';

        // // pay less if less than 1 debit(aUSD) will be left,
        // // make sure tx success by leaving more than 1 debit(aUSD).
        // print(originalLoan.debits - debits.abs());
        // if (originalLoan.debits - debits.abs() > BigInt.zero &&
        //     originalLoan.debits - debits.abs() < loan.type.minimumDebitValue) {
        //   final minimumDebitValue = Fmt.bigIntToDouble(
        //       loan.type.minimumDebitValue, balancePair[1]!.decimals!);
        //   final bool canContinue = await (_confirmPaybackParams(
        //           '${dic!['loan.warn1']}$minimumDebitValue${dic['loan.warn2']}$minimumDebitValue${dic['loan.warn3']}')
        //       as Future<bool>);
        //   if (!canContinue) return null;
        //   debitSubtract = loan.type.debitToDebitShare(
        //       loan.type.minimumDebitValue - originalLoan.debits);
        // }

        final BigInt balanceStableCoin =
            Fmt.balanceInt(balancePair[1]!.amount) -
                Fmt.balanceInt(balancePair[1]!.minBalance);
        if (balanceStableCoin <=
            loan.type.debitShareToDebit(debitSubtract).abs()) {
          debitSubtract = balanceStableCoin -
              loan.type
                  .debitToDebitShare(balanceStableCoin ~/ BigInt.from(1000000));
        }
      }
      detail[dic![dicValue]!] = Text(
        '${Fmt.priceFloorBigInt(loan.type.debitShareToDebit(debitSubtract).abs(), balancePair[1]!.decimals!, lengthMax: 4)} ${PluginFmt.tokenView(karura_stable_coin)}',
        style: Theme.of(context)
            .textTheme
            .headline1
            ?.copyWith(color: Colors.white),
      );
    }

    return {
      'detail': detail,
      'params': [
        loan.token!.currencyId,
        collaterals != BigInt.zero ? collaterals.toString() : 0,
        debitSubtract.toString()
      ]
    };
  }

  Future<bool?> _confirmPaybackParams(String message) async {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    final bool? res = await showCupertinoDialog(
        context: context,
        builder: (_) {
          return CupertinoAlertDialog(
            content: Text(message),
            actions: <Widget>[
              CupertinoDialogAction(
                child: Text(dic['loan.warn.back']!),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              CupertinoDialogAction(
                child: Text(I18n.of(context)!
                    .getDic(i18n_full_dic_karura, 'common')!['ok']!),
                onPressed: () => Navigator.of(context).pop(true),
              )
            ],
          );
        });
    return res;
  }
}
