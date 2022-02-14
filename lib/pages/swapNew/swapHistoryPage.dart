import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
import 'package:polkawallet_ui/components/TransferIcon.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginLoadingWidget.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/utils/format.dart';

class SwapHistoryPage extends StatelessWidget {
  SwapHistoryPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/karura/swap/txs';

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
            document: gql(swapQuery),
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
            final list = List.of(result.data!['dexActions']['nodes'])
                .map((i) => TxSwapData.fromJson(i as Map, plugin))
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

                final TxSwapData detail = list[i];
                TransferIconType type = TransferIconType.swap;
                String describe = "";
                switch (detail.action) {
                  case "removeLiquidity":
                    type = TransferIconType.remove_liquidity;
                    describe =
                        "remove ${detail.amountReceive} ${PluginFmt.tokenView(detail.tokenReceive)} and ${detail.amountPay} ${PluginFmt.tokenView(detail.tokenPay)}";
                    break;
                  case "addProvision":
                    type = TransferIconType.add_provision;
                    describe =
                        "add ${detail.amountReceive} ${PluginFmt.tokenView(detail.tokenReceive)} and ${detail.amountPay} ${PluginFmt.tokenView(detail.tokenPay)} in boostrap";
                    break;
                  case "addLiquidity":
                    type = TransferIconType.add_liquidity;
                    describe =
                        "add ${detail.amountReceive} ${PluginFmt.tokenView(detail.tokenReceive)} and ${detail.amountPay} ${PluginFmt.tokenView(detail.tokenPay)}";
                    break;
                  case "swap":
                    type = TransferIconType.swap;
                    describe =
                        "swap  ${detail.amountReceive} ${PluginFmt.tokenView(detail.tokenReceive)} for ${detail.amountPay} ${PluginFmt.tokenView(detail.tokenPay)}";
                    break;
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
                          dic['dex.${detail.action}']!,
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
                            ?.copyWith(color: Colors.white, fontSize: 10)),
                    leading: TransferIcon(
                        type:
                            detail.isSuccess! ? type : TransferIconType.failure,
                        bgColor: detail.isSuccess!
                            ? Color(0x57FFFFFF)
                            : Color(0xFFD7D7D7)),
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
