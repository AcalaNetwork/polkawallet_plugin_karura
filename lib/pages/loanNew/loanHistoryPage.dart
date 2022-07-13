import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:intl/intl.dart';
import 'package:polkawallet_plugin_karura/api/history/types/historyData.dart';
import 'package:polkawallet_plugin_karura/api/types/txLoanData.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/common/constants/subQuery.dart';
import 'package:polkawallet_plugin_karura/pages/loanNew/loanTxDetailPage.dart';
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
import 'package:polkawallet_ui/utils/index.dart';

class LoanHistoryPage extends StatefulWidget {
  LoanHistoryPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/karura/loan/txs';

  @override
  State<LoanHistoryPage> createState() => _LoanHistoryPageState();
}

class _LoanHistoryPageState extends State<LoanHistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.plugin.service!.history.getLoans();
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
        child: Observer(builder: (_) {
          final list = widget.plugin.store?.history.loans;
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

              final HistoryData history = list[i];
              final TxLoanData detail =
                  TxLoanData.fromJson(history, widget.plugin);
              TransferIconType type = TransferIconType.mint;
              var describe = history.message ?? '';
              switch (detail.actionType) {
                case TxLoanData.actionTypeDeposit:
                  type = TransferIconType.deposit;
                  break;
                case TxLoanData.actionTypeWithdraw:
                  type = TransferIconType.withdraw;
                  break;
                case TxLoanData.actionTypePayback:
                  type = TransferIconType.payback;
                  break;
                default:
                  type = TransferIconType.mint;
              }

              return Container(
                decoration: BoxDecoration(
                  color: Color(0x14ffffff),
                  border: Border(
                      bottom: BorderSide(width: 0.5, color: Color(0x24ffffff))),
                ),
                child: ListTile(
                  dense: true,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dic['loan.${detail.actionType}'] ?? '',
                        style: Theme.of(context).textTheme.headline5?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w600),
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
                  leading: TransferIcon(type: type, bgColor: Color(0x57FFFFFF)),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      LoanTxDetailPage.route,
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
