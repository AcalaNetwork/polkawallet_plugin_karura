import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/api/types/loanType.dart';
import 'package:polkawallet_plugin_karura/pages/loanNew/loanCreatePage.dart';
import 'package:polkawallet_plugin_karura/pages/loanNew/loanTabBarWidget.dart';
import 'package:polkawallet_plugin_karura/pages/multiply/pieChartPainter.dart';
import 'package:polkawallet_plugin_karura/pages/types/loanPageParams.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/connectionChecker.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginLoadingWidget.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTokenIcon.dart';
import 'package:polkawallet_ui/utils/consts.dart';

class MultiplyPage extends StatefulWidget {
  MultiplyPage(this.plugin, this.keyring, {Key? key}) : super(key: key);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/karura/multiply';

  @override
  State<MultiplyPage> createState() => _MultiplyPageState();
}

class _MultiplyPageState extends State<MultiplyPage> {
  Map<String, PageController> _pageController = Map<String, PageController>();

  Future<void> _fetchData() async {
    widget.plugin.service!.earn.getDexIncentiveLoyaltyEndBlock();
    widget.plugin.service!.gov.updateBestNumber();
    await widget.plugin.service!.loan
        .queryLoanTypes(widget.keyring.current.address);

    await widget.plugin.service!.assets.queryMarketPrices();

    await widget.plugin.service!.loan
        .subscribeAccountLoans(widget.keyring.current.address);
  }

  @override
  void dispose() {
    super.dispose();
    widget.plugin.service!.loan.unsubscribeAccountLoans();
  }

  @override
  Widget build(BuildContext context) {
    final dicCommon = I18n.of(context)!.getDic(i18n_full_dic_karura, 'common');
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala');
    final argsJson = ModalRoute.of(context)!.settings.arguments as Map? ?? {};
    final args = LoanPageParams.fromJson(argsJson);

    return Observer(builder: (_) {
      final loans = widget.plugin.store!.loan.loans.values.toList();
      loans.retainWhere((loan) =>
          loan.debits > BigInt.zero || loan.collaterals > BigInt.zero);
      final isDataLoading =
          widget.plugin.store!.loan.loansLoading && loans.length == 0 ||
              // do not show loan card if collateralRatio was not calculated.
              (loans.length > 0 && loans[0].collateralRatio <= 0);

      int initialLoanTypeIndex = 0;
      if (args.loanType != null) {
        initialLoanTypeIndex = widget.plugin.store!.loan.loanTypes
            .indexWhere((e) => e.token?.tokenNameId == args.loanType);
      } else if (loans.length > 0) {
        initialLoanTypeIndex = widget.plugin.store!.loan.loanTypes.indexWhere(
            (e) => e.token?.tokenNameId == loans[0].token?.tokenNameId);
      }
      return PluginScaffold(
          appBar: PluginAppBar(
            title: Text(dicCommon!['multiply.title']!),
          ),
          body: isDataLoading
              ? Column(
                  children: [
                    ConnectionChecker(widget.plugin, onConnected: _fetchData),
                    Container(
                      height: MediaQuery.of(context).size.height / 2,
                      child: PluginLoadingWidget(),
                    )
                  ],
                )
              : LoanTabBarWidget(
                  initialTab:
                      initialLoanTypeIndex > -1 ? initialLoanTypeIndex : 0,
                  data: widget.plugin.store!.loan.loanTypes.map((e) {
                    final _loans = loans
                        .where((data) => data.token!.symbol == e.token!.symbol);
                    LoanData? loan = _loans.length > 0 ? _loans.first : null;
                    Widget child =
                        CreateVaultWidget(e.token!.symbol!, onPressed: () {
                      Navigator.of(context)
                          .pushNamed(LoanCreatePage.route, arguments: e.token);
                    });
                    if (loan != null) {
                      if (_pageController[loan.token!.symbol] == null) {
                        _pageController[loan.token!.symbol!] = PageController();
                      }
                      child = PageView(
                        scrollDirection: Axis.vertical,
                        controller: _pageController[loan.token!.symbol!],
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LoanView(loan),
                              GestureDetector(
                                  onTap: () {
                                    _pageController[loan.token!.symbol!]!
                                        .animateToPage(
                                      1,
                                      duration: Duration(milliseconds: 400),
                                      curve: Curves.ease,
                                    );
                                  },
                                  child: Padding(
                                      padding: EdgeInsets.only(bottom: 22),
                                      child: Text(
                                        "Adjust Multiple",
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline3
                                            ?.copyWith(
                                                fontSize: 18,
                                                color:
                                                    PluginColorsDark.headline1),
                                      )))
                            ],
                          ),
                          Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                                color: Color(0x8AFFFFFF),
                                borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(24),
                                    topRight: Radius.circular(24),
                                    bottomRight: Radius.circular(24))),
                          )
                        ],
                      );
                    }
                    return LoanTabBarWidgetData(
                      PluginTokenIcon(
                          e.token!.symbol!, widget.plugin.tokenIcons),
                      child,
                    );
                  }).toList(),
                ));
    });
  }
}

class LoanView extends StatelessWidget {
  LoanView(this._loan, {Key? key}) : super(key: key);
  LoanData _loan;

  @override
  Widget build(BuildContext context) {
    final sumInUSD = _loan.collateralInUSD + _loan.debitInUSD;
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 244,
          padding: EdgeInsets.only(left: 20, top: 12, right: 20, bottom: 15),
          decoration: BoxDecoration(
              color: Color(0x1AFFFFFF),
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(24))),
          child: Column(
            children: [
              Container(
                width: 150,
                height: 150,
                child: CustomPaint(
                  painter: pieChartPainter(_loan.collateralInUSD / sumInUSD,
                      _loan.debitInUSD / sumInUSD),
                ),
              )
            ],
          ),
        )
      ],
    );
  }
}

class CreateVaultWidget extends StatelessWidget {
  const CreateVaultWidget(this.symbol, {this.onPressed, Key? key})
      : super(key: key);
  final String symbol;
  final Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final dicCommon = I18n.of(context)!.getDic(i18n_full_dic_karura, 'common');
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala');
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
                color: Color(0x1AFFFFFF),
                borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                    bottomRight: Radius.circular(24))),
            child: Column(
              children: [
                Padding(
                    padding: EdgeInsets.only(top: 54, bottom: 42),
                    child: Image.asset(
                      "packages/polkawallet_plugin_karura/assets/images/create_vault_logo.png",
                      width: 116,
                    )),
                Container(
                  width: double.infinity,
                  height: 96,
                  color: Color(0x33FFFFFF),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${dic!['loan.multiply.with']} 54.00 ${PluginFmt.tokenView(symbol)}",
                        style: Theme.of(context)
                            .textTheme
                            .headline3
                            ?.copyWith(color: PluginColorsDark.headline1),
                      ),
                      Text(
                        "${dic['loan.multiply.message1']} 233.82 ${PluginFmt.tokenView(symbol)} ${dic['loan.multiply.message2']}",
                        style: Theme.of(context)
                            .textTheme
                            .headline3
                            ?.copyWith(color: PluginColorsDark.headline1),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 104,
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                          child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                              padding: EdgeInsets.only(bottom: 10),
                              child: Text(
                                dic['loan.multiply.maxMultiple']!,
                                style: Theme.of(context)
                                    .textTheme
                                    .headline5
                                    ?.copyWith(
                                        color: PluginColorsDark.headline1),
                              )),
                          Text(
                            "4.33x",
                            style: Theme.of(context)
                                .textTheme
                                .headline5
                                ?.copyWith(color: PluginColorsDark.headline1),
                          )
                        ],
                      )),
                      Expanded(
                          child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                              padding: EdgeInsets.only(bottom: 10),
                              child: Text(
                                dic['loan.multiply.variableAnnualFee']!,
                                style: Theme.of(context)
                                    .textTheme
                                    .headline5
                                    ?.copyWith(
                                        color: PluginColorsDark.headline1),
                              )),
                          Text(
                            "3.00%",
                            style: Theme.of(context)
                                .textTheme
                                .headline5
                                ?.copyWith(color: PluginColorsDark.headline1),
                          )
                        ],
                      ))
                    ],
                  ),
                )
              ],
            ),
          ),
          Container(
              margin: EdgeInsets.only(bottom: 38),
              child: PluginButton(
                title: dicCommon!['multiply.title']!,
                onPressed: onPressed,
              ))
        ],
      ),
    );
  }
}
