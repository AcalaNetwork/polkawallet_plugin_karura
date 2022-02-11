import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:polkawallet_plugin_karura/api/types/dexPoolInfoData.dart';
import 'package:polkawallet_plugin_karura/common/constants/base.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/pages/earn/addLiquidityPage.dart';
import 'package:polkawallet_plugin_karura/pages/swap/bootstrapPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/infoItem.dart';
import 'package:polkawallet_ui/components/infoItemRow.dart';
import 'package:polkawallet_ui/components/linearProgressBar.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/tapTooltip.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginLoadingWidget.dart';
import 'package:polkawallet_ui/utils/format.dart';

class BootstrapList extends StatefulWidget {
  BootstrapList(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  @override
  _BootstrapListState createState() => _BootstrapListState();
}

class _BootstrapListState extends State<BootstrapList> {
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      new GlobalKey<RefreshIndicatorState>();

  int _bestNumber = 0;

  Map<String?, List> _userProvisions = {};
  Map<String?, List?> _initialShareRates = {};

  bool _withStake = true;
  bool _claimSubmitting = false;

  Future<void> _updateBestNumber() async {
    final res = await widget.plugin.sdk.webView!
        .evalJavascript('api.derive.chain.bestNumber()');
    final blockNumber = int.parse(res.toString());
    if (mounted) {
      setState(() {
        _bestNumber = blockNumber;
      });
    }
  }

  Future<void> _updateData() async {
    _updateBestNumber();

    await Future.wait([
      widget.plugin.service!.earn.getDexPools(),
      widget.plugin.service!.earn.getBootstraps(),
      _queryUserProvisions(),
      widget.plugin.service!.assets
          .queryMarketPrices([relay_chain_token_symbol]),
    ]);

    if (_userProvisions.keys.length > 0) {
      await widget.plugin.service!.earn.queryIncentives();
    }
  }

  Future<void> _queryUserProvisions() async {
    final query = widget.plugin.store!.earn.dexPools.map((e) {
      final pool = jsonEncode(e.tokens);
      return 'Promise.all(['
          'api.query.dex.provisioningPool($pool, "${widget.keyring.current.address}"),'
          'api.query.dex.initialShareExchangeRates($pool)'
          '])';
    }).join(',');
    final res = await widget.plugin.sdk.webView!
        .evalJavascript('Promise.all([$query])');
    final Map<String?, List> provisions = {};
    final Map<String?, List?> shareRates = {};
    widget.plugin.store!.earn.dexPools.asMap().forEach((i, e) {
      final provision = res[i][0] as List;
      if (BigInt.parse(provision[0].toString()) > BigInt.zero ||
          BigInt.parse(provision[1].toString()) > BigInt.zero) {
        provisions[e.tokenNameId] = provision;
      }
      shareRates[e.tokenNameId] = res[i][1] as List?;
    });
    if (mounted) {
      setState(() {
        _userProvisions = provisions;
        _initialShareRates = shareRates;
      });
    }
  }

  TxConfirmParams _claimLPToken(
      DexPoolData pool, BigInt amount, int decimals, String poolTokenSymbol) {
    setState(() {
      _claimSubmitting = true;
    });
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala');
    final params = [
      widget.keyring.current.address,
      pool.tokens![0],
      pool.tokens![1]
    ];
    if (_withStake) {
      final batchTxs = [
        'api.tx.dex.claimDexShare(...${jsonEncode(params)})',
        'api.tx.incentives.depositDexShare(...${jsonEncode([
              {'DEXShare': pool.tokens},
              amount.toString()
            ])})',
      ];
      return TxConfirmParams(
        txTitle: 'Claim LP Token',
        module: 'utility',
        call: 'batch',
        txDisplay: {
          dic!['earn.pool']: poolTokenSymbol,
          "": dic['earn.withStake.info'],
        },
        txDisplayBold: {
          dic['loan.amount']!: Text(
            '${Fmt.priceFloorBigInt(amount, decimals, lengthMax: 4)} LP',
            style: Theme.of(context).textTheme.headline1,
          ),
        },
        params: [],
        rawParams: '[[${batchTxs.join(',')}]]',
      );
    }
    return TxConfirmParams(
        txTitle: 'Claim LP Token',
        module: 'dex',
        call: 'claimDexShare',
        txDisplay: {
          dic!['earn.pool']: poolTokenSymbol,
        },
        txDisplayBold: {
          dic['loan.amount']!: Text(
            '${Fmt.priceFloorBigInt(amount, decimals, lengthMax: 4)} LP',
            style: Theme.of(context).textTheme.headline1,
          ),
        },
        params: [
          widget.keyring.current.address,
          pool.tokens![0],
          pool.tokens![1]
        ]);
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _refreshKey.currentState!.show();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      final bootstraps = widget.plugin.store!.earn.bootstraps.toList();
      final dexPools = widget.plugin.store!.earn.dexPools.toList();
      dexPools.retainWhere((e) => _userProvisions.keys.contains(e.tokenNameId));

      return RefreshIndicator(
        key: _refreshKey,
        onRefresh: _updateData,
        child: ListView(
          padding: EdgeInsets.fromLTRB(8, 16, 8, 16),
          children: bootstraps.length == 0 && dexPools.length == 0
              ? ([
                  Center(
                    child: Container(
                      height: MediaQuery.of(context).size.width,
                      child: ListTail(isEmpty: true, isLoading: false),
                    ),
                  )
                ])
              : [
                  ...bootstraps.map((e) {
                    return _BootStrapCard(
                      plugin: widget.plugin,
                      pool: e,
                      bestNumber: _bestNumber,
                      tokenIcons: widget.plugin.tokenIcons,
                      relayChainTokenPrice: widget.plugin.store!.assets
                          .marketPrices[relay_chain_token_symbol],
                    );
                  }).toList(),
                  ...dexPools.map((e) {
                    final balancePair = e.tokens!
                        .map((e) => AssetsUtils.tokenDataFromCurrencyId(
                            widget.plugin, e))
                        .toList();
                    return _BootStrapCardEnabled(
                      widget.plugin,
                      pool: e,
                      userProvision: _userProvisions[e.tokenNameId],
                      shareRate: _initialShareRates[e.tokenNameId],
                      tokenIcons: widget.plugin.tokenIcons,
                      existentialDeposit: Fmt.priceCeilBigInt(
                          Fmt.balanceInt(balancePair[0]!.minBalance),
                          balancePair[0]!.decimals!,
                          lengthMax: 6),
                      withStake: _withStake,
                      onWithStakeChange: (v) {
                        setState(() {
                          _withStake = v;
                        });
                      },
                      onClaimLP: _claimLPToken,
                      onFinish: (res) async {
                        if (res != null) {
                          await _refreshKey.currentState!.show();
                        }
                        setState(() {
                          _claimSubmitting = false;
                        });
                      },
                      submitting: _claimSubmitting,
                    );
                  }).toList(),
                ],
        ),
      );
    });
  }
}

class _BootStrapCard extends StatelessWidget {
  _BootStrapCard(
      {this.plugin,
      this.pool,
      this.bestNumber,
      this.tokenIcons,
      this.relayChainTokenPrice});

  final PluginKarura? plugin;
  final DexPoolData? pool;
  final int? bestNumber;
  final Map<String, Widget>? tokenIcons;
  final double? relayChainTokenPrice;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    final primaryColor = Theme.of(context).primaryColor;
    final colorGrey = Theme.of(context).unselectedWidgetColor;

    final balancePair = pool!.tokens!
        .map((e) => AssetsUtils.tokenDataFromCurrencyId(plugin, e))
        .toList();
    final poolSymbol = balancePair.map((e) => e!.symbol).join('-');
    final tokenPairView =
        balancePair.map((e) => PluginFmt.tokenView(e!.symbol ?? '')).toList();

    final targetLeft =
        Fmt.balanceInt(pool!.provisioning!.targetProvision![0].toString());
    final targetRight =
        Fmt.balanceInt(pool!.provisioning!.targetProvision![1].toString());
    final nowLeft =
        Fmt.balanceInt(pool!.provisioning!.accumulatedProvision![0].toString());
    final nowRight =
        Fmt.balanceInt(pool!.provisioning!.accumulatedProvision![1].toString());
    final progressLeft = nowLeft / targetLeft;
    final progressRight = nowRight / targetRight;
    final ratio = nowLeft > BigInt.zero
        ? Fmt.bigIntToDouble(nowRight, balancePair[1]!.decimals!) /
            Fmt.bigIntToDouble(nowLeft, balancePair[0]!.decimals!)
        : 1.0;
    final blocksEnd = pool!.provisioning!.notBefore! - bestNumber!;
    final time = bestNumber! > 0
        ? DateTime.now()
            .add(Duration(milliseconds: BLOCK_TIME_DEFAULT * blocksEnd))
        : null;

    String ratioView =
        '1 ${tokenPairView[0]} : ${Fmt.priceCeil(ratio, lengthMax: 6)} ${tokenPairView[1]}';
    if (poolSymbol == 'KAR-KSM') {
      final priceView = relayChainTokenPrice == null
          ? '--.--'
          : Fmt.priceFloor(relayChainTokenPrice! * ratio);
      ratioView += '\n1 ${tokenPairView[0]} ≈ \$$priceView';
    }
    return RoundedCard(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                child: TokenIcon(poolSymbol, tokenIcons!),
                margin: EdgeInsets.only(right: 8),
              ),
              Expanded(
                  child: Text(
                tokenPairView.join('-'),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colorGrey,
                ),
              )),
              Text(
                dic['boot.provision']!,
                style: TextStyle(
                  fontSize: 12,
                  color: primaryColor,
                ),
              )
            ],
          ),
          Divider(height: 24),
          Container(
            margin: EdgeInsets.only(bottom: 8),
            child: Text(
              dic['boot.provision.info']!,
              style: TextStyle(color: colorGrey),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.only(right: 16),
                child: _Checkbox(progressLeft >= 1 || progressRight >= 1),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dic['boot.provision.condition.1']!),
                  Row(
                    children: [
                      Text(
                          '${Fmt.priceCeilBigInt(targetLeft, balancePair[0]!.decimals!)} ${tokenPairView[0]}'),
                      Text(
                        ' (${Fmt.ratio(progressLeft)} ${dic['boot.provision.met']})',
                        style: TextStyle(color: primaryColor),
                      ),
                    ],
                  ),
                  LinearProgressbar(
                    margin: EdgeInsets.only(top: 4, bottom: 4),
                    width: MediaQuery.of(context).size.width - 88,
                    progress: progressLeft,
                    color: primaryColor,
                  ),
                  Text(dic['boot.provision.or']!),
                  Row(
                    children: [
                      Text(
                          '${Fmt.priceCeilBigInt(targetRight, balancePair[1]!.decimals!)} ${tokenPairView[1]}'),
                      Text(
                        ' (${Fmt.ratio(progressRight)} ${dic['boot.provision.met']})',
                        style: TextStyle(color: primaryColor),
                      ),
                    ],
                  ),
                  LinearProgressbar(
                    margin: EdgeInsets.only(top: 4, bottom: 12),
                    width: MediaQuery.of(context).size.width - 88,
                    progress: progressRight,
                    color: primaryColor,
                  )
                ],
              )
            ],
          ),
          Row(
            children: [
              Container(
                margin: EdgeInsets.only(right: 16),
                child: _Checkbox(blocksEnd < 0),
              ),
              Text(dic['boot.provision.condition.2']! +
                  ' ' +
                  (time != null
                      ? DateFormat.yMd().format(time.toLocal())
                      : '--:--'))
            ],
          ),
          Divider(),
          Container(
            margin: EdgeInsets.only(bottom: 8),
            child: InfoItemRow(
                dic['boot.total']!,
                '${Fmt.priceCeilBigInt(nowLeft, balancePair[0]!.decimals!)} ${tokenPairView[0]}\n'
                '+ ${Fmt.priceCeilBigInt(nowRight, balancePair[1]!.decimals!)} ${tokenPairView[1]}'),
          ),
          Container(
            margin: EdgeInsets.only(bottom: 16),
            child: InfoItemRow(dic['boot.ratio']!, ratioView),
          ),
          RoundedButton(
            text: dic['boot.title'],
            onPressed: () {
              Navigator.of(context)
                  .pushNamed(BootstrapPage.route, arguments: pool);
            },
          )
        ],
      ),
    );
  }
}

class _BootStrapCardEnabled extends StatelessWidget {
  _BootStrapCardEnabled(this.plugin,
      {this.pool,
      this.userProvision,
      this.shareRate,
      this.tokenIcons,
      this.existentialDeposit,
      this.withStake,
      this.onWithStakeChange,
      required this.onClaimLP,
      this.onFinish,
      this.submitting});

  final PluginKarura plugin;
  final DexPoolData? pool;
  final List? userProvision;
  final List? shareRate;
  final Map<String, Widget>? tokenIcons;
  final String? existentialDeposit;
  final bool? withStake;
  final Function(bool)? onWithStakeChange;
  final TxConfirmParams Function(DexPoolData, BigInt, int, String) onClaimLP;
  final Function(Map?)? onFinish;
  final bool? submitting;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    final primaryColor = Theme.of(context).primaryColor;
    final colorGrey = Theme.of(context).unselectedWidgetColor;

    final balancePair = pool!.tokens!
        .map((e) => AssetsUtils.tokenDataFromCurrencyId(plugin, e))
        .toList();
    final tokenPairView =
        balancePair.map((e) => PluginFmt.tokenView(e!.symbol ?? '')).toList();
    final poolTokenSymbol = tokenPairView.join('-');

    final userLeft = Fmt.balanceInt(userProvision![0].toString());
    final userRight = Fmt.balanceInt(userProvision![1].toString());
    final ratio = Fmt.balanceInt(shareRate![1].toString());
    final amount = userLeft + (userRight * ratio ~/ Fmt.tokenInt('1', 18));

    return RoundedCard(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                child: TokenIcon(poolTokenSymbol, tokenIcons!),
                margin: EdgeInsets.only(right: 8),
              ),
              Expanded(
                  child: Text(
                poolTokenSymbol,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colorGrey,
                ),
              )),
              Text(
                dic['boot.enabled']!,
                style: TextStyle(
                  fontSize: 12,
                  color: primaryColor,
                ),
              )
            ],
          ),
          Divider(height: 24),
          Container(
            margin: EdgeInsets.only(bottom: 16),
            child: Text(dic['boot.my']!),
          ),
          Row(
            children: [
              InfoItem(
                crossAxisAlignment: CrossAxisAlignment.center,
                title: tokenPairView[0],
                content:
                    Fmt.priceFloorBigInt(userLeft, balancePair[0]!.decimals!),
              ),
              InfoItem(
                crossAxisAlignment: CrossAxisAlignment.center,
                title: tokenPairView[1],
                content:
                    Fmt.priceFloorBigInt(userRight, balancePair[1]!.decimals!),
              ),
            ],
          ),
          Divider(height: 24),
          Container(
            margin: EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TapTooltip(
                  message: dic['cross.exist.msg']!,
                  child: Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Text(dic['transfer.exist']!),
                      ),
                      Icon(
                        Icons.info,
                        size: 16,
                        color: Theme.of(context).unselectedWidgetColor,
                      ),
                    ],
                  ),
                ),
                Expanded(child: Container(width: 2)),
                Text(existentialDeposit!,
                    style: Theme.of(context).textTheme.headline4),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(bottom: 8),
            child: InfoItemRow(
                'LP tokens',
                Fmt.priceFloorBigInt(amount, balancePair[0]!.decimals!,
                    lengthMax: 4)),
          ),
          Container(
            margin: EdgeInsets.only(top: 8, bottom: 16),
            padding: EdgeInsets.fromLTRB(8, 8, 8, 16),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.black12, width: 0.5),
                borderRadius: BorderRadius.all(Radius.circular(8))),
            child: StakeLPTips(
              plugin,
              pool: pool,
              poolSymbol: poolTokenSymbol,
              switchActive: withStake,
              onSwitch: onWithStakeChange,
            ),
          ),
          submitting!
              ? RoundedButton(
                  text: 'Claim LP Tokens',
                  icon: PluginLoadingWidget(),
                )
              : TxButton(
                  text: 'Claim LP Tokens',
                  getTxParams: () async => onClaimLP(pool!, amount,
                      balancePair[0]!.decimals!, poolTokenSymbol),
                  onFinish: onFinish,
                )
        ],
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  _Checkbox(this.checked);
  final bool checked;
  @override
  Widget build(BuildContext context) {
    return Icon(checked ? Icons.check_box : Icons.check_box_outline_blank,
        size: 24,
        color: checked
            ? Theme.of(context).primaryColor
            : Theme.of(context).unselectedWidgetColor);
  }
}
