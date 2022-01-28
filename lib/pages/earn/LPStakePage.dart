import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/api/types/dexPoolInfoData.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class LPStakePageParams {
  LPStakePageParams(this.pool, this.action);
  final String action;
  final DexPoolData pool;
}

class LPStakePage extends StatefulWidget {
  LPStakePage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/karura/earn/stake';
  static const String actionStake = 'stake';
  static const String actionUnStake = 'unStake';

  @override
  _LPStakePage createState() => _LPStakePage();
}

class _LPStakePage extends State<LPStakePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _amountCtrl = new TextEditingController();

  bool _isMax = false;

  String? _validateAmount(String value, BigInt? available, int? decimals) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'common');

    String v = value.trim();
    final error = Fmt.validatePrice(value, context);
    if (error != null) {
      return error;
    }
    BigInt input = Fmt.tokenInt(v, decimals!);
    if (!_isMax && input > available!) {
      return dic!['amount.low'];
    }
    final LPStakePageParams args =
        ModalRoute.of(context)!.settings.arguments as LPStakePageParams;
    final balance =
        widget.plugin.store!.assets.tokenBalanceMap[args.pool.tokenNameId];
    final balanceInt = Fmt.balanceInt(balance?.amount ?? '0');
    if (balanceInt == BigInt.zero) {
      final min = Fmt.balanceInt(balance?.minBalance ?? '0');
      if (input < min) {
        return '${dic!['amount.min']} ${Fmt.priceCeilBigInt(min, decimals, lengthMax: 6)}';
      }
    }
    return null;
  }

  void _onSetMax(BigInt? max, int? decimals) {
    setState(() {
      _amountCtrl.text = Fmt.bigIntToDouble(max, decimals!).toStringAsFixed(6);
      _isMax = true;
    });
  }

  Future<void> _onSubmit(BigInt? max, int? decimals) async {
    if (!_formKey.currentState!.validate()) return;

    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    final LPStakePageParams params =
        ModalRoute.of(context)!.settings.arguments as LPStakePageParams;
    final isStake = params.action == LPStakePage.actionStake;

    final tokenPair = params.pool.tokens!
        .map((e) => AssetsUtils.tokenDataFromCurrencyId(widget.plugin, e))
        .toList();
    final poolTokenSymbol =
        tokenPair.map((e) => PluginFmt.tokenView(e?.symbol)).toList().join('-');

    String input = _amountCtrl.text.trim();
    BigInt? amount = Fmt.tokenInt(input, decimals!);
    if (_isMax || max! - amount < BigInt.one) {
      amount = max;
      input = Fmt.token(max, decimals);
    }
    final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
        arguments: TxConfirmParams(
          module: 'incentives',
          call: isStake ? 'depositDexShare' : 'withdrawDexShare',
          txTitle: '${dic['earn.${params.action}']} $poolTokenSymbol LP',
          txDisplay: {
            dic['earn.pool']: poolTokenSymbol,
          },
          txDisplayBold: {
            dic['loan.amount']!: Text(
              '$input LP',
              style: Theme.of(context).textTheme.headline1,
            ),
          },
          params: [
            {'DEXShare': params.pool.tokens},
            amount.toString()
          ],
        ))) as Map?;
    if (res != null) {
      Navigator.of(context).pop(res);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    final assetDic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'common');

    final LPStakePageParams args =
        ModalRoute.of(context)!.settings.arguments as LPStakePageParams;

    final tokenPair = args.pool.tokens!
        .map((e) => AssetsUtils.tokenDataFromCurrencyId(widget.plugin, e))
        .toList();
    final poolTokenSymbol =
        PluginFmt.tokenView(tokenPair.map((e) => e?.symbol).join('-'));

    return Scaffold(
      appBar: AppBar(
        title: Text('${dic['earn.${args.action}']} $poolTokenSymbol'),
        centerTitle: true,
        leading: BackBtn(),
      ),
      body: SafeArea(
        child: Observer(
          builder: (_) {
            final isStake = args.action == LPStakePage.actionStake;

            BigInt? balance = BigInt.zero;
            if (!isStake) {
              final poolInfo = widget
                  .plugin.store!.earn.dexPoolInfoMap[args.pool.tokenNameId]!;
              balance = poolInfo.shares;
            } else {
              balance = Fmt.balanceInt(widget.plugin.store!.assets
                      .tokenBalanceMap[args.pool.tokenNameId]?.amount ??
                  '0');
            }

            final balanceView = Fmt.priceFloorBigInt(
                balance, tokenPair[0]!.decimals!,
                lengthMax: 6);
            return Column(
              children: [
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: EdgeInsets.only(left: 16, right: 16),
                      children: [
                        TextFormField(
                          decoration: InputDecoration(
                            hintText: assetDic!['amount'],
                            labelText:
                                '${assetDic['amount']} (${assetDic['amount.available']}: $balanceView)',
                            suffix: GestureDetector(
                              child: Text(
                                dic['loan.max']!,
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor),
                              ),
                              onTap: () =>
                                  _onSetMax(balance, tokenPair[0]!.decimals),
                            ),
                          ),
                          inputFormatters: [
                            UI.decimalInputFormatter(tokenPair[0]!.decimals!)!
                          ],
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          controller: _amountCtrl,
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          validator: (v) => _validateAmount(
                              v!, balance, tokenPair[0]!.decimals),
                          onChanged: (_) {
                            if (_isMax) {
                              setState(() {
                                _isMax = false;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: RoundedButton(
                    text: dic['earn.${args.action}'],
                    onPressed: () => _onSubmit(balance, tokenPair[0]!.decimals),
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }
}
