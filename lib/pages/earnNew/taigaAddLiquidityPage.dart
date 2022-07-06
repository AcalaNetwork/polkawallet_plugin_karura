import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/connectionChecker.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginAccountInfoAction.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginInputBalance.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/components/v3/index.dart' as v3;

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

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
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
          taigaToken.tokens!.forEach(
              (element) => _textControllers.add(TextEditingController()));
        }
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
                              return PluginInputBalance(
                                titleTag: "Token${index + 1}",
                                margin: EdgeInsets.only(
                                    bottom:
                                        index + 1 >= tokenPair.length ? 0 : 24),
                                balance: e,
                                tokenIconsMap: widget.plugin.tokenIcons,
                                inputCtrl: _textControllers[index],
                                onInputChange: (value) {},
                                onSetMax: (max) {},
                              );
                            }).toList(),
                            Padding(
                                padding: EdgeInsets.only(top: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Text(
                                      "Add all assets in a balanced proportion",
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
                                          value: true,
                                          onChanged: (value) {},
                                          isPlugin: true,
                                        ),
                                      ),
                                    )
                                  ],
                                ))
                          ],
                        )
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
