import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/api/types/calcHomaMintAmountData.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/pages/swap/bootstrapPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginInputBalance.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginLoadingWidget.dart';

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
  CalcHomaMintAmountData? _data;
  bool isLoading = false;

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
        _data = CalcHomaMintAmountData("", "", null);
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

    final call = _data?.suggestRedeemRequests != null &&
            _data!.suggestRedeemRequests!.length > 0
        ? 'mintForRequests'
        : 'mint';

    final List params = [
      _maxInput != null
          ? _maxInput.toString()
          : Fmt.tokenInt(pay, stakeDecimal).toString()
    ];
    if (_data?.suggestRedeemRequests != null &&
        _data!.suggestRedeemRequests!.length > 0) {
      params.add(_data!.suggestRedeemRequests);
    }
    final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
        arguments: TxConfirmParams(
          module: 'homa',
          call: call,
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
              '≈ ${Fmt.priceFloor(double.tryParse(_amountReceive), lengthMax: 4)} L$relay_chain_token_symbol',
              style: Theme.of(context)
                  .textTheme
                  .headline1
                  ?.copyWith(color: Colors.white),
            ),
          },
          params: params,
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

        final minStake = widget.plugin.store!.homa.env!.mintThreshold;

        return PluginScaffold(
          appBar: PluginAppBar(
              title: Text('${dic['homa.mint']} L$stakeToken'),
              centerTitle: true),
          body: SafeArea(
              child: ListView(
            padding: EdgeInsets.all(16),
            children: <Widget>[
              PluginInputBalance(
                inputCtrl: _amountPayCtrl,
                margin: EdgeInsets.only(bottom: 2),
                titleTag: dic['earn.stake'],
                onInputChange: (v) =>
                    _onSupplyAmountChange(v, balanceDouble, minStake),
                onSetMax: karBalance > 0.1
                    ? (v) => _onSetMax(v, stakeDecimal, balanceDouble, minStake)
                    : null,
                onClear: () {
                  setState(() {
                    _amountPayCtrl.text = '';
                  });
                  _onSupplyAmountChange('', balanceDouble, minStake);
                },
                balance:
                    widget.plugin.store!.assets.tokenBalanceMap[stakeToken],
                tokenIconsMap: widget.plugin.tokenIcons,
              ),
              ErrorMessage(
                _error,
                margin: EdgeInsets.symmetric(vertical: 2),
              ),
              Visibility(visible: isLoading, child: PluginLoadingWidget()),
              Visibility(
                  visible: _amountReceive.isNotEmpty &&
                      _amountPayCtrl.text.length > 0,
                  child: PluginInputBalance(
                    enabled: false,
                    text: _amountReceive,
                    margin: EdgeInsets.only(bottom: 2),
                    titleTag: dic['homa.mint'],
                    balance: widget
                        .plugin.store!.assets.tokenBalanceMap["L$stakeToken"],
                    tokenIconsMap: widget.plugin.tokenIcons,
                  )),
              Container(
                margin: EdgeInsets.only(top: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dic['v3.homa.minStakingAmmount']!,
                      style: Theme.of(context).textTheme.headline4?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      "$minStake $stakeToken",
                      style: Theme.of(context).textTheme.headline4?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    )
                  ],
                ),
              ),
              Padding(
                  padding: EdgeInsets.only(top: 300, bottom: 38),
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
