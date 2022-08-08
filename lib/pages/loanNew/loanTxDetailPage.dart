import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:polkawallet_plugin_karura/api/types/txLoanData.dart';
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

class LoanTxDetailPage extends StatelessWidget {
  LoanTxDetailPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static final String route = '/karura/loan/tx';

  @override
  Widget build(BuildContext context) {
    final Map<String, String> dic =
        I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    final Map<String, String> dicCommon =
        I18n.of(context)!.getDic(i18n_full_dic_karura, 'common')!;

    final amountStyle = TextStyle(
        fontSize: UI.getTextSize(16, context),
        fontWeight: FontWeight.bold,
        color: PluginColorsDark.headline1);

    final TxLoanData tx =
        ModalRoute.of(context)!.settings.arguments as TxLoanData;

    final List<TxDetailInfoItem> items = [
      TxDetailInfoItem(
        label: 'Event',
        content: Text(
            tx.event!.replaceAll('loans.', '').replaceAll('cdpEngine.', ''),
            style: amountStyle),
      ),
      TxDetailInfoItem(
        label: dic['txs.action'],
        content: Text(dic['loan.${tx.actionType}']!, style: amountStyle),
      )
    ];

    if (tx.actionType == TxLoanData.actionLiquidate) {
      if (tx.collateral != BigInt.zero) {
        items.add(TxDetailInfoItem(
          label: dicCommon['amount'],
          content: Text(
              '${tx.amountCollateral} ${PluginFmt.tokenView(tx.token)}',
              style: amountStyle),
        ));
      }
    } else if (tx.actionType == TxLoanData.actionClose) {
      items.add(TxDetailInfoItem(
        label: dic['loan.return'],
        content: Text('${tx.amountCollateral} ${PluginFmt.tokenView(tx.token)}',
            style: amountStyle),
      ));
      items.add(TxDetailInfoItem(
        label: dic['loan.payback'],
        content: Text('${tx.amountDebit} $karura_stable_coin_view',
            style: amountStyle),
      ));
    } else {
      if (tx.collateral != BigInt.zero) {
        items.add(TxDetailInfoItem(
          label: tx.collateral! > BigInt.zero
              ? dic['loan.deposit']
              : dic['loan.withdraw'],
          content: Text(
              '${tx.amountCollateral} ${PluginFmt.tokenView(tx.token)}',
              style: amountStyle),
        ));
      }
      if (tx.debit != BigInt.zero) {
        items.add(TxDetailInfoItem(
          label:
              tx.debit! < BigInt.zero ? dic['loan.payback'] : dic['loan.mint'],
          content: Text('${tx.amountDebit} $karura_stable_coin_view',
              style: amountStyle),
        ));
      }
    }

    String? networkName = plugin.basic.name;
    if (plugin.basic.isTestNet) {
      networkName = '${networkName!.split('-')[0]}-testnet';
    }
    return PluginTxDetail(
      success: tx.isSuccess,
      action: dic['loan.${tx.actionType}'],
      // blockNum: int.parse(tx.block),
      hash: tx.hash,
      resolveLinks: tx.resolveLinks,
      blockTime:
          Fmt.dateTime(DateFormat("yyyy-MM-ddTHH:mm:ss").parse(tx.time, true)),
      networkName: networkName,
      infoItems: items,
      current: keyring.current,
    );
  }
}
