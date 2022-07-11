import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:intl/intl.dart';
import 'package:polkawallet_plugin_karura/api/types/txSwapData.dart';
import 'package:polkawallet_plugin_karura/common/constants/base.dart';
import 'package:polkawallet_plugin_karura/common/constants/subQuery.dart';
import 'package:polkawallet_plugin_karura/pages/swapNew/swapDetailPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/service/graphql.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/TransferIcon.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class SwapHistoryPage extends StatefulWidget {
  SwapHistoryPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/karura/swap/txs';

  @override
  State<SwapHistoryPage> createState() => _SwapHistoryPageState();
}

class _SwapHistoryPageState extends State<SwapHistoryPage> {
  List<TxSwapData> _list = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final client = clientFor(uri: GraphQLConfig['httpUri']!);

      final result = await client.value.query(QueryOptions(
        document: gql(swapQuery),
        variables: <String, String?>{
          'account': widget.keyring.current.address,
        },
      ));

      List<TxSwapData> list = [];
      if (result.data != null) {
        list = List.of(result.data!['dexActions']['nodes'])
            .map((i) => TxSwapData.fromJson(i as Map, widget.plugin))
            .toList();
      }

      await _queryTaigaPoolInfo();

      final clientTaiga = clientFor(uri: GraphQLConfig['taigaUri']!);

      final resultTaiga = await clientTaiga.value.query(QueryOptions(
        document: gql(swapTaigaQuery),
        variables: <String, String?>{
          'address': widget.keyring.current.address,
        },
      ));
      if (resultTaiga.data != null) {
        resultTaiga.data!.forEach((key, value) {
          if (value is Map && value['nodes'] != null) {
            list.addAll(List.of(value['nodes'])
                .map((i) => TxSwapData.fromTaigaJson(i as Map, widget.plugin))
                .toList());
          }
        });
      }

      list.sort((left, right) => right.time.compareTo(left.time));

      setState(() {
        _isLoading = false;
        _list.addAll(list);
      });
    });
  }

  Future<void> _queryTaigaPoolInfo() async {
    if (widget.plugin.store!.earn.taigaTokenPairs.length == 0) {
      final info = await widget.plugin.api!.earn
          .getTaigaPoolInfo(widget.keyring.current.address!);
      widget.plugin.store!.earn.setTaigaPoolInfo(info);
      final data = await widget.plugin.api!.earn.getTaigaTokenPairs();
      widget.plugin.store!.earn.setTaigaTokenPairs(data!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    return PluginScaffold(
      appBar: PluginAppBar(
        title: Text(dic['loan.txs']!),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
                child: ListView.builder(
              itemCount: _list.length + 1,
              itemBuilder: (BuildContext context, int i) {
                if (i == _list.length) {
                  return ListTail(
                    isEmpty: _list.length == 0,
                    isLoading: _isLoading,
                    color: Colors.white,
                  );
                }

                final TxSwapData detail = _list[i];
                TransferIconType type = TransferIconType.swap;
                String describe = "";
                String action = detail.action ?? "";
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
                  //taiga
                  case "mint":
                    type = TransferIconType.add_liquidity;
                    action = "addLiquidity";
                    describe =
                        "add ${detail.amounts.map((e) => e.toTokenString()).join(" and ")}";
                    break;
                  case "proportionredeem":
                  case "singleredeem":
                  case "multiredeem":
                    type = TransferIconType.remove_liquidity;
                    action = "removeLiquidity";
                    describe =
                        "remove ${detail.amountPay} ${PluginFmt.tokenView(detail.tokenPay)}";
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
                          dic['dex.$action']!,
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
                        style: Theme.of(context).textTheme.headline5?.copyWith(
                            color: Colors.white,
                            fontSize: UI.getTextSize(10, context))),
                    leading: TransferIcon(
                        type: (detail.isSuccess ?? true)
                            ? type
                            : TransferIconType.failure,
                        bgColor: (detail.isSuccess ?? true)
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
            ))
          ],
        ),
      ),
    );
  }
}
