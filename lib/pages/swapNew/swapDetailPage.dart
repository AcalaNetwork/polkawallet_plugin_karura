import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:polkawallet_plugin_karura/api/history/types/historyData.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTxDetail.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class SwapDetailPage extends StatelessWidget {
  SwapDetailPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static final String route = '/karura/swap/tx';

  @override
  Widget build(BuildContext context) {
    final Map<String, String> dic =
        I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;

    final HistoryData tx =
        ModalRoute.of(context)!.settings.arguments as HistoryData;

    final tokenPay = AssetsUtils.tokenDataFromCurrencyId(
        plugin, {'token': tx.data!['token0Id']});
    final tokenReceive = AssetsUtils.tokenDataFromCurrencyId(
        plugin, {'token': tx.data!['token1Id']});

    final token0 = PluginFmt.tokenView(tokenPay.symbol);
    final token1 = PluginFmt.tokenView(tokenReceive.symbol);
    final tokenLP = '$token0-$token1 LP';

    final amountPay = Fmt.priceFloorBigInt(
        Fmt.balanceInt(tx.data!['token0Amount']), tokenPay.decimals ?? 12,
        lengthMax: 6);
    final amountReceive = Fmt.priceFloorBigInt(
        Fmt.balanceInt(tx.data!['token1Amount']), tokenReceive.decimals ?? 12,
        lengthMax: 6);
    final amountShare = Fmt.priceFloorBigInt(
        Fmt.balanceInt(tx.data!['shareAmount']), tokenPay.decimals ?? 12,
        lengthMax: 6);

    final amountStyle = TextStyle(
        fontSize: UI.getTextSize(16, context),
        fontWeight: FontWeight.bold,
        color: PluginColorsDark.headline1);

    String? networkName = plugin.basic.name;
    if (plugin.basic.isTestNet) {
      networkName = '${networkName!.split('-')[0]}-testnet';
    }
    final List<TxDetailInfoItem> items = [
      TxDetailInfoItem(
        label: 'Event',
        content: Text(tx.event!.replaceAll('dex.', ''), style: amountStyle),
      ),
      TxDetailInfoItem(
        label: dic['txs.action'],
        content: Text(dic['${tx.event}']!, style: amountStyle),
      )
    ];
    switch (tx.event) {
      case "dex.Swap":
        items.addAll([
          TxDetailInfoItem(
            label: dic['dex.pay'],
            content: Text('$amountPay $token0', style: amountStyle),
          ),
          TxDetailInfoItem(
            label: dic['dex.receive'],
            content: Text('$amountReceive $token1', style: amountStyle),
          )
        ]);
        break;
      case "dex.AddProvision":
        items.add(TxDetailInfoItem(
            label: dic['dex.pay'],
            content: Text(
              '$amountPay $token0\n'
              '+ $amountReceive $token1',
              style: amountStyle,
              textAlign: TextAlign.right,
            )));
        break;
      case "dex.AddLiquidity":
        items.addAll([
          TxDetailInfoItem(
            label: dic['dex.pay'],
            content: Text(
                '$amountPay $token0\n'
                '+ $amountReceive $token1',
                textAlign: TextAlign.right,
                style: amountStyle),
          ),
          TxDetailInfoItem(
            label: dic['dex.receive'],
            content:
                Text('${tx.data!['shareAmount']} $tokenLP', style: amountStyle),
          )
        ]);
        break;
      case "dex.RemoveLiquidity":
        items.addAll([
          TxDetailInfoItem(
            label: dic['dex.pay'],
            content: Text('$amountShare $tokenLP', style: amountStyle),
          ),
          TxDetailInfoItem(
            label: dic['dex.receive'],
            content: Text(
                '$amountPay $token0\n'
                '+ $amountReceive $token1',
                textAlign: TextAlign.right,
                style: amountStyle),
          )
        ]);
    }

    return PluginTxDetail(
      success: true,
      action: dic['${tx.event}'],
      // blockNum: int.parse(tx.block),
      hash: tx.hash,
      blockTime: Fmt.dateTime(
          DateFormat("yyyy-MM-ddTHH:mm:ss").parse(tx.data!['timestamp'], true)),
      networkName: networkName,
      infoItems: items,
      current: keyring.current,
    );
  }
}
