import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/api/types/loanType.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/pages/loanNew/loanInfoPanel.dart';
import 'package:polkawallet_plugin_karura/pages/swapNew/bootstrapPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/components/v3/infoItemRow.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginInputBalance.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/utils/format.dart';

class LoanCreatePage extends StatefulWidget {
  LoanCreatePage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/karura/loan/create';

  @override
  _LoanCreatePageState createState() => _LoanCreatePageState();
}

class _LoanCreatePageState extends State<LoanCreatePage> {
  final TextEditingController _amountCtrl = new TextEditingController();
  final TextEditingController _amountCtrl2 = new TextEditingController();

  TokenBalanceData? _token;

  BigInt _amountCollateral = BigInt.zero;
  BigInt _amountDebit = BigInt.zero;

  BigInt _maxToBorrow = BigInt.zero;
  double _currentRatio = 0;
  BigInt _liquidationPrice = BigInt.zero;

  bool _autoValidate = false;

  String? _error1;
  String? _error2;

  void _updateState(LoanType loanType, BigInt collateral, BigInt debit,
      {required int stableCoinDecimals, required int collateralDecimals}) {
    final tokenPrice =
        widget.plugin.store!.assets.prices[_token!.tokenNameId] ?? BigInt.zero;
    final collateralInUSD = loanType.tokenToUSD(collateral, tokenPrice,
        stableCoinDecimals: stableCoinDecimals,
        collateralDecimals: collateralDecimals);
    final debitInUSD = debit;
    setState(() {
      _liquidationPrice = loanType.calcLiquidationPrice(debitInUSD, collateral,
          stableCoinDecimals: stableCoinDecimals,
          collateralDecimals: collateralDecimals);
      _currentRatio = loanType.calcCollateralRatio(debitInUSD, collateralInUSD);
    });
  }

  void _onAmount1Change(
      String value, LoanType loanType, BigInt? price, BigInt available,
      {int? stableCoinDecimals, int? collateralDecimals}) {
    String v = value.trim();

    var error = _validateAmount1(value, available, collateralDecimals);
    setState(() {
      _error1 = error;
    });
    if (error != null) {
      return;
    }

    BigInt collateral = Fmt.tokenInt(v, collateralDecimals!);
    setState(() {
      _amountCollateral = collateral;
      _maxToBorrow = loanType.calcMaxToBorrow(collateral, price,
          stableCoinDecimals: stableCoinDecimals,
          collateralDecimals: collateralDecimals);
    });

    error = _validateAmount2(
        _amountCtrl2.text,
        loanType,
        Fmt.priceFloorBigInt(_maxToBorrow, stableCoinDecimals!),
        stableCoinDecimals);
    setState(() {
      _error2 = error;
    });

    if (v.isEmpty) return;

    if (_amountDebit > BigInt.zero) {
      _updateState(loanType, collateral, _amountDebit,
          stableCoinDecimals: stableCoinDecimals,
          collateralDecimals: collateralDecimals);
    }

    _checkAutoValidate();
  }

  void _onAmount2Change(String value, LoanType loanType,
      int? stableCoinDecimals, int? collateralDecimals) {
    String v = value.trim();
    if (v.isEmpty) return;
    final error = _validateAmount2(
        value,
        loanType,
        Fmt.priceFloorBigInt(_maxToBorrow, stableCoinDecimals!),
        stableCoinDecimals);
    setState(() {
      _error2 = error;
    });
    if (error != null) {
      return;
    }

    BigInt debits = Fmt.tokenInt(v, stableCoinDecimals);

    setState(() {
      _amountDebit = debits;
    });

    if (_amountCollateral > BigInt.zero) {
      _updateState(loanType, _amountCollateral, debits,
          stableCoinDecimals: stableCoinDecimals,
          collateralDecimals: collateralDecimals!);
    }

    _checkAutoValidate();
  }

  void _checkAutoValidate({String? value1, String? value2}) {
    if (_autoValidate) return;
    if (value1 == null) {
      value1 = _amountCtrl.text.trim();
    }
    if (value2 == null) {
      value2 = _amountCtrl2.text.trim();
    }
    if (value1.isNotEmpty && value2.isNotEmpty) {
      setState(() {
        _autoValidate = true;
      });
    }
  }

  String? _validateAmount1(
      String value, BigInt available, int? collateralDecimals) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'common');

    String v = value.trim();
    final error = Fmt.validatePrice(v, context);
    if (error != null) {
      return error;
    }
    BigInt collateral = Fmt.tokenInt(v, collateralDecimals!);
    if (collateral > available) {
      return dic!['amount.low'];
    }
    return null;
  }

  String? _validateAmount2(
      String value, LoanType loanType, String max, int? stableCoinDecimals) {
    final assetDic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'common');
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala');

    String v = value.trim();
    final error = Fmt.validatePrice(v, context);
    if (error != null) {
      return error;
    }

    final input = double.parse(v);
    final min =
        Fmt.bigIntToDouble(loanType.minimumDebitValue, stableCoinDecimals!);

    if (input < min) {
      return '${assetDic!['min']} ${min.toStringAsFixed(2)}';
    }
    BigInt debits = Fmt.tokenInt(v, stableCoinDecimals);
    if (debits >= _maxToBorrow) {
      return '${dic!['loan.max']} $max';
    }
    return null;
  }

  Map _getTxParams(LoanType loanType,
      {required int stableCoinDecimals, required int collateralDecimals}) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    final debit = _amountDebit <= loanType.minimumDebitValue
        ? (loanType.minimumDebitValue + BigInt.from(10000))
        : _amountDebit;
    return {
      'detail': {
        dic['loan.collateral']: Text(
          '${Fmt.token(_amountCollateral, collateralDecimals)} ${PluginFmt.tokenView(_token!.symbol)}',
          style: Theme.of(context)
              .textTheme
              .headline1
              ?.copyWith(color: PluginColorsDark.headline1),
        ),
        dic['loan.mint']: Text(
          '${Fmt.token(_amountDebit, stableCoinDecimals)} $karura_stable_coin_view',
          style: Theme.of(context)
              .textTheme
              .headline1
              ?.copyWith(color: PluginColorsDark.headline1),
        ),
      },
      'params': [
        _token!.currencyId,
        _amountCollateral.toString(),
        debit.toString(),
      ]
    };
  }

  List<TokenBalanceData?> _getTokenOptions({bool all = false}) {
    final tokenOptions =
        widget.plugin.store!.loan.loanTypes.map((e) => e.token).toList();
    if (all) return tokenOptions;

    final loans = widget.plugin.store!.loan.loans.values.toList();
    loans.retainWhere(
        (loan) => loan.debits > BigInt.zero || loan.collaterals > BigInt.zero);

    tokenOptions
        .retainWhere((e) => loans.map((i) => i.token).toList().indexOf(e) < 0);
    return tokenOptions;
  }

  Future<void> _onSubmit(String pageTitle, LoanType loanType,
      {required int stableCoinDecimals,
      required int collateralDecimals}) async {
    final token = _token ?? widget.plugin.store!.loan.loanTypes[0].token!;
    final balancePair = AssetsUtils.getBalancePairFromTokenNameId(
        widget.plugin, [token.tokenNameId, karura_stable_coin]);
    var error = _validateAmount1(_amountCtrl.text,
        Fmt.balanceInt(balancePair[0].amount), collateralDecimals);
    setState(() {
      _error1 = error;
    });
    error = _validateAmount2(
        _amountCtrl2.text,
        loanType,
        Fmt.priceFloorBigInt(_maxToBorrow, stableCoinDecimals),
        stableCoinDecimals);
    setState(() {
      _error2 = error;
    });
    if (error != null) {
      return;
    }
    final params = _getTxParams(loanType,
        stableCoinDecimals: stableCoinDecimals,
        collateralDecimals: collateralDecimals);
    final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
        arguments: TxConfirmParams(
          module: 'honzon',
          call: 'adjustLoanByDebitValue',
          txTitle: pageTitle,
          txDisplayBold: params['detail'],
          params: params['params'],
          isPlugin: true,
        ))) as Map?;
    if (res != null) {
      Navigator.of(context).pop(res);
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      final token =
          ModalRoute.of(context)?.settings.arguments as TokenBalanceData?;
      if (token != null) {
        setState(() {
          _token = token;
        });
      } else {
        final tokenOptions = _getTokenOptions();
        setState(() {
          _token = tokenOptions[0];
        });
      }
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
    return Observer(builder: (_) {
      final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
      final assetDic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'common');

      final token = _token ?? widget.plugin.store!.loan.loanTypes[0].token!;

      final balancePair = AssetsUtils.getBalancePairFromTokenNameId(
          widget.plugin, [token.tokenNameId, karura_stable_coin]);

      final pageTitle =
          '${dic['loan.create']} ${PluginFmt.tokenView(token.symbol)}';

      final price = widget.plugin.store!.assets.prices[token.tokenNameId];

      final loanType = widget.plugin.store!.loan.loanTypes
          .firstWhere((i) => i.token!.tokenNameId == token.tokenNameId);
      final balance = Fmt.balanceInt(balancePair[0].amount);
      final available = balance;

      final maxToBorrow =
          Fmt.priceFloorBigInt(_maxToBorrow, balancePair[1].decimals!);

      return PluginScaffold(
        appBar: PluginAppBar(title: Text(pageTitle), centerTitle: true),
        body: Builder(builder: (BuildContext context) {
          return SafeArea(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: <Widget>[
                PluginInputBalance(
                  tokenViewFunction: (value) {
                    return PluginFmt.tokenView(value);
                  },
                  inputCtrl: _amountCtrl,
                  margin: EdgeInsets.only(bottom: 2),
                  titleTag: dic['loan.collateral'],
                  onInputChange: (v) => _onAmount1Change(
                      v, loanType, price, available,
                      stableCoinDecimals: balancePair[1].decimals,
                      collateralDecimals: balancePair[0].decimals),
                  balance: token,
                  tokenIconsMap: widget.plugin.tokenIcons,
                  onClear: () {
                    _amountCtrl.text = '';
                    var error = _validateAmount2(
                        _amountCtrl2.text,
                        loanType,
                        Fmt.priceFloorBigInt(
                            _maxToBorrow, balancePair[1].decimals!),
                        balancePair[1].decimals);
                    setState(() {
                      _error2 = error;
                      _amountCollateral = BigInt.zero;
                      _maxToBorrow = BigInt.zero;
                    });
                  },
                ),
                ErrorMessage(_error1,
                    margin: EdgeInsets.symmetric(vertical: 2)),
                PluginInputBalance(
                  tokenViewFunction: (value) {
                    return PluginFmt.tokenView(value);
                  },
                  inputCtrl: _amountCtrl2,
                  tokenBgColor: Colors.white,
                  margin: EdgeInsets.only(bottom: 2, top: 24),
                  titleTag: assetDic!['amount'],
                  onInputChange: (v) => _onAmount2Change(v, loanType,
                      balancePair[1].decimals, balancePair[0].decimals),
                  balance: TokenBalanceData(
                      symbol: karura_stable_coin_view,
                      decimals: balancePair[1].decimals!,
                      amount: _maxToBorrow.toString()),
                  tokenIconsMap: widget.plugin.tokenIcons,
                  onClear: () {
                    _amountCtrl2.text = '';
                    setState(() {
                      _amountDebit = BigInt.zero;
                    });
                  },
                ),
                ErrorMessage(_error2,
                    margin: EdgeInsets.symmetric(vertical: 2)),
                Padding(
                    padding: EdgeInsets.only(bottom: 5, top: 24),
                    child: InfoItemRow(
                      dic['v3.maxCanMint']!,
                      "$maxToBorrow $karura_stable_coin_view",
                      labelStyle: Theme.of(context)
                          .textTheme
                          .headline4
                          ?.copyWith(
                              color: Colors.white, fontWeight: FontWeight.w600),
                      contentStyle: Theme.of(context)
                          .textTheme
                          .headline4
                          ?.copyWith(
                              color: Colors.white, fontWeight: FontWeight.w400),
                    )),
                Padding(
                    padding: EdgeInsets.only(bottom: 5),
                    child: InfoItemRow(
                      dic['v3.minimumGenerate']!,
                      "${Fmt.priceCeilBigInt(loanType.minimumDebitValue, balancePair[1].decimals!)} $karura_stable_coin_view",
                      labelStyle: Theme.of(context)
                          .textTheme
                          .headline4
                          ?.copyWith(
                              color: Colors.white, fontWeight: FontWeight.w600),
                      contentStyle: Theme.of(context)
                          .textTheme
                          .headline4
                          ?.copyWith(
                              color: Colors.white, fontWeight: FontWeight.w400),
                    )),
                Padding(
                    padding: EdgeInsets.only(bottom: 23, top: 15),
                    child: Image.asset(
                        "packages/polkawallet_plugin_karura/assets/images/divider.png")),
                LoanInfoPanel(
                  price: price,
                  liquidationRatio: loanType.liquidationRatio,
                  requiredRatio: loanType.requiredCollateralRatio,
                  currentRatio: _currentRatio,
                  liquidationPrice: _liquidationPrice,
                  stableFeeYear: loanType.stableFeeYear,
                ),
                Padding(
                    padding: EdgeInsets.only(top: 37, bottom: 38),
                    child: PluginButton(
                      title: '${dic['v3.loan.submit']}',
                      onPressed: () {
                        if (_error1 == null && _error2 == null) {
                          _onSubmit(pageTitle, loanType,
                              stableCoinDecimals: balancePair[1].decimals!,
                              collateralDecimals: balancePair[0].decimals!);
                        }
                      },
                    )),
              ],
            ),
          );
        }),
      );
    });
  }
}
