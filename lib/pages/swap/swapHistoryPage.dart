import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:intl/intl.dart';
import 'package:polkawallet_plugin_karura/api/types/txSwapData.dart';
import 'package:polkawallet_plugin_karura/common/constants/subQuery.dart';
import 'package:polkawallet_plugin_karura/pages/swap/swapDetailPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/utils/format.dart';

class SwapHistoryPage extends StatelessWidget {
  SwapHistoryPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/acala/swap/txs';

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'acala');
    return Scaffold(
      appBar: AppBar(
        title: Text(dic['loan.txs']),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Query(
          options: QueryOptions(
            document: gql(swapQuery),
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
            final list = List.of(result.data['dexActions']['nodes'])
                .map((i) => TxSwapData.fromJson(
                    i as Map,
                    plugin.networkState.tokenSymbol,
                    plugin.networkState.tokenDecimals))
                .toList();

            return ListView.builder(
              itemCount: list.length + 1,
              itemBuilder: (BuildContext context, int i) {
                if (i == list.length) {
                  return ListTail(isEmpty: list.length == 0, isLoading: false);
                }

                final TxSwapData detail = list[i];
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(width: 0.5, color: Colors.black12)),
                  ),
                  child: ListTile(
                    title: Text(detail.action, style: TextStyle(fontSize: 14)),
                    subtitle: Text(Fmt.dateTime(
                        DateFormat("yyyy-MM-ddTHH:mm:ss")
                            .parse(detail.time, true))),
                    leading: SvgPicture.asset(
                        'packages/polkawallet_plugin_karura/assets/images/${detail.isSuccess ? 'assets_down' : 'tx_failed'}.svg',
                        width: 32),
                    trailing: Container(
                      width: 140,
                      child: Text(
                        '${PluginFmt.tokenView(detail.tokenPay)}-${PluginFmt.tokenView(detail.tokenReceive)}',
                        style: Theme.of(context).textTheme.headline4,
                        textAlign: TextAlign.end,
                      ),
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        SwapDetailPage.route,
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
