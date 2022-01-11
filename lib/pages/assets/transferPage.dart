import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_plugin_karura/common/components/insufficientKARWarn.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/pages/currencySelectPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/api/types/txInfoData.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/currencyWithIcon.dart';
import 'package:polkawallet_ui/components/tapTooltip.dart';
import 'package:polkawallet_ui/components/textTag.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/components/v3/addressFormItem.dart';
import 'package:polkawallet_ui/components/v3/addressIcon.dart';
import 'package:polkawallet_ui/components/v3/addressTextFormField.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/index.dart' as v3;
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:polkawallet_ui/components/v3/txButton.dart';
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

  KeyPairData? _accountTo;
  List<KeyPairData> _accountOptions = [];
  TokenBalanceData? _token;
  String? _chainTo;
  bool _accountToEditable = false;

  String? _accountToError;

  TxFeeEstimateResult? _fee;
  BigInt? _amountMax;

  bool _submitting = false;

  Future<String?> _checkAccountTo(KeyPairData? acc) async {
    if (widget.keyring.allAccounts.indexWhere((e) => e.pubKey == acc!.pubKey) >=
        0) {
      return null;
    }

    final addressCheckValid = await widget.plugin.sdk.webView!.evalJavascript(
        '(account.checkAddressFormat != undefined ? {}:null)',
        wrapPromise: false);
    if (addressCheckValid != null) {
      final res = await widget.plugin.sdk.api.account.checkAddressFormat(
          acc!.address!,
          network_ss58_format[_chainTo ?? widget.plugin.basic.name!]!);
      if (res != null && !res) {
        return I18n.of(context)!
            .getDic(i18n_full_dic_ui, 'account')!['ss58.mismatch'];
      }
    }
    return null;
  }

  Future<void> _validateAccountTo(KeyPairData? acc) async {
    final error = await _checkAccountTo(acc);
    setState(() {
      _accountToError = error;
    });
  }

  Future<String> _getTxFee({bool isXCM = false, bool reload = false}) async {
    if (_fee?.partialFee != null && !reload) {
      return _fee!.partialFee.toString();
    }

    final sender = TxSenderData(
        widget.keyring.current.address, widget.keyring.current.pubKey);
    final txInfo =
        TxInfoData(isXCM ? 'xTokens' : 'currencies', 'transfer', sender);
    final fee = await widget.plugin.sdk.api.tx.estimateFees(
        txInfo,
        isXCM
            ? [
                _token!.currencyId,
                '1000000000',
                [
                  1,
                  {
                    'X1': {
                      'AccountId32': {
                        'id': _accountTo!.address,
                        'network': 'Any'
                      }
                    }
                  }
                ],
                // params.weight
                xcm_dest_weight_kusama
              ]
            : [
                widget.keyring.current.address,
                _token!.currencyId,
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
    acc.address = (to as QRCodeResult).address!.address;
    acc.name = to.address!.name;
    final res = await Future.wait([
      widget.plugin.sdk.api.account.getAddressIcons([acc.address]),
      _checkAccountTo(acc),
    ]);
    if (res[0] != null) {
      final List icon = res[0] as List<dynamic>;
      acc.icon = icon[0][1];
    }
    setState(() {
      _accountTo = acc;
      _accountToError = res[1] as String?;
    });
    print(_accountTo!.address);
  }

  /// XCM only support KSM transfer back to Kusama.
  void _onSelectChain(Map<String, Widget> crossChainIcons) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala');

    final List tokenXcmConfig =
        widget.plugin.store!.setting.tokensConfig['xcm'] != null
            ? widget.plugin.store!.setting.tokensConfig['xcm']
                    [_token!.symbol!.toUpperCase()] ??
                []
            : [];
    final options = [widget.plugin.basic.name, ...tokenXcmConfig];

    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(dic!['cross.chain.select']!),
        actions: options.map((e) {
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
                    child: TokenIcon(e, crossChainIcons),
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
                widget.keyring.setSS58(network_ss58_format[e]);
                final options = widget.keyring.allWithContacts.toList();
                widget.keyring.setSS58(widget.plugin.basic.ss58);
                setState(() {
                  _chainTo = e;
                  _accountOptions = options;

                  if (e != widget.plugin.basic.name) {
                    _accountTo = widget.keyring.current;
                  }
                });

                _validateAccountTo(_accountTo);

                // update estimated tx fee if switch ToChain
                _getTxFee(isXCM: e != widget.plugin.basic.name, reload: true);
              }
              Navigator.of(context).pop();
            },
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          child: Text(I18n.of(context)!
              .getDic(i18n_full_dic_karura, 'common')!['cancel']!),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _onSwitchEditable(bool v) async {
    if (v) {
      final confirm = await showCupertinoDialog(
          context: context,
          builder: (_) {
            final dic =
                I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
            final dicCommon =
                I18n.of(context)!.getDic(i18n_full_dic_karura, 'common')!;
            return CupertinoAlertDialog(
              title: Text(dic['cross.warn']!),
              content: Text(dic['cross.warn.info']!),
              actions: [
                CupertinoButton(
                    child: Text(dicCommon['cancel']!),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    }),
                CupertinoButton(
                    child: Text(dicCommon['ok']!),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    }),
              ],
            );
          });
      if (!confirm) return;
    }
    setState(() {
      _accountToEditable = v;
      if (!v) {
        _accountTo = widget.keyring.current;
      }
    });
  }

  Future<TxConfirmParams?> _getTxParams(String chainTo) async {
    if (_accountToError == null &&
        _formKey.currentState!.validate() &&
        !_submitting) {
      final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'common')!;
      final tokenView = PluginFmt.tokenView(_token!.symbol);

      /// send XCM tx if cross chain
      if (chainTo != widget.plugin.basic.name) {
        final dicAcala =
            I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala');
        final isToParent = _chainTo == relay_chain_name;

        String? destPubKey = _accountTo!.pubKey;
        // we need to decode address for the pubKey here
        if (destPubKey == null || destPubKey.isEmpty) {
          setState(() {
            _submitting = true;
          });
          final pk = await widget.plugin.sdk.api.account
              .decodeAddress([_accountTo!.address!]);
          setState(() {
            _submitting = false;
          });
          if (pk == null) return null;

          destPubKey = pk.keys.toList()[0];
        }

        final isV2XCM = await widget.plugin.sdk.webView!.evalJavascript(
            'api.createType(api.tx.xTokens.transfer.meta.args[2].toJSON()["type"]).defKeys.includes("V1")',
            wrapPromise: false);
        final dest = {
          'parents': 1,
          'interior': isToParent
              ? {
                  'X1': {
                    'AccountId32': {'id': destPubKey, 'network': 'Any'}
                  }
                }
              : {
                  'X2': [
                    {'Parachain': para_chain_ids[_chainTo!]},
                    {
                      'AccountId32': {'id': destPubKey, 'network': 'Any'}
                    }
                  ]
                }
        };
        return TxConfirmParams(
          txTitle:
              '${dicAcala!['transfer']} $tokenView (${dicAcala['cross.xcm']})',
          module: 'xTokens',
          call: 'transfer',
          txDisplay: {
            dicAcala['cross.chain']: chainTo.toUpperCase(),
          },
          txDisplayBold: {
            dic['amount']!: Text(
              Fmt.priceFloor(double.tryParse(_amountCtrl.text.trim()),
                      lengthMax: 8) +
                  ' $tokenView',
              style: Theme.of(context).textTheme.headline1,
            ),
            dic['address']!: Row(
              children: [
                AddressIcon(_accountTo!.address, svg: _accountTo!.icon),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.fromLTRB(8, 16, 0, 16),
                    child: Text(
                      Fmt.address(_accountTo?.address, pad: 8) ?? '',
                      style: Theme.of(context).textTheme.headline4,
                    ),
                  ),
                ),
              ],
            ),
          },
          params: [
            // params.currencyId
            _token!.currencyId,
            // params.amount
            (_amountMax ??
                    Fmt.tokenInt(_amountCtrl.text.trim(), _token!.decimals!))
                .toString(),
            // params.dest
            isV2XCM ? {'V1': dest} : dest,
            // params.weight
            isV2XCM
                ? xcm_dest_weight_v2
                : isToParent
                    ? xcm_dest_weight_kusama
                    : xcm_dest_weight_karura
          ],
        );
      }

      /// else return normal transfer
      final params = [
        // params.to
        _accountTo!.address,
        // params.currencyId
        _token!.currencyId,
        // params.amount
        (_amountMax ?? Fmt.tokenInt(_amountCtrl.text.trim(), _token!.decimals!))
            .toString(),
      ];
      return TxConfirmParams(
        module: 'currencies',
        call: 'transfer',
        txTitle:
            '${I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!['transfer']} $tokenView',
        txDisplay: {},
        txDisplayBold: {
          dic['amount']!: Text(
            Fmt.priceFloor(double.tryParse(_amountCtrl.text.trim()),
                    lengthMax: 8) +
                ' $tokenView',
            style: Theme.of(context).textTheme.headline1,
          ),
          dic['address']!: Row(
            children: [
              AddressIcon(_accountTo!.address, svg: _accountTo!.icon),
              Expanded(
                child: Container(
                  margin: EdgeInsets.fromLTRB(8, 16, 0, 16),
                  child: Text(
                    Fmt.address(_accountTo?.address, pad: 8) ?? '',
                    style: Theme.of(context).textTheme.headline4,
                  ),
                ),
              ),
            ],
          ),
        },
        params: params,
      );
    }
    return null;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      final TokenBalanceData? token =
          ModalRoute.of(context)!.settings.arguments as TokenBalanceData?;
      setState(() {
        _token = token;
        _accountOptions = widget.keyring.allWithContacts.toList();
        _accountTo = widget.keyring.current;
      });

      _getTxFee();
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
        final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'common')!;
        final dicAcala =
            I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
        final TokenBalanceData? args =
            ModalRoute.of(context)!.settings.arguments as TokenBalanceData?;
        final token = _token ?? args!;
        final tokenSymbol = token.symbol!.toUpperCase();
        final tokenView = PluginFmt.tokenView(token.symbol);

        final List? tokenXcmConfig =
            widget.plugin.store!.setting.tokensConfig['xcm'] != null
                ? widget.plugin.store!.setting.tokensConfig['xcm'][tokenSymbol]
                : [];
        final canCrossChain =
            tokenXcmConfig != null && tokenXcmConfig.length > 0;

        final nativeTokenBalance =
            Fmt.balanceInt(widget.plugin.balances.native!.freeBalance) -
                Fmt.balanceInt(widget.plugin.balances.native!.frozenFee);
        final accountED = PluginFmt.getAccountED(widget.plugin);
        final isNativeTokenLow = nativeTokenBalance - accountED <
            Fmt.balanceInt((_fee?.partialFee ?? 0).toString()) * BigInt.two;

        final balanceData = widget.plugin.store!.assets
            .tokenBalanceMap[token.tokenNameId ?? tokenSymbol];
        final available = Fmt.balanceInt(balanceData?.amount) -
            Fmt.balanceInt(balanceData?.locked);
        final nativeToken = widget.plugin.networkState.tokenSymbol![0];
        final nativeTokenDecimals = widget.plugin.networkState.tokenDecimals![
            widget.plugin.networkState.tokenSymbol!.indexOf(nativeToken)];
        final existDeposit = token.tokenNameId == nativeToken
            ? Fmt.balanceInt(widget
                .plugin.networkConst['balances']['existentialDeposit']
                .toString())
            : Fmt.balanceInt(widget.plugin.store!.assets
                .tokenBalanceMap[token.tokenNameId]!.minBalance);

        final chainTo = _chainTo ?? widget.plugin.basic.name!;
        final isCrossChain = widget.plugin.basic.name != chainTo;
        final destExistDeposit = isCrossChain
            ? Fmt.balanceInt(cross_chain_xcm_fees[chainTo]![tokenSymbol]![
                'existentialDeposit'])
            : BigInt.zero;
        final destFee = isCrossChain
            ? Fmt.balanceInt(
                cross_chain_xcm_fees[chainTo]![tokenSymbol]!['fee'])
            : BigInt.zero;

        final colorGrey = Theme.of(context).unselectedWidgetColor;
        final crossChainIcons = cross_chain_icons
            .map((k, v) => MapEntry(k.toUpperCase(), Image.asset(v)));

        final labelStyle = Theme.of(context).textTheme.headline4;

        return Scaffold(
          appBar: AppBar(
            title: Text(dic['transfer']!),
            centerTitle: true,
            leading: BackBtn(),
            actions: <Widget>[
              Visibility(
                visible: !isCrossChain,
                child: v3.IconButton(
                    margin: EdgeInsets.only(right: 12),
                    icon: SvgPicture.asset(
                      'assets/images/scan.svg',
                      color: Theme.of(context).cardColor,
                      width: 18,
                    ),
                    onPressed: _onScan,
                    isBlueBg: true),
              )
            ],
          ),
          body: SafeArea(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(dic['address.from'] ?? '', style: labelStyle),
                        AddressFormItem(widget.keyring.current),
                        Container(height: 8.h),
                        Visibility(
                            visible: !(!isCrossChain || _accountToEditable),
                            child:
                                Text(dic['address'] ?? '', style: labelStyle)),
                        Visibility(
                            visible: !(!isCrossChain || _accountToEditable),
                            child: AddressFormItem(widget.keyring.current)),
                        Visibility(
                          visible: !isCrossChain || _accountToEditable,
                          child: AddressTextFormField(
                            widget.plugin.sdk.api,
                            _accountOptions,
                            labelText: dic['address'],
                            labelStyle: labelStyle,
                            hintText: dic['address'],
                            initialValue: _accountTo,
                            onChanged: (KeyPairData? acc) async {
                              final error = await _checkAccountTo(acc);
                              setState(() {
                                _accountTo = acc;
                                _accountToError = error;
                              });
                            },
                            key: ValueKey<KeyPairData?>(_accountTo),
                          ),
                        ),
                        Visibility(
                            visible: _accountToError != null,
                            child: Container(
                              margin: EdgeInsets.only(top: 4),
                              child: Text(_accountToError ?? "",
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.red)),
                            )),
                        Visibility(
                          visible: isCrossChain,
                          child: GestureDetector(
                            child: Container(
                              child: Row(
                                children: [
                                  v3.Checkbox(
                                    padding: EdgeInsets.fromLTRB(0, 8, 8, 0),
                                    value: _accountToEditable,
                                    onChanged: _onSwitchEditable,
                                  ),
                                  Container(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Text(
                                      dicAcala['cross.edit']!,
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            onTap: () => _onSwitchEditable(!_accountToEditable),
                          ),
                        ),
                        Container(height: 10.h),
                        Form(
                            key: _formKey,
                            child: v3.TextInputWidget(
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              decoration: v3.InputDecorationV3(
                                hintText: dic['amount.hint'],
                                labelText:
                                    '${dic['amount']} (${dic['balance']}: ${Fmt.priceFloorBigInt(
                                  available,
                                  token.decimals!,
                                  lengthMax: 6,
                                )})',
                                labelStyle: labelStyle,
                                suffix: GestureDetector(
                                  child: Text(dic['amount.max']!,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .toggleableActiveColor)),
                                  onTap: () {
                                    setState(() {
                                      _amountMax = available;
                                      _amountCtrl.text = Fmt.bigIntToDouble(
                                              available, token.decimals!)
                                          .toStringAsFixed(8);
                                    });
                                  },
                                ),
                              ),
                              inputFormatters: [
                                UI.decimalInputFormatter(token.decimals!)!
                              ],
                              controller: _amountCtrl,
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              onChanged: (_) {
                                setState(() {
                                  _amountMax = null;
                                });
                              },
                              validator: (v) {
                                final error = Fmt.validatePrice(v!, context);
                                if (error != null) {
                                  return error;
                                }

                                final input =
                                    Fmt.tokenInt(v.trim(), token.decimals!);
                                if (_amountMax == null &&
                                    Fmt.bigIntToDouble(input, token.decimals!) >
                                        available /
                                            BigInt.from(
                                                pow(10, token.decimals!))) {
                                  return dic['amount.low'];
                                }
                                return null;
                              },
                            )),
                        Container(
                          margin: EdgeInsets.only(top: 8, bottom: 8),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Container(
                                    margin: EdgeInsets.only(bottom: 4),
                                    child: Text(dic['currency']!,
                                        style: labelStyle),
                                  ),
                                  RoundedCard(
                                    padding: EdgeInsets.all(8),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        CurrencyWithIcon(
                                          tokenView,
                                          TokenIcon(tokenSymbol,
                                              widget.plugin.tokenIcons),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 18,
                                          color: colorGrey,
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            onTap: () async {
                              final tokens = widget
                                  .plugin.store!.assets.tokenBalanceMap.values
                                  .toList();
                              if (widget.plugin.store!.setting
                                          .tokensConfig['invisible'] !=
                                      null &&
                                  widget.plugin.store!.setting
                                          .tokensConfig['disabled'] !=
                                      null) {
                                tokens.removeWhere((e) =>
                                    List.of(widget.plugin.store!.setting
                                            .tokensConfig['invisible'])
                                        .contains(e.symbol) ||
                                    List.of(widget.plugin.store!.setting
                                            .tokensConfig['disabled'])
                                        .contains(e.symbol));
                              }
                              final res = (await Navigator.of(context)
                                  .pushNamed(CurrencySelectPage.route,
                                      arguments: tokens) as TokenBalanceData?);
                              if (res != null && res.symbol != _token!.symbol) {
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
                        Visibility(
                            visible: canCrossChain,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                margin: EdgeInsets.only(bottom: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        dicAcala['cross.chain']!,
                                        style: labelStyle,
                                      ),
                                    ),
                                    RoundedCard(
                                      padding: EdgeInsets.all(8),
                                      child: Row(
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
                                                      ? TokenIcon(_chainTo!,
                                                          crossChainIcons)
                                                      : widget
                                                          .plugin.basic.icon,
                                                ),
                                              ),
                                              Text(chainTo.toUpperCase())
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Visibility(
                                                  visible: isCrossChain,
                                                  child: TextTag(
                                                      dicAcala['cross.xcm'],
                                                      margin: EdgeInsets.only(
                                                          right: 8),
                                                      color: Theme.of(context)
                                                          .errorColor)),
                                              Icon(
                                                Icons.arrow_forward_ios,
                                                size: 18,
                                                color: colorGrey,
                                              )
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () => _onSelectChain(crossChainIcons),
                            )),
                        Visibility(
                          visible: isNativeTokenLow,
                          child: InsufficientKARWarn(),
                        ),
                        Visibility(
                            visible: isCrossChain,
                            child: Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: TapTooltip(
                                      message: dicAcala['cross.exist.msg']!,
                                      child: Row(
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.only(right: 4),
                                            child:
                                                Text(dicAcala['cross.exist']!),
                                          ),
                                          Icon(
                                            Icons.info,
                                            size: 16,
                                            color: Theme.of(context)
                                                .unselectedWidgetColor,
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 0,
                                    child: Text(
                                        '${Fmt.priceCeilBigInt(destExistDeposit, token.decimals!, lengthMax: 6)} $tokenView'),
                                  )
                                ],
                              ),
                            )),
                        Visibility(
                            visible: isCrossChain,
                            child: Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(right: 4),
                                      child: Text(dicAcala['cross.fee']!),
                                    ),
                                  ),
                                  Text(
                                      '${Fmt.priceCeilBigInt(destFee, token.decimals!, lengthMax: 6)} $tokenView'),
                                ],
                              ),
                            )),
                        Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                child: TapTooltip(
                                  message: dicAcala['cross.exist.msg']!,
                                  child: Row(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(right: 4),
                                        child:
                                            Text(dicAcala['transfer.exist']!),
                                      ),
                                      Icon(
                                        Icons.info,
                                        size: 16,
                                        color: Theme.of(context)
                                            .unselectedWidgetColor,
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              Text(
                                  '${Fmt.priceCeilBigInt(existDeposit, token.decimals!, lengthMax: 6)} $tokenView'),
                            ],
                          ),
                        ),
                        Visibility(
                          visible: _fee?.partialFee != null,
                          child: Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(right: 4),
                                    child: Text(dicAcala['transfer.fee']!),
                                  ),
                                ),
                                Text(
                                    '${Fmt.priceCeilBigInt(Fmt.balanceInt((_fee?.partialFee ?? 0).toString()), nativeTokenDecimals, lengthMax: 6)} $nativeToken'),
                              ],
                            ),
                          ),
                        ),
                        Visibility(
                            visible: isCrossChain,
                            child: _CrossChainTransferWarning(
                              token: tokenSymbol,
                              chain: (widget.plugin.store!.setting
                                      .tokensConfig['warning'] ??
                                  {})[tokenSymbol],
                            )),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 14.w, 16.h),
                  child: TxButton(
                    text: dic['make'],
                    getTxParams: (() async =>
                        _getTxParams(chainTo) as Future<TxConfirmParams>),
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

class _CrossChainTransferWarning extends StatelessWidget {
  _CrossChainTransferWarning({this.token, this.chain});
  final String? token;
  final String? chain;

  String getWarnInfo(BuildContext context) {
    return I18n.of(context)!.locale.toString().contains('zh')
        ? '交易所当前不支持 Karura 网络跨链转账充提 $token，请先使用跨链转账将 $token 转回 $chain，再从 $chain 网络转账至交易所地址。'
        : 'Exchanges do not currently support direct transfers of $token to/from Karura. In order to successfully send $token to an exchange address, it is required that you first complete an Cross-Chain-Transfer of the token(s) from Karura to $chain.';
  }

  @override
  Widget build(BuildContext context) {
    if (chain == null || chain!.isEmpty) return Container();

    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
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
            dic['cross.warn']!,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).errorColor),
          ),
          Text(getWarnInfo(context), style: TextStyle(fontSize: 12))
        ],
      ),
    );
  }
}
