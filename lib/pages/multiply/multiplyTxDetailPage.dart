import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:polkawallet_plugin_karura/api/types/txMultiplyData.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTxDetail.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class MultiplyTxDetailPage extends StatelessWidget {
  MultiplyTxDetailPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static final String route = '/karura/multiply/tx';

  @override
  Widget build(BuildContext context) {
    final Map<String, String> dic =
        I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    final amountStyle = TextStyle(
        fontSize: UI.getTextSize(16, context),
        fontWeight: FontWeight.bold,
        color: PluginColorsDark.headline1);

    final TxMultiplyData tx =
        ModalRoute.of(context)!.settings.arguments as TxMultiplyData;

    final List<TxDetailInfoItem> items = [
      TxDetailInfoItem(
        label: 'Event',
        content: Text('ExpandCollateral',
            style: tx.isSuccess == null
                ? TextStyle(
                    fontFamily: "TitilliumWeb-SemiBold",
                    fontSize: UI.getTextSize(30, context),
                    fontWeight: FontWeight.w600,
                    color: PluginColorsDark.headline1)
                : amountStyle),
      ),
      TxDetailInfoItem(
        label: dic['txs.action'],
        content: Text(dic['loan.multiply.${tx.action}']!, style: amountStyle),
      )
    ];
    if (tx.action == TxMultiplyData.expand) {
      items.add(TxDetailInfoItem(
        label: dic['loan.multiply.buying'],
        content: Text('${tx.amountCollateral} ${PluginFmt.tokenView(tx.token)}',
            style: amountStyle),
      ));
    } else {
      items.add(TxDetailInfoItem(
        label: dic['loan.multiply.selling'],
        content: Text('${tx.amountCollateral} ${PluginFmt.tokenView(tx.token)}',
            style: amountStyle),
      ));
    }
    items.add(TxDetailInfoItem(
      label: dic['loan.multiply.outstandingDebt'],
      content: Text('${tx.amountDebit} $karura_stable_coin_view',
          style: amountStyle),
    ));

    String? networkName = plugin.basic.name;
    if (plugin.basic.isTestNet) {
      networkName = '${networkName!.split('-')[0]}-testnet';
    }
    return PluginTxDetail(
      success: tx.isSuccess,
      action: dic['loan.multiply.${tx.action}'],
      // blockNum: int.parse(tx.block),
      hash: tx.hash,
      blockTime:
          Fmt.dateTime(DateFormat("yyyy-MM-ddTHH:mm:ss").parse(tx.time, true)),
      networkName: networkName,
      infoItems: items,
      current: keyring.current,
    );
  }
}
