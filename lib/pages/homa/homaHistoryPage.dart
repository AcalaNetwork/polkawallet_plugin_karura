import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:intl/intl.dart';
import 'package:polkawallet_plugin_karura/api/types/txHomaData.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/common/constants/subQuery.dart';
import 'package:polkawallet_plugin_karura/pages/homa/homaTxDetailPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/TransferIcon.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/utils/format.dart';

class HomaHistoryPage extends StatelessWidget {
  HomaHistoryPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/karura/homa/txs';

  @override
  Widget build(BuildContext context) {
    final symbols = plugin.networkState.tokenSymbol;
    final decimals = plugin.networkState.tokenDecimals;
    final symbol = relay_chain_token_symbol;
    return Scaffold(
      appBar: AppBar(
        title: Text(
            I18n.of(context).getDic(i18n_full_dic_karura, 'acala')['loan.txs']),
        centerTitle: true,
        leading: BackBtn(),
      ),
      body: SafeArea(
        child: Query(
          options: QueryOptions(
            document: gql(homaQuery),
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

            final list = List.of(result.data['homaActions']['nodes'])
                .map((i) => TxHomaData.fromJson(i as Map))
                .toList();
            list.removeWhere((e) =>
                e.action == TxHomaData.actionRedeemed &&
                e.amountReceive == BigInt.zero);

            final nativeDecimal = decimals[symbols.indexOf(symbol)];
            final liquidDecimal = decimals[symbols.indexOf('L$symbol')];

            return ListView.builder(
              itemCount: list.length + 1,
              itemBuilder: (BuildContext context, int i) {
                if (i == list.length) {
                  return ListTail(isEmpty: list.length == 0, isLoading: false);
                }

                final detail = list[i];

                String amountPay = '';
                String amountReceive = '';

                switch (detail.action) {
                  case TxHomaData.actionMint:
                    amountPay =
                        '${Fmt.priceFloorBigInt(detail.amountPay, nativeDecimal)} $symbol';
                    amountReceive =
                        '${Fmt.priceFloorBigInt(detail.amountReceive, liquidDecimal)} L$symbol';
                    break;
                  case TxHomaData.actionRedeem:
                    amountPay =
                        '${Fmt.priceFloorBigInt(detail.amountPay, liquidDecimal)} L$symbol';
                    break;
                  case TxHomaData.actionRedeemed:
                    amountReceive =
                        '${Fmt.priceFloorBigInt(detail.amountReceive, nativeDecimal)} $symbol';
                    break;
                  case TxHomaData.actionRedeemCancel:
                    amountPay =
                        '${Fmt.priceFloorBigInt(detail.amountReceive, liquidDecimal)} L$symbol';
                }

                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(width: 0.5, color: Colors.black12)),
                  ),
                  child: ListTile(
                    dense: true,
                    title: Text('${detail.action} $amountReceive'),
                    subtitle: Text(Fmt.dateTime(
                        DateFormat("yyyy-MM-ddTHH:mm:ss")
                            .parse(detail.time, true))),
                    leading: TransferIcon(
                      type: detail.action == TxHomaData.actionMint ||
                              detail.action == TxHomaData.actionRedeemCancel
                          ? TransferIconType.rollOut
                          : TransferIconType.rollIn,
                    ),
                    trailing: Text(
                      amountPay,
                      style: Theme.of(context).textTheme.headline4,
                      textAlign: TextAlign.end,
                    ),
                    onTap: () => Navigator.of(context)
                        .pushNamed(HomaTxDetailPage.route, arguments: detail),
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
