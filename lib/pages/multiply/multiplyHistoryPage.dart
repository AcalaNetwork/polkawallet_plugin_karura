import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:intl/intl.dart';
import 'package:polkawallet_plugin_karura/api/types/txMultiplyData.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/common/constants/subQuery.dart';
import 'package:polkawallet_plugin_karura/pages/multiply/multiplyTxDetailPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/TransferIcon.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginPopLoadingWidget.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class MultiplyHistoryPage extends StatelessWidget {
  MultiplyHistoryPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/karura/multiply/txs';

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
              fetchPolicy: FetchPolicy.noCache,
              document: gql(multiplyQuery),
              variables: <String, String?>{
                'senderId': keyring.current.address,
              },
            ),
            builder: (
              QueryResult result, {
              Future<QueryResult?> Function()? refetch,
              FetchMore? fetchMore,
            }) {
              if (result.data == null) {
                return PluginPopLoadingContainer(loading: true);
              }
              final list = List.of(result.data!['extrinsics']['nodes'])
                  .map((i) => TxMultiplyData.fromJson(i as Map, plugin))
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

                  final TxMultiplyData detail = list[i];

                  TransferIconType type = TransferIconType.expand_collateral;
                  var describe =
                      "${detail.amountDebit} ${PluginFmt.tokenView(karura_stable_coin_view)} in debt and buy ${detail.amountCollateral} ${PluginFmt.tokenView(detail.token)}";
                  if (detail.action == TxMultiplyData.expand) {
                    describe =
                        "${detail.amountDebit} ${PluginFmt.tokenView(karura_stable_coin_view)} in debt and buy ${detail.amountCollateral} ${PluginFmt.tokenView(detail.token)}";
                  } else if (detail.action == TxMultiplyData.shrink) {
                    describe =
                        "${detail.amountDebit} ${PluginFmt.tokenView(karura_stable_coin_view)} in debt and sell ${detail.amountCollateral} ${PluginFmt.tokenView(detail.token)}";
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
                            dic['loan.multiply.${detail.action}']!,
                            style: Theme.of(context)
                                .textTheme
                                .headline5
                                ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600),
                          ),
                          Text(describe,
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
                              ?.copyWith(
                                  color: Colors.white,
                                  fontSize: UI.getTextSize(10, context))),
                      leading: TransferIcon(
                          type: detail.isSuccess == false
                              ? TransferIconType.failure
                              : type,
                          bgColor: detail.isSuccess == false
                              ? Color(0xFFD7D7D7)
                              : Color(0x57FFFFFF)),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          MultiplyTxDetailPage.route,
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
