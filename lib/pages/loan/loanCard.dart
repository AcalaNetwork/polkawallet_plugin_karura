import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_karura/api/types/loanType.dart';
import 'package:polkawallet_plugin_karura/pages/loan/loanAdjustPage.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/outlinedButtonSmall.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/tapTooltip.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/utils/format.dart';

class LoanDebtCard extends StatelessWidget {
  LoanDebtCard(
    this.loan,
    this.balance,
    this.stableCoinSymbol,
    this.stableCoinDecimals,
    this.collateralDecimals,
    this.tokenIcons,
  );
  final LoanData loan;
  final String balance;
  final String stableCoinSymbol;
  final int stableCoinDecimals;
  final int collateralDecimals;
  final Map<String, Widget> tokenIcons;
  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');
    return RoundedCard(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.only(bottom: 8),
                        child: Text(
                            '${dic['loan.borrowed']}(${PluginFmt.tokenView(stableCoinSymbol)})'),
                      ),
                      Row(children: [
                        Container(
                            margin: EdgeInsets.only(right: 8),
                            child: TokenIcon(stableCoinSymbol, tokenIcons)),
                        Text(
                            Fmt.priceCeilBigInt(
                                loan.debits, stableCoinDecimals),
                            style: TextStyle(
                              fontSize: 30,
                              letterSpacing: -0.8,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            )),
                      ]),
                      Container(
                        margin: EdgeInsets.only(top: 4),
                        child: Text(
                          '${I18n.of(context).getDic(i18n_full_dic_karura, 'common')['balance']}: $balance',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).unselectedWidgetColor,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(dic['collateral.interest']),
                    Container(
                      margin: EdgeInsets.only(top: 16, bottom: 24),
                      child: Text(Fmt.ratio(loan.stableFeeYear),
                          style: Theme.of(context).textTheme.headline4),
                    ),
                  ],
                ),
              ]),
          Divider(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButtonSmall(
                  content: dic['loan.payback'],
                  active: false,
                  padding: EdgeInsets.only(top: 8, bottom: 8),
                  margin: EdgeInsets.only(right: 8),
                  onPressed: loan.debits <= BigInt.zero
                      ? null
                      : () => Navigator.of(context).pushNamed(
                            LoanAdjustPage.route,
                            arguments: LoanAdjustPageParams(
                                LoanAdjustPage.actionTypePayback, loan.token),
                          ),
                ),
              ),
              Expanded(
                child: OutlinedButtonSmall(
                  content: dic['loan.mint'],
                  active: true,
                  padding: EdgeInsets.only(top: 8, bottom: 8),
                  margin: EdgeInsets.only(left: 8),
                  onPressed: () => Navigator.of(context).pushNamed(
                    LoanAdjustPage.route,
                    arguments: LoanAdjustPageParams(
                        LoanAdjustPage.actionTypeMint, loan.token),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LoanCollateralCard extends StatelessWidget {
  LoanCollateralCard(
    this.loan,
    this.balance,
    this.stableCoinDecimals,
    this.collateralDecimals,
    this.tokenIcons,
  );
  final LoanData loan;
  final String balance;
  final int stableCoinDecimals;
  final int collateralDecimals;
  final Map<String, Widget> tokenIcons;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');
    return RoundedCard(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.only(bottom: 8),
                        child: Text(
                            '${dic['loan.collateral']}(${PluginFmt.tokenView(loan.token)})'),
                      ),
                      Row(children: [
                        Container(
                            margin: EdgeInsets.only(right: 8),
                            child: TokenIcon(loan.token, tokenIcons)),
                        Text(
                            Fmt.priceFloorBigInt(
                                loan.collaterals, collateralDecimals),
                            style: TextStyle(
                              fontSize: 30,
                              letterSpacing: -0.8,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            )),
                      ]),
                      Container(
                        margin: EdgeInsets.only(top: 4),
                        child: Text(
                          '${I18n.of(context).getDic(i18n_full_dic_karura, 'common')['balance']}: $balance',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).unselectedWidgetColor,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Column(
                  children: [
                    TapTooltip(
                      message: dic['loan.ratio.info.KSM'],
                      child: Row(
                        children: [
                          Icon(Icons.info,
                              color: Theme.of(context).disabledColor, size: 14),
                          Container(
                            padding: EdgeInsets.only(left: 4),
                            child: Text(dic['loan.ratio']),
                          )
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 16, bottom: 24),
                      child: Text(Fmt.ratio(loan.collateralRatio),
                          style: Theme.of(context).textTheme.headline4),
                    ),
                  ],
                ),
              ]),
          Divider(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButtonSmall(
                  content: dic['loan.withdraw'],
                  active: false,
                  padding: EdgeInsets.only(top: 8, bottom: 8),
                  margin: EdgeInsets.only(right: 8),
                  onPressed: () => Navigator.of(context).pushNamed(
                    LoanAdjustPage.route,
                    arguments: LoanAdjustPageParams(
                        LoanAdjustPage.actionTypeWithdraw, loan.token),
                  ),
                ),
              ),
              Expanded(
                child: OutlinedButtonSmall(
                  content: dic['loan.deposit'],
                  active: true,
                  padding: EdgeInsets.only(top: 8, bottom: 8),
                  margin: EdgeInsets.only(left: 8),
                  onPressed: () => Navigator.of(context).pushNamed(
                    LoanAdjustPage.route,
                    arguments: LoanAdjustPageParams(
                        LoanAdjustPage.actionTypeDeposit, loan.token),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
