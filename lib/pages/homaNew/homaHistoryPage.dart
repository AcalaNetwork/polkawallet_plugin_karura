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
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/utils/format.dart';

class HomaHistoryPage extends StatelessWidget {
  HomaHistoryPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/karura/homa/txs';

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    final symbols = plugin.networkState.tokenSymbol;
    final decimals = plugin.networkState.tokenDecimals;
    final symbol = relay_chain_token_symbol;
    return PluginScaffold(
      appBar: PluginAppBar(
        title: Text(dic['loan.txs']!),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Query(
          options: QueryOptions(
            document: gql(homaQuery),
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

            final list = List.of(result.data!['homaActions']['nodes'])
                .map((i) =>
                    TxHomaData.fromJson((i as Map) as Map<String, dynamic>))
                .toList();
            list.removeWhere((e) =>
                e.action == TxHomaData.actionRedeemed &&
                e.amountReceive == BigInt.zero);

            final nativeDecimal = decimals![symbols!.indexOf(symbol)];
            final liquidDecimal = decimals[symbols.indexOf('L$symbol')];

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

                final detail = list[i];

                String amountTail = '';
                String amountTitle = '';
                TransferIconType type = TransferIconType.redeem;

                switch (detail.action) {
                  case TxHomaData.actionMint:
                    type = TransferIconType.mint;
                    amountTail =
                        '${dic['homa.${detail.action}']} ${Fmt.priceFloorBigInt(detail.amountPay, nativeDecimal)} $symbol for ${Fmt.priceFloorBigInt(detail.amountReceive, liquidDecimal)} L$symbol';
                    break;
                  case TxHomaData.actionRedeem:
                    amountTail =
                        '${dic['homa.${detail.action}']} ${Fmt.priceFloorBigInt(detail.amountPay, liquidDecimal)} L$symbol';
                    break;
                  case TxHomaData.actionRedeemedByUnbond:
                    amountTail =
                        '${dic['homa.${detail.action}']} ${Fmt.priceFloorBigInt(detail.amountReceive, nativeDecimal)} $symbol';
                    break;
                  case TxHomaData.actionRedeemed:
                  case TxHomaData.actionRedeemedByFastMatch:
                  case TxHomaData.actionWithdrawRedemption:
                    amountTail =
                        '${dic['homa.${detail.action}']} ${Fmt.priceFloorBigInt(detail.amountReceive, nativeDecimal)} $symbol for ${Fmt.priceFloorBigInt(detail.amountPay, liquidDecimal)} L$symbol';
                    break;
                  case TxHomaData.actionRedeemCancel:
                    amountTail =
                        '${dic['homa.${detail.action}']} ${Fmt.priceFloorBigInt(detail.amountReceive, liquidDecimal)} L$symbol';
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
                          '${dic['homa.${detail.action}']} $amountTitle',
                          style: Theme.of(context)
                              .textTheme
                              .headline5
                              ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                        ),
                        Text(amountTail,
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
                    leading:
                        TransferIcon(type: type, bgColor: Color(0x57FFFFFF)),
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
