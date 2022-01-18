import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/api/types/loanType.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/pages/currencySelectPage.dart';
import 'package:polkawallet_plugin_karura/pages/loan/loanDetailPage.dart';
import 'package:polkawallet_plugin_karura/pages/loan/loanInfoPanel.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';

class LoanCreatePage extends StatefulWidget {
  LoanCreatePage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/karura/loan/create';

  @override
  _LoanCreatePageState createState() => _LoanCreatePageState();
}

class _LoanCreatePageState extends State<LoanCreatePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _amountCtrl = new TextEditingController();
  final TextEditingController _amountCtrl2 = new TextEditingController();

  TokenBalanceData? _token;

  BigInt _amountCollateral = BigInt.zero;
  BigInt _amountDebit = BigInt.zero;

  BigInt _maxToBorrow = BigInt.zero;
  double _currentRatio = 0;
  BigInt _liquidationPrice = BigInt.zero;

  bool _autoValidate = false;

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

  void _onAmount1Change(String value, LoanType loanType, BigInt? price,
      {int? stableCoinDecimals, int? collateralDecimals}) {
    String v = value.trim();
    if (v.isEmpty) return;

    BigInt collateral = Fmt.tokenInt(v, collateralDecimals!);
    setState(() {
      _amountCollateral = collateral;
      _maxToBorrow = loanType.calcMaxToBorrow(collateral, price,
          stableCoinDecimals: stableCoinDecimals,
          collateralDecimals: collateralDecimals);
    });

    if (_amountDebit > BigInt.zero) {
      _updateState(loanType, collateral, _amountDebit,
          stableCoinDecimals: stableCoinDecimals!,
          collateralDecimals: collateralDecimals);
    }

    _checkAutoValidate();
  }

  void _onAmount2Change(String value, LoanType loanType,
      int? stableCoinDecimals, int? collateralDecimals) {
    String v = value.trim();
    if (v.isEmpty) return;

    BigInt debits = Fmt.tokenInt(v, stableCoinDecimals!);

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
    final debitShare = loanType.debitToDebitShare(
        _amountDebit <= loanType.minimumDebitValue
            ? (loanType.minimumDebitValue + BigInt.from(10000))
            : _amountDebit);
    return {
      'detail': {
        dic['loan.collateral']: Text(
          '${Fmt.token(_amountCollateral, collateralDecimals)} ${PluginFmt.tokenView(_token!.symbol)}',
          style: Theme.of(context).textTheme.headline1,
        ),
        dic['loan.mint']: Text(
          '${Fmt.token(_amountDebit, stableCoinDecimals)} $karura_stable_coin_view',
          style: Theme.of(context).textTheme.headline1,
        ),
      },
      'params': [
        _token!.currencyId,
        _amountCollateral.toString(),
        debitShare.toString(),
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
    final params = _getTxParams(loanType,
        stableCoinDecimals: stableCoinDecimals,
        collateralDecimals: collateralDecimals);
    final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
        arguments: TxConfirmParams(
          module: 'honzon',
          call: 'adjustLoan',
          txTitle: pageTitle,
          txDisplayBold: params['detail'],
          params: params['params'],
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
      final balance = Fmt.balanceInt(balancePair[0]!.amount);
      final available = balance;

      final balanceView = Fmt.priceFloorBigInt(
          available, balancePair[0]!.decimals!,
          lengthMax: 4);
      final maxToBorrow =
          Fmt.priceFloorBigInt(_maxToBorrow, balancePair[1]!.decimals!);

      return Scaffold(
        appBar: AppBar(
          title: Text(pageTitle),
          centerTitle: true,
          leading: BackBtn(),
        ),
        body: Builder(builder: (BuildContext context) {
          return SafeArea(
            child: Column(
              children: <Widget>[
                CurrencySelector(
                  tokenOptions: _getTokenOptions(all: true),
                  tokenIcons: widget.plugin.tokenIcons,
                  token: token,
                  price: widget.plugin.store!.assets.prices[token.tokenNameId],
                  onSelect: (res) {
                    if (res != null) {
                      final loan =
                          widget.plugin.store!.loan.loans[res.tokenNameId];
                      if ((loan?.debits ?? BigInt.zero) > BigInt.zero ||
                          ((loan?.collaterals ?? BigInt.zero) > BigInt.zero)) {
                        Navigator.of(context).popAndPushNamed(
                            LoanDetailPage.route,
                            arguments: loan);
                        return;
                      }
                      setState(() {
                        _token = res;
                      });
                    }
                  },
                ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _autoValidate
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    child: ListView(
                      padding: EdgeInsets.all(16),
                      children: <Widget>[
                        LoanInfoPanel(
                          price: price,
                          liquidationRatio: loanType.liquidationRatio,
                          requiredRatio: loanType.requiredCollateralRatio,
                          currentRatio: _currentRatio,
                          liquidationPrice: _liquidationPrice,
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Text(dic['loan.amount.collateral']!),
                        ),
                        TextFormField(
                          decoration: InputDecoration(
                            hintText: assetDic!['amount'],
                            labelText:
                                '${assetDic['amount']} (${assetDic['amount.available']}: $balanceView ${PluginFmt.tokenView(token.symbol)})',
                          ),
                          inputFormatters: [
                            UI.decimalInputFormatter(balancePair[0]!.decimals!)!
                          ],
                          controller: _amountCtrl,
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          validator: (v) => _validateAmount1(
                              v!, available, balancePair[0]!.decimals),
                          onChanged: (v) => _onAmount1Change(v, loanType, price,
                              stableCoinDecimals: balancePair[1]!.decimals,
                              collateralDecimals: balancePair[0]!.decimals),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Text(dic['loan.amount.debit']!),
                        ),
                        TextFormField(
                          decoration: InputDecoration(
                            hintText: assetDic['amount'],
                            labelText:
                                '${assetDic['amount']} (${dic['loan.max']}: $maxToBorrow $karura_stable_coin_view)',
                          ),
                          inputFormatters: [
                            UI.decimalInputFormatter(balancePair[1]!.decimals!)!
                          ],
                          controller: _amountCtrl2,
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          validator: (v) => _validateAmount2(v!, loanType,
                              maxToBorrow, balancePair[1]!.decimals),
                          onChanged: (v) => _onAmount2Change(
                              v,
                              loanType,
                              balancePair[1]!.decimals,
                              balancePair[0]!.decimals),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: RoundedButton(
                    text: I18n.of(context)!
                        .getDic(i18n_full_dic_ui, 'common')!['tx.submit'],
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _onSubmit(pageTitle, loanType,
                            stableCoinDecimals: balancePair[1]!.decimals!,
                            collateralDecimals: balancePair[0]!.decimals!);
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      );
    });
  }
}

class CurrencySelector extends StatelessWidget {
  CurrencySelector({
    this.tokenOptions,
    this.tokenIcons,
    this.token,
    this.price,
    this.onSelect,
  });
  final List<TokenBalanceData?>? tokenOptions;
  final Map<String, Widget>? tokenIcons;
  final TokenBalanceData? token;
  final BigInt? price;
  final Function(TokenBalanceData)? onSelect;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16.0, // has the effect of softening the shadow
            spreadRadius: 4.0, // has the effect of extending the shadow
            offset: Offset(
              2.0, // horizontal, move right 10
              2.0, // vertical, move down 10
            ),
          )
        ],
      ),
      child: ListTile(
        dense: true,
        leading: TokenIcon(token!.symbol!, tokenIcons!),
        title: Text(
          PluginFmt.tokenView(token!.symbol),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        subtitle: price != null
            ? Text(
                '\$${Fmt.token(price, acala_price_decimals)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).unselectedWidgetColor,
                ),
              )
            : null,
        trailing: Icon(Icons.arrow_forward_ios, size: 18),
        onTap: tokenOptions!.length > 0
            ? () async {
                final res = await Navigator.of(context).pushNamed(
                  CurrencySelectPage.route,
                  arguments: tokenOptions,
                );
                if (res != null) {
                  onSelect!(res as TokenBalanceData);
                }
              }
            : null,
      ),
    );
  }
}
