import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_plugin_karura/utils/uiUtils.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class LPStakePageParams {
  LPStakePageParams(this.poolId, this.action);
  final String action;
  final String poolId;
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

  String _validateAmount(String value, BigInt available, int decimals) {
    final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'common');

    String v = value.trim();
    try {
      if (v.isEmpty || double.parse(v) == 0) {
        return dic['amount.error'];
      }
    } catch (err) {
      return dic['amount.error'];
    }
    BigInt input = Fmt.tokenInt(v, decimals);
    if (!_isMax && input > available) {
      return dic['amount.low'];
    }
    final LPStakePageParams args = ModalRoute.of(context).settings.arguments;
    final balance = Fmt.balanceInt(
        widget.plugin.store.assets.tokenBalanceMap[args.poolId]?.amount ?? '0');
    if (balance == BigInt.zero) {
      final pair = args.poolId.split('-').toList();
      final min = pair[0] == widget.plugin.networkState.tokenSymbol[0]
          ? Fmt.balanceInt(
              widget.plugin.networkConst['balances']['existentialDeposit'])
          : Fmt.balanceInt(existential_deposit[pair[0]]);
      if (input < min) {
        return '${dic['amount.min']} ${Fmt.priceCeilBigInt(min, decimals, lengthMax: 6)}';
      }
    }
    return null;
  }

  void _onSetMax(BigInt max, int decimals) {
    setState(() {
      _amountCtrl.text = Fmt.bigIntToDouble(max, decimals).toStringAsFixed(6);
      _isMax = true;
    });
  }

  Future<void> _onSubmit(BigInt max, int decimals) async {
    if (!_formKey.currentState.validate()) return;

    final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');
    final LPStakePageParams params = ModalRoute.of(context).settings.arguments;
    final isStake = params.action == LPStakePage.actionStake;
    try {
      final actionDisabled =
          isStake ? action_earn_deposit_lp : action_earn_withdraw_lp;
      if (widget.plugin.store.setting.liveModules['earn']['actionsDisabled']
              [actionDisabled] ??
          false) {
        UIUtils.showInvalidActionAlert(context, actionDisabled);
        return;
      }
    } catch (err) {
      // ignore
    }

    final pool = params.poolId.split('-').map((e) => ({'Token': e})).toList();
    String input = _amountCtrl.text.trim();
    BigInt amount = Fmt.tokenInt(input, decimals);
    if (_isMax || max - amount < BigInt.one) {
      amount = max;
      input = Fmt.token(max, decimals);
    }
    final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
        arguments: TxConfirmParams(
          module: 'incentives',
          call: isStake ? 'depositDexShare' : 'withdrawDexShare',
          txTitle:
              '${dic['earn.${params.action}']} ${PluginFmt.tokenView(params.poolId)}',
          txDisplay: {
            "poolId": params.poolId,
            "amount": input,
          },
          params: [
            {'DEXShare': pool},
            amount.toString()
          ],
        ))) as Map;
    if (res != null) {
      Navigator.of(context).pop(res);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');
    final assetDic = I18n.of(context).getDic(i18n_full_dic_karura, 'common');
    final symbols = widget.plugin.networkState.tokenSymbol;
    final decimals = widget.plugin.networkState.tokenDecimals;

    final stableCoinDecimals = decimals[symbols.indexOf(karura_stable_coin)];

    final LPStakePageParams args = ModalRoute.of(context).settings.arguments;

    final token =
        args.poolId.split('-').firstWhere((e) => e != karura_stable_coin);
    final tokenDecimals = decimals[symbols.indexOf(token)];
    final shareDecimals = stableCoinDecimals >= tokenDecimals
        ? stableCoinDecimals
        : tokenDecimals;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${dic['earn.${args.action}']} ${PluginFmt.tokenView(args.poolId)}'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Observer(
          builder: (_) {
            final isStake = args.action == LPStakePage.actionStake;

            BigInt balance = BigInt.zero;
            if (!isStake) {
              final poolInfo =
                  widget.plugin.store.earn.dexPoolInfoMap[args.poolId];
              balance = poolInfo.shares;
            } else {
              balance = Fmt.balanceInt(widget.plugin.store.assets
                      .tokenBalanceMap[args.poolId]?.amount ??
                  '0');
            }

            final balanceView =
                Fmt.priceFloorBigInt(balance, shareDecimals, lengthMax: 6);
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
                            hintText: assetDic['amount'],
                            labelText:
                                '${assetDic['amount']} (${assetDic['amount.available']}: $balanceView)',
                            suffix: GestureDetector(
                              child: Text(
                                dic['loan.max'],
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor),
                              ),
                              onTap: () => _onSetMax(balance, shareDecimals),
                            ),
                          ),
                          inputFormatters: [
                            UI.decimalInputFormatter(shareDecimals)
                          ],
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          controller: _amountCtrl,
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          validator: (v) =>
                              _validateAmount(v, balance, shareDecimals),
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
                    onPressed: () => _onSubmit(balance, shareDecimals),
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
