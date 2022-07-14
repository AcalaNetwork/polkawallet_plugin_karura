import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:polkawallet_plugin_karura/api/types/txHomaData.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/pages/homaNew/homaTxDetailPage.dart';
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

class HomaHistoryPage extends StatefulWidget {
  HomaHistoryPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/karura/homa/txs';

  @override
  State<HomaHistoryPage> createState() => _HomaHistoryPageState();
}

class _HomaHistoryPageState extends State<HomaHistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.plugin.service!.history.getHomas();
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
            final list = widget.plugin.store?.history.homas;

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

                final history = list[i];
                final detail = TxHomaData.fromHistory(history);
                String amountTail = history.message ?? "";
                TransferIconType type = TransferIconType.redeem;

                switch (detail.action) {
                  case TxHomaData.actionMint:
                    type = TransferIconType.mint;
                    break;
                  // case TxHomaData.actionRedeem:
                  // case TxHomaData.actionLiteRedeem:
                  //   break;
                  // case TxHomaData.actionRedeemedByUnbond:
                  //   break;
                  // case TxHomaData.actionRedeemedByFastMatch:
                  //   break;
                  // case TxHomaData.actionRedeemed:
                  // case TxHomaData.actionLiteRedeemed:
                  //   break;
                  // case TxHomaData.actionWithdrawRedemption:
                  //   break;
                  // case TxHomaData.actionRedeemCancel:
                  //   break;
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
                          '${dic[detail.action]}',
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
                        style: Theme.of(context).textTheme.headline5?.copyWith(
                            color: Colors.white,
                            fontSize: UI.getTextSize(10, context))),
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
