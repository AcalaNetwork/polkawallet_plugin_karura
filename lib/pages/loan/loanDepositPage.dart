import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_karura/api/types/loanType.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/pages/loan/loanCreatePage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';

class LoanDepositPage extends StatefulWidget {
  LoanDepositPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/karura/loan/deposit';
  static const String actionTypeDeposit = 'deposit';
  static const String actionTypeWithdraw = 'withdraw';

  @override
  _LoanDepositPageState createState() => _LoanDepositPageState();
}

class LoanDepositPageParams {
  LoanDepositPageParams(this.actionType, this.token);
  final String actionType;
  final TokenBalanceData token;
}

class _LoanDepositPageState extends State<LoanDepositPage> {
  final _formKey = GlobalKey<FormState>();

  TokenBalanceData _token;

  final TextEditingController _amountCtrl = new TextEditingController();

  BigInt _amountCollateral = BigInt.zero;

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

  Future<Map> _getTxParams(LoanData loan, int stableCoinDecimals) async {
    final LoanDepositPageParams params =
        ModalRoute.of(context).settings.arguments;
    final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');
    switch (params.actionType) {
      case LoanDepositPage.actionTypeDeposit:
        return {
          'detail': {
            dic['loan.deposit']: Text(
              '${_amountCtrl.text.trim()} ${PluginFmt.tokenView(loan.token.symbol)}',
              style: Theme.of(context).textTheme.headline1,
            ),
          },
          'params': [
            params.token.currencyId,
            _amountCollateral.toString(),
            0,
          ]
        };
      case LoanDepositPage.actionTypeWithdraw:
        return {
          'detail': {
            dic['loan.withdraw']: Text(
              '${_amountCtrl.text.trim()} ${PluginFmt.tokenView(loan.token.symbol)}',
              style: Theme.of(context).textTheme.headline1,
            ),
          },
          'params': [
            params.token.currencyId,
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
          txDisplayBold: params['detail'],
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
      final LoanDepositPageParams params =
          ModalRoute.of(context).settings.arguments;

      final loan = widget.plugin.store.loan.loans[params.token.tokenNameId];
      setState(() {
        _amountCollateral = loan.collaterals;
        _token = params.token;
      });
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var dic = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');
    var assetDic = I18n.of(context).getDic(i18n_full_dic_karura, 'common');

    final LoanDepositPageParams params =
        ModalRoute.of(context).settings.arguments;
    final token = _token ?? params.token;

    final balancePair = AssetsUtils.getBalancePairFromTokenNameId(
        widget.plugin, [token.tokenNameId, karura_stable_coin]);

    final tokenOptions =
        widget.plugin.store.loan.loanTypes.map((e) => e.token).toList();
    tokenOptions.retainWhere((e) {
      final incentive = widget.plugin.store.earn.incentives.loans;
      return incentive != null &&
          incentive[e] != null &&
          (incentive[e][0].amount ?? 0) > 0;
    });

    final loan = widget.plugin.store.loan.loans[token.tokenNameId];
    final price = widget.plugin.store.assets.prices[token.tokenNameId];

    final symbolView = PluginFmt.tokenView(token.symbol);
    String titleSuffix = ' $symbolView';

    final BigInt balance = Fmt.balanceInt(balancePair[0].amount);
    BigInt available = balance;

    if (params.actionType == LoanDepositPage.actionTypeWithdraw) {
      // max to withdraw
      available = loan.collaterals - loan.requiredCollateral > BigInt.zero
          ? loan.collaterals - loan.requiredCollateral
          : BigInt.zero;
    }

    final availableView =
        Fmt.priceFloorBigInt(available, balancePair[0].decimals, lengthMax: 8);

    final pageTitle = '${dic['loan.${params.actionType}']}$titleSuffix';

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
                tokenOptions: tokenOptions,
                tokenIcons: widget.plugin.tokenIcons,
                token: token,
                price: widget.plugin.store.assets.prices[token.tokenNameId],
                onSelect: (res) {
                  if (res != null && _token != res) {
                    setState(() {
                      _token = res;
                    });
                  }
                },
              ),
              Expanded(
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: ListView(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(top: 8, left: 16, right: 16),
                        child: TextFormField(
                          decoration: InputDecoration(
                            hintText: assetDic['amount'],
                            labelText:
                                '${assetDic['amount']} (${assetDic['amount.available']}: $availableView $symbolView)',
                            suffix: loan.token.symbol !=
                                        widget.plugin.networkState
                                            .tokenSymbol[0] &&
                                    (params.actionType ==
                                            LoanDepositPage.actionTypeDeposit ||
                                        loan.debits == BigInt.zero)
                                ? GestureDetector(
                                    child: Text(
                                      dic['loan.max'],
                                      style: TextStyle(
                                          color:
                                              Theme.of(context).primaryColor),
                                    ),
                                    onTap: () async {
                                      setState(() {
                                        _amountCollateral = available;
                                        _amountCtrl.text = Fmt.bigIntToDouble(
                                                available,
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
                            UI.decimalInputFormatter(balancePair[0].decimals)
                          ],
                          controller: _amountCtrl,
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          validator: (v) => _validateAmount1(v, available),
                          onChanged: (v) => _onAmount1Change(
                            v,
                            loan.type,
                            price,
                            balancePair[1].decimals,
                            balancePair[0].decimals,
                          ),
                        ),
                      ),
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
