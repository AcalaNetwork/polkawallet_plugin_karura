import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/api/types/calcHomaMintAmountData.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/pages/swap/bootstrapPage.dart';
import 'package:polkawallet_plugin_karura/pages/swap/swapTokenInput.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/infoItemRow.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
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
  CalcHomaMintAmountData? _data;

  Future<void> _updateReceiveAmount(double input) async {
    if (mounted) {
      final isHomaAlive =
          (ModalRoute.of(context)!.settings.arguments as Map)['isHomaAlive'];
      var data = await (isHomaAlive
          ? widget.plugin.api!.homa.calcHomaNewMintAmount(input)
          : widget.plugin.api!.homa.calcHomaMintAmount(input));

      setState(() {
        _amountReceive = "${isHomaAlive ? data!['receive'] : data!['received']}";
        _data = isHomaAlive
            ? CalcHomaMintAmountData("", "", null)
            : CalcHomaMintAmountData.fromJson(data as Map<String, dynamic>);
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

    if (pay <= minStake) {
      final minLabel = I18n.of(context)!
          .getDic(i18n_full_dic_karura, 'acala')!['homa.pool.min'];
      return '$minLabel > ${minStake.toStringAsFixed(4)}';
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

    _updateReceiveAmount(amount);
  }

  Future<void> _onSubmit(int stakeDecimal) async {
    final pay = _amountPayCtrl.text.trim();

    if (_error != null || pay.isEmpty) return;

    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;

    final isHomaAlive =
        (ModalRoute.of(context)!.settings.arguments as Map)['isHomaAlive'];

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
          module: isHomaAlive ? 'homa' : 'homaLite',
          call: call,
          txTitle: '${dic['homa.mint']} L$relay_chain_token_symbol',
          txDisplay: {},
          txDisplayBold: {
            dic['dex.pay']!: Text(
              '$pay $relay_chain_token_symbol',
              style: Theme.of(context).textTheme.headline1,
            ),
            dic['dex.receive']!: Text(
              '≈ ${Fmt.priceFloor(double.tryParse(_amountReceive), lengthMax: 4)} L$relay_chain_token_symbol',
              style: Theme.of(context).textTheme.headline1,
            ),
          },
          params: params,
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

        final minStake = widget.plugin.store!.homa.env != null
            ? widget.plugin.store!.homa.env!.mintThreshold
            : (Fmt.balanceDouble(
                    widget
                        .plugin.networkConst['homaLite']['minimumMintThreshold']
                        .toString(),
                    stakeDecimal) +
                Fmt.balanceDouble(
                    widget.plugin.networkConst['homaLite']['mintFee']
                        .toString(),
                    stakeDecimal));

        return Scaffold(
          appBar: AppBar(
            title: Text('${dic['homa.mint']} L$stakeToken'),
            centerTitle: true,
            leading: BackBtn(),
          ),
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: <Widget>[
                RoundedCard(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SwapTokenInput(
                        title: dic['dex.pay'],
                        inputCtrl: _amountPayCtrl,
                        balance: widget
                            .plugin.store!.assets.tokenBalanceMap[stakeToken],
                        tokenIconsMap: widget.plugin.tokenIcons,
                        onInputChange: (v) =>
                            _onSupplyAmountChange(v, balanceDouble, minStake),
                        onSetMax: karBalance > 0.1
                            ? (v) => _onSetMax(
                                v, stakeDecimal, balanceDouble, minStake)
                            : null,
                        onClear: () {
                          setState(() {
                            _amountPayCtrl.text = '';
                          });
                          _onSupplyAmountChange('', balanceDouble, minStake);
                        },
                      ),
                      ErrorMessage(_error),
                      Visibility(
                          visible: _amountReceive.isNotEmpty,
                          child: Container(
                            margin: EdgeInsets.only(top: 16),
                            child: InfoItemRow(dic['dex.receive']!,
                                '$_amountReceive L$stakeToken'),
                          )),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: RoundedButton(
                    text: dic['homa.mint'],
                    onPressed: () => _onSubmit(stakeDecimal),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
