import 'package:flutter/cupertino.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:polkawallet_plugin_karura/api/types/transferData.dart';
import 'package:polkawallet_plugin_karura/common/constants/base.dart';
import 'package:polkawallet_plugin_karura/common/constants/subQuery.dart';
import 'package:polkawallet_plugin_karura/pages/assets/tokenDetailPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/service/graphql.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginLoadingWidget.dart';

class NativeTokenTransfers extends StatelessWidget {
  NativeTokenTransfers(this.plugin, this.account, this.transferType);

  final PluginKarura plugin;
  final int transferType;
  final String account;

  @override
  Widget build(BuildContext context) {
    final nativeToken = AssetsUtils.getBalanceFromTokenNameId(plugin, 'KAR');
    if (nativeToken == null) {
      return Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [PluginLoadingWidget()],
        ),
      );
    }

    return ClientProvider(
      child: Builder(
        builder: (_) => Query(
            options: QueryOptions(
              document: gql(transferQuery),
              variables: <String, String?>{
                'account': account,
                'token': 'KAR',
              },
            ),
            builder: (
              QueryResult result, {
              Future<QueryResult?> Function()? refetch,
              FetchMore? fetchMore,
            }) {
              if (result.data == null) {
                return Container(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [PluginLoadingWidget()],
                  ),
                );
              }
              final txs = List.of(result.data!['transfers']['nodes'])
                  .map((i) => TransferData.fromJson(i as Map, nativeToken))
                  .toList();
              txs.removeWhere((e) => e.to == account && e.isSuccess == false);

              if (transferType > 0) {
                txs.retainWhere(
                    (e) => (transferType == 1 ? e.to : e.from) == account);
              }
              return ListView.builder(
                itemCount: txs.length + 1,
                itemBuilder: (_, i) {
                  if (i == txs.length) {
                    return ListTail(isEmpty: txs.length == 0, isLoading: false);
                  }
                  return TransferListItem(
                    data: txs[i],
                    token: nativeToken.symbol,
                    isOut: txs[i].from == account,
                  );
                },
              );
            }),
      ),
      uri: GraphQLConfig['httpUri']!,
    );
  }
}
