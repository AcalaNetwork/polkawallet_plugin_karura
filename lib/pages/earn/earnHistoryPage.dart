import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:intl/intl.dart';
import 'package:polkawallet_plugin_karura/api/types/txIncentiveData.dart';
import 'package:polkawallet_plugin_karura/common/constants/subQuery.dart';
import 'package:polkawallet_plugin_karura/pages/earn/earnTxDetailPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/TransferIcon.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/utils/format.dart';

class EarnHistoryPage extends StatelessWidget {
  EarnHistoryPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/karura/earn/txs';

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;

    return Scaffold(
      appBar: AppBar(
        title: Text(dic['loan.txs']!),
        centerTitle: true,
        leading: BackBtn(),
      ),
      body: SafeArea(
        child: Query(
          options: QueryOptions(
            document: gql(dexStakeQuery),
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
                  children: [CupertinoActivityIndicator()],
                ),
              );
            }

            final nodes =
                List.of(result.data!['incentiveActions']['nodes']).toList();
            nodes.removeWhere(
                (e) => jsonDecode(e['data'][1]['value'])['loans'] != null);
            final list = nodes
                .map((i) => TxDexIncentiveData.fromJson((i as Map) as Map<String, dynamic>, plugin))
                .toList();

            return ListView.builder(
              itemCount: list.length + 1,
              itemBuilder: (BuildContext context, int i) {
                if (i == list.length) {
                  return ListTail(isEmpty: list.length == 0, isLoading: false);
                }

                final detail = list[i];
                String? amount = '';
                TransferIconType icon = TransferIconType.rollIn;
                switch (detail.event) {
                  case TxDexIncentiveData.actionStake:
                    amount = detail.amountShare;
                    icon = TransferIconType.rollOut;
                    break;
                  case TxDexIncentiveData.actionClaimRewards:
                  case TxDexIncentiveData.actionPayoutRewards:
                    amount = detail.amountShare;
                    icon = TransferIconType.earn;
                    break;
                  case TxDexIncentiveData.actionUnStake:
                    amount = detail.amountShare;
                    break;
                }

                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(width: 0.5, color: Colors.black12)),
                  ),
                  child: ListTile(
                    dense: true,
                    title: Text(amount!, style: TextStyle(fontSize: 14)),
                    subtitle: Text(Fmt.dateTime(
                        DateFormat("yyyy-MM-ddTHH:mm:ss")
                            .parse(detail.time, true))),
                    leading: TransferIcon(
                        type: icon, bgColor: Theme.of(context).cardColor),
                    trailing: Text(
                      dic['earn.${detail.event}']!,
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.end,
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        EarnTxDetailPage.route,
                        arguments: detail,
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

const earn_actions_map = {
  'addLiquidity': 'earn.add',
  'removeLiquidity': 'earn.remove',
  'depositDexShare': 'earn.stake',
  'withdrawDexShare': 'earn.unStake',
  'claimRewards': 'earn.claim',
};
