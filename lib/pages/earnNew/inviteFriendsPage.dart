import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_karura/api/types/dexPoolInfoData.dart';
import 'package:polkawallet_plugin_karura/pages/earnNew/addLiquidityPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginOutlinedButtonSmall.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTokenIcon.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:qr_flutter_fork/qr_flutter_fork.dart';

class InviteFriendsPage extends StatelessWidget {
  InviteFriendsPage(this.plugin, this.keyring, {Key? key}) : super(key: key);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/karura/earn/inviteFriends';

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;

    final DexPoolData pool =
        ModalRoute.of(context)!.settings.arguments as DexPoolData;
    final balancePair = pool.tokens!
        .map((e) => AssetsUtils.tokenDataFromCurrencyId(plugin, e))
        .toList();

    final size = MediaQuery.of(context).size.width - 32 * 2;

    double rewardAPR = 0;
    double savingRewardAPR = 0;
    final incentiveV2 = plugin.store!.earn.incentives;
    if (incentiveV2.dex != null) {
      (incentiveV2.dex![pool.tokenNameId!] ?? []).forEach((e) {
        rewardAPR += e.apr ?? 0;
      });
      (incentiveV2.dexSaving[pool.tokenNameId!] ?? []).forEach((e) {
        savingRewardAPR += e.apr ?? 0;
      });
    }

    final url =
        "https://polkawallet.io${AddLiquidityPage.route}?poolId=${Uri.encodeComponent(pool.tokenNameId!)}";

    return PluginScaffold(
      appBar: PluginAppBar(
          title: Text(dic['v3.earn.inviteFriends']!), centerTitle: true),
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 16,
            right: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  padding:
                      EdgeInsets.only(left: 14, right: 24, top: 12, bottom: 12),
                  decoration: BoxDecoration(
                      color: Color(0x1AD8D8D8),
                      borderRadius:
                          BorderRadius.only(topRight: Radius.circular(14))),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PluginTokenIcon(
                        PluginFmt.tokenView(
                            balancePair.map((e) => e!.symbol).join('-')),
                        plugin.tokenIcons,
                        size: 40,
                      ),
                      Container(
                        margin: EdgeInsets.only(left: 16),
                        child: Text(
                            PluginFmt.tokenView(
                                balancePair.map((e) => e!.symbol).join('-')),
                            style: Theme.of(context)
                                .textTheme
                                .headline3
                                ?.copyWith(fontSize: 18, color: Colors.white)),
                      )
                    ],
                  )),
              Container(
                padding:
                    EdgeInsets.only(left: 16, right: 16, top: 40, bottom: 40),
                decoration: BoxDecoration(
                    color: Color(0xFFFFFFFF).withAlpha(36),
                    borderRadius: BorderRadius.only(
                        topRight: Radius.circular(14),
                        bottomLeft: Radius.circular(14),
                        bottomRight: Radius.circular(14))),
                child: Container(
                  width: size,
                  height: size,
                  padding: EdgeInsets.all(3),
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [
                            Color(0x08FFFFFF),
                            Color(0x24FFFFFF),
                            Color(0xFFFF7849)
                          ],
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                          stops: [0.1, 0.15, 1.0]),
                      borderRadius: BorderRadius.circular(size / 2)),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                        color: Color(0xFF24262A),
                        borderRadius: BorderRadius.circular((size - 6) / 2)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('APR',
                            style: Theme.of(context)
                                .textTheme
                                .headline4
                                ?.copyWith(color: Colors.white)),
                        Text(Fmt.ratio(rewardAPR + savingRewardAPR),
                            style: Theme.of(context)
                                .textTheme
                                .headline3
                                ?.copyWith(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    height: 1.0)),
                        Image.asset(
                          'packages/polkawallet_plugin_karura/assets/images/invite_friends.png',
                          height: size - 90,
                        )
                      ],
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 20, bottom: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        QrImage(
                          padding: EdgeInsets.zero,
                          data: url,
                          size: 58,
                          foregroundColor: Colors.white,
                        ),
                        Padding(
                            padding: EdgeInsets.only(right: 13, left: 15),
                            child: Text(
                              dic['v3.earn.scanMessage']!,
                              style: Theme.of(context)
                                  .textTheme
                                  .headline4
                                  ?.copyWith(color: Colors.white),
                            ))
                      ],
                    ),
                  ),
                  PluginOutlinedButtonSmall(
                    active: true,
                    margin: EdgeInsets.zero,
                    padding: EdgeInsets.symmetric(horizontal: 33, vertical: 3),
                    color: Color(0xFFFF7849),
                    content: dic['v3.earn.copyLink']!,
                    onPressed: () => UI.copyAndNotify(context, url),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
