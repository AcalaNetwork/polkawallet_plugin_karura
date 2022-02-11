import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
import 'package:polkawallet_ui/components/TransferIcon.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginLoadingWidget.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/utils/format.dart';

class LoanHistoryPage extends StatelessWidget {
  LoanHistoryPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/karura/loan/txs';

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    return PluginScaffold(
      appBar: PluginAppBar(
        title: Text(dic['loan.txs']!),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Query(
            options: QueryOptions(
              document: gql(loanQuery),
              variables: <String, String?>{
                'account': keyring.current.address,
              },
            ),
            builder: (
              QueryResult result, {
              Future<QueryResult?> Function()? refetch,
              FetchMore? fetchMore,
            }) {
              if (result.data == null) {
                return Container(
                  height: MediaQuery.of(context).size.height / 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [PluginLoadingWidget()],
                  ),
                );
              }
              final list = List.of(result.data!['loanActions']['nodes'])
                  .map((i) =>
                      TxLoanData.fromJson(i as Map, karura_stable_coin, plugin))
                  .toList();
              return ListView.builder(
                itemCount: list.length + 1,
                itemBuilder: (BuildContext context, int i) {
                  if (i == list.length) {
                    return ListTail(
                      isEmpty: list.length == 0,
                      isLoading: false,
                      color: Colors.white,
                    );
                  }

                  final TxLoanData detail = list[i];
                  String? amount = detail.amountDebit;
                  String token = karura_stable_coin_view;
                  if (detail.actionType == TxLoanData.actionTypeDeposit ||
                      detail.actionType == TxLoanData.actionTypeWithdraw) {
                    amount = detail.amountCollateral;
                    token = PluginFmt.tokenView(detail.token);
                  }

                  TransferIconType type = TransferIconType.mint;
                  if (detail.actionType == TxLoanData.actionTypeDeposit) {
                    type = TransferIconType.deposit;
                  } else if (detail.actionType ==
                      TxLoanData.actionTypeWithdraw) {
                    type = TransferIconType.withdraw;
                  } else if (detail.actionType ==
                      TxLoanData.actionTypePayback) {
                    type = TransferIconType.payback;
                  }
                  return Container(
                    decoration: BoxDecoration(
                      color: Color(0x14ffffff),
                      border: Border(
                          bottom:
                              BorderSide(width: 0.5, color: Color(0x24ffffff))),
                    ),
                    child: ListTile(
                      dense: true,
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dic['loan.${detail.actionType}']!,
                            style: Theme.of(context)
                                .textTheme
                                .headline5
                                ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600),
                          ),
                          Text('$amount $token',
                              textAlign: TextAlign.start,
                              style: Theme.of(context)
                                  .textTheme
                                  .headline5
                                  ?.copyWith(color: Colors.white))
                        ],
                      ),
                      subtitle: Text(
                          Fmt.dateTime(DateFormat("yyyy-MM-ddTHH:mm:ss")
                              .parse(detail.time, true)),
                          style: Theme.of(context)
                              .textTheme
                              .headline5
                              ?.copyWith(color: Colors.white, fontSize: 10)),
                      leading: TransferIcon(
                          type: detail.isSuccess!
                              ? type
                              : TransferIconType.failure,
                          bgColor: detail.isSuccess!
                              ? Color(0x57FFFFFF)
                              : Color(0xFFD7D7D7)),
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
