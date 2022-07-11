import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/pages/earnNew/taigaAddLiquidityPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class CompletedPage extends StatefulWidget {
  CompletedPage(this.plugin, {Key? key}) : super(key: key);
  final PluginKarura plugin;

  static final String route = '/homa/completed';
  @override
  State<CompletedPage> createState() => _CompletedPageState();
}

class _CompletedPageState extends State<CompletedPage> {
  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    final data = ModalRoute.of(context)!.settings.arguments as Map;

    final dexPools = widget.plugin.store!.earn.taigaPoolInfoMap;
    double taigaApr = 0;
    dexPools["sa://0"]?.apy.forEach((key, value) {
      taigaApr += value;
    });

    return PluginScaffold(
        appBar: PluginAppBar(
          title: Text('${dic['homa.mint']} L$relay_chain_token_symbol'),
          centerTitle: true,
        ),
        body: SafeArea(
            child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 16, bottom: 16, left: 16),
                width: double.infinity,
                child: Image.asset("assets/images/completed.png"),
              ),
              Text(
                dic['earn.dex.joinPool.completed']!,
                style: Theme.of(context).textTheme.headline2?.copyWith(
                    fontSize: UI.getTextSize(36, context),
                    fontWeight: FontWeight.bold,
                    color: PluginColorsDark.headline1),
              ),
              Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    "${data["receive"]} L$relay_chain_token_symbol ${dic['v3.loan.minted']}",
                    style: Theme.of(context).textTheme.headline4?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: PluginColorsDark.primary),
                  )),
              Padding(
                padding: EdgeInsets.only(left: 45, right: 45, top: 16),
                child: Text(
                  "${dic['earn.dex.joinPool.message1']} $relay_chain_token_symbol-L$relay_chain_token_symbol ${dic['earn.dex.joinPool.message2']} ${Fmt.ratio(taigaApr)} ${dic['earn.dex.joinPool.message3']}",
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headline5
                      ?.copyWith(color: Colors.white, height: 1.8),
                ),
              ),
              Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.only(top: 113),
                child: Row(
                  children: [
                    Expanded(
                      child: PluginButton(
                        title: dic['earn.dex.joinPool.back']!,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    Container(
                      width: 18,
                    ),
                    Expanded(
                      child: PluginButton(
                        backgroundColor: PluginColorsDark.headline1,
                        title: dic['earn.add']!,
                        onPressed: () => Navigator.of(context).popAndPushNamed(
                            TaigaAddLiquidityPage.route,
                            arguments: {'poolId': "sa://0"}),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        )));
  }
}
