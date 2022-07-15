import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:polkawallet_plugin_karura/api/types/txHomaData.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTxDetail.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class HomaTxDetailPage extends StatelessWidget {
  HomaTxDetailPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static final String route = '/karura/homa/tx';

  @override
  Widget build(BuildContext context) {
    final Map<String, String> dic =
        I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    final decimals = plugin.networkState.tokenDecimals!;
    final symbols = plugin.networkState.tokenSymbol!;

    final TxHomaData tx =
        ModalRoute.of(context)!.settings.arguments as TxHomaData;

    final symbol = relay_chain_token_symbol;
    final nativeDecimal = decimals[symbols.indexOf(symbol)];
    final liquidDecimal = decimals[symbols.indexOf('L$symbol')];

    final amountStyle = TextStyle(
        fontSize: UI.getTextSize(16, context),
        fontWeight: FontWeight.bold,
        color: PluginColorsDark.headline1);

    final infoItems = <TxDetailInfoItem>[
      TxDetailInfoItem(
        label: 'Event',
        content: Text(tx.action!.replaceAll('homa.', ''), style: amountStyle),
      ),
      TxDetailInfoItem(
        label: dic['txs.action'],
        content: Text(dic['${tx.action}']!, style: amountStyle),
      )
    ];

    switch (tx.action) {
      case TxHomaData.actionMint:
        infoItems.addAll([
          TxDetailInfoItem(
            label: dic['dex.pay'],
            content: Text(
                '${Fmt.priceFloorBigInt(tx.amountPay, nativeDecimal, lengthMax: 6)} $symbol',
                style: amountStyle),
          ),
          TxDetailInfoItem(
            label: dic['dex.receive'],
            content: Text(
                '${Fmt.priceFloorBigInt(tx.amountReceive, liquidDecimal, lengthMax: 6)} L$symbol',
                style: amountStyle),
          )
        ]);
        break;
      case TxHomaData.actionRedeemedByFastMatch:
        infoItems.addAll([
          TxDetailInfoItem(
            label: dic['dex.pay'],
            content: Text(
                '${Fmt.priceFloorBigInt(tx.amountPay, liquidDecimal, lengthMax: 6)} L$symbol',
                style: amountStyle),
          ),
          TxDetailInfoItem(
            label: dic['dex.receive'],
            content: Text(
                '${Fmt.priceFloorBigInt(tx.amountReceive, nativeDecimal, lengthMax: 6)} $symbol',
                style: amountStyle),
          )
        ]);
        break;
      case TxHomaData.actionRedeem:
      case TxHomaData.actionLiteRedeem:
        infoItems.add(TxDetailInfoItem(
          label: dic['dex.pay'],
          content: Text(
              '${Fmt.priceFloorBigInt(tx.amountPay, liquidDecimal, lengthMax: 6)} L$symbol',
              style: amountStyle),
        ));
        break;

      case TxHomaData.actionRedeemedByUnbond:
        infoItems.add(TxDetailInfoItem(
          label: dic['dex.receive'],
          content: Text(
              '${Fmt.priceFloorBigInt(tx.amountReceive, nativeDecimal, lengthMax: 6)} $symbol',
              style: amountStyle),
        ));
        break;
      case TxHomaData.actionLiteRedeemed:
        infoItems.add(TxDetailInfoItem(
          label: dic['dex.receive'],
          content: Text(
              '${Fmt.priceFloorBigInt(tx.amountReceive, nativeDecimal, lengthMax: 6)} $symbol',
              style: amountStyle),
        ));
        break;
      case TxHomaData.actionRedeemed:
      case TxHomaData.actionWithdrawRedemption:
        infoItems.add(TxDetailInfoItem(
          label: dic['dex.receive'],
          content: Text(
              '${Fmt.priceFloorBigInt(tx.amountReceive, nativeDecimal, lengthMax: 6)} $symbol',
              style: amountStyle),
        ));
        break;
      case TxHomaData.actionRedeemCancel:
        infoItems.add(TxDetailInfoItem(
          label: dic['dex.receive'],
          content: Text(
              '${Fmt.priceFloorBigInt(tx.amountReceive, liquidDecimal, lengthMax: 6)} L$symbol',
              style: amountStyle),
        ));
    }

    return PluginTxDetail(
      current: keyring.current,
      success: true,
      action: dic['${tx.action}'],
      // blockNum: int.parse(tx.block),
      hash: tx.hash,
      blockTime:
          Fmt.dateTime(DateFormat("yyyy-MM-ddTHH:mm:ss").parse(tx.time, true)),
      networkName: plugin.basic.name,
      infoItems: infoItems,
    );
  }
}
