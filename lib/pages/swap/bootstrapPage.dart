import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/api/types/dexPoolInfoData.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/pages/swap/swapTokenInput.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/infoItem.dart';
import 'package:polkawallet_ui/components/infoItemRow.dart';
import 'package:polkawallet_ui/components/outlinedButtonSmall.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/utils/format.dart';

class BootstrapPage extends StatefulWidget {
  BootstrapPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/karura/dex/bootstrap';

  @override
  _BootstrapPageState createState() => _BootstrapPageState();
}

class _BootstrapPageState extends State<BootstrapPage> {
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      new GlobalKey<RefreshIndicatorState>();

  final TextEditingController _amountLeftCtrl = new TextEditingController();
  final TextEditingController _amountRightCtrl = new TextEditingController();

  int _addTab = 0;

  List? _userProvisioning;

  String? _leftAmountError;
  String? _rightAmountError;
  Timer? _delayTimer;

  Future<void> _queryData() async {
    final pools = await widget.plugin.api!.swap.getBootstraps();
    final DexPoolData args =
        ModalRoute.of(context)!.settings.arguments as DexPoolData;
    final poolIndex =
        pools.indexWhere((element) => args.tokenNameId == element.tokenNameId);
    if (poolIndex < 0) {
      Navigator.of(context).pop(true);
      return;
    }
    widget.plugin.store!.earn.setBootstraps(pools);
    final List res = await Future.wait([
      widget.plugin.sdk.webView!.evalJavascript(
          'api.query.dex.provisioningPool(${jsonEncode(args.tokens)}, "${widget.keyring.current.address}")'),
      widget.plugin.service!.assets
          .queryMarketPrices([relay_chain_token_symbol]),
    ]);

    if (mounted) {
      setState(() {
        _userProvisioning = res[0];
      });
    }
  }

  void _onAmountChange(int index, String value) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'common');
    final DexPoolData args =
        ModalRoute.of(context)!.settings.arguments as DexPoolData;
    final balancePair = args.tokens!
        .map((e) => AssetsUtils.tokenDataFromCurrencyId(widget.plugin, e))
        .toList();
    final balance = balancePair[index];

    final v = value.trim();
    String? error = Fmt.validatePrice(v, context);

    if (error == null) {
      final input = double.parse(v);
      final DexPoolData pool =
          ModalRoute.of(context)!.settings.arguments as DexPoolData;
      final min = Fmt.balanceDouble(
          pool.provisioning!.minContribution![index].toString(),
          balance!.decimals!);
      if (input < min) {
        error = '${dic!['min']} ${Fmt.priceCeil(min, lengthMax: 6)}';
      } else if (double.parse(v) >
          Fmt.bigIntToDouble(
              Fmt.balanceInt(balance.amount ?? '0'), balance.decimals!)) {
        error = dic!['amount.low'];
      }
    }

    // update pool info while amount changes
    if (_delayTimer != null) {
      _delayTimer!.cancel();
    }
    _delayTimer = Timer(Duration(milliseconds: 500), () {
      widget.plugin.service!.earn.getBootstraps();
    });

    if (mounted) {
      if (index == 0 && _leftAmountError != error) {
        setState(() {
          _leftAmountError = error;
        });
      } else if (_rightAmountError != error) {
        setState(() {
          _rightAmountError = error;
        });
      }
    }
  }

  Future<TxConfirmParams?> _onSubmit() async {
    if (_addTab != 1 && _amountLeftCtrl.text.isEmpty) {
      setState(() {
        _leftAmountError = Fmt.validatePrice(_amountLeftCtrl.text, context);
      });
    }
    if (_addTab != 0 && _amountRightCtrl.text.isEmpty) {
      setState(() {
        _rightAmountError = Fmt.validatePrice(_amountRightCtrl.text, context);
      });
    }
    if (_leftAmountError != null || _rightAmountError != null) {
      return null;
    }

    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    final DexPoolData pool =
        ModalRoute.of(context)!.settings.arguments as DexPoolData;
    final balancePair = pool.tokens!
        .map((e) => AssetsUtils.tokenDataFromCurrencyId(widget.plugin, e))
        .toList();

    final left = _amountLeftCtrl.text.trim();
    final right = _amountRightCtrl.text.trim();
    final leftAmount = left.isEmpty ? '0' : left;
    final rightAmount = right.isEmpty ? '0' : right;
    return TxConfirmParams(
      txTitle: dic['boot.provision.add'],
      module: 'dex',
      call: 'addProvision',
      txDisplay: {
        dic['earn.pool']: '${balancePair[0]!.symbol}-${balancePair[1]!.symbol}',
      },
      txDisplayBold: {
        "Token 1": Text(
          '$leftAmount ${balancePair[0]!.symbol}',
          style: Theme.of(context).textTheme.headline1,
        ),
        "Token 2": Text(
          '$rightAmount ${balancePair[1]!.symbol}',
          style: Theme.of(context).textTheme.headline1,
        ),
      },
      params: [
        pool.tokens![0],
        pool.tokens![1],
        Fmt.tokenInt(leftAmount, balancePair[0]!.decimals!).toString(),
        Fmt.tokenInt(rightAmount, balancePair[1]!.decimals!).toString(),
      ],
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _refreshKey.currentState!.show();
    });
  }

  @override
  void dispose() {
    _amountLeftCtrl.dispose();
    _amountRightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala');
    final colorGrey = Theme.of(context).unselectedWidgetColor;

    final DexPoolData? args =
        ModalRoute.of(context)!.settings.arguments as DexPoolData?;
    return Observer(builder: (_) {
      final poolIndex = widget.plugin.store!.earn.bootstraps
          .indexWhere((e) => e.tokenNameId == args!.tokenNameId);
      if (poolIndex < 0) {
        return Scaffold(
            appBar:
                AppBar(title: Text('${dic!['boot.title']}'), centerTitle: true),
            body: Container());
      }
      final pool = widget.plugin.store!.earn.bootstraps[poolIndex];
      final balancePair = pool.tokens!
          .map((e) => AssetsUtils.tokenDataFromCurrencyId(widget.plugin, e))
          .toList();
      final pairView =
          balancePair.map((e) => PluginFmt.tokenView(e!.symbol)).toList();

      final nowLeft = Fmt.balanceDouble(
          pool.provisioning!.accumulatedProvision![0].toString(),
          balancePair[0]!.decimals!);
      final nowRight = Fmt.balanceDouble(
          pool.provisioning!.accumulatedProvision![1].toString(),
          balancePair[1]!.decimals!);
      final myLeft = Fmt.balanceDouble(
          _userProvisioning != null ? _userProvisioning![0].toString() : '0',
          balancePair[0]!.decimals!);
      final myRight = Fmt.balanceDouble(
          _userProvisioning != null ? _userProvisioning![1].toString() : '0',
          balancePair[1]!.decimals!);
      final poolInfo =
          PluginFmt.calcLiquidityShare([nowLeft, nowRight], [myLeft, myRight]);

      final addLeft = double.parse(_amountLeftCtrl.text.trim().isEmpty
          ? '0'
          : _amountLeftCtrl.text.trim());
      final addRight = double.parse(_amountRightCtrl.text.trim().isEmpty
          ? '0'
          : _amountRightCtrl.text.trim());
      final poolInfoAfter = PluginFmt.calcLiquidityShare(
          [nowLeft + addLeft, nowRight + addRight], [addLeft, addRight]);

      final estShareLabel = '${dic!['boot.my.est']} ${dic['boot.my.share']}';
      final estTokenLabel = '${dic['boot.my.est']} LP Tokens';

      final ratio =
          nowLeft > 0 ? (nowRight + addRight) / (nowLeft + addLeft) : 1.0;
      final ratioView1 =
          '1 ${pairView[0]} : ${Fmt.priceCeil(ratio, lengthMax: 6)} ${pairView[1]}';
      String ratioView2 = '';
      final nativeToken = widget.plugin.networkState.tokenSymbol![0];
      final relayChainToken = relay_chain_token_symbol;
      if (balancePair.map((e) => e!.symbol).join('-').toUpperCase() ==
          '$nativeToken-$relayChainToken') {
        final relayChainTokenPrice =
            widget.plugin.store!.assets.marketPrices[relayChainToken];
        final priceView = relayChainTokenPrice == null
            ? '--.--'
            : Fmt.priceFloor(relayChainTokenPrice * ratio);
        ratioView2 += '1 ${pairView[0]} ≈ \$$priceView';
      }

      return Scaffold(
        appBar: AppBar(
          title: Text('${pairView.join('-')} ${dic['boot.title']}'),
          centerTitle: true,
          leading: BackBtn(),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  key: _refreshKey,
                  onRefresh: _queryData,
                  child: ListView(
                    padding: EdgeInsets.all(16),
                    children: [
                      RoundedCard(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Container(
                              margin: EdgeInsets.only(bottom: 16),
                              child: Text(dic['boot.my']!),
                            ),
                            Text(
                              Fmt.priceFloor(myLeft) +
                                  '${pairView[0]} + ' +
                                  Fmt.priceFloor(myRight) +
                                  pairView[1],
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: colorGrey,
                                  letterSpacing: -0.8),
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 24),
                              child: Row(
                                children: [
                                  InfoItem(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    title: estShareLabel,
                                    content: Fmt.ratio(poolInfo.ratio),
                                  ),
                                  InfoItem(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    title: estTokenLabel,
                                    content: Fmt.priceFloor(poolInfo.lp,
                                        lengthMax: 6),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      RoundedCard(
                        padding: EdgeInsets.all(16),
                        margin: EdgeInsets.only(top: 16),
                        child: Column(
                          children: [
                            Container(
                              margin: EdgeInsets.only(bottom: 16),
                              child: Text(dic['boot.provision.add']!),
                            ),
                            Container(
                              margin: EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  OutlinedButtonSmall(
                                    content: pairView[0],
                                    active: _addTab == 0,
                                    onPressed: () {
                                      if (_addTab != 0) {
                                        setState(() {
                                          _addTab = 0;
                                          _amountRightCtrl.text = '';
                                          _rightAmountError = null;
                                        });
                                      }
                                    },
                                  ),
                                  OutlinedButtonSmall(
                                    content: pairView[1],
                                    active: _addTab == 1,
                                    onPressed: () {
                                      if (_addTab != 1) {
                                        setState(() {
                                          _addTab = 1;
                                          _amountLeftCtrl.text = '';
                                          _leftAmountError = null;
                                        });
                                      }
                                    },
                                  ),
                                  OutlinedButtonSmall(
                                    content: '${pairView[0]} + ${pairView[1]}',
                                    active: _addTab == 2,
                                    onPressed: () {
                                      if (_addTab != 2) {
                                        setState(() {
                                          _addTab = 2;
                                        });
                                      }
                                    },
                                  )
                                ],
                              ),
                            ),
                            Visibility(
                                visible: _addTab != 1,
                                child: Column(
                                  children: [
                                    Container(
                                      margin: EdgeInsets.only(top: 8),
                                      child: SwapTokenInput(
                                        title: dic['earn.add'],
                                        inputCtrl: _amountLeftCtrl,
                                        balance: balancePair[0],
                                        tokenIconsMap: widget.plugin.tokenIcons,
                                        onInputChange: (v) =>
                                            _onAmountChange(0, v),
                                        onClear: () {
                                          setState(() {
                                            _amountLeftCtrl.text = '';
                                          });
                                          _onAmountChange(0, '0');
                                        },
                                      ),
                                    ),
                                    ErrorMessage(_leftAmountError),
                                  ],
                                )),
                            Visibility(
                                visible: _addTab == 2, child: Icon(Icons.add)),
                            Visibility(
                                visible: _addTab != 0,
                                child: Column(
                                  children: [
                                    Container(
                                      margin: EdgeInsets.only(top: 8),
                                      child: SwapTokenInput(
                                        title: dic['earn.add'],
                                        inputCtrl: _amountRightCtrl,
                                        balance: balancePair[1],
                                        tokenIconsMap: widget.plugin.tokenIcons,
                                        onInputChange: (v) =>
                                            _onAmountChange(1, v),
                                        onClear: () {
                                          setState(() {
                                            _amountRightCtrl.text = '';
                                          });
                                          _onAmountChange(1, '0');
                                        },
                                      ),
                                    ),
                                    ErrorMessage(_rightAmountError),
                                  ],
                                )),
                            Container(
                              margin: EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  InfoItem(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    title: ratioView1,
                                    content: ratioView2,
                                  )
                                ],
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 8),
                              child: InfoItemRow(estShareLabel,
                                  '+${Fmt.ratio(poolInfoAfter.ratio)}'),
                            ),
                            InfoItemRow(estTokenLabel,
                                '+${Fmt.priceFloor(poolInfoAfter.lp, lengthMax: 6)}'),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.all(16),
                child: TxButton(
                  text: dic['boot.provision.add'],
                  getTxParams: _onSubmit,
                  onFinish: (res) {
                    if (res != null) {
                      _refreshKey.currentState!.show();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class ErrorMessage extends StatelessWidget {
  ErrorMessage(this.error, {this.margin});
  final error;
  EdgeInsetsGeometry? margin;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.only(left: 16, top: 4),
      child: error == null
          ? null
          : Row(children: [
              Text(
                error,
                style: TextStyle(fontSize: 12, color: Colors.red),
              )
            ]),
    );
  }
}
