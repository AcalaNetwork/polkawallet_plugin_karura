import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:polkawallet_plugin_karura/api/types/transferData.dart';
import 'package:polkawallet_plugin_karura/common/constants/subQuery.dart';
import 'package:polkawallet_plugin_karura/pages/assets/transferDetailPage.dart';
import 'package:polkawallet_plugin_karura/pages/assets/transferPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/TransferIcon.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/borderedTitle.dart';
import 'package:polkawallet_ui/components/v3/cardButton.dart';
import 'package:polkawallet_ui/components/v3/iconButton.dart' as v3;
import 'package:polkawallet_ui/components/v3/plugin/pluginLoadingWidget.dart';
import 'package:polkawallet_ui/pages/accountQrCodePage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class TokenDetailPage extends StatefulWidget {
  TokenDetailPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static final String route = '/assets/token/detail';

  @override
  _TokenDetailPageSate createState() => _TokenDetailPageSate();
}

class _TokenDetailPageSate extends State<TokenDetailPage> {
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      new GlobalKey<RefreshIndicatorState>();

  final colorIn = Color(0xFF62CFE4);
  final colorOut = Color(0xFF3394FF);

  int _txFilterIndex = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final TokenBalanceData token =
          ModalRoute.of(context)!.settings.arguments as TokenBalanceData;
      widget.plugin.service!.assets.updateTokenBalances(token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'common')!;

    final TokenBalanceData token =
        ModalRoute.of(context)!.settings.arguments as TokenBalanceData;

    final titleColor = Theme.of(context).cardColor;

    final filterOptions = [dic['all'], dic['in'], dic['out']];

    return Scaffold(
      appBar: AppBar(
          title: Text(PluginFmt.tokenView(token.symbol)),
          centerTitle: true,
          elevation: 0.0,
          leading: BackBtn()),
      body: Observer(
        builder: (_) {
          final tokenSymbol = token.symbol;
          final balance = AssetsUtils.getBalanceFromTokenNameId(
              widget.plugin, token.tokenNameId);

          final tokensConfig =
              widget.plugin.store!.setting.remoteConfig['tokens'] ?? {};
          final disabledTokens = tokensConfig['disabled'];
          bool transferDisabled = false;
          if (disabledTokens != null) {
            transferDisabled = List.of(disabledTokens).contains(tokenSymbol);
          }
          return RefreshIndicator(
            key: _refreshKey,
            onRefresh: () =>
                widget.plugin.service!.assets.updateTokenBalances(token),
            child: Column(
              children: <Widget>[
                BalanceCard(
                  balance,
                  symbol: tokenSymbol ?? '',
                  decimals: token.decimals!,
                  tokenPrice:
                      widget.plugin.store?.assets.marketPrices[tokenSymbol] ??
                          0,
                  bgColors: [Color(0xFF2B292A), Color(0xFFCD4337)],
                  icon: TokenIcon(
                    tokenSymbol ?? '',
                    widget.plugin.tokenIcons,
                    size: 45,
                  ),
                ),
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 3.w),
                            child: CardButton(
                              icon: Padding(
                                padding: EdgeInsets.only(left: 3),
                                child: Image.asset(
                                  "packages/polkawallet_plugin_karura/assets/images/send.png",
                                  width: 37,
                                ),
                              ),
                              text: dic['send']!,
                              onPressed: transferDisabled
                                  ? null
                                  : () {
                                      Navigator.pushNamed(
                                        context,
                                        TransferPage.route,
                                        arguments: {
                                          'tokenNameId': token.tokenNameId
                                        },
                                      );
                                    },
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 3.w),
                            child: CardButton(
                              icon: Image.asset(
                                  "packages/polkawallet_plugin_karura/assets/images/qr.png",
                                  width: 37),
                              text: dic['receive']!,
                              onPressed: () {
                                Navigator.pushNamed(
                                    context, AccountQrCodePage.route);
                              },
                            ),
                          ),
                        ),
                      ],
                    )),
                Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        BorderedTitle(
                            title: I18n.of(context)!.getDic(
                                i18n_full_dic_karura, 'acala')!['loan.txs']),
                        Row(
                          children: [
                            Container(
                              width: 36.w,
                              height: 28.h,
                              margin: EdgeInsets.only(right: 8.w),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                image: DecorationImage(
                                    image: AssetImage(
                                        "packages/polkawallet_plugin_karura/assets/images/bg_tag.png"),
                                    fit: BoxFit.fill),
                              ),
                              child: Center(
                                child: Text(filterOptions[_txFilterIndex]!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headline5
                                        ?.copyWith(
                                            color: Theme.of(context)
                                                .toggleableActiveColor,
                                            fontWeight: FontWeight.w600)),
                              ),
                            ),
                            GestureDetector(
                                onTap: () {
                                  showCupertinoModalPopup(
                                      context: context,
                                      builder: (context) {
                                        return CupertinoActionSheet(
                                          actions: filterOptions.map((e) {
                                            return CupertinoButton(
                                                child: Text(e!),
                                                onPressed: () {
                                                  setState(() {
                                                    _txFilterIndex =
                                                        filterOptions
                                                            .indexOf(e);
                                                  });
                                                  Navigator.pop(context);
                                                });
                                          }).toList(),
                                          cancelButton: CupertinoButton(
                                            child: Text(dic['cancel']!),
                                            onPressed: () =>
                                                Navigator.pop(context),
                                          ),
                                        );
                                      });
                                },
                                child: v3.IconButton(
                                  icon: SvgPicture.asset(
                                    'assets/images/icon_screening.svg',
                                    color: Color(0xFF979797),
                                    width: 22.h,
                                  ),
                                ))
                          ],
                        )
                      ],
                    )),
                Expanded(
                  child: Container(
                    color: titleColor,
                    child: Query(
                        options: QueryOptions(
                          document: gql(transferQuery),
                          variables: <String, String?>{
                            'account': widget.keyring.current.address,
                            'token': token.tokenNameId,
                          },
                        ),
                        builder: (
                          QueryResult result, {
                          Future<QueryResult?> Function()? refetch,
                          FetchMore? fetchMore,
                        }) {
                          if (result.data == null) {
                            return Container(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [PluginLoadingWidget()],
                              ),
                            );
                          }
                          final txs =
                              List.of(result.data!['transfers']['nodes'])
                                  .map((i) =>
                                      TransferData.fromJson(i as Map, token))
                                  .toList();
                          txs.removeWhere((e) =>
                              e.to == widget.keyring.current.address &&
                              e.isSuccess == false);

                          if (_txFilterIndex > 0) {
                            txs.retainWhere((e) =>
                                (_txFilterIndex == 1 ? e.to : e.from) ==
                                widget.keyring.current.address);
                          }
                          return ListView.builder(
                            itemCount: txs.length + 1,
                            itemBuilder: (_, i) {
                              if (i == txs.length) {
                                return ListTail(
                                    isEmpty: txs.length == 0, isLoading: false);
                              }
                              return TransferListItem(
                                data: txs[i],
                                token: tokenSymbol,
                                isOut: txs[i].from ==
                                    widget.keyring.current.address,
                              );
                            },
                          );
                        }),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Widget priceItemBuild(Widget icon, String title, String price, Color color,
    BuildContext context) {
  return Padding(
      padding: EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
              height: 16.w,
              width: 16.w,
              margin: EdgeInsets.only(right: 8.w),
              child: icon),
          Text(
            title,
            style: TextStyle(
                color: color,
                fontSize: UI.getTextSize(12, context),
                fontWeight: FontWeight.w600,
                fontFamily: UI.getFontFamily('TitilliumWeb', context)),
          ),
          Expanded(
            child: Text(
              price,
              textAlign: TextAlign.end,
              style: TextStyle(
                  color: color,
                  fontSize: UI.getTextSize(12, context),
                  fontWeight: FontWeight.w400,
                  fontFamily: UI.getFontFamily('TitilliumWeb', context)),
            ),
          )
        ],
      ));
}

class BalanceCard extends StatelessWidget {
  BalanceCard(
    this.tokenBalance, {
    this.tokenPrice,
    required this.symbol,
    required this.decimals,
    this.bgColors,
    this.icon,
  });

  final String symbol;
  final int decimals;
  final TokenBalanceData? tokenBalance;
  final double? tokenPrice;
  final List<Color>? bgColors;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'common')!;

    final free = Fmt.balanceInt(tokenBalance?.amount ?? '0');
    final locked = Fmt.balanceInt(tokenBalance?.locked ?? '0');
    final reserved = Fmt.balanceInt(tokenBalance?.reserved ?? '0');
    final transferable = free - locked;
    final total = free + reserved;

    double? tokenValue;
    if (tokenPrice != null) {
      tokenValue = (tokenPrice ?? 0) > 0
          ? tokenPrice! * Fmt.bigIntToDouble(total, decimals)
          : 0;
    }

    final titleColor = Theme.of(context).cardColor;
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(const Radius.circular(16)),
        gradient: LinearGradient(
          colors: bgColors ??
              [Theme.of(context).primaryColor, Theme.of(context).hoverColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            // color: primaryColor.withAlpha(100),
            color: Color(0x4D000000),
            blurRadius: 5.0,
            spreadRadius: 1.0,
            offset: Offset(5.0, 5.0),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
              padding: EdgeInsets.only(bottom: 22.h),
              child: Row(
                children: [
                  Container(margin: EdgeInsets.only(right: 8), child: icon),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        Fmt.priceFloorBigInt(total, decimals, lengthMax: 8),
                        style: TextStyle(
                            color: titleColor,
                            fontSize: UI.getTextSize(20, context),
                            letterSpacing: -0.8,
                            fontWeight: FontWeight.w600,
                            fontFamily:
                                UI.getFontFamily('TitilliumWeb', context)),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Visibility(
                        visible: tokenValue != null,
                        child: Text(
                          '≈ \$ ${Fmt.priceFloor(tokenValue)}',
                          style: Theme.of(context)
                              .textTheme
                              .headline6
                              ?.copyWith(
                                  color: titleColor,
                                  letterSpacing: -0.8,
                                  fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              )),
          Container(
            width: MediaQuery.of(context).size.width * 0.5,
            child: Column(
              children: [
                priceItemBuild(
                    SvgPicture.asset(
                      'assets/images/transferrable_icon.svg',
                      color: titleColor,
                    ),
                    dic['asset.transferable']!,
                    Fmt.priceFloorBigInt(
                      transferable,
                      decimals,
                      lengthMax: 4,
                    ),
                    titleColor,
                    context),
                priceItemBuild(
                    SvgPicture.asset(
                      'assets/images/locked_icon.svg',
                      color: titleColor,
                    ),
                    dic['asset.lock']!,
                    Fmt.priceFloorBigInt(
                      locked,
                      decimals,
                      lengthMax: 4,
                    ),
                    titleColor,
                    context),
                priceItemBuild(
                    SvgPicture.asset(
                      'assets/images/reversed_icon.svg',
                      color: titleColor,
                    ),
                    dic['asset.reserve']!,
                    Fmt.priceFloorBigInt(
                      locked,
                      decimals,
                      lengthMax: 4,
                    ),
                    titleColor,
                    context),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TransferListItem extends StatelessWidget {
  TransferListItem({
    this.data,
    this.token,
    this.isOut,
    this.crossChain,
  });

  final TransferData? data;
  final String? token;
  final String? crossChain;
  final bool? isOut;

  @override
  Widget build(BuildContext context) {
    final address = isOut! ? data!.to : data!.from;
    final title = Fmt.address(address);
    return ListTile(
      dense: true,
      leading: data!.isSuccess!
          ? isOut!
              ? TransferIcon(
                  type: TransferIconType.rollOut,
                  bgColor: Theme.of(context).cardColor)
              : TransferIcon(
                  type: TransferIconType.rollIn,
                  bgColor: Theme.of(context).cardColor)
          : TransferIcon(
              type: TransferIconType.failure, bgColor: Color(0xFFD7D7D7)),
      title: Text('$title${crossChain != null ? ' ($crossChain)' : ''}'),
      subtitle: Text(Fmt.dateTime(DateTime.parse(data!.timestamp))),
      trailing: Container(
        width: 110,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                '${isOut! ? '-' : '+'} ${data!.amount}',
                style: Theme.of(context).textTheme.headline5!.copyWith(
                    color: data!.isSuccess!
                        ? Theme.of(context).toggleableActiveColor
                        : Theme.of(context).unselectedWidgetColor,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
      onTap: () {
        Navigator.pushNamed(
          context,
          TransferDetailPage.route,
          arguments: data,
        );
      },
    );
  }
}
