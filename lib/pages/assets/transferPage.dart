import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/pages/currencySelectPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/api/types/txInfoData.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/addressInputField.dart';
import 'package:polkawallet_ui/components/currencyWithIcon.dart';
import 'package:polkawallet_ui/components/tapTooltip.dart';
import 'package:polkawallet_ui/components/textTag.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/pages/scanPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';

class TransferPage extends StatefulWidget {
  TransferPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static final String route = '/assets/token/transfer';

  @override
  _TransferPageState createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _amountCtrl = new TextEditingController();

  KeyPairData _accountTo;
  List<KeyPairData> _accountOptions = [];
  String _token;
  String _chainTo;

  String _accountToError;

  TxFeeEstimateResult _fee;

  Future<String> _checkAccountTo(KeyPairData acc) async {
    if (widget.keyring.allAccounts.indexWhere((e) => e.pubKey == acc.pubKey) >=
        0) {
      return null;
    }

    final addressCheckValid = await widget.plugin.sdk.webView.evalJavascript(
        '(account.checkAddressFormat != undefined ? {}:null)',
        wrapPromise: false);
    if (addressCheckValid != null) {
      final res = await widget.plugin.sdk.api.account.checkAddressFormat(
          acc.address,
          network_ss58_format[_chainTo ?? widget.plugin.basic.name]);
      if (res != null && !res) {
        return I18n.of(context)
            .getDic(i18n_full_dic_ui, 'account')['ss58.mismatch'];
      }
    }
    return null;
  }

  Future<void> _validateAccountTo(KeyPairData acc) async {
    final error = await _checkAccountTo(acc);
    setState(() {
      _accountToError = error;
    });
  }

  Future<String> _getTxFee({bool isXCM = false, bool reload = false}) async {
    if (_fee?.partialFee != null && !reload) {
      return _fee.partialFee.toString();
    }

    final sender = TxSenderData(
        widget.keyring.current.address, widget.keyring.current.pubKey);
    final txInfo =
        TxInfoData(isXCM ? 'xTokens' : 'currencies', 'transfer', sender);
    final fee = await widget.plugin.sdk.api.tx.estimateFees(
        txInfo,
        isXCM
            ? [
                {'Token': _token},
                '1000000000',
                {
                  'X2': [
                    'Parent',
                    {
                      'AccountId32': {
                        'id': _accountTo.address,
                        'network': 'Any'
                      }
                    }
                  ]
                },
                // params.weight
                xcm_dest_weight
              ]
            : [
                widget.keyring.current.address,
                {'Token': _token, 'decimals': 12},
                '1000000000'
              ]);
    if (mounted) {
      setState(() {
        _fee = fee;
      });
    }
    return fee.partialFee.toString();
  }

  Future<void> _onScan() async {
    final to = await Navigator.of(context).pushNamed(ScanPage.route);
    if (to == null) return;
    final acc = KeyPairData();
    acc.address = (to as QRCodeResult).address.address;
    acc.name = (to as QRCodeResult).address.name;
    final res = await Future.wait([
      widget.plugin.sdk.api.account.getAddressIcons([acc.address]),
      _checkAccountTo(acc),
    ]);
    if (res != null && res[0] != null) {
      final List icon = res[0];
      acc.icon = icon[0][1];
    }
    setState(() {
      _accountTo = acc;
      _accountToError = res[1];
    });
    print(_accountTo.address);
  }

  /// XCM only support KSM transfer back to Kusama.
  void _onSelectChain() {
    final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');

    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(dic['cross.chain.select']),
        actions: [widget.plugin.basic.name, relay_chain_name].map((e) {
          return CupertinoActionSheetAction(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(right: 8),
                  width: 32,
                  height: 32,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: e == widget.plugin.basic.name
                        ? widget.plugin.basic.icon
                        : TokenIcon(
                            relay_chain_token_symbol, widget.plugin.tokenIcons),
                  ),
                ),
                Text(
                  e.toUpperCase(),
                )
              ],
            ),
            onPressed: () {
              if (e != _chainTo) {
                // set ss58 of _chainTo so we can get according address
                // from AddressInputField
                widget.keyring.setSS58(
                    e == relay_chain_name ? 2 : widget.plugin.basic.ss58);
                final options = widget.keyring.allWithContacts.toList();
                widget.keyring.setSS58(widget.plugin.basic.ss58);
                setState(() {
                  _chainTo = e;
                  _accountOptions = options;

                  final isInAccountList = options
                          .indexWhere((e) => e.pubKey == _accountTo.pubKey) >=
                      0;
                  if (isInAccountList) {
                    _accountTo = options
                        .firstWhere((e) => e.pubKey == _accountTo.pubKey);
                  }
                });

                _validateAccountTo(_accountTo);

                // update estimated tx fee if switch ToChain
                _getTxFee(isXCM: e == relay_chain_name, reload: true);
              }
              Navigator.of(context).pop();
            },
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          child: Text(I18n.of(context)
              .getDic(i18n_full_dic_karura, 'common')['cancel']),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  TxConfirmParams _getTxParams(String chainTo) {
    if (_accountToError == null && _formKey.currentState.validate()) {
      final decimals =
          widget.plugin.store.assets.tokenBalanceMap[_token].decimals;

      /// send XCM tx if cross chain
      if (chainTo != widget.plugin.basic.name) {
        final dicAcala = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');
        return TxConfirmParams(
          txTitle: '${dicAcala['transfer']} $_token (${dicAcala['cross.xcm']})',
          module: 'xTokens',
          call: 'transfer',
          txDisplay: {
            "chain": chainTo,
            "destination": _accountTo.address,
            "currency": _token,
            "amount": _amountCtrl.text.trim(),
          },
          params: [
            // params.currencyId
            {'Token': _token},
            // params.amount
            Fmt.tokenInt(_amountCtrl.text.trim(), decimals).toString(),
            // params.dest
            {
              'X2': [
                'Parent',
                {
                  'AccountId32': {'id': _accountTo.address, 'network': 'Any'}
                }
              ]
            },
            // params.weight
            xcm_dest_weight
          ],
        );
      }

      /// else return normal transfer
      final dexShare = _token.toUpperCase().split('-');

      final params = [
        // params.to
        _accountTo.address,
        // params.currencyId
        _token.contains('-')
            ? {
                'DEXShare': dexShare.map((e) => ({'Token': e})).toList(),
                'decimals': decimals
              }
            : {'Token': _token.toUpperCase(), 'decimals': decimals},
        // params.amount
        Fmt.tokenInt(_amountCtrl.text.trim(), decimals).toString(),
      ];
      final tokenView = PluginFmt.tokenView(_token);
      return TxConfirmParams(
        module: 'currencies',
        call: 'transfer',
        txTitle:
            '${I18n.of(context).getDic(i18n_full_dic_karura, 'acala')['transfer']} $tokenView',
        txDisplay: {
          "destination": _accountTo.address,
          "currency": tokenView,
          "amount": _amountCtrl.text.trim(),
        },
        params: params,
      );
    }
    return null;
  }

  Future<void> _initAccountTo(KeyPairData acc) async {
    final to = KeyPairData();
    to.address = acc.address;
    to.pubKey = acc.pubKey;
    setState(() {
      _accountTo = to;
    });
    final icon =
        await widget.plugin.sdk.api.account.getAddressIcons([acc.address]);
    if (icon != null) {
      final accWithIcon = KeyPairData();
      accWithIcon.address = acc.address;
      accWithIcon.pubKey = acc.pubKey;
      accWithIcon.icon = icon[0][1];
      setState(() {
        _accountTo = accWithIcon;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final String token = ModalRoute.of(context).settings.arguments;
      setState(() {
        _token = token;
        _accountOptions = widget.keyring.allWithContacts.toList();
      });

      _getTxFee();

      if (widget.keyring.allWithContacts.length > 0) {
        _initAccountTo(widget.keyring.allWithContacts[0]);
      }
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'common');
        final dicAcala = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');
        final String args = ModalRoute.of(context).settings.arguments;
        final token = _token ?? args;
        final tokenView = PluginFmt.tokenView(token);

        final relayChainToken = relay_chain_token_symbol;

        final nativeToken = widget.plugin.networkState.tokenSymbol[0];
        final decimals =
            widget.plugin.store.assets.tokenBalanceMap[token]?.decimals ?? 12;
        final balanceData =
            widget.plugin.store.assets.tokenBalanceMap[token.toUpperCase()];
        final available = Fmt.balanceInt(balanceData?.amount) -
            Fmt.balanceInt(balanceData?.locked);
        final existDepositToken =
            token.contains('-') ? token.split('-')[0] : token;
        final existDeposit = existDepositToken == nativeToken
            ? Fmt.balanceInt(widget
                .plugin.networkConst['balances']['existentialDeposit']
                .toString())
            : Fmt.balanceInt(existential_deposit[existDepositToken]);

        final chainTo = _chainTo ?? widget.plugin.basic.name;
        final isCrossChain = widget.plugin.basic.name != chainTo;
        final destExistDeposit = isCrossChain
            ? Fmt.balanceInt(
                relay_chain_xcm_fees[chainTo]['existentialDeposit'])
            : BigInt.zero;
        final destFee = isCrossChain
            ? Fmt.balanceInt(relay_chain_xcm_fees[chainTo]['fee'])
            : BigInt.zero;

        final colorGrey = Theme.of(context).unselectedWidgetColor;

        return Scaffold(
          appBar: AppBar(
            title: Text(dic['transfer']),
            centerTitle: true,
            actions: <Widget>[
              IconButton(
                padding: EdgeInsets.only(right: 8),
                icon: SvgPicture.asset(
                  'assets/images/scan.svg',
                  color: Theme.of(context).cardColor,
                  width: 28,
                ),
                onPressed: _onScan,
              )
            ],
          ),
          body: SafeArea(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: EdgeInsets.all(16),
                      children: <Widget>[
                        AddressInputField(
                          widget.plugin.sdk.api,
                          _accountOptions,
                          label: dic['address'],
                          initialValue: _accountTo,
                          onChanged: (KeyPairData acc) async {
                            final error = await _checkAccountTo(acc);
                            setState(() {
                              _accountTo = acc;
                              _accountToError = error;
                            });
                          },
                          key: ValueKey<KeyPairData>(_accountTo),
                        ),
                        _accountToError != null
                            ? Container(
                                margin: EdgeInsets.only(top: 4),
                                child: Text(_accountToError,
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.red)),
                              )
                            : Container(),
                        TextFormField(
                          decoration: InputDecoration(
                            hintText: dic['amount'],
                            labelText:
                                '${dic['amount']} (${dic['balance']}: ${Fmt.priceFloorBigInt(
                              available,
                              decimals,
                              lengthMax: 6,
                            )})',
                          ),
                          inputFormatters: [UI.decimalInputFormatter(decimals)],
                          controller: _amountCtrl,
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          validator: (v) {
                            if (v.isEmpty) {
                              return dic['amount.error'];
                            }
                            if (double.parse(v.trim()) >
                                available / BigInt.from(pow(10, decimals))) {
                              return dic['amount.low'];
                            }
                            return null;
                          },
                        ),
                        Container(
                          color: Theme.of(context).canvasColor,
                          margin: EdgeInsets.only(top: 16, bottom: 16),
                          child: GestureDetector(
                            child: Container(
                              color: Theme.of(context).canvasColor,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Container(
                                    margin: EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      dic['currency'],
                                      style: TextStyle(
                                          color: colorGrey, fontSize: 12),
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      CurrencyWithIcon(
                                        tokenView,
                                        TokenIcon(
                                            token, widget.plugin.tokenIcons),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 18,
                                        color: colorGrey,
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            onTap: () async {
                              final tokens = widget
                                  .plugin.store.assets.tokenBalanceMap.keys
                                  .toList();
                              final res = await Navigator.of(context).pushNamed(
                                  CurrencySelectPage.route,
                                  arguments: tokens);
                              if (res != null && res != _token) {
                                // reload tx fee if user switch to normal transfer from XCM
                                if (isCrossChain) {
                                  _getTxFee(isXCM: false, reload: true);
                                }

                                setState(() {
                                  _token = res;
                                  _chainTo = widget.plugin.basic.name;
                                });

                                _validateAccountTo(_accountTo);
                              }
                            },
                          ),
                        ),
                        token == relayChainToken
                            ? GestureDetector(
                                child: Container(
                                  color: Theme.of(context).canvasColor,
                                  margin: EdgeInsets.only(bottom: 16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Padding(
                                        padding: EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          dicAcala['cross.chain'],
                                          style: TextStyle(
                                              color: colorGrey, fontSize: 12),
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          Row(
                                            children: <Widget>[
                                              Container(
                                                margin:
                                                    EdgeInsets.only(right: 8),
                                                width: 32,
                                                height: 32,
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(32),
                                                  child: isCrossChain
                                                      ? TokenIcon(
                                                          token,
                                                          widget.plugin
                                                              .tokenIcons)
                                                      : widget
                                                          .plugin.basic.icon,
                                                ),
                                              ),
                                              Text(chainTo.toUpperCase())
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              isCrossChain
                                                  ? TextTag(
                                                      dicAcala['cross.xcm'],
                                                      margin: EdgeInsets.only(
                                                          right: 8),
                                                      color: Colors.red)
                                                  : Container(),
                                              Icon(
                                                Icons.arrow_forward_ios,
                                                size: 18,
                                                color: colorGrey,
                                              )
                                            ],
                                          )
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                onTap: _onSelectChain,
                              )
                            : Container(),
                        isCrossChain
                            ? Padding(
                                padding: EdgeInsets.only(top: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.only(right: 4),
                                        child: Text(dicAcala['cross.exist']),
                                      ),
                                    ),
                                    Expanded(
                                      child: TapTooltip(
                                        message: dicAcala['cross.exist.msg'],
                                        child: Icon(
                                          Icons.info,
                                          size: 16,
                                          color: Theme.of(context)
                                              .unselectedWidgetColor,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 0,
                                      child: Text(
                                          '${Fmt.priceCeilBigInt(destExistDeposit, decimals, lengthMax: 6)} $tokenView'),
                                    )
                                  ],
                                ),
                              )
                            : Container(),
                        isCrossChain
                            ? Padding(
                                padding: EdgeInsets.only(top: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.only(right: 4),
                                        child: Text(dicAcala['cross.fee']),
                                      ),
                                    ),
                                    Text(
                                        '${Fmt.priceCeilBigInt(destFee, decimals, lengthMax: 6)} $tokenView'),
                                  ],
                                ),
                              )
                            : Container(),
                        Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child: Text(dicAcala['transfer.exist']),
                                ),
                              ),
                              TapTooltip(
                                message: dicAcala['cross.exist.msg'],
                                child: Icon(
                                  Icons.info,
                                  size: 16,
                                  color:
                                      Theme.of(context).unselectedWidgetColor,
                                ),
                              ),
                              Expanded(child: Container(width: 2)),
                              Text(
                                  '${Fmt.priceCeilBigInt(existDeposit, decimals, lengthMax: 6)} $tokenView'),
                            ],
                          ),
                        ),
                        _fee?.partialFee != null
                            ? Padding(
                                padding: EdgeInsets.only(top: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.only(right: 4),
                                        child: Text(dicAcala['transfer.fee']),
                                      ),
                                    ),
                                    Text(
                                        '${Fmt.priceCeilBigInt(Fmt.balanceInt(_fee.partialFee.toString()), decimals, lengthMax: 6)} $nativeToken'),
                                  ],
                                ),
                              )
                            : Container(),
                        _token == 'KSM'
                            ? _KSMCrossChainTransferWarning()
                            : Container(),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(16),
                  child: TxButton(
                    text: dic['make'],
                    getTxParams: () async => _getTxParams(chainTo),
                    onFinish: (res) {
                      if (res != null) {
                        Navigator.of(context).pop(res);
                      }
                    },
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

class _KSMCrossChainTransferWarning extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');
    return Container(
      margin: EdgeInsets.only(top: 16, bottom: 24),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: Colors.black12,
          border: Border.all(color: Colors.black26, width: 0.5),
          borderRadius: BorderRadius.all(Radius.circular(8))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dic['cross.warn'],
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          Text(dic['cross.warn.network'], style: TextStyle(fontSize: 12))
        ],
      ),
    );
  }
}
