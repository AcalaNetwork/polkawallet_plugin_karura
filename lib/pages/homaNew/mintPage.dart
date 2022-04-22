import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/pages/homaNew/redeemPage.dart';
import 'package:polkawallet_plugin_karura/pages/swapNew/bootstrapPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginInputBalance.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginLoadingWidget.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTextTag.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';

class MintPage extends StatefulWidget {
  MintPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/karura/homa/mint';

  @override
  _MintPageState createState() => _MintPageState();
}

class _MintPageState extends State<MintPage> {
  final TextEditingController _amountPayCtrl = new TextEditingController();

  String? _error;
  String _amountReceive = '';
  BigInt? _maxInput;
  bool isLoading = false;
  int _selectIndex = 0;

  Future<void> _updateReceiveAmount(double input) async {
    if (input == 0) {
      return null;
    }
    if (mounted) {
      setState(() {
        isLoading = true;
      });
      var data = await widget.plugin.api!.homa.calcHomaNewMintAmount(input);

      setState(() {
        isLoading = false;
        _amountReceive = "${data!['receive']}";
      });
    }
  }

  void _onSupplyAmountChange(String v, double balance, double minStake) {
    final supply = v.trim();
    setState(() {
      _maxInput = null;
    });

    final error = _validateInput(supply, balance, minStake);
    setState(() {
      _error = error;
      // if (error != null) {
      //   _amountReceive = '';
      // }
    });
    if (error != null) {
      return;
    }
    _updateReceiveAmount(double.parse(supply));
  }

  String? _validateInput(String supply, double balance, double minStake) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'common');
    final error = Fmt.validatePrice(supply, context);
    if (error != null) {
      return error;
    }
    final pay = double.parse(supply);
    if (_maxInput == null && pay > balance) {
      return dic!['amount.low'];
    }

    if (pay < minStake) {
      final minLabel = I18n.of(context)!
          .getDic(i18n_full_dic_karura, 'acala')!['homa.pool.min'];
      return '$minLabel   ${minStake.toStringAsFixed(4)}';
    }

    final homaEnv = widget.plugin.store!.homa.env!;
    if (double.tryParse(supply)! + homaEnv.totalStaking >
        homaEnv.stakingSoftCap!) {
      return I18n.of(context)!
          .getDic(i18n_full_dic_karura, 'acala')!['homa.pool.cap.error'];
    }

    return error;
  }

  void _onSetMax(BigInt max, int decimals, double balance, double minStake) {
    final homaEnv = widget.plugin.store!.homa.env!;
    final staked = Fmt.tokenInt(homaEnv.totalStaking.toString(), decimals);
    final cap = Fmt.tokenInt(homaEnv.stakingSoftCap.toString(), decimals);
    if (staked + max > cap) {
      max = cap - staked;
    }

    final amount = Fmt.bigIntToDouble(max, decimals);
    setState(() {
      _amountPayCtrl.text = amount.toStringAsFixed(6);
      _maxInput = max;
      _error = _validateInput(amount.toString(), balance, minStake);
    });

    if (_error == null) {
      _updateReceiveAmount(amount);
    }
  }

  Future<void> _onSubmit(int stakeDecimal) async {
    final pay = _amountPayCtrl.text.trim();

    if (_error != null || pay.isEmpty) return;

    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;

    final amount = _maxInput != null
        ? _maxInput.toString()
        : Fmt.tokenInt(pay, stakeDecimal).toString();

    if (_selectIndex == 0) {
      final receive = Fmt.balanceInt(_amountReceive).toString();
      final batchTxs = [
        'api.tx.homa.mint("$amount")',
        'api.tx.honzon.adjustLoan({Token: "L$relay_chain_token_symbol"}, "$receive", 0)',
      ];

      final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
          arguments: TxConfirmParams(
            module: 'utility',
            call: 'batch',
            txTitle: '${dic['homa.mint']} L$relay_chain_token_symbol',
            txDisplay: {'': dic['v3.homa.stake.more']},
            txDisplayBold: {
              dic['dex.pay']!: Text(
                '$pay $relay_chain_token_symbol',
                style: Theme.of(context)
                    .textTheme
                    .headline1
                    ?.copyWith(color: Colors.white),
              ),
              dic['dex.receive']!: Text(
                '≈ ${Fmt.priceFloorBigInt(Fmt.balanceInt(_amountReceive), 12, lengthMax: 4)} L$relay_chain_token_symbol',
                style: Theme.of(context)
                    .textTheme
                    .headline1
                    ?.copyWith(color: Colors.white),
              ),
            },
            params: [],
            rawParams: '[[${batchTxs.join(',')}]]',
            isPlugin: true,
          ))) as Map?;

      if (res != null) {
        Navigator.of(context).pop('1');
      }
      return;
    }

    /// else only send mint call
    final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
        arguments: TxConfirmParams(
          module: 'homa',
          call: 'mint',
          txTitle: '${dic['homa.mint']} L$relay_chain_token_symbol',
          txDisplay: {},
          txDisplayBold: {
            dic['dex.pay']!: Text(
              '$pay $relay_chain_token_symbol',
              style: Theme.of(context)
                  .textTheme
                  .headline1
                  ?.copyWith(color: Colors.white),
            ),
            dic['dex.receive']!: Text(
              '≈ ${Fmt.priceFloorBigInt(Fmt.balanceInt(_amountReceive), 12, lengthMax: 4)} L$relay_chain_token_symbol',
              style: Theme.of(context)
                  .textTheme
                  .headline1
                  ?.copyWith(color: Colors.white),
            ),
          },
          params: [amount],
          isPlugin: true,
        ))) as Map?;

    if (res != null) {
      Navigator.of(context).pop('1');
    }
  }

  @override
  void dispose() {
    _amountPayCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(_) {
    return Observer(
      builder: (BuildContext context) {
        final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;

        final symbols = widget.plugin.networkState.tokenSymbol!;
        final stakeToken = relay_chain_token_symbol;
        final decimals = widget.plugin.networkState.tokenDecimals!;

        final karBalance = Fmt.balanceDouble(
            widget.plugin.balances.native!.availableBalance.toString(),
            decimals[0]);
        final balanceData =
            widget.plugin.store!.assets.tokenBalanceMap[stakeToken];

        final stakeDecimal = decimals[symbols.indexOf(stakeToken)];
        final balanceDouble =
            Fmt.balanceDouble(balanceData?.amount ?? "0", stakeDecimal);

        final isDataLoading = widget.plugin.store!.homa.env == null;

        final minStake = widget.plugin.store!.homa.env?.mintThreshold;

        bool isRewardsOpen = false;
        double rewardApr = 0;
        final rewards =
            widget.plugin.store!.earn.incentives.loans?['L$stakeToken'];
        if ((rewards ?? []).length > 0) {
          rewards?.forEach((e) {
            if (e.tokenNameId == karura_stable_coin && (e.amount ?? 0) > 0) {
              isRewardsOpen = true;
              rewardApr = e.apr ?? 0;
            }
          });
        }

        return PluginScaffold(
          appBar: PluginAppBar(
              title: Text('${dic['homa.mint']} L$stakeToken'),
              centerTitle: true),
          body: SafeArea(
              child: isDataLoading
                  ? Container(
                      height: double.infinity,
                      width: double.infinity,
                      child: Center(child: PluginLoadingWidget()),
                    )
                  : ListView(
                      padding: EdgeInsets.all(16),
                      children: <Widget>[
                        PluginInputBalance(
                          tokenViewFunction: (value) {
                            return PluginFmt.tokenView(value);
                          },
                          inputCtrl: _amountPayCtrl,
                          margin: EdgeInsets.only(bottom: 2),
                          titleTag: dic['earn.stake'],
                          onInputChange: (v) => _onSupplyAmountChange(
                              v, balanceDouble, minStake!),
                          onSetMax: karBalance > 0.1
                              ? (v) => _onSetMax(
                                  v, stakeDecimal, balanceDouble, minStake!)
                              : null,
                          onClear: () {
                            setState(() {
                              _amountPayCtrl.text = '';
                            });
                            _onSupplyAmountChange('', balanceDouble, minStake!);
                          },
                          balance: widget
                              .plugin.store!.assets.tokenBalanceMap[stakeToken],
                          tokenIconsMap: widget.plugin.tokenIcons,
                        ),
                        ErrorMessage(
                          _error,
                          margin: EdgeInsets.symmetric(vertical: 2),
                        ),
                        Visibility(
                            visible: isLoading, child: PluginLoadingWidget()),
                        Visibility(
                            visible: _amountReceive.isNotEmpty &&
                                _amountPayCtrl.text.length > 0,
                            child: PluginInputBalance(
                              tokenViewFunction: (value) {
                                return PluginFmt.tokenView(value);
                              },
                              enabled: false,
                              text: Fmt.priceFloorBigInt(
                                  Fmt.balanceInt(_amountReceive), 12,
                                  lengthMax: 4),
                              margin: EdgeInsets.only(bottom: 2),
                              titleTag: dic['homa.mint'],
                              balance: widget.plugin.store!.assets
                                  .tokenBalanceMap["L$stakeToken"],
                              tokenIconsMap: widget.plugin.tokenIcons,
                            )),
                        Container(
                          margin: EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                dic['v3.homa.minStakingAmmount']!,
                                style: Theme.of(context)
                                    .textTheme
                                    .headline4
                                    ?.copyWith(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                              ),
                              Text(
                                "$minStake $stakeToken",
                                style: Theme.of(context)
                                    .textTheme
                                    .headline4
                                    ?.copyWith(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                              )
                            ],
                          ),
                        ),
                        Visibility(
                          visible: isRewardsOpen,
                          child: Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: Column(
                                children: [
                                  PluginTextTag(
                                    title: dic['v3.homa.stake.method']!,
                                  ),
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 11, vertical: 14),
                                    margin: EdgeInsets.only(bottom: 20),
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Color(0xCCFFFFFF), width: 1),
                                        borderRadius: const BorderRadius.only(
                                            bottomLeft: Radius.circular(17),
                                            topRight: Radius.circular(17),
                                            bottomRight: Radius.circular(17))),
                                    child: Column(
                                      children: [
                                        UnStakeTypeItemWidget(
                                          title: dic['v3.homa.stake.more']!,
                                          value:
                                              "${dic['v3.homa.stake.apy.total']!} ${(19.92 + rewardApr * 100).toStringAsFixed(2)}%",
                                          subtitle: Container(
                                            margin: EdgeInsets.only(top: 8),
                                            child: Text(
                                              '(${dic['v3.homa.stake.apy.protocol']} 19.92% + ${dic['v3.homa.stake.apy.reward']} ${(rewardApr * 100).toStringAsFixed(2)}%)',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headline6
                                                  ?.copyWith(
                                                      color: Color(0xFFFC8156)),
                                            ),
                                          ),
                                          describe: dic[
                                              'v3.homa.stake.more.describe']!,
                                          margin: EdgeInsets.only(bottom: 12),
                                          valueColor: Color(0xFFFC8156),
                                          isSelect: _selectIndex == 0,
                                          ontap: () {
                                            setState(() {
                                              _selectIndex = 0;
                                            });
                                          },
                                        ),
                                        UnStakeTypeItemWidget(
                                          title: dic['v3.homa.stake']!,
                                          value:
                                              "${dic['v3.homa.stake.apy.total']!} 19.92%",
                                          subtitle: Container(
                                            margin: EdgeInsets.only(top: 8),
                                            child: Text(
                                              '(${dic['v3.homa.stake.apy.protocol']} 19.92%)',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headline6
                                                  ?.copyWith(
                                                      color: Color(0xFFFC8156)),
                                            ),
                                          ),
                                          describe: dic[
                                              'v3.homa.stake.more.describe']!,
                                          valueColor: Color(0xFFFC8156),
                                          isSelect: _selectIndex == 1,
                                          ontap: () {
                                            setState(() {
                                              _selectIndex = 1;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )),
                        ),
                        Padding(
                            padding: EdgeInsets.only(top: 8, bottom: 32),
                            child: PluginButton(
                              title: dic['v3.loan.submit']!,
                              onPressed: () => _onSubmit(stakeDecimal),
                            ))
                      ],
                    )),
        );
      },
    );
  }
}
