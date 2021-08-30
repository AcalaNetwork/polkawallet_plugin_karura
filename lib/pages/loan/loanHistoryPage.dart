import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:intl/intl.dart';
import 'package:polkawallet_plugin_karura/api/types/txLoanData.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/common/constants/subQuery.dart';
import 'package:polkawallet_plugin_karura/pages/loan/loanTxDetailPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/utils/format.dart';

class LoanHistoryPage extends StatelessWidget {
  LoanHistoryPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/acala/loan/txs';

  @override
  Widget build(BuildContext context) {
    final symbols = plugin.networkState.tokenSymbol;
    final decimals = plugin.networkState.tokenDecimals;

    final stableCoinDecimals = decimals[symbols.indexOf(karura_stable_coin)];
    return Scaffold(
      appBar: AppBar(
        title: Text(
            I18n.of(context).getDic(i18n_full_dic_acala, 'acala')['loan.txs']),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Query(
            options: QueryOptions(
              document: gql(loanQuery),
              variables: <String, String>{
                'account': keyring.current.address,
              },
            ),
            builder: (
              QueryResult result, {
              Future<QueryResult> Function() refetch,
              FetchMore fetchMore,
            }) {
              if (result.data == null) {
                return Container(
                  height: MediaQuery.of(context).size.height / 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [CupertinoActivityIndicator()],
                  ),
                );
              }
              final list =
                  List.of(result.data['loanActions']['nodes']).map((i) {
                final token = jsonDecode(i['data'][1]['value']);
                return TxLoanData.fromJson(
                    i as Map,
                    karura_stable_coin,
                    stableCoinDecimals,
                    decimals[symbols.indexOf(token['token'])]);
              }).toList();
              return ListView.builder(
                itemCount: list.length + 1,
                itemBuilder: (BuildContext context, int i) {
                  if (i == list.length) {
                    return ListTail(
                        isEmpty: list.length == 0, isLoading: false);
                  }

                  final TxLoanData detail = list[i];
                  bool isOut = false;
                  if (detail.actionType == TxLoanData.actionTypePayback ||
                      detail.actionType == TxLoanData.actionTypeDeposit ||
                      detail.actionType == TxLoanData.actionLiquidate) {
                    isOut = true;
                  }
                  String amount = detail.amountDebit;
                  String token = karura_stable_coin_view;
                  if (detail.actionType == TxLoanData.actionTypeDeposit ||
                      detail.actionType == TxLoanData.actionTypeWithdraw) {
                    amount = detail.amountCollateral;
                    token = PluginFmt.tokenView(detail.token);
                  }
                  return Container(
                    decoration: BoxDecoration(
                      border: Border(
                          bottom:
                              BorderSide(width: 0.5, color: Colors.black12)),
                    ),
                    child: ListTile(
                      title: Text(detail.actionType,
                          style: TextStyle(fontSize: 14)),
                      subtitle: Text(Fmt.dateTime(
                          DateFormat("yyyy-MM-ddTHH:mm:ss")
                              .parse(detail.time, true))),
                      leading: SvgPicture.asset(
                          'packages/polkawallet_plugin_karura/assets/images/${detail.isSuccess ? isOut ? 'assets_up' : 'assets_down' : 'tx_failed'}.svg',
                          width: 32),
                      trailing: FittedBox(
                        child: Text(
                          '$amount $token',
                          style: Theme.of(context).textTheme.headline4,
                          textAlign: TextAlign.end,
                        ),
                      ),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          LoanTxDetailPage.route,
                          arguments: detail,
                        );
                      },
                    ),
                  );
                },
              );
            }),
      ),
    );
  }
}
