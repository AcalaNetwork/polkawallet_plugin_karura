import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:polkawallet_plugin_karura/api/types/loanType.dart';
import 'package:polkawallet_plugin_karura/common/constants/base.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/pages/loan/loanInfoPanel.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';

class LoanAdjustPage extends StatefulWidget {
  LoanAdjustPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/karura/loan/adjust';
  static const String actionTypeMint = 'mint';
  static const String actionTypePayback = 'payback';
  static const String actionTypeDeposit = 'deposit';
  static const String actionTypeWithdraw = 'withdraw';

  @override
  _LoanAdjustPageState createState() => _LoanAdjustPageState();
}

class LoanAdjustPageParams {
  LoanAdjustPageParams(this.actionType, this.token);
  final String actionType;
  final String token;
}

class _LoanAdjustPageState extends State<LoanAdjustPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _amountCtrl = new TextEditingController();
  final TextEditingController _amountCtrl2 = new TextEditingController();

  BigInt _amountCollateral = BigInt.zero;
  BigInt _amountDebit = BigInt.zero;

  double _currentRatio = 0;
  BigInt _liquidationPrice = BigInt.zero;

  bool _autoValidate = false;
  bool _paybackAndCloseChecked = false;

  void _updateState(LoanType loanType, BigInt collateral, BigInt debit,
      int stableCoinDecimals, int collateralDecimals) {
    final LoanAdjustPageParams params =
        ModalRoute.of(context).settings.arguments;

    final tokenPrice = widget.plugin.store.assets.prices[params.token];
    final collateralInUSD = loanType.tokenToUSD(collateral, tokenPrice,
        collateralDecimals: collateralDecimals,
        stableCoinDecimals: stableCoinDecimals);
    final debitInUSD = debit;
    setState(() {
      _liquidationPrice = loanType.calcLiquidationPrice(debitInUSD, collateral,
          collateralDecimals: collateralDecimals,
          stableCoinDecimals: stableCoinDecimals);
      _currentRatio = loanType.calcCollateralRatio(debitInUSD, collateralInUSD);
    });
  }

  Map _calcTotalAmount(BigInt collateral, BigInt debit) {
    final LoanAdjustPageParams params =
        ModalRoute.of(context).settings.arguments;
    var collateralTotal = collateral;
    var debitTotal = debit;
    final loan = widget.plugin.store.loan.loans[params.token];
    switch (params.actionType) {
      case LoanAdjustPage.actionTypeDeposit:
        collateralTotal = loan.collaterals + collateral;
        break;
      case LoanAdjustPage.actionTypeWithdraw:
        collateralTotal = loan.collaterals - collateral;
        break;
      case LoanAdjustPage.actionTypeMint:
        debitTotal = loan.debits + debit;
        break;
      case LoanAdjustPage.actionTypePayback:
        debitTotal = loan.debits - debit;
        break;
      default:
      // do nothing
    }

    return {
      'collateral': collateralTotal,
      'debit': debitTotal,
    };
  }

  void _onAmount1Change(
    String value,
    LoanType loanType,
    BigInt price,
    int stableCoinDecimals,
    int collateralDecimals, {
    BigInt max,
  }) {
    String v = value.trim();
    if (v.isEmpty) return;

    BigInt collateral = max != null ? max : Fmt.tokenInt(v, collateralDecimals);
    setState(() {
      _amountCollateral = collateral;
    });

    Map amountTotal = _calcTotalAmount(collateral, _amountDebit);
    _updateState(loanType, amountTotal['collateral'], amountTotal['debit'],
        stableCoinDecimals, collateralDecimals);

    _checkAutoValidate();
  }

  void _onAmount2Change(
    String value,
    LoanType loanType,
    BigInt stableCoinPrice,
    int stableCoinDecimals,
    int collateralDecimals,
    bool showCheckbox, {
    BigInt debits,
  }) {
    String v = value.trim();
    if (v.isEmpty) return;

    BigInt debitsNew = debits ?? Fmt.tokenInt(v, stableCoinDecimals);

    setState(() {
      _amountDebit = debitsNew;
    });
    if (!showCheckbox && _paybackAndCloseChecked) {
      setState(() {
        _paybackAndCloseChecked = false;
      });
    }

    Map amountTotal = _calcTotalAmount(_amountCollateral, debitsNew);
    _updateState(loanType, amountTotal['collateral'], amountTotal['debit'],
        stableCoinDecimals, collateralDecimals);

    _checkAutoValidate();
  }

  void _checkAutoValidate({String value1, String value2}) {
    if (_autoValidate) return;
    if (value1 == null) {
      value1 = _amountCtrl.text.trim();
    }
    if (value2 == null) {
      value2 = _amountCtrl2.text.trim();
    }
    if (value1.isNotEmpty || value2.isNotEmpty) {
      setState(() {
        _autoValidate = true;
      });
    }
  }

  String _validateAmount1(String value, BigInt available) {
    final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'common');

    final error = Fmt.validatePrice(value, context);
    if (error != null) {
      return error;
    }
    if (_amountCollateral > available) {
      return dic['amount.low'];
    }
    return null;
  }

  String _validateAmount2(String value, BigInt max, String maxToBorrowView,
      BigInt balanceAUSD, LoanData loan, int stableCoinDecimals) {
    final assetDic = I18n.of(context).getDic(i18n_full_dic_karura, 'common');
    final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');

    final error = Fmt.validatePrice(value, context);
    if (error != null) {
      return error;
    }
    final LoanAdjustPageParams params =
        ModalRoute.of(context).settings.arguments;
    if (params.actionType == LoanAdjustPage.actionTypeMint) {
      if (_amountDebit > max) {
        return '${dic['loan.max']} $maxToBorrowView';
      }
      if (loan.debits + _amountDebit < loan.type.minimumDebitValue) {
        return assetDic['min'] +
            ' ' +
            Fmt.bigIntToDouble(loan.type.minimumDebitValue, stableCoinDecimals)
                .toStringAsFixed(2);
      }
    }
    if (params.actionType == LoanAdjustPage.actionTypePayback) {
      if (_amountDebit > balanceAUSD) {
        String balance = Fmt.token(balanceAUSD, stableCoinDecimals);
        return '${assetDic['amount.low']}(${assetDic['balance']}: $balance)';
      }
      if (_amountDebit > loan.debits) {
        return '${dic['loan.max']} ${Fmt.priceFloorBigInt(loan.debits, stableCoinDecimals)}';
      }
      BigInt debitLeft = loan.debits - _amountDebit;
      if (debitLeft > BigInt.zero && debitLeft < loan.type.minimumDebitValue) {
        return dic['payback.small'] +
            ', ${assetDic['min']} ' +
            Fmt.bigIntToDouble(loan.type.minimumDebitValue, stableCoinDecimals)
                .toStringAsFixed(2);
      }
    }
    return null;
  }

  Future<bool> _confirmPaybackParams() async {
    final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');
    final bool res = await showCupertinoDialog(
        context: context,
        builder: (_) {
          return CupertinoAlertDialog(
            content: Text(dic[
                'loan.warn${widget.plugin.basic.name == plugin_name_karura ? '.KSM' : ''}']),
            actions: <Widget>[
              CupertinoDialogAction(
                child: Text(dic['loan.warn.back']),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              CupertinoDialogAction(
                child: Text(I18n.of(context)
                    .getDic(i18n_full_dic_karura, 'common')['ok']),
                onPressed: () => Navigator.of(context).pop(true),
              )
            ],
          );
        });
    return res;
  }

  Future<Map> _getTxParams(LoanData loan, int stableCoinDecimals) async {
    final LoanAdjustPageParams params =
        ModalRoute.of(context).settings.arguments;
    switch (params.actionType) {
      case LoanAdjustPage.actionTypeMint:
        // borrow min debit value if user's debit is empty
        final debitAdd = loan.type.debitToDebitShare(
            loan.debits == BigInt.zero &&
                    _amountDebit <= loan.type.minimumDebitValue
                ? (loan.type.minimumDebitValue + BigInt.from(10000))
                : _amountDebit);
        return {
          'detail': {
            "amount": _amountCtrl2.text.trim(),
          },
          'params': [
            {'token': params.token},
            0,
            debitAdd.toString(),
          ]
        };
      case LoanAdjustPage.actionTypePayback:
        // payback all debts if user input more than debts
        BigInt debitSubtract = _amountDebit >= loan.debits
            ? loan.debitShares
            : loan.type.debitToDebitShare(_amountDebit);

        // pay less if less than 1 debit(aUSD) will be left,
        // make sure tx success by leaving more than 1 debit(aUSD).
        final debitValueOne = Fmt.tokenInt('1', stableCoinDecimals);
        if (loan.debits - _amountDebit > BigInt.zero &&
            loan.debits - _amountDebit < debitValueOne) {
          final bool canContinue = await _confirmPaybackParams();
          if (!canContinue) return null;
          debitSubtract =
              loan.debitShares - loan.type.debitToDebitShare(debitValueOne);
        }
        return {
          'detail': {
            "amount": _amountCtrl2.text.trim(),
          },
          'params': [
            {'token': params.token},
            _paybackAndCloseChecked
                ? (BigInt.zero - loan.collaterals).toString()
                : 0,
            (BigInt.zero - debitSubtract).toString(),
          ]
        };
      case LoanAdjustPage.actionTypeDeposit:
        return {
          'detail': {
            "amount":
                _amountCtrl.text.trim() + ' ' + PluginFmt.tokenView(loan.token),
          },
          'params': [
            {'token': params.token},
            _amountCollateral.toString(),
            0,
          ]
        };
      case LoanAdjustPage.actionTypeWithdraw:
        return {
          'detail': {
            "amount":
                _amountCtrl.text.trim() + ' ' + PluginFmt.tokenView(loan.token),
          },
          'params': [
            {'token': params.token},
            (BigInt.zero - _amountCollateral).toString(),
            0,
          ]
        };
      default:
        return {};
    }
  }

  Future<void> _onSubmit(
      String title, LoanData loan, int stableCoinDecimals) async {
    final params = await _getTxParams(loan, stableCoinDecimals);
    if (params == null) return null;

    final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
        arguments: TxConfirmParams(
          module: 'honzon',
          call: 'adjustLoan',
          txTitle: title,
          txDisplay: params['detail'],
          params: params['params'],
        ))) as Map;
    if (res != null) {
      Navigator.of(context).pop(res);
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final symbols = widget.plugin.networkState.tokenSymbol;
      final decimals = widget.plugin.networkState.tokenDecimals;

      final stableCoinDecimals = decimals[symbols.indexOf(karura_stable_coin)];

      final LoanAdjustPageParams params =
          ModalRoute.of(context).settings.arguments;

      final loan = widget.plugin.store.loan.loans[params.token];
      setState(() {
        _amountCollateral = loan.collaterals;
        _amountDebit = loan.debits;
      });
      _updateState(loan.type, loan.collaterals, loan.debits, stableCoinDecimals,
          decimals[symbols.indexOf(params.token)]);
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _amountCtrl2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var dic = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');
    var assetDic = I18n.of(context).getDic(i18n_full_dic_karura, 'common');

    final LoanAdjustPageParams params =
        ModalRoute.of(context).settings.arguments;
    final symbol = params.token;
    final balancePair =
        PluginFmt.getBalancePair(widget.plugin, [symbol, karura_stable_coin]);

    final loan = widget.plugin.store.loan.loans[symbol];

    final price = widget.plugin.store.assets.prices[symbol];
    final stableCoinPrice = Fmt.tokenInt('1', balancePair[1].decimals);

    final symbolView = PluginFmt.tokenView(symbol);
    final stableCoinView = karura_stable_coin_view;
    String titleSuffix = ' $symbolView';
    bool showCollateral = true;
    bool showDebit = true;

    final BigInt balanceStableCoin = Fmt.balanceInt(balancePair[1].amount);
    final BigInt balance = Fmt.balanceInt(balancePair[0].amount);
    BigInt available = balance;
    BigInt maxToBorrow = loan.maxToBorrow - loan.debits;
    String maxToBorrowView =
        Fmt.priceFloorBigInt(maxToBorrow, balancePair[1].decimals);

    switch (params.actionType) {
      case LoanAdjustPage.actionTypeMint:
        maxToBorrow = maxToBorrow > BigInt.zero ? maxToBorrow : BigInt.zero;
        maxToBorrowView =
            Fmt.priceFloorBigInt(maxToBorrow, balancePair[1].decimals);
        showCollateral = false;
        titleSuffix = ' $stableCoinView';
        break;
      case LoanAdjustPage.actionTypePayback:
        // max to payback
        maxToBorrow = balanceStableCoin > loan.debits
            ? loan.debits
            : (balanceStableCoin - BigInt.from(100000000000));
        maxToBorrowView = balanceStableCoin > loan.debits
            ? Fmt.priceCeilBigInt(maxToBorrow, balancePair[1].decimals)
            : Fmt.priceFloorBigInt(maxToBorrow, balancePair[1].decimals);
        showCollateral = false;
        titleSuffix = ' $stableCoinView';
        break;
      case LoanAdjustPage.actionTypeDeposit:
        showDebit = false;
        break;
      case LoanAdjustPage.actionTypeWithdraw:
        // max to withdraw
        available = loan.collaterals - loan.requiredCollateral > BigInt.zero
            ? loan.collaterals - loan.requiredCollateral
            : BigInt.zero;
        showDebit = false;
        break;
      default:
    }

    final availableView =
        Fmt.priceFloorBigInt(available, balancePair[0].decimals, lengthMax: 8);
    final debitsView =
        Fmt.priceCeilBigInt(loan.debits, balancePair[1].decimals);
    final collateralView =
        Fmt.priceFloorBigInt(loan.collaterals, balancePair[0].decimals);

    final pageTitle = '${dic['loan.${params.actionType}']}$titleSuffix';

    final showCheckbox =
        params.actionType == LoanAdjustPage.actionTypePayback &&
            _amountCtrl2.text.trim().isNotEmpty &&
            _amountDebit == loan.debits;

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
        centerTitle: true,
      ),
      body: Builder(builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: Form(
                  key: _formKey,
                  autovalidateMode: _autoValidate
                      ? AutovalidateMode.always
                      : AutovalidateMode.disabled,
                  child: ListView(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: LoanInfoPanel(
                          debits: '$debitsView $stableCoinView',
                          collateral: '$collateralView $symbolView',
                          price: price,
                          liquidationRatio: loan.type.liquidationRatio,
                          requiredRatio: loan.type.requiredCollateralRatio,
                          currentRatio: _currentRatio,
                          liquidationPrice: _liquidationPrice,
                        ),
                      ),
                      Visibility(
                          visible: showCollateral,
                          child: Padding(
                            padding: EdgeInsets.only(left: 16, right: 16),
                            child: TextFormField(
                              decoration: InputDecoration(
                                hintText: assetDic['amount'],
                                labelText:
                                    '${assetDic['amount']} (${assetDic['amount.available']}: $availableView $symbolView)',
                                suffix: loan.token !=
                                            widget.plugin.networkState
                                                .tokenSymbol[0] &&
                                        (params.actionType ==
                                                LoanAdjustPage
                                                    .actionTypeDeposit ||
                                            loan.debits == BigInt.zero)
                                    ? GestureDetector(
                                        child: Text(
                                          dic['loan.max'],
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .primaryColor),
                                        ),
                                        onTap: () async {
                                          setState(() {
                                            _amountCollateral = available;
                                            _amountCtrl.text =
                                                Fmt.bigIntToDouble(available,
                                                        balancePair[0].decimals)
                                                    .toString();
                                          });
                                          _onAmount1Change(
                                            availableView,
                                            loan.type,
                                            price,
                                            balancePair[1].decimals,
                                            balancePair[0].decimals,
                                            max: available,
                                          );
                                        },
                                      )
                                    : null,
                              ),
                              inputFormatters: [
                                UI.decimalInputFormatter(
                                    balancePair[0].decimals)
                              ],
                              controller: _amountCtrl,
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              validator: (v) => _validateAmount1(v, available),
                              onChanged: (v) => _onAmount1Change(
                                v,
                                loan.type,
                                price,
                                balancePair[1].decimals,
                                balancePair[0].decimals,
                              ),
                            ),
                          )),
                      Visibility(
                          visible: showDebit,
                          child: Padding(
                            padding: EdgeInsets.only(left: 16, right: 16),
                            child: TextFormField(
                              decoration: InputDecoration(
                                hintText: assetDic['amount'],
                                labelText:
                                    '${assetDic['amount']}(${dic['loan.max']}: $maxToBorrowView)',
                                suffix: params.actionType ==
                                        LoanAdjustPage.actionTypePayback
                                    ? GestureDetector(
                                        child: Text(
                                          dic['loan.max'],
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .primaryColor),
                                        ),
                                        onTap: () async {
                                          double max = NumberFormat(",##0.00")
                                              .parse(maxToBorrowView);
                                          setState(() {
                                            _amountDebit = maxToBorrow;
                                            _amountCtrl2.text = max.toString();
                                          });
                                          _onAmount2Change(
                                            maxToBorrowView,
                                            loan.type,
                                            stableCoinPrice,
                                            balancePair[1].decimals,
                                            balancePair[0].decimals,
                                            showCheckbox,
                                            debits: maxToBorrow,
                                          );
                                        },
                                      )
                                    : null,
                              ),
                              inputFormatters: [
                                UI.decimalInputFormatter(
                                    balancePair[1].decimals)
                              ],
                              controller: _amountCtrl2,
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              validator: (v) => _validateAmount2(
                                  v,
                                  maxToBorrow,
                                  maxToBorrowView,
                                  balanceStableCoin,
                                  loan,
                                  balancePair[1].decimals),
                              onChanged: (v) => _onAmount2Change(
                                  v,
                                  loan.type,
                                  stableCoinPrice,
                                  balancePair[1].decimals,
                                  balancePair[0].decimals,
                                  showCheckbox),
                            ),
                          )),
                      Visibility(
                          visible: showCheckbox,
                          child: Row(
                            children: <Widget>[
                              Checkbox(
                                value: _paybackAndCloseChecked,
                                onChanged: (v) {
                                  setState(() {
                                    _paybackAndCloseChecked = v;
                                  });
                                },
                              ),
                              GestureDetector(
                                child: Text(dic['loan.withdraw.all']),
                                onTap: () {
                                  setState(() {
                                    _paybackAndCloseChecked =
                                        !_paybackAndCloseChecked;
                                  });
                                },
                              )
                            ],
                          )),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: RoundedButton(
                  text: I18n.of(context)
                      .getDic(i18n_full_dic_ui, 'common')['tx.submit'],
                  onPressed: () {
                    if (_formKey.currentState.validate()) {
                      _onSubmit(pageTitle, loan, balancePair[1].decimals);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
