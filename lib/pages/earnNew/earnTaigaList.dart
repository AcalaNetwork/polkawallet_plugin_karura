import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_plugin_karura/api/types/dexPoolInfoData.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/connectionChecker.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTokenIcon.dart';
import 'package:polkawallet_ui/components/v3/plugin/roundedPluginCard.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class EarnTaigaList extends StatefulWidget {
  EarnTaigaList(this.plugin, this.keyring, {Key? key}) : super(key: key);
  final PluginKarura plugin;
  final Keyring keyring;

  @override
  State<EarnTaigaList> createState() => _EarnTaigaListState();
}

class _EarnTaigaListState extends State<EarnTaigaList> {
  List<DexPoolData>? taigaPoolData;

  Future<void> _queryTaigaPoolInfo() async {
    final info = await widget.plugin.api!.earn
        .getTaigaPoolInfo(widget.keyring.current.address!);
    widget.plugin.store!.earn.setTaigaPoolInfo(info);
    taigaPoolData = await widget.plugin.api!.earn.getTaigaTokenPairs();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    return Observer(builder: (_) {
      var dexPools = widget.plugin.store!.earn.taigaPoolInfoMap;
      return Column(
        children: [
          ConnectionChecker(
            widget.plugin,
            onConnected: _queryTaigaPoolInfo,
          ),
          Expanded(
              child: dexPools.length == 0
                  ? ListView(
                      padding: EdgeInsets.all(16),
                      children: [
                        Center(
                          child: Container(
                            height: MediaQuery.of(context).size.width,
                            child: ListTail(
                              isEmpty: true,
                              isLoading: false,
                              color: Colors.white,
                            ),
                          ),
                        )
                      ],
                    )
                  : GridView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: dexPools.length,
                      itemBuilder: (_, i) {
                        final taigaPoolInfo =
                            dexPools[dexPools.keys.toList()[i]];

                        final balance = AssetsUtils.getBalanceFromTokenNameId(
                            widget.plugin, dexPools.keys.toList()[i]);
                        final price = AssetsUtils.getMarketPrice(
                            widget.plugin, balance.symbol!);

                        final tokenSymbol = balance.symbol;

                        var apy = 0.0;
                        taigaPoolInfo?.apy.forEach((key, value) {
                          apy += value;
                        });

                        return GestureDetector(
                          child: RoundedPluginCard(
                              borderRadius: const BorderRadius.all(
                                  const Radius.circular(9)),
                              child: Column(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    alignment: Alignment.centerLeft,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(9),
                                          topRight: Radius.circular(9)),
                                    ),
                                    padding: EdgeInsets.only(
                                        left: 12, top: 7, right: 8, bottom: 9),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        PluginTokenIcon(
                                          tokenSymbol ?? "",
                                          widget.plugin.tokenIcons,
                                          size: 24,
                                        ),
                                        // Row(
                                        //   children: [
                                        //     Visibility(
                                        //         visible: unstaked,
                                        //         child: Padding(
                                        //             padding: EdgeInsets.only(
                                        //                 left: 4),
                                        //             child: Image.asset(
                                        //               "packages/polkawallet_plugin_karura/assets/images/unstaked.png",
                                        //               width: 24,
                                        //             ))),
                                        //     Visibility(
                                        //         visible: (poolInfo?.shares ??
                                        //                 BigInt.zero) !=
                                        //             BigInt.zero,
                                        //         child: Padding(
                                        //             padding: EdgeInsets.only(
                                        //                 left: 4),
                                        //             child: SvgPicture.asset(
                                        //               "packages/polkawallet_plugin_karura/assets/images/staked.svg",
                                        //               color: Colors.white,
                                        //               width: 24,
                                        //             ))),
                                        //     Visibility(
                                        //         visible: canClaim,
                                        //         child: Padding(
                                        //             padding: EdgeInsets.only(
                                        //                 left: 4),
                                        //             child: Image.asset(
                                        //               "packages/polkawallet_plugin_karura/assets/images/rewards.png",
                                        //               width: 24,
                                        //             ))),
                                        //   ],
                                        // )
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                      child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.only(
                                        left: 12, top: 6, right: 12),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.only(
                                            bottomLeft: Radius.circular(9),
                                            bottomRight: Radius.circular(9)),
                                        color: Color(0xFF494b4e)),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          PluginFmt.tokenView(tokenSymbol),
                                          style: Theme.of(context)
                                              .textTheme
                                              .headline4
                                              ?.copyWith(
                                                  color: Color(0xBDFFFFFF),
                                                  fontWeight: FontWeight.w600),
                                        ),
                                        Padding(
                                            padding: EdgeInsets.only(top: 17),
                                            child: Text(
                                              dic['earn.apy']!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headline3
                                                  ?.copyWith(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      height: 1.0,
                                                      fontSize: UI.getTextSize(
                                                          24, context)),
                                            )),
                                        Text(
                                          Fmt.ratio(apy),
                                          style: Theme.of(context)
                                              .textTheme
                                              .headline3
                                              ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  height: 1.0,
                                                  fontSize: UI.getTextSize(
                                                      24, context)),
                                        ),
                                        Text(
                                          '${dic['earn.staked']} \$${Fmt.priceFloorFormatter(Fmt.balanceDouble(taigaPoolInfo?.totalShares ?? "", balance.decimals!) * price)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headline5
                                              ?.copyWith(
                                                  color: Color(0xBDFFFFFF)),
                                        ),
                                      ],
                                    ),
                                  )),
                                ],
                              )),
                          onTap: () {
                            // => Navigator.of(context).pushNamed(
                            //   EarnDetailPage.route,
                            //   arguments: {'poolId': dexPools[i].tokenNameId})
                          },
                        );
                      },
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 24,
                          crossAxisSpacing: 20,
                          childAspectRatio: 168 / 190.0),
                    ))
        ],
      );
    });
  }
}
