import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:polkawallet_plugin_karura/api/types/txSwapData.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/txDetail.dart';
import 'package:polkawallet_ui/utils/format.dart';

class SwapDetailPage extends StatelessWidget {
  SwapDetailPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static final String route = '/karura/swap/tx';

  @override
  Widget build(BuildContext context) {
    final Map<String, String> dic =
        I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;

    final TxSwapData tx = ModalRoute.of(context)!.settings.arguments as TxSwapData;
    final token0 = PluginFmt.tokenView(tx.tokenPay);
    final token1 = PluginFmt.tokenView(tx.tokenReceive);
    final balancePair = AssetsUtils.getBalancePairFromTokenNameId(
        plugin, [tx.tokenPay, tx.tokenReceive]);
    final tokenLP = '$token0-$token1 LP';
    final amount0 = Fmt.balance(tx.amountPay, balancePair[0]!.decimals!);
    final amount1 = Fmt.balance(tx.amountReceive, balancePair[1]!.decimals!);
    final amountLP = Fmt.balance(tx.amountShare, balancePair[0]!.decimals!);

    final amountStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);

    String? networkName = plugin.basic.name;
    if (plugin.basic.isTestNet) {
      networkName = '${networkName!.split('-')[0]}-testnet';
    }
    final List<TxDetailInfoItem> items = [
      TxDetailInfoItem(
        label: 'Event',
        content: Text(tx.action!, style: amountStyle),
      ),
      TxDetailInfoItem(
        label: dic['txs.action'],
        content: Text(dic['dex.${tx.action}']!, style: amountStyle),
      )
    ];
    switch (tx.action) {
      case "swap":
        items.addAll([
          TxDetailInfoItem(
            label: dic['dex.pay'],
            content: Text('$amount0 $token0', style: amountStyle),
          ),
          TxDetailInfoItem(
            label: dic['dex.receive'],
            content: Text('$amount1 $token1', style: amountStyle),
          )
        ]);
        break;
      case "addProvision":
        items.add(TxDetailInfoItem(
            label: dic['dex.pay'],
            content: Text(
              '$amount0 $token0\n'
              '+ $amount1 $token1',
              style: amountStyle,
              textAlign: TextAlign.right,
            )));
        break;
      case "addLiquidity":
        items.addAll([
          TxDetailInfoItem(
            label: dic['dex.pay'],
            content: Text(
                '$amount0 $token0\n'
                '+ $amount1 $token1',
                textAlign: TextAlign.right,
                style: amountStyle),
          ),
          TxDetailInfoItem(
            label: dic['dex.receive'],
            content: Text('$amountLP $tokenLP', style: amountStyle),
          )
        ]);
        break;
      case "removeLiquidity":
        items.addAll([
          TxDetailInfoItem(
            label: dic['dex.pay'],
            content: Text('$amountLP $tokenLP', style: amountStyle),
          ),
          TxDetailInfoItem(
            label: dic['dex.receive'],
            content: Text(
                '$amount0 $token0\n'
                '+ $amount1 $token1',
                textAlign: TextAlign.right,
                style: amountStyle),
          )
        ]);
    }

    return TxDetail(
      success: tx.isSuccess,
      action: dic['dex.${tx.action}'],
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
