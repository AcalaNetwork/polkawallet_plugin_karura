import 'dart:convert';
import 'dart:math';

import 'package:ethereum_addresses/ethereum_addresses.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_plugin_karura/common/components/insufficientKARWarn.dart';
import 'package:polkawallet_plugin_karura/common/constants/base.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/pages/assets/xcmChainSelector.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/api/types/txInfoData.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/currencyWithIcon.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/components/v3/addressFormItem.dart';
import 'package:polkawallet_ui/components/v3/addressIcon.dart';
import 'package:polkawallet_ui/components/v3/addressTextFormField.dart';
import 'package:polkawallet_ui/components/v3/button.dart';
import 'package:polkawallet_ui/components/v3/index.dart' as v3;
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:polkawallet_ui/pages/v3/xcmTxConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';

class TransferFormXCM extends StatefulWidget {
  TransferFormXCM(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  @override
  _TransferFormXCMState createState() => _TransferFormXCMState();
}

class _TransferFormXCMState extends State<TransferFormXCM> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _amountCtrl = new TextEditingController();
  final TextEditingController _address20Ctrl = new TextEditingController();

  KeyPairData? _accountTo;
  List<KeyPairData> _accountOptions = [];
  TokenBalanceData? _token;
  String _chainFrom = plugin_name_karura;
  String? _chainTo;
  bool _accountToEditable = false;
  bool _keepAlive = true;

  Map _accountSysInfo = {};
  Map<String, TokenBalanceData> _fromChainBalances = {};

  String? _accountToError;

  String? _fee;
  BigInt? _amountMax;

  bool _connecting = false;
  bool _submitting = false;

  String? _validateAddress20(String? v) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'common');
    final input = v?.trim();
    if (input == null || input.isEmpty) {
      return dic!['input.empty'];
    }
    try {
      final output = checksumEthereumAddress(input);
      print(output);
    } catch (err) {
      return dic!['address.error.eth'];
    }
    return null;
  }

  Future<String?> _checkBlackList(KeyPairData acc) async {
    final addresses =
        await widget.plugin.sdk.api.account.decodeAddress([acc.address!]);
    if (addresses != null) {
      final pubKey = addresses.keys.toList()[0];
      if (widget.plugin.sdk.blackList.indexOf(pubKey) > -1) {
        return I18n.of(context)!
            .getDic(i18n_full_dic_karura, 'common')!['transfer.scam'];
      }
    }
    return null;
  }

  Future<String?> _checkAccountTo(KeyPairData acc, int chainToSS58) async {
    final blackListCheck = await _checkBlackList(acc);
    if (blackListCheck != null) return blackListCheck;

    if (widget.keyring.allAccounts.indexWhere((e) => e.pubKey == acc.pubKey) >=
        0) {
      return null;
    }

    final addressCheckValid = await widget.plugin.sdk.webView!.evalJavascript(
        '(account.checkAddressFormat != undefined ? {}:null)',
        wrapPromise: false);
    if (addressCheckValid != null) {
      final res = await widget.plugin.sdk.api.account
          .checkAddressFormat(acc!.address!, chainToSS58);
      if (res != null && !res) {
        return I18n.of(context)!
            .getDic(i18n_full_dic_ui, 'account')!['ss58.mismatch'];
      }
    }
    return null;
  }

  Future<void> _validateAccountTo(KeyPairData acc, int chainToSS58) async {
    final error = await _checkAccountTo(acc, chainToSS58);
    setState(() {
      _accountToError = error;
    });
  }

  Future<void> _getAccountSysInfo() async {
    final info = await widget.plugin.sdk.webView?.evalJavascript(
        'api.query.system.account("${widget.keyring.current.address}")');
    if (info != null) {
      setState(() {
        _accountSysInfo = info;
      });
    }
  }

  Future<String> _getTxFee({reload = false}) async {
    if (_fee != null && !reload) {
      return _fee!;
    }

    final sender = TxSenderData(
        widget.keyring.current.address, widget.keyring.current.pubKey);
    final xcmParams = await _getXcmParams('100000000', feeEstimate: true);
    if (xcmParams == null) return '0';

    final txInfo = TxInfoData(xcmParams['module'], xcmParams['call'], sender);

    String fee = '0';
    if (_chainFrom == plugin_name_karura) {
      final feeData = await widget.plugin.sdk.api.tx
          .estimateFees(txInfo, xcmParams['params']);
      fee = feeData.partialFee.toString();
    } else {
      final feeData = await widget.plugin.sdk.webView?.evalJavascript(
          'keyring.txFeeEstimate(xcm.getApi("$_chainFrom"), ${jsonEncode(txInfo)}, ${jsonEncode(xcmParams['params'])})');
      if (feeData != null) {
        fee = feeData['partialFee'].toString();
      }
    }

    if (mounted) {
      setState(() {
        _fee = fee;
      });
    }
    return fee;
  }

  void _onChainSelected(List<String> chains) {
    if (chains[0] != plugin_name_karura) {
      _updateFromChain(chains[0]);
    }

    setState(() {
      _chainFrom = chains[0];
      _chainTo = chains[1];
      _fee = null;
      if (chains[0] != plugin_name_karura) {
        _connecting = true;
      }
    });

    if (chains[0] == plugin_name_karura) {
      _getTxFee(reload: true);
    }
  }

  Future<void> _updateFromChain(String chainName) async {
    final connected = await widget.plugin.sdk.webView!
        .evalJavascript('xcm.connectFromChain(["$chainName"])');
    if (connected != null) {
      final TokenBalanceData? args =
          ModalRoute.of(context)!.settings.arguments as TokenBalanceData?;
      final token = _token ?? args!;
      final balances = await widget.plugin.sdk.webView!.evalJavascript(
          'xcm.getBalances("$chainName", "${widget.keyring.current.address}", ["${token.symbol}"])');
      if (balances != null) {
        final balance = List.of(balances)[0];
        if (balance != null && mounted) {
          final balanceData = TokenBalanceData(
            tokenNameId: balance['tokenNameId'],
            amount: balance['amount'],
            decimals: balance['decimals'],
          );
          setState(() {
            _fromChainBalances = {
              ..._fromChainBalances,
              chainName: balanceData,
            };
          });
        }
      }

      _getTxFee(reload: true);
    }

    setState(() {
      _connecting = false;
    });
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
        _accountToError = null;
      }
    });
  }

  void _onSwitchCheckAlive(bool res, bool isNoDeath) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'common')!;

    if (!res) {
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text(dic['note']!),
            content: Text(dic['transfer.note.msg1']!),
            actions: <Widget>[
              CupertinoButton(
                child: Text(I18n.of(context)!
                    .getDic(i18n_full_dic_ui, 'common')!['cancel']!),
                onPressed: () => Navigator.of(context).pop(),
              ),
              CupertinoButton(
                child: Text(I18n.of(context)!
                    .getDic(i18n_full_dic_ui, 'common')!['ok']!),
                onPressed: () {
                  Navigator.of(context).pop();

                  if (isNoDeath) {
                    showCupertinoDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return CupertinoAlertDialog(
                          title: Text(dic['note']!),
                          content: Text(dic['transfer.note.msg2']!),
                          actions: <Widget>[
                            CupertinoButton(
                              child: Text(I18n.of(context)!
                                  .getDic(i18n_full_dic_ui, 'common')!['ok']!),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    setState(() {
                      _keepAlive = res;
                    });
                  }
                },
              ),
            ],
          );
        },
      );
    } else {
      setState(() {
        _keepAlive = res;
      });
    }
  }

  Future<Map?> _getXcmParams(String amount, {bool feeEstimate = false}) async {
    final tokensConfig =
        widget.plugin.store!.setting.remoteConfig['tokens'] ?? {};
    final chainFromInfo = (tokensConfig['xcmChains'] ?? {})[_chainFrom] ?? {};
    final chainToInfo = (tokensConfig['xcmChains'] ?? {})[_chainTo] ?? {};
    final sendFee = List.of((tokensConfig['xcmSendFee'] ?? {})[_chainTo] ?? []);

    final address = _chainTo == para_chain_name_moon
        ? feeEstimate
            ? '0x0000000000000000000000000000000000000000'
            : checksumEthereumAddress(_address20Ctrl.text.trim())
        : feeEstimate
            ? widget.keyring.current.address
            : _accountTo?.address;

    final Map? xcmParams = await widget.plugin.sdk.webView?.evalJavascript(
        'xcm.getTransferParams('
        '{name: "$_chainFrom", paraChainId: ${chainFromInfo['id']}},'
        '{name: "$_chainTo", paraChainId: ${chainToInfo['id']}},'
        '"${_token?.symbol}", "$amount", "$address", ${jsonEncode(sendFee)})');
    return xcmParams;
  }

  Future<XcmTxConfirmParams?> _getTxParams(
      Widget? chainFromIcon, String feeToken) async {
    if (_accountToError == null &&
        _formKey.currentState!.validate() &&
        !_submitting &&
        !_connecting) {
      final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'common')!;
      final dicAcala = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala');
      final tokenView = PluginFmt.tokenView(_token!.symbol);

      final xcmParams = await _getXcmParams((_amountMax ??
              Fmt.tokenInt(_amountCtrl.text.trim(), _token!.decimals!))
          .toString());
      if (xcmParams != null) {
        return XcmTxConfirmParams(
          txTitle:
              '${dicAcala!['transfer']} $tokenView (${dicAcala['cross.xcm']})',
          module: xcmParams['module'],
          call: xcmParams['call'],
          txDisplay: {
            dicAcala['cross.chain']: _chainTo?.toUpperCase(),
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
                      Fmt.address(_accountTo?.address, pad: 8),
                      style: Theme.of(context).textTheme.headline4,
                    ),
                  ),
                ),
              ],
            ),
          },
          params: xcmParams['params'],
          chainFrom: _chainFrom,
          chainFromIcon: chainFromIcon,
          feeToken: feeToken,
        );
      }
    }
    return null;
  }

  String _getWarnInfo(String token) {
    return I18n.of(context)!.locale.toString().contains('zh')
        ? '交易所当前不支持 Karura 网络跨链转账充提 $token，请先使用跨链转账将 $token 转回 $_chainTo，再从 $_chainTo 网络转账至交易所地址。'
        : 'Exchanges do not currently support direct transfers of $token to/from Karura. In order to successfully send $token to an exchange address, it is required that you first complete an Cross-Chain-Transfer of the token(s) from Karura to $_chainTo.';
  }

  String _getForeignAssetEDWarn() {
    return I18n.of(context)!.locale.toString().contains('zh')
        ? '收款地址需在 $_chainTo 网络上持有 $relay_chain_token_symbol，否则会转账失败。'
        : 'The receiver address should have available $relay_chain_token_symbol balance on $_chainTo, or the transfer will fail.';
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      final TokenBalanceData? token =
          ModalRoute.of(context)!.settings.arguments as TokenBalanceData?;
      final tokensConfig =
          widget.plugin.store!.setting.remoteConfig['tokens'] ?? {};
      final tokenXcmConfig = List<String>.from(
          (tokensConfig['xcm'] ?? {})[token?.tokenNameId] ?? []);
      setState(() {
        _token = token;
        _accountOptions = widget.keyring.allWithContacts.toList();
        _accountTo = widget.keyring.current;
        _chainTo = tokenXcmConfig[0];
      });

      _getTxFee();
      _getAccountSysInfo();
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _address20Ctrl.dispose();

    final tokensConfig =
        widget.plugin.store!.setting.remoteConfig['tokens'] ?? {};
    final tokenXcmFromConfig = List<String>.from(
        (tokensConfig['xcmFrom'] ?? {})[_token?.tokenNameId] ?? []);
    if (tokenXcmFromConfig.length > 0) {
      widget.plugin.sdk.webView!.evalJavascript(
          'xcm.disconnectFromChain(${jsonEncode(tokenXcmFromConfig)})');
    }

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

        final tokensConfig =
            widget.plugin.store!.setting.remoteConfig['tokens'] ?? {};
        final tokenXcmConfig = List<String>.from(
            (tokensConfig['xcm'] ?? {})[token.tokenNameId] ?? []);
        final tokenXcmFromConfig = List<String>.from(
            (tokensConfig['xcmFrom'] ?? {})[token.tokenNameId] ?? []);
        final isFromKar = _chainFrom == plugin_name_karura;

        final canCrossChain =
            tokenXcmConfig.length > 0 || tokenXcmFromConfig.length > 0;

        final nativeTokenBalance =
            Fmt.balanceInt(widget.plugin.balances.native?.freeBalance) -
                Fmt.balanceInt(widget.plugin.balances.native?.frozenFee);
        final notTransferable = Fmt.balanceInt(
                (widget.plugin.balances.native?.reservedBalance ?? 0)
                    .toString()) +
            Fmt.balanceInt(
                (widget.plugin.balances.native?.lockedBalance ?? 0).toString());
        final accountED =
            _keepAlive ? PluginFmt.getAccountED(widget.plugin) : BigInt.zero;
        final isNativeTokenLow =
            nativeTokenBalance - accountED < Fmt.balanceInt(_fee) * BigInt.two;
        final isAccountNormal = (_accountSysInfo['consumers'] as int?) == 0 ||
            ((_accountSysInfo['providers'] as int?) ?? 0) > 0;

        final balanceData = isFromKar
            ? AssetsUtils.getBalanceFromTokenNameId(
                widget.plugin, token.tokenNameId)
            : _fromChainBalances[_chainFrom];
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
        final fee = Fmt.balanceInt(_fee);
        BigInt max = available;
        if (tokenSymbol == nativeToken) {
          max = notTransferable > BigInt.zero
              ? notTransferable > accountED
                  ? available - fee
                  : available - (accountED - notTransferable) - fee
              : available - accountED - fee;
        }
        if (max < BigInt.zero) {
          max = BigInt.zero;
        }

        final chainTo = _chainTo ?? tokenXcmConfig[0];
        final isTokenFromStateMine =
            token.src != null && token.src!['Parachain'] == '1,000';
        final isToMoonRiver = chainTo == para_chain_name_moon;
        final tokenXcmInfo =
            (tokensConfig['xcmInfo'] ?? {})[isFromKar ? chainTo : _chainFrom] ??
                {};
        final destExistDeposit = isFromKar
            ? Fmt.balanceInt(
                (tokenXcmInfo[tokenSymbol] ?? {})['existentialDeposit'])
            : Fmt.balanceInt(token.minBalance);
        final destFee = isFromKar
            ? isTokenFromStateMine
                ? BigInt.zero
                : Fmt.balanceInt((tokenXcmInfo[tokenSymbol] ?? {})['fee'])
            : Fmt.balanceInt((tokenXcmInfo[tokenSymbol] ?? {})['receiveFee']);
        final sendFee =
            List.of((tokensConfig['xcmSendFee'] ?? {})[chainTo] ?? []);
        final sendFeeAmount =
            sendFee.length > 0 ? Fmt.balanceInt(sendFee[1]) : BigInt.zero;
        final sendFeeToken = sendFee.length > 0
            ? AssetsUtils.tokenDataFromCurrencyId(widget.plugin, sendFee[0])
            : TokenBalanceData();

        final relayChainTokenBalance = AssetsUtils.getBalanceFromTokenNameId(
            widget.plugin, relay_chain_token_symbol);
        final isToStateMineFeeError = isFromKar &&
            isTokenFromStateMine &&
            (Fmt.balanceInt(relayChainTokenBalance?.amount) <
                Fmt.balanceInt(foreign_asset_xcm_dest_fee));

        final crossChainIcons = Map<String, Widget>.from(
            widget.plugin.store!.assets.crossChainIcons.map((k, v) => MapEntry(
                k.toUpperCase(),
                (v as String).contains('.svg')
                    ? SvgPicture.network(v)
                    : Image.network(v))));
        final chainToSS58 = isFromKar
            ? ((tokensConfig['xcmChains'] ?? {})[chainTo] ?? {})['ss58']
            : widget.plugin.basic.ss58;
        final feeToken = ((tokensConfig['xcmChains'] ?? {})[_chainFrom] ??
            {})['nativeToken'];

        final labelStyle = Theme.of(context).textTheme.headline4;
        final subTitleStyle = TextStyle(fontSize: 12, height: 1);
        final infoValueStyle = Theme.of(context)
            .textTheme
            .headline5!
            .copyWith(fontWeight: FontWeight.w600);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            canCrossChain
                ? XcmChainSelector(
                    widget.plugin,
                    fromChains: tokenXcmFromConfig,
                    toChains: tokenXcmConfig,
                    crossChainIcons: crossChainIcons,
                    onChanged: _onChainSelected,
                  )
                : Container(),
            Text(dic['address.from'] ?? '', style: labelStyle),
            AddressFormItem(widget.keyring.current),
            Container(height: 8.h),
            Visibility(
                visible: !_accountToEditable && !isToMoonRiver,
                child: Text(dic['address'] ?? '', style: labelStyle)),
            Visibility(
                visible: !_accountToEditable && !isToMoonRiver,
                child: AddressFormItem(widget.keyring.current)),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Visibility(
                    visible: _accountToEditable,
                    child: AddressTextFormField(
                      widget.plugin.sdk.api,
                      _accountOptions,
                      labelText: dic['address'],
                      labelStyle: labelStyle,
                      hintText: dic['address'],
                      initialValue: _accountTo,
                      onChanged: (KeyPairData acc) async {
                        final error = await _checkAccountTo(acc, chainToSS58);
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
                            style: TextStyle(fontSize: 12, color: Colors.red)),
                      )),
                  isToMoonRiver
                      ? v3.TextInputWidget(
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: v3.InputDecorationV3(
                            hintText: dic['address'],
                            labelText: dic['address'],
                            labelStyle: labelStyle,
                            suffix: GestureDetector(
                              child: Icon(
                                Icons.cancel,
                                size: 18,
                                color: Theme.of(context).unselectedWidgetColor,
                              ),
                              onTap: () {
                                setState(() {
                                  _address20Ctrl.text = '';
                                });
                              },
                            ),
                          ),
                          controller: _address20Ctrl,
                          validator: _validateAddress20,
                        )
                      : GestureDetector(
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
                  Container(height: 10.h),
                  v3.TextInputWidget(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: v3.InputDecorationV3(
                      hintText: dic['amount.hint'],
                      labelText:
                          '${dic['amount']} (${dic['balance']}: ${Fmt.priceFloorBigInt(
                        available,
                        token.decimals!,
                        lengthMax: 6,
                      )}${isFromKar ? '' : ' in ${_chainFrom?.toUpperCase()}'})',
                      labelStyle: labelStyle,
                      suffix: fee > BigInt.zero
                          ? GestureDetector(
                              child: Text(dic['amount.max']!,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .toggleableActiveColor)),
                              onTap: () {
                                setState(() {
                                  _amountMax = max;
                                  _amountCtrl.text =
                                      Fmt.bigIntToDouble(max, token.decimals!)
                                          .toStringAsFixed(8);
                                });
                              },
                            )
                          : null,
                    ),
                    inputFormatters: [
                      UI.decimalInputFormatter(token.decimals!)!
                    ],
                    controller: _amountCtrl,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
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

                      final input = Fmt.tokenInt(v.trim(), token.decimals!);
                      if (_amountMax == null &&
                          Fmt.bigIntToDouble(input, token.decimals!) >
                              max / BigInt.from(pow(10, token.decimals!))) {
                        return dic['amount.low'];
                      }
                      return null;
                    },
                  )
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 8, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(bottom: 4),
                    child: Text(dic['currency']!, style: labelStyle),
                  ),
                  RoundedCard(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: CurrencyWithIcon(
                      tokenView,
                      TokenIcon(tokenSymbol, widget.plugin.tokenIcons),
                    ),
                  ),
                ],
              ),
            ),
            Visibility(
              visible: isFromKar && isNativeTokenLow,
              child: InsufficientKARWarn(),
            ),
            RoundedCard(
              margin: EdgeInsets.only(top: 16.h),
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                              padding: EdgeInsets.only(right: 40),
                              child: Text(dicAcala['cross.exist']!,
                                  style: labelStyle)),
                        ),
                        Expanded(
                            flex: 0,
                            child: Text(
                                '${Fmt.priceCeilBigInt(destExistDeposit, token.decimals!, lengthMax: 6)} $tokenView',
                                style: infoValueStyle)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: 4),
                            child:
                                Text(dicAcala['cross.fee']!, style: labelStyle),
                          ),
                        ),
                        Text(
                          '${Fmt.priceCeilBigInt(destFee, token.decimals!, lengthMax: 6)} $tokenView',
                          style: infoValueStyle,
                        )
                      ],
                    ),
                  ),
                  Visibility(
                    visible: isFromKar && sendFee.length > 0,
                    child: Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: Text('XCM fee', style: labelStyle),
                            ),
                          ),
                          Text(
                              '${Fmt.priceFloorBigInt(sendFeeAmount, sendFeeToken?.decimals ?? 12, lengthMax: 6)} ${sendFeeToken?.symbol}',
                              style: infoValueStyle),
                        ],
                      ),
                    ),
                  ),
                  Visibility(
                    visible: isFromKar,
                    child: Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Container(
                                padding: EdgeInsets.only(right: 60),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(dicAcala['transfer.exist']!,
                                        style: labelStyle),
                                    Text(dicAcala['cross.exist.msg']!,
                                        style: subTitleStyle),
                                  ],
                                )),
                          ),
                          Text(
                              '${Fmt.priceCeilBigInt(existDeposit, token.decimals!, lengthMax: 6)} $tokenView',
                              style: infoValueStyle),
                        ],
                      ),
                    ),
                  ),
                  Visibility(
                      visible: _fee != null,
                      child: Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Text(dicAcala['transfer.fee']!,
                                    style: labelStyle),
                              ),
                            ),
                            Text(
                                '${Fmt.priceCeilBigInt(Fmt.balanceInt(_fee), nativeTokenDecimals, lengthMax: 6)} $feeToken',
                                style: infoValueStyle),
                          ],
                        ),
                      )),
                  Visibility(
                      visible: isFromKar &&
                          tokenSymbol == nativeToken &&
                          available > BigInt.zero,
                      child: Container(
                        margin: EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Container(
                                  padding: EdgeInsets.only(right: 60),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dic['transfer.alive']!,
                                        style: labelStyle,
                                      ),
                                      Text(
                                        dic['transfer.alive.msg']!,
                                        style: subTitleStyle,
                                      ),
                                    ],
                                  )),
                            ),
                            v3.CupertinoSwitch(
                              value: _keepAlive,
                              // account is not allow_death if it has
                              // locked/reserved balances
                              onChanged: (v) => _onSwitchCheckAlive(
                                  v,
                                  !isAccountNormal ||
                                      notTransferable > BigInt.zero),
                            )
                          ],
                        ),
                      ))
                ],
              ),
            ),
            Visibility(
                visible: isFromKar &&
                    tokenSymbol != nativeToken &&
                    tokenSymbol != karura_stable_coin &&
                    tokenSymbol != 'L$relay_chain_token_symbol',
                child: _CrossChainTransferWarning(
                    message: _getWarnInfo(tokenSymbol))),
            Visibility(
                visible: isFromKar && isTokenFromStateMine,
                child: _CrossChainTransferWarning(
                    message: _getForeignAssetEDWarn())),
            isToStateMineFeeError
                ? Container(
                    margin: EdgeInsets.only(top: 8),
                    child: Text(
                      '$relay_chain_token_symbol ${dic['xcm.foreign.fee']!} (${Fmt.balance(foreign_asset_xcm_dest_fee, relayChainTokenBalance?.decimals ?? 12)} $relay_chain_token_symbol)',
                      style: TextStyle(color: Colors.red, fontSize: 10),
                    ),
                  )
                : Container(),
            Container(
              padding: EdgeInsets.only(top: 16),
              child: Button(
                title: _connecting ? dic['xcm.connecting']! : dic['make']!,
                onPressed: () async {
                  final params = await _getTxParams(
                      TokenIcon(_chainFrom, crossChainIcons), feeToken);
                  if (params != null) {
                    final res = await Navigator.of(context)
                        .pushNamed(XcmTxConfirmPage.route, arguments: params);
                    if (res != null) {
                      Navigator.of(context).pop(res);
                    }
                  }
                },
              ),
            )
          ],
        );
      },
    );
  }
}

class _CrossChainTransferWarning extends StatelessWidget {
  _CrossChainTransferWarning({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return Container();

    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    return Container(
      margin: EdgeInsets.only(top: 16),
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
          Text(message, style: TextStyle(fontSize: 12))
        ],
      ),
    );
  }
}
