import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:polkawallet_plugin_karura/api/history/types/historyData.dart';

import 'package:polkawallet_plugin_karura/pages/swapNew/swapDetailPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/TransferIcon.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginLoadingWidget.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.plugin.service!.history.getSwaps();
    });
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
        child: Observer(
          builder: (_) {
            final list = widget.plugin.store?.history.swaps;

            if (list == null) {
              return Container(
                height: MediaQuery.of(context).size.height / 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [PluginLoadingWidget()],
                ),
              );
            }
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

                final HistoryData detail = list[i];
                TransferIconType type = TransferIconType.swap;
                String describe = detail.message ?? "";
                switch (detail.event) {
                  case "dex.RemoveLiquidity":
                    type = TransferIconType.remove_liquidity;
                    break;
                  case "dex.AddProvision":
                    type = TransferIconType.add_provision;
                    break;
                  case "dex.AddLiquidity":
                    type = TransferIconType.add_liquidity;
                    break;
                  case "dex.Swap":
                    type = TransferIconType.swap;
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
                          dic['${detail.event}'] ?? "",
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
                            .parse(detail.data!['timestamp'], true)),
                        style: Theme.of(context).textTheme.headline5?.copyWith(
                            color: Colors.white,
                            fontSize: UI.getTextSize(10, context))),
                    leading:
                        TransferIcon(type: type, bgColor: Color(0x57FFFFFF)),
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
