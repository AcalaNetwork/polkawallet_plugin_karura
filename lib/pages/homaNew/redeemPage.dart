import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/api/types/calcHomaRedeemAmount.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/pages/swap/bootstrapPage.dart';
import 'package:polkawallet_plugin_karura/pages/swap/swapTokenInput.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/textTag.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginInputBalance.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginLoadingWidget.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTextTag.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';

class RedeemPage extends StatefulWidget {
  RedeemPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/karura/homa/redeem';

  @override
  _RedeemPageState createState() => _RedeemPageState();
}

class _RedeemPageState extends State<RedeemPage> {
  final TextEditingController _amountPayCtrl = new TextEditingController();

  String? _error;
  BigInt? _maxInput;

  CalcHomaRedeemAmount? _data;
  num _receiveAmount = 0;
  num _fastReceiveAmount = 0;
  num _swapAmount = 0;

  List<String>? symbols;
  final stakeToken = relay_chain_token_symbol;
  List<int>? decimals;

  late double karBalance;

  late int stakeDecimal;

  late double minRedeem;

  Timer? _timer;

  bool isLoading = false;

  num selectIndex = 0;

  @override
  void initState() {
    super.initState();

    symbols = widget.plugin.networkState.tokenSymbol;
    decimals = widget.plugin.networkState.tokenDecimals;

    karBalance = Fmt.balanceDouble(
        widget.plugin.balances.native!.availableBalance.toString(),
        decimals![symbols!.indexOf("L$stakeToken")]);

    stakeDecimal = decimals![symbols!.indexOf("L$stakeToken")];

    minRedeem = widget.plugin.store!.homa.env != null
        ? widget.plugin.store!.homa.env!.redeemThreshold
        : Fmt.balanceDouble(
            widget.plugin.networkConst['homaLite']['minimumRedeemThreshold']
                .toString(),
            stakeDecimal);
  }

  Future<void> _updateReceiveAmount(double? input) async {
    if (mounted && input != null) {
      setState(() {
        isLoading = true;
      });

      final fastData =
          await (widget.plugin.api!.homa.calcHomaNewRedeemAmount(input, true)
              as FutureOr<Map<dynamic, dynamic>>);

      setState(() {
        _fastReceiveAmount = fastData['receive'];
      });

      final data =
          await (widget.plugin.api!.homa.calcHomaNewRedeemAmount(input, false)
              as FutureOr<Map<dynamic, dynamic>>);

      setState(() {
        _receiveAmount = data['receive'];
      });

      final lToken =
          AssetsUtils.getBalanceFromTokenNameId(widget.plugin, 'L$stakeToken');
      final token =
          AssetsUtils.getBalanceFromTokenNameId(widget.plugin, stakeToken);
      final swapRes = await widget.plugin.api!.swap.queryTokenSwapAmount(
          input.toString(),
          null,
          [
            {...lToken!.currencyId!, 'decimals': lToken.decimals},
            {...token!.currencyId!, 'decimals': token.decimals},
          ],
          '0.1');
      setState(() {
        _swapAmount = swapRes.amount!;
      });

      setState(() {
        isLoading = false;
      });
    }
  }

  void _onSupplyAmountChange(String v, BigInt max) {
    final supply = v.trim();
    setState(() {
      _maxInput = null;
    });

    final error = _validateInput(supply, max);
    setState(() {
      _error = error;
      if (error != null) {
        _data = null;
      }
    });

    if (error != null) {
      return;
    }
    _updateReceiveAmount(double.tryParse(supply));
  }

  String? _validateInput(String supply, BigInt? max) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'common');
    final error = Fmt.validatePrice(supply, context);
    if (error != null) {
      return error;
    }

    final pay = double.parse(supply);
    if (_maxInput == null &&
        Fmt.tokenInt(supply,
                decimals![symbols!.indexOf('L$relay_chain_token_symbol')]) >
            max!) {
      return dic!['amount.low'];
    }

    if (pay < minRedeem) {
      final minLabel = I18n.of(context)!
          .getDic(i18n_full_dic_karura, 'acala')!['homa.pool.redeem'];
      return '$minLabel   ${minRedeem.toStringAsFixed(4)}';
    }

    return error;
  }

  void _onSetMax(BigInt? max) {
    final amount = Fmt.bigIntToDouble(max, stakeDecimal);
    setState(() {
      _amountPayCtrl.text = amount.toStringAsFixed(6);
      _maxInput = max;
      _error = _validateInput(amount.toString(), max);
    });

    _updateReceiveAmount(amount);
  }

  BigInt _getMaxAmount() {
    final pendingRedeemReq = Fmt.balanceInt(
        (widget.plugin.store!.homa.userInfo?.redeemRequest ?? {})['amount'] ??
            '0');
    final lTokenBalance =
        widget.plugin.store!.assets.tokenBalanceMap["L$stakeToken"]!;
    return Fmt.balanceInt(lTokenBalance.amount) + pendingRedeemReq;
  }

  Future<void> _onSubmit() async {
    final pay = _amountPayCtrl.text.trim();

    if (_error != null || pay.isEmpty || (_data == null && _receiveAmount == 0))
      return;

    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;

    final txDisplay = {
      dic['dex.pay']!: Text(
        '$pay L$stakeToken',
        style: Theme.of(context).textTheme.headline1,
      ),
      dic['dex.receive']!: Text(
        '≈ ${Fmt.priceFloor((selectIndex == 0 ? _fastReceiveAmount : selectIndex == 1 ? _swapAmount : _receiveAmount) as double?)} $stakeToken',
        style: Theme.of(context).textTheme.headline1,
      ),
    };

    String module = 'homa';
    String call = 'requestRedeem';
    List params = [
      (_maxInput ?? Fmt.tokenInt(pay, stakeDecimal)).toString(),
      false,
    ];
    String? paramsRaw;
    if (selectIndex == 0) {
      //fast redeem
      module = 'utility';
      call = 'batch';
      params = [
        (_maxInput ?? Fmt.tokenInt(pay, stakeDecimal)).toString(),
        true,
      ];
      paramsRaw = '[['
          'api.tx.homa.requestRedeem(...${jsonEncode(params)}),'
          'api.tx.homa.fastMatchRedeems(["${widget.keyring.current.address}"])'
          ']]';
      params = [];
    } else if (selectIndex == 1) {
      // swap
      module = 'utility';
      call = 'batch';
      params = [
        [
          {'Token': 'L$stakeToken'},
          {'Token': stakeToken}
        ],
        (_maxInput ?? Fmt.tokenInt(pay, stakeDecimal)).toString(),
        "0",
      ];
      paramsRaw = '[['
          'api.tx.homa.requestRedeem(...${jsonEncode([0, false])}),'
          'api.tx.dex.swapWithExactSupply(...${jsonEncode(params)})'
          ']]';
      params = [];
    }

    final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
        arguments: TxConfirmParams(
          module: module,
          call: call,
          txTitle: dic['homa.redeem'],
          txDisplay: selectIndex != 2
              ? {
                  dic['homa.fast']: '',
                }
              : {},
          txDisplayBold: txDisplay,
          params: params,
          rawParams: paramsRaw,
        ))) as Map?;

    if (res != null) {
      Navigator.of(context).pop('1');
    }
  }

  @override
  void dispose() {
    _amountPayCtrl.dispose();
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
    super.dispose();
  }

  @override
  Widget build(_) {
    final grey = Theme.of(context).unselectedWidgetColor;
    return Observer(
      builder: (BuildContext context) {
        final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;

        final lTokenBalance =
            widget.plugin.store!.assets.tokenBalanceMap["L$stakeToken"]!;
        final max = _getMaxAmount();

        return PluginScaffold(
          appBar: PluginAppBar(
            title: Text('${dic['homa.redeem']} $stakeToken'),
            centerTitle: true,
          ),
          body: SafeArea(
              child: Column(
            children: [
              Expanded(
                  child: ListView(
                padding: EdgeInsets.all(16),
                children: <Widget>[
                  PluginInputBalance(
                    margin: EdgeInsets.only(bottom: 2),
                    titleTag: dic['earn.unStake'],
                    inputCtrl: _amountPayCtrl,
                    balance: TokenBalanceData(
                        symbol: lTokenBalance.symbol,
                        amount: max.toString(),
                        decimals: lTokenBalance.decimals),
                    tokenIconsMap: widget.plugin.tokenIcons,
                    onInputChange: (v) => _onSupplyAmountChange(v, max),
                    onSetMax: karBalance > 0.1 ? (v) => _onSetMax(v) : null,
                    onClear: () {
                      setState(() {
                        _amountPayCtrl.text = '';
                      });
                      _onSupplyAmountChange('', max);
                    },
                  ),
                  Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dic['v3.homa.minUnstakingAmmount']!,
                          style: Theme.of(context)
                              .textTheme
                              .headline5
                              ?.copyWith(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w300),
                        ),
                        Text(
                          "${minRedeem.toStringAsFixed(4)} $stakeToken",
                          style: Theme.of(context)
                              .textTheme
                              .headline5
                              ?.copyWith(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w300),
                        )
                      ],
                    ),
                  ),
                  ErrorMessage(_error),
                  Visibility(visible: isLoading, child: PluginLoadingWidget()),
                  Column(
                    children: [
                      PluginTextTag(
                        title: dic['v3.selectRedeemMethod']!,
                      ),
                      Container(
                        width: double.infinity,
                        padding:
                            EdgeInsets.symmetric(horizontal: 11, vertical: 14),
                        margin: EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 1),
                            borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(17),
                                topRight: Radius.circular(17),
                                bottomRight: Radius.circular(17))),
                        child: Column(
                          children: [
                            UnStakeTypeItemWidget(
                              title: dic['homa.fast']!,
                              value:
                                  "$_fastReceiveAmount $relay_chain_token_symbol",
                              describe: dic['homa.fast.describe']!,
                              isSelect: selectIndex == 0,
                              ontap: () {
                                setState(() {
                                  selectIndex = 0;
                                });
                              },
                            ),
                            UnStakeTypeItemWidget(
                              title: dic['dex.swap']!,
                              value: "$_swapAmount $relay_chain_token_symbol",
                              margin: EdgeInsets.symmetric(vertical: 14),
                              describe: dic['dex.swap.describe']!,
                              isSelect: selectIndex == 1,
                              ontap: () {
                                setState(() {
                                  selectIndex = 1;
                                });
                              },
                            ),
                            UnStakeTypeItemWidget(
                              title: dic['v3.homa.unbond']!,
                              value:
                                  "$_receiveAmount $relay_chain_token_symbol",
                              describe: dic['v3.homa.unbond.describe']!,
                              isSelect: selectIndex == 2,
                              ontap: () {
                                setState(() {
                                  selectIndex = 2;
                                });
                              },
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  // RoundedCard(
                  //   margin: EdgeInsets.only(top: 20),
                  //   padding: EdgeInsets.all(16),
                  //   child: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: <Widget>[
                  //       Visibility(
                  //           visible: pendingRedeemReq > BigInt.zero &&
                  //               !_isFastRedeem,
                  //           child: Container(
                  //             margin: EdgeInsets.only(bottom: 8),
                  //             child: Row(
                  //               children: [
                  //                 Expanded(
                  //                     child: TextTag(
                  //                   dic['homa.redeem.pending']! +
                  //                       ' $pendingRedeemReqView L$relay_chain_token_symbol' +
                  //                       '\n${dic['homa.redeem.replace']}',
                  //                   padding: EdgeInsets.symmetric(
                  //                       vertical: 4, horizontal: 8),
                  //                 ))
                  //               ],
                  //             ),
                  //           )),
                  //       SwapTokenInput(
                  //         title: dic['dex.pay'],
                  //         inputCtrl: _amountPayCtrl,
                  //         balance: TokenBalanceData(
                  //             symbol: lTokenBalance.symbol,
                  //             amount: max.toString(),
                  //             decimals: lTokenBalance.decimals),
                  //         tokenIconsMap: widget.plugin.tokenIcons,
                  //         onInputChange: (v) => _onSupplyAmountChange(v, max),
                  //         onSetMax:
                  //             karBalance > 0.1 ? (v) => _onSetMax(v) : null,
                  //         onClear: () {
                  //           setState(() {
                  //             _amountPayCtrl.text = '';
                  //           });
                  //           _onSupplyAmountChange('', max);
                  //         },
                  //       ),
                  //       ErrorMessage(_error),
                  //       // Visibility(
                  //       //     visible: _amountReceive.isNotEmpty,
                  //       //     child: Container(
                  //       //       margin: EdgeInsets.only(top: 16),
                  //       //       child: InfoItemRow(dic['dex.receive'],
                  //       //           '$_amountReceive L$stakeToken'),
                  //       //     )),
                  //       Container(
                  //         child: Row(
                  //           mainAxisAlignment: MainAxisAlignment.end,
                  //           children: [
                  //             Text(dic['homa.fast']!,
                  //                 style: TextStyle(fontSize: 13)),
                  //             Container(
                  //               margin: EdgeInsets.only(left: 5),
                  //               child: CupertinoSwitch(
                  //                 value: _isFastRedeem,
                  //                 onChanged: _switchFast,
                  //               ),
                  //             )
                  //           ],
                  //         ),
                  //       ),
                  //       Container(
                  //         margin: EdgeInsets.only(top: 5),
                  //         padding: EdgeInsets.all(16),
                  //         decoration: BoxDecoration(
                  //           borderRadius: BorderRadius.all(Radius.circular(16)),
                  //           border: Border.all(
                  //               color: Theme.of(context).disabledColor,
                  //               width: 0.5),
                  //         ),
                  //         child: Column(
                  //           children: [
                  //             // Row(
                  //             //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //             //   children: [
                  //             //     Text(dic['homa.redeem.unbonding']!,
                  //             //         style: labelStyle),
                  //             //     Text("$unbondEras Kusama Eras")
                  //             //   ],
                  //             // ),
                  //             Row(
                  //               mainAxisAlignment:
                  //                   MainAxisAlignment.spaceBetween,
                  //               children: [
                  //                 Text(dic['homa.redeem.receive']!,
                  //                     style: labelStyle),
                  //                 Text(
                  //                     "${_data != null ? _data!.expected : (_receiveAmount ?? 0)} $stakeToken")
                  //               ],
                  //             ),
                  //             Visibility(
                  //                 visible: _isFastRedeem,
                  //                 child: Row(
                  //                   mainAxisAlignment:
                  //                       MainAxisAlignment.spaceBetween,
                  //                   children: [
                  //                     Text(dic['homa.redeem.fee']!,
                  //                         style: labelStyle),
                  //                     Text(
                  //                         "${_data != null ? _data!.fee : _fastFee} L$stakeToken")
                  //                   ],
                  //                 )),
                  //           ],
                  //         ),
                  //       ),
                  //       // Container(
                  //       //   margin: EdgeInsets.only(top: 8),
                  //       //   child: Row(
                  //       //     mainAxisAlignment: MainAxisAlignment.end,
                  //       //     children: [
                  //       //       Text(dic['homa.now']!,
                  //       //           style: TextStyle(fontSize: 13)),
                  //       //       GestureDetector(
                  //       //         child: Container(
                  //       //           padding: EdgeInsets.only(left: 5),
                  //       //           child: Text(
                  //       //             'Swap',
                  //       //             style: TextStyle(
                  //       //               color: Theme.of(context).primaryColor,
                  //       //               fontStyle: FontStyle.italic,
                  //       //               decoration: TextDecoration.underline,
                  //       //             ),
                  //       //           ),
                  //       //         ),
                  //       //         onTap: () {
                  //       //           Navigator.popUntil(
                  //       //               context, ModalRoute.withName('/'));
                  //       //           Navigator.of(context).pushNamed(SwapPage.route);
                  //       //         },
                  //       //       )
                  //       //     ],
                  //       //   ),
                  //       // ),
                  //     ],
                  //   ),
                  // )
                ],
              )),
              Padding(
                  padding: EdgeInsets.only(left: 16, right: 16, bottom: 54),
                  child: PluginButton(
                    title: dic['homa.redeem']!,
                    onPressed: _onSubmit,
                  ))
            ],
          )),
        );
      },
    );
  }
}

class UnStakeTypeItemWidget extends StatelessWidget {
  const UnStakeTypeItemWidget(
      {required this.title,
      required this.value,
      required this.describe,
      this.isSelect = false,
      this.margin,
      this.ontap,
      Key? key})
      : super(key: key);
  final String title;
  final String value;
  final String describe;
  final bool isSelect;
  final EdgeInsetsGeometry? margin;
  final Function()? ontap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: ontap,
        child: Container(
          height: 110,
          padding: EdgeInsets.all(10),
          margin: margin,
          decoration: BoxDecoration(
              color: Color(0x24FFFFFF),
              border: isSelect
                  ? Border.all(color: Color(0xFFFC8156), width: 2)
                  : null,
              borderRadius: const BorderRadius.all(Radius.circular(8))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headline4?.copyWith(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headline4?.copyWith(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  )
                ],
              ),
              Container(
                  padding: EdgeInsets.only(top: 8),
                  margin: EdgeInsets.only(right: 60),
                  child: Text(
                    describe,
                    style: Theme.of(context).textTheme.headline5?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w300,
                        fontSize: 10),
                  ))
            ],
          ),
        ));
  }
}
