import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/api/types/dexPoolInfoData.dart';
import 'package:polkawallet_plugin_karura/pages/swapNew/bootstrapPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/connectionChecker.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/v3/plugin/PluginTxButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginAccountInfoAction.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginInputBalance.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/components/v3/index.dart' as v3;
import 'package:polkawallet_ui/pages/v3/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';

class TaigaAddLiquidityPage extends StatefulWidget {
  TaigaAddLiquidityPage(this.plugin, this.keyring, {Key? key})
      : super(key: key);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/karura/earn/taigaAddLiquidity';

  @override
  State<TaigaAddLiquidityPage> createState() => _TaigaAddLiquidityPageState();
}

class _TaigaAddLiquidityPageState extends State<TaigaAddLiquidityPage> {
  List<TextEditingController> _textControllers = [];
  List<dynamic> _error = [];
  bool _balancedProportion = false;
  Map<dynamic, dynamic>? _mintAmount;

  bool _loading = true;
  Future<void> _queryTaigaPoolInfo() async {
    final info = await widget.plugin.api!.earn
        .getTaigaPoolInfo(widget.keyring.current.address!);
    widget.plugin.store!.earn.setTaigaPoolInfo(info);
    final data = await widget.plugin.api!.earn.getTaigaTokenPairs();
    widget.plugin.store!.earn.setTaigaTokenPairs(data!);
    setState(() {
      _loading = false;
    });
  }

  Future<void> _getTaigaMintAmount() async {
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    final pool = widget.plugin.store!.earn.taigaTokenPairs
        .firstWhere((e) => e.tokenNameId == args?['poolId']);
    final tokenPair = pool.tokens!
        .map((e) => AssetsUtils.tokenDataFromCurrencyId(widget.plugin, e))
        .toList();

    final List<String> input = [];
    _textControllers.forEach((element) {
      final index = _textControllers.indexOf(element);
      if (element.text.trim().isNotEmpty) {
        input.add(Fmt.tokenInt(element.text.trim(), tokenPair[index].decimals!)
            .toString());
      } else {
        input.add("0");
      }
    });
    final info = await widget.plugin.api!.earn
        .getTaigaMintAmount(args?['poolId'], input, 0.005);
    setState(() {
      _mintAmount = info;
    });
  }

  Future<void> _onMaxAmountChange(DexPoolData taigaToken,
      List<TokenBalanceData> tokenPair, String target, int index) async {
    final value = target.trim();
    double v = 0;
    try {
      v = value.isEmpty ? 0 : double.parse(value);
    } catch (e) {}
    if (_balancedProportion) {
      tokenPair.forEach((element) {
        final eIndex = tokenPair.indexOf(element);
        if (eIndex != index) {
          var ratio = 0.0;
          if (Fmt.balanceDouble(
                  taigaToken.balances![index], tokenPair[index].decimals!) >
              0) {
            ratio = Fmt.balanceDouble(
                    taigaToken.balances![eIndex], tokenPair[eIndex].decimals!) /
                Fmt.balanceDouble(
                    taigaToken.balances![index], tokenPair[index].decimals!);
          }

          _textControllers[eIndex].text = (ratio * v).toStringAsFixed(6);
        } else {
          _textControllers[eIndex].text = target;
        }
      });
    } else {
      _textControllers[index].text = target;
    }
    final res = _onValidate(tokenPair, index);
    if (res) {
      _getTaigaMintAmount();
    }
  }

  Future<void> _onAmountChange(DexPoolData taigaToken,
      List<TokenBalanceData> tokenPair, String target, int index) async {
    final value = target.trim();
    double v = 0;
    try {
      v = value.isEmpty ? 0 : double.parse(value);
    } catch (e) {}
    if (_balancedProportion) {
      tokenPair.forEach((element) {
        final eIndex = tokenPair.indexOf(element);
        if (eIndex != index) {
          var ratio = 0.0;
          if (Fmt.balanceDouble(
                  taigaToken.balances![index], tokenPair[index].decimals!) >
              0) {
            ratio = Fmt.balanceDouble(
                    taigaToken.balances![eIndex], tokenPair[eIndex].decimals!) /
                Fmt.balanceDouble(
                    taigaToken.balances![index], tokenPair[index].decimals!);
          }
          _textControllers[eIndex].text = (ratio * v).toStringAsFixed(6);
        }
      });
    }
    if (_onValidate(tokenPair, index)) {
      _getTaigaMintAmount();
    }
  }

  bool _onValidate(List<TokenBalanceData> tokenPair, int index) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'common');
    tokenPair.forEach((element) {
      final eIndex = tokenPair.indexOf(element);
      final v = _textControllers[eIndex].text.trim();
      if (v.isNotEmpty || eIndex == index) {
        String? error = Fmt.validatePrice(v, context);
        if (error == null) {
          if (double.parse(v) >
              Fmt.balanceDouble(element.amount!, element.decimals ?? 12)) {
            error = dic!['amount.low'];
          }
        }
        _error[eIndex] = error;
      } else {
        _error[eIndex] = null;
      }
    });
    setState(() {});
    return _error.indexWhere((element) => element != null) < 0;
  }

  Future<void> _onSubmit(int? decimalsLeft, int? decimalsRight) async {
    if (_error.indexWhere((element) => element != null) < 0) {
      final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala');
      final args = ModalRoute.of(context)!.settings.arguments as Map?;
      final pool = widget.plugin.store!.earn.taigaTokenPairs
          .firstWhere((e) => e.tokenNameId == args?['poolId']);

      Map<String, Widget> txDisplayBold = {};
      // final params = [
      //   args?['poolId'],
      //   _textControllers.map((e) {
      //     final taigaTokenPairs = widget.plugin.store!.earn.taigaTokenPairs;
      //     final taigaToken = taigaTokenPairs
      //         .where((e) => e.tokenNameId == args?['poolId'])
      //         .first;
      //     final tokenPair = taigaToken.tokens!
      //         .map((e) => AssetsUtils.tokenDataFromCurrencyId(widget.plugin, e))
      //         .toList();
      //     final index = _textControllers.indexOf(e);
      //     if (e.text.trim().isNotEmpty) {
      //       txDisplayBold.addAll({
      //         "Token ${index + 1}": Text(
      //           '${e.text.trim()} ${PluginFmt.tokenView(tokenPair[index].symbol)}',
      //           style: Theme.of(context)
      //               .textTheme
      //               .headline1
      //               ?.copyWith(color: Colors.white),
      //         )
      //       });
      //     }
      //     return Fmt.tokenInt(e.text.trim(), tokenPair[index].decimals!)
      //         .toString();
      //   }).toList(),
      //   '0',
      // ];

      final tokenPair = pool.tokens!
          .map((e) => AssetsUtils.tokenDataFromCurrencyId(widget.plugin, e))
          .toList();
      final txDisplay = {
        dic!['earn.pool']: tokenPair.map((e) => e.symbol).join("-")
      };
      final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
          arguments: TxConfirmParams(
            module: 'stableAsset',
            call: 'mint',
            txTitle: I18n.of(context)!
                .getDic(i18n_full_dic_karura, 'acala')!['earn.add'],
            txDisplay: txDisplay,
            txDisplayBold: txDisplayBold,
            params: _mintAmount!["params"],
            isPlugin: true,
          ))) as Map?;
      if (res != null) {
        Navigator.of(context).pop(res);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    final args = ModalRoute.of(context)!.settings.arguments as Map?;

    final lableStyle = Theme.of(context)
        .textTheme
        .headline5
        ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600);
    final valueStyle =
        Theme.of(context).textTheme.headline5?.copyWith(color: Colors.white);
    return PluginScaffold(
      appBar: PluginAppBar(
        title: Text(dic['earn.add']!),
        actions: [PluginAccountInfoAction(widget.keyring)],
      ),
      body: Observer(builder: (_) {
        final dexPools = widget.plugin.store!.earn.taigaPoolInfoMap;
        final taigaTokenPairs = widget.plugin.store!.earn.taigaTokenPairs;
        final taigaPool = dexPools[args?['poolId']];
        final taigaToken = taigaTokenPairs
            .where((e) => e.tokenNameId == args?['poolId'])
            .first;
        final tokenPair = taigaToken.tokens!
            .map((e) => AssetsUtils.tokenDataFromCurrencyId(widget.plugin, e))
            .toList();
        if (_textControllers.length == 0) {
          taigaToken.tokens!.forEach((element) {
            _error.add(null);
            _textControllers.add(TextEditingController());
          });
        }

        final balance = AssetsUtils.getBalanceFromTokenNameId(
            widget.plugin, taigaToken.tokenNameId);

        List<String> poolSize = [];
        taigaToken.balances?.forEach((element) {
          final index = taigaToken.balances!.indexOf(element);
          poolSize.add(
              "${index == 0 ? '' : '+ '}${Fmt.balance(element, tokenPair[index].decimals!)} ${PluginFmt.tokenView(tokenPair[index].symbol)}");
        });

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ConnectionChecker(
                    widget.plugin,
                    onConnected: _queryTaigaPoolInfo,
                  ),
                  dexPools.length == 0 || taigaTokenPairs.length == 0
                      ? ListView(
                          padding: EdgeInsets.all(16),
                          children: [
                            Center(
                              child: Container(
                                height: MediaQuery.of(context).size.width,
                                child: ListTail(
                                  isEmpty: true,
                                  isLoading: _loading,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          ],
                        )
                      : Column(
                          children: [
                            ...tokenPair.map((e) {
                              final index = tokenPair.indexOf(e);
                              return Padding(
                                  padding: EdgeInsets.only(
                                      bottom: index + 1 >= tokenPair.length
                                          ? 0
                                          : 24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      PluginInputBalance(
                                        titleTag: "Token${index + 1}",
                                        margin: EdgeInsets.zero,
                                        balance: e,
                                        tokenIconsMap: widget.plugin.tokenIcons,
                                        inputCtrl: _textControllers[index],
                                        onInputChange: (value) {
                                          _onAmountChange(
                                              taigaToken,
                                              tokenPair,
                                              _textControllers[index].text,
                                              index);
                                        },
                                        onSetMax: (max) {
                                          var amount = Fmt.bigIntToDouble(
                                                  max, e.decimals!)
                                              .toStringAsFixed(6);
                                          final inputString =
                                              Fmt.bigIntToDouble(
                                                      max, e.decimals!)
                                                  .toString()
                                                  .split(".");
                                          if (inputString.length > 1 &&
                                              inputString[1].length > 6) {
                                            amount =
                                                "${inputString[0]}.${inputString[1].substring(0, 6)}";
                                          }
                                          _onMaxAmountChange(taigaToken,
                                              tokenPair, amount, index);
                                        },
                                      ),
                                      ErrorMessage(
                                        _error[index],
                                        margin:
                                            EdgeInsets.symmetric(vertical: 2),
                                      ),
                                    ],
                                  ));
                            }).toList(),
                            Padding(
                                padding: EdgeInsets.only(top: 10, bottom: 24),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Text(
                                      dic['earn.taiga.addLiquidity']!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headline5
                                          ?.copyWith(color: Color(0xFFFFFAF9)),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: SizedBox(
                                        width: 28,
                                        child: v3.CupertinoSwitch(
                                          value: _balancedProportion,
                                          onChanged: (value) {
                                            setState(() {
                                              _balancedProportion = value;
                                              for (int i = 0;
                                                  i < _error.length;
                                                  i++) {
                                                _error[i] = null;
                                              }
                                              _textControllers
                                                  .forEach((element) {
                                                element.text = "";
                                              });
                                            });
                                          },
                                          isPlugin: true,
                                        ),
                                      ),
                                    )
                                  ],
                                )),
                            Visibility(
                                visible: _mintAmount != null,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        dic['v3.earn.lpTokenReceived']!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline4
                                            ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Text(
                                        '≈ ${Fmt.priceFloorBigInt(BigInt.parse(_mintAmount?["minAmount"] ?? "0"), balance.decimals!)} ${PluginFmt.tokenView(balance.symbol)}',
                                        textAlign: TextAlign.right,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline4
                                            ?.copyWith(
                                              color: Colors.white,
                                            )),
                                  ],
                                )),
                            Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    dic['earn.taiga.poolSize']!,
                                    style: lableStyle,
                                  ),
                                  Text(
                                    poolSize.join("\n"),
                                    textAlign: TextAlign.end,
                                    style: valueStyle?.copyWith(height: 1.7),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                  Padding(
                      padding: EdgeInsets.only(top: 37, bottom: 38),
                      child: PluginButton(
                        title: dic['earn.add']!,
                        onPressed: () => _onSubmit(
                            tokenPair[0].decimals, tokenPair[1].decimals),
                      )),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
